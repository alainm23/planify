// Planify Quick View — a GNOME Shell panel button with a quick-view popup
// for the Planify to-do app (https://github.com/alainm23/planify).
//
// Copyright © 2026 Planify contributors
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Tasks are read (never written) from Planify's SQLite database using the
// read-only `sqlite3` CLI via a subprocess. Completion is delegated to the
// Planify app through its exported `org.freedesktop.Application` action
// `complete`, so recurring tasks and Todoist sync stay consistent.

import Clutter from 'gi://Clutter';
import GLib from 'gi://GLib';
import Gio from 'gi://Gio';
import GObject from 'gi://GObject';
import Meta from 'gi://Meta';
import Pango from 'gi://Pango';
import Shell from 'gi://Shell';
import St from 'gi://St';

import {Extension, gettext as _, ngettext} from 'resource:///org/gnome/shell/extensions/extension.js';
import * as BoxPointer from 'resource:///org/gnome/shell/ui/boxpointer.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as PanelMenu from 'resource:///org/gnome/shell/ui/panelMenu.js';
import * as PopupMenu from 'resource:///org/gnome/shell/ui/popupMenu.js';

// GJS 1.88 no longer auto-promisifies Gio.DBusConnection.call.
Gio._promisify(Gio.DBusConnection.prototype, 'call');

const APP_ID = 'io.github.alainm23.planify';
const APP_DBUS_NAME = 'io.github.alainm23.planify';
const APP_DBUS_PATH = '/io/github/alainm23/planify';
const CLI_ID = 'io.github.alainm23.planify.cli';
const DEBUG_DBUS_NAME = 'io.github.alainm23.planify.QuickView';
const EXT_UUID = 'planify-quick-view@alainm23.github.io';
const DEBUG_DBUS_PATH = '/io/github/alainm23/planify/QuickView';

const BADGE_DOT_CHAR = '\u25CF';

const OPEN_MS = 220;
const CLOSE_MS = 160;
const FILE_MONITOR_DEBOUNCE_MS = 250;
const ROLLOVER_POLL_SECONDS = 120;
const MAX_QUERY_ROWS = 100;
const SENTINEL_ID = '__done__';
const DEFAULT_COLOR = '#3584e4';

// Priority semantics follow Todoist: 4 = P1 (most urgent), 1 = none.
// pqv-p4 deliberately has no rule — the base .pqv-circle look.
const PRIORITY_COLOR = {3: '#ff9f43', 4: '#ed5353'};

const DEBUG_IFACE_XML = `
<node>
  <interface name="io.github.alainm23.planify.QuickView">
    <method name="Toggle"/>
    <method name="Open"/>
    <method name="Close"/>
    <method name="Status">
      <arg type="s" direction="out" name="state"/>
    </method>
    <method name="Capture">
      <arg type="s" direction="in" name="path"/>
      <arg type="b" direction="out" name="ok"/>
    </method>
    <method name="Repaint">
      <arg type="b" direction="in" name="start"/>
    </method>
    <method name="RowDebug">
      <arg type="i" direction="in" name="index"/>
      <arg type="s" direction="out" name="info"/>
    </method>
    <method name="ToggleExpand">
      <arg type="i" direction="in" name="index"/>
    </method>
    <method name="ToggleAdd"/>
    <method name="DebugSubmit">
      <arg type="s" direction="in" name="text"/>
    </method>
  </interface>
</node>`;

// One statement returns the visible tasks plus today's completion count:
// tasks first (ORDER BY inside the subselect keeps that), then a sentinel
// row carrying the count even when the task list is empty. Dates are stored
// as local time ("YYYY-MM-DD" or "YYYY-MM-DDTHH:MM:SS(+offset)" inside the
// `due` JSON; the field can also be an empty string), so lexical comparison
// with date('now','localtime') matches Planify's own "Today" semantics.
const TASKS_SQL = `
WITH done AS (
  SELECT COUNT(*) AS c FROM Items
  WHERE checked = 1 AND COALESCE(is_deleted, 0) = 0 AND COALESCE(is_trash, 0) = 0
    AND substr(completed_at, 1, 10) = date('now', 'localtime')
),
pinned AS (
  SELECT i.id AS id,
         i.content AS content,
         i.description AS description,
         i.due AS due,
         i.priority AS priority,
         i.pinned AS pinned,
         i.parent_id AS parent_id,
         p.name AS project,
         p.color AS color
  FROM Items i JOIN Projects p ON p.id = i.project_id
  WHERE i.pinned = 1 AND i.checked = 0
    AND COALESCE(i.is_deleted, 0) = 0 AND COALESCE(i.is_trash, 0) = 0
    AND COALESCE(i.item_type, 'task') = 'task'
    AND COALESCE(p.is_deleted, 0) = 0 AND COALESCE(p.is_archived, 0) = 0
    AND COALESCE(i.due, '') != '' OR (i.pinned = 1 AND i.checked = 0)
  ORDER BY i.child_order ASC
  LIMIT 10
),
tasks AS (
  SELECT i.id AS id,
         i.content AS content,
         i.description AS description,
         i.due AS due,
         i.priority AS priority,
         i.pinned AS pinned,
         i.parent_id AS parent_id,
         p.name AS project,
         p.color AS color
  FROM Items i JOIN Projects p ON p.id = i.project_id
  WHERE i.checked = 0
    AND COALESCE(i.is_deleted, 0) = 0 AND COALESCE(i.is_trash, 0) = 0
    AND COALESCE(i.item_type, 'task') = 'task'
    AND COALESCE(p.is_deleted, 0) = 0 AND COALESCE(p.is_archived, 0) = 0
    AND json_valid(i.due) = 1
    AND COALESCE(json_extract(i.due, '$.date'), '') != ''
    AND substr(json_extract(i.due, '$.date'), 1, 10) <= date('now', 'localtime')
    AND i.pinned = 0
  ORDER BY substr(json_extract(i.due, '$.date'), 1, 10) ASC,
           i.priority DESC, i.child_order ASC
  LIMIT ${MAX_QUERY_ROWS}
)
SELECT id, content, description, due, priority, pinned, parent_id, project, color,
       1 AS is_pinned, NULL AS done_today FROM pinned
UNION ALL
SELECT id, content, description, due, priority, pinned, parent_id, project, color,
       0 AS is_pinned, NULL AS done_today FROM tasks
UNION ALL
SELECT '${SENTINEL_ID}', '', '', '', 0, 0, NULL, '', '', 0,
       (SELECT c FROM done)`;

function logInfo(msg) {
    console.log(`[planify-quick-view] ${msg}`);
}

function logWarn(msg) {
    console.warn(`[planify-quick-view] ${msg}`);
}

/** Local "today" as YYYY-MM-DD, matching how Planify stores dates. */
function todayStr() {
    return GLib.DateTime.new_now_local().format('%F');
}

/** Parse a Planify `due` JSON string into display metadata. */
function parseDue(dueJson) {
    try {
        const o = JSON.parse(dueJson);
        const date = typeof o.date === 'string' ? o.date : null;
        if (!date)
            return null;
        const hasTime = date.length > 10;
        return {
            date: date.slice(0, 10),
            time: hasTime ? date.slice(11, 16) : null,
            isRecurring: o.is_recurring === true,
        };
    } catch {
        return null;
    }
}

/** Project colors come from the user's DB; keep only safe hex values. */
function safeColor(color) {
    return /^#[0-9a-fA-F]{6}$/.test(color ?? '') ? color : DEFAULT_COLOR;
}

/**
 * Read-only view over Planify's SQLite database. Resolves the database
 * path (native install, Flatpak, or a settings override), spawns the
 * `sqlite3` CLI read-only for queries, and watches the file for changes.
 */
class PlanifyStore {
    constructor(settings, onChanged) {
        this._settings = settings;
        this._onChanged = onChanged || (() => {});
        this._cancellable = new Gio.Cancellable();
        this._generation = 0;
        this._monitor = null;
        this._monitorDebounceId = 0;
        this._retryId = 0;

        this.tasks = [];        // [{id, content, due{...}, priority, project, color, isSubtask, isOverdue}]
        this.doneToday = 0;
        this.dbFound = false;

        this._watchFile();
    }

    get dbPath() {
        let override = this._settings.get_string('database-path');
        // Never let a path be parsed as a sqlite3 CLI option.
        if (override.startsWith('-'))
            override = `./${override}`;
        if (override !== '')
            return override;

        const candidates = [
            GLib.build_filenamev([GLib.get_user_data_dir(), APP_ID, 'database.db']),
            GLib.build_filenamev([GLib.get_home_dir(), '.var', 'app', APP_ID,
                'data', APP_ID, 'database.db']),
        ];
        return candidates.find(p => GLib.file_test(p, GLib.FileTest.EXISTS)) || candidates[0];
    }

    _watchFile() {
        this._monitor?.cancel();
        this._monitor = null;

        if (!GLib.file_test(this.dbPath, GLib.FileTest.EXISTS))
            return;

        try {
            this._monitor = Gio.File.new_for_path(this.dbPath)
                .monitor(Gio.FileMonitorFlags.NONE, null);
            this._monitor.connect('changed', () => this._scheduleRefresh());
        } catch (e) {
            logWarn(`file monitor failed: ${e.message}`);
        }
    }

    _scheduleRefresh() {
        if (this._monitorDebounceId)
            return;
        this._monitorDebounceId = GLib.timeout_add(GLib.PRIORITY_DEFAULT,
            FILE_MONITOR_DEBOUNCE_MS, () => {
                this._monitorDebounceId = 0;
                this.refresh().catch(e => logWarn(`monitor refresh: ${e.message}`));
                return GLib.SOURCE_REMOVE;
            });
    }

    /** Re-arm the file watcher if the database appeared or moved. */
    rewatchIfStale() {
        if (!this._monitor)
            this._watchFile();
    }

    /** Query the DB, update the cache, notify the consumer. */
    refresh() {
        this.rewatchIfStale();

        if (!GLib.file_test(this.dbPath, GLib.FileTest.EXISTS)) {
            this._generation++;
            this.tasks = [];
            this.doneToday = 0;
            this.dbFound = false;
            this._onChanged(this.snapshot());
            return Promise.resolve(this.snapshot());
        }

        const generation = ++this._generation;
        return this._query(TASKS_SQL).then(rows => {
            if (generation !== this._generation)
                return this.snapshot(); // superseded by a newer query

            const today = todayStr();
            this.doneToday = 0;
            this.tasks = [];
            for (const row of rows) {
                if (row.id === SENTINEL_ID) {
                    this.doneToday = row.done_today ?? 0;
                    continue;
                }
                const due = parseDue(row.due) ||
                    {date: today, time: null, isRecurring: false};
                this.tasks.push({
                    id: row.id,
                    content: row.content ?? '',
                    description: row.description ?? '',
                    due,
                    priority: row.priority ?? 1,
                    project: row.project ?? '',
                    color: safeColor(row.color),
                    isSubtask: !!row.parent_id,
                    isPinned: row.is_pinned === 1,
                    isOverdue: !row.is_pinned && due.date < today,
                });
            }
            this.dbFound = true;
            this._onChanged(this.snapshot());
            return this.snapshot();
        });
    }

    snapshot() {
        return {tasks: this.tasks, doneToday: this.doneToday, dbFound: this.dbFound};
    }

    _query(sql, allowRetry = true) {
        const path = this.dbPath;

        // argv vector only — never a shell string (review + safety).
        const argv = ['sqlite3', '-readonly', '-json', '-cmd', '.timeout 400', path, sql];
        const proc = new Gio.Subprocess({
            argv,
            flags: Gio.SubprocessFlags.STDOUT_PIPE | Gio.SubprocessFlags.STDERR_PIPE,
        });

        return new Promise((resolve, reject) => {
            try {
                // init() throws synchronously if the spawn fails
                // (e.g. sqlite3 not installed) — surface as rejection.
                proc.init(this._cancellable);
            } catch (e) {
                reject(e);
                return;
            }
            proc.communicate_utf8_async(null, this._cancellable, (p, res) => {
                try {
                    const [ok, stdout, stderr] = p.communicate_utf8_finish(res);
                    if (!ok || p.get_exit_status() !== 0) {
                        const busy = (stderr ?? '').includes('locked');
                        if (busy && allowRetry) {
                            // The writer (Planify / Todoist sync) holds the DB
                            // for a moment; one short retry is enough.
                            if (this._retryId)
                                GLib.Source.remove(this._retryId);
                            this._retryId = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 120, () => {
                                this._retryId = 0;
                                this._query(sql, false).then(resolve, reject);
                                return GLib.SOURCE_REMOVE;
                            });
                            return;
                        }
                        reject(new Error((stderr ?? 'sqlite3 failed').trim()));
                        return;
                    }
                    resolve(stdout.trim() ? JSON.parse(stdout) : []);
                } catch (e) {
                    reject(e);
                }
            });
        });
    }

    async isAppRunning() {
        try {
            const res = await Gio.DBus.session.call('org.freedesktop.DBus',
                '/org/freedesktop/DBus', 'org.freedesktop.DBus', 'NameHasOwner',
                new GLib.Variant('(s)', [APP_DBUS_NAME]), null,
                Gio.DBusCallFlags.NONE, 1500, this._cancellable);
            return res.deepUnpack()[0];
        } catch {
            return false;
        }
    }

    /** The app's exported GActions (complete, show-item, snooze-N). */
    _actionGroup() {
        if (!this._actions)
            this._actions = Gio.DBusActionGroup.get(Gio.DBus.session,
                APP_DBUS_NAME, APP_DBUS_PATH);
        return this._actions;
    }

    /**
     * Complete a task. With the app running we delegate to its `complete`
     * GAction (live UI update). With the app closed we use Planify's own
     * CLI, which runs the app's core completion path (Services.Store
     * bookkeeping + Item.complete_item, so recurring tasks advance)
     * without opening the GUI. The extension never writes the DB itself.
     */
    async requestComplete(taskId) {
        if (await this.isAppRunning()) {
            this._activateAppAction('complete', taskId);
        } else {
            this._spawn(['flatpak', 'run', '--command=' + CLI_ID, APP_ID,
                'update', '--task-id', taskId, '--complete', 'true']);
        }
    }

    // GJS 1.88 cannot JS-convert the 'av' parameter slot of
    // org.freedesktop.Application.ActivateAction (throws "Invalid GVariant
    // signature ()"); the D-Bus action group activates the app's exported
    // GActions directly with their native parameter type ('s').
    _activateAppAction(action, taskId) {
        try {
            this._actionGroup().activate_action(action,
                GLib.Variant.new('s', taskId));
        } catch (e) {
            logWarn(`${action} failed: ${e.message}`);
        }
    }

    async _desktopAppInfo(id) {
        // Gio.DesktopAppInfo moved to GioUnix on GNOME 50 (deprecated in
        // Gio); fall back for older shells.
        if (this._DesktopAppInfo === undefined) {
            try {
                this._DesktopAppInfo = (await import('gi://GioUnix')).DesktopAppInfo;
            } catch {
                this._DesktopAppInfo = Gio.DesktopAppInfo;
            }
        }
        try {
            return this._DesktopAppInfo.new(id);
        } catch {
            return null;
        }
    }

    /** Create a task due today through Planify's CLI (Store-layer path:
        inbox project, proper sync bookkeeping, live app notification). */
    addTaskToday(content) {
        const today = GLib.DateTime.new_now_local().format('%F');
        const argv = ['flatpak', 'run', '--command=' + CLI_ID, APP_ID,
            'add', '--content', content, '--due', today];
        try {
            const proc = new Gio.Subprocess({
                argv,
                flags: Gio.SubprocessFlags.STDOUT_SILENCE | Gio.SubprocessFlags.STDERR_PIPE,
            });
            proc.init(null);
            proc.communicate_utf8_async(null, this._cancellable, (p, res) => {
                try {
                    const [ok, , stderr] = p.communicate_utf8_finish(res);
                    if (!ok || p.get_exit_status() !== 0)
                        logWarn(`add failed: ${(stderr ?? '').trim() || 'unknown error'}`);
                } catch (e) {
                    logWarn(`add failed: ${e.message}`);
                }
            });
        } catch (e) {
            logWarn(`add spawn failed: ${e.message}`);
        }
    }

    async launchApp() {
        const appInfo = await this._desktopAppInfo(`${APP_ID}.desktop`);
        if (appInfo) {
            try {
                appInfo.launch([], null);
                return;
            } catch (e) {
                logWarn(`launch failed: ${e.message}`);
            }
        }
        this._spawn(['flatpak', 'run', APP_ID]);
    }

    _spawn(argv) {
        try {
            const proc = new Gio.Subprocess({
                argv,
                flags: Gio.SubprocessFlags.STDOUT_SILENCE | Gio.SubprocessFlags.STDERR_SILENCE,
            });
            proc.init(null);
        } catch (e) {
            logWarn(`spawn ${argv[0]} failed: ${e.message}`);
        }
    }

    destroy() {
        this._generation++;
        this._cancellable.cancel();
        this._actions = null;
        for (const id of [this._monitorDebounceId, this._retryId]) {
            if (id)
                GLib.Source.remove(id);
        }
        this._monitorDebounceId = 0;
        this._retryId = 0;
        this._monitor?.cancel();
        this._monitor = null;
        this.tasks = [];
    }
}

const TaskRow = GObject.registerClass(
class TaskRow extends PopupMenu.PopupBaseMenuItem {
    _init(task) {
        super._init({reactive: true, can_focus: true});

        this.task = task;
        this.done = false;
        this._titleCorrectId = 0;

        // Drop the shell's row class: shell themes style .popup-menu-item
        // hover/selected with !important accent colors (and :selected can
        // stick after the pointer leaves). .pqv-row owns the styling.
        this.remove_style_class_name('popup-menu-item');
        this.add_style_class_name('pqv-row');
        if (task.isSubtask)
            this.add_style_class_name('pqv-row-subtask');

        const circle = new St.Bin({
            style_class: 'pqv-circle',
            style: `border-color: ${task.color};`,
            y_align: Clutter.ActorAlign.CENTER,
        });
        this._check = new St.Icon({
            gicon: Gio.ThemedIcon.new('object-select-symbolic'),
            icon_size: 11,
            style_class: 'pqv-check',
            visible: false,
        });
        // Shown while a completion is pending its undo window.
        this._undo = new St.Icon({
            gicon: Gio.ThemedIcon.new('edit-undo-symbolic'),
            icon_size: 11,
            style_class: 'pqv-undo',
            visible: false,
        });
        const circleIcons = new St.BoxLayout();
        circleIcons.add_child(this._check);
        circleIcons.add_child(this._undo);
        circle.set_child(circleIcons);
        this._circle = circle;

        const column = new St.BoxLayout({
            orientation: Clutter.Orientation.VERTICAL,
            style_class: 'pqv-row-col',
            x_expand: true,
        });

        const titleRow = new St.BoxLayout({
            style_class: 'pqv-title-row',
            x_expand: true,
            y_align: Clutter.ActorAlign.CENTER,
        });
        this._titleRow = titleRow;
        // Priority flag dot (Todoist semantics: 4 = P1, 3 = P2). Planify
        // shows flags only for the two most urgent levels.
        if (task.priority >= 3) {
            titleRow.add_child(new St.Bin({
                style_class: 'pqv-flag',
                style: `background-color: ${PRIORITY_COLOR[task.priority] ?? PRIORITY_COLOR[3]}; width: 7px; height: 7px;`,
            }));
        }
        const title = new St.Label({
            text: task.content,
            style_class: 'pqv-title',
            y_align: Clutter.ActorAlign.CENTER,
        });
        title.clutter_text.ellipsize = Pango.EllipsizeMode.END;
        titleRow.add_child(title);
        this._title = title;

        const sub = new St.BoxLayout({
            style_class: 'pqv-sub',
            y_align: Clutter.ActorAlign.CENTER,
        });
        sub.add_child(new St.Bin({
            style_class: 'pqv-dot',
            style: `background-color: ${task.color}; width: 7px; height: 7px;`,
        }));
        sub.add_child(new St.Label({
            text: task.project,
            style_class: 'pqv-project',
            y_align: Clutter.ActorAlign.CENTER,
        }));

        let dueText = task.due.date === '' ? '' :
            (task.isOverdue ? _('Overdue') : '');
        if (dueText !== '' && task.due.time)
            dueText += ` · ${task.due.time}`;
        else if (dueText === '' && task.due.time)
            dueText = task.due.time;
        if (dueText !== '') {
            sub.add_child(new St.Label({
                text: dueText,
                style_class: `pqv-due ${task.isOverdue ? 'pqv-due-overdue' : ''}`,
                y_align: Clutter.ActorAlign.CENTER,
            }));
        }
        if (task.due.isRecurring) {
            sub.add_child(new St.Label({
                text: '↻',
                style_class: 'pqv-recurring',
                y_align: Clutter.ActorAlign.CENTER,
            }));
        }

        column.add_child(titleRow);
        column.add_child(sub);

        // Description: hidden by default; clicking the title folds it out.
        // The label is selectable and a copy button writes it to the
        // clipboard (selection + Ctrl+C inside a grabbed menu is flaky).
        this._descReveal = new St.BoxLayout({
            style_class: 'pqv-desc-reveal',
            vertical: false,
        });
        const hasDescription = (task.description ?? '').trim() !== '';
        this._descLabel = new St.Label({
            text: hasDescription ? task.description : _('No description'),
            style_class: `pqv-desc ${hasDescription ? '' : 'pqv-desc-empty'}`,
        });
        this._descLabel.clutter_text.line_wrap = true;
        this._descLabel.clutter_text.editable = false;
        try {
            this._descLabel.clutter_text.selectable = true;
        } catch {
            // selection is best-effort; the copy button always works
        }
        this._descLabel.reactive = true;
        this._descReveal.add_child(this._descLabel);

        this._copyButton = new St.Button({
            style_class: 'pqv-copybtn',
            child: new St.Icon({
                gicon: Gio.ThemedIcon.new('edit-copy-symbolic'),
                icon_size: 12,
            }),
            y_align: Clutter.ActorAlign.START,
        });
        this._copyButton.connect('clicked', () => {
            this._copyDescription();
        });
        this._descReveal.add_child(this._copyButton);

        this._descReveal.visible = false;
        column.add_child(this._descReveal);

        this.expanded = false;

        this.add_child(circle);
        this.add_child(column);
    }

    _copyDescription() {
        try {
            const clipboard = St.Clipboard.get_default();
            clipboard.set_content(St.ClipboardType.CLIPBOARD,
                this.task.description ?? '');
            this._copyButton.add_style_class_name('pqv-copybtn-done');
            if (this._copyFeedbackId)
                GLib.Source.remove(this._copyFeedbackId);
            this._copyFeedbackId = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 1200, () => {
                this._copyFeedbackId = 0;
                try {
                    this._copyButton.remove_style_class_name('pqv-copybtn-done');
                } catch {
                    // row destroyed meanwhile
                }
                return GLib.SOURCE_REMOVE;
            });
        } catch (e) {
            logWarn(`copy failed: ${e.message}`);
        }
    }

    toggleExpand() {
        if (this.expanded)
            this._collapse();
        else
            this._expand();
    }

    _expand() {
        this.expanded = true;
        this.add_style_class_name('pqv-row-expanded');
        // Un-truncate the title: wrap to as many lines as it needs.
        // Clutter's BoxLayout does not do height-for-width and St.Label
        // does not either, so we compute the wrapped height ourselves
        // (line height measured pre-wrap × ceil(naturalWidth/available))
        // and pin it via min-height + explicit height.
        const [, lineH] = this._title.clutter_text.get_preferred_height(-1);
        const [, natW] = this._title.clutter_text.get_preferred_width(-1);
        this._title.clutter_text.ellipsize = Pango.EllipsizeMode.NONE;
        this._title.clutter_text.line_wrap = true;
        this._title.clutter_text.single_line_mode = false;
        const box = this._descReveal;
        box.show();
        // The title row is x_expand: its allocated width is the real
        // available text width (the label's own allocation can still read
        // as its natural width at this point). The quick estimate is
        // deliberately generous; a correction pass then re-pins the height
        // from the ACTUAL Pango layout (word-wrap wastes width, so the
        // arithmetic alone under-counts lines).
        this._relayoutWrappedTitle(lineH, natW, this._titleRow.get_size()[0] || 300);
        if (this._titleCorrectId)
            GLib.Source.remove(this._titleCorrectId);
        this._titleCorrectId = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 60, () => {
            this._titleCorrectId = 0;
            if (!this.expanded)
                return GLib.SOURCE_REMOVE;
            try {
                const layout = this._title.clutter_text.get_layout();
                const [, wrappedH] = layout.get_pixel_size();
                const corrected = Math.ceil(wrappedH) + 4;
                this._title.set_style(`min-height: ${corrected}px;`);
                this._title.set_height(corrected);
                this.queue_relayout();
            } catch {
                // label gone (rebuild) — nothing to correct
            }
            return GLib.SOURCE_REMOVE;
        });
        const rowW = this.get_size()[0] || 352;
        const [, natH] = this._descLabel.get_preferred_height(Math.max(1, rowW - 76));
        if (!St.Settings.get().enable_animations) {
            box.height = -1;
            box.opacity = 255;
            return;
        }
        box.remove_all_transitions();
        box.set({height: 0, opacity: 0});
        box.ease({
            height: Math.max(1, natH),
            opacity: 255,
            duration: 220,
            mode: Clutter.AnimationMode.EASE_OUT_QUAD,
            onComplete: () => {
                box.height = -1; // back to natural size
            },
        });
    }

    _relayoutWrappedTitle(lineH, natW, available) {
        // Slightly overestimate: +1 spare line absorbs word-wrap
        // inefficiency until the correction pass measures the real layout.
        const safeWidth = Math.max(1, available - 12);
        const lines = Math.max(1, Math.ceil(natW / safeWidth) + 1);
        const natH = lines * Math.max(1, lineH) + 4;
        this._title.set_style(`min-height: ${natH}px;`);
        this._title.set_height(natH);
    }

    _collapse() {
        this.expanded = false;
        this.remove_style_class_name('pqv-row-expanded');
        this._title.clutter_text.ellipsize = Pango.EllipsizeMode.END;
        this._title.clutter_text.line_wrap = false;
        this._title.clutter_text.single_line_mode = true;
        if (this._titleCorrectId) {
            GLib.Source.remove(this._titleCorrectId);
            this._titleCorrectId = 0;
        }
        this._title.set_style('');
        this._title.set_height(-1);
        this._title.queue_relayout();
        this.queue_relayout();
        const box = this._descReveal;
        if (!St.Settings.get().enable_animations) {
            box.hide();
            box.height = -1;
            box.opacity = 255;
            return;
        }
        box.remove_all_transitions();
        const current = box.height > 0 ? box.height : box.get_preferred_height(-1)[1];
        box.set({height: current, opacity: 255});
        box.ease({
            height: 0,
            opacity: 0,
            duration: 180,
            mode: Clutter.AnimationMode.EASE_IN_QUAD,
            onComplete: () => {
                box.hide();
                box.height = -1;
                box.opacity = 255;
            },
        });
    }

    hitsDescription(event) {
        if (!this.expanded || !event)
            return false;
        const [x, y] = event.get_coords();
        if (x === undefined || x < 0 || y === undefined || y < 0)
            return false;
        const [cx, cy] = this._descReveal.get_transformed_position();
        const [w, h] = this._descReveal.get_size();
        return x >= cx && x <= cx + w && y >= cy && y <= cy + h;
    }

    /** Pending-undo state: accent circle with an undo glyph. */
    setPending(on) {
        this.pending = on;
        if (on)
            this._circle.add_style_class_name('pqv-circle-pending');
        else
            this._circle.remove_style_class_name('pqv-circle-pending');
        this._undo.visible = on;
        this._check.visible = this.done;
    }

    /**
     * True when the click (or touch) landed on the circle checkbox.
     * Keyboard activation (no usable coordinates) routes to open.
     */
    hitsCheckbox(event) {
        if (!event)
            return false;
        const [x, y] = event.get_coords();
        if (x === undefined || x < 0 || y === undefined || y < 0)
            return false;
        const [cx, cy] = this._circle.get_transformed_position();
        const [w, h] = this._circle.get_size();
        const pad = 4;
        return x >= cx - pad && x <= cx + w + pad &&
               y >= cy - pad && y <= cy + h + pad;
    }

    destroy() {
        if (this._copyFeedbackId) {
            GLib.Source.remove(this._copyFeedbackId);
            this._copyFeedbackId = 0;
        }
        if (this._titleCorrectId) {
            GLib.Source.remove(this._titleCorrectId);
            this._titleCorrectId = 0;
        }
        this.remove_all_transitions();
        super.destroy();
    }

    markDone() {
        if (this.done)
            return;
        this.done = true;
        this._circle.add_style_class_name('pqv-circle-done');
        this._check.visible = true;
        this._title.add_style_class_name('pqv-title-done');
    }

    /** Fade the row out and destroy it (macOS Reminders-style). */
    animateOut() {
        if (!St.Settings.get().enable_animations) {
            this.destroy();
            return;
        }
        this.remove_all_transitions();
        this.ease({
            opacity: 0,
            translation_x: 14,
            duration: 200,
            mode: Clutter.AnimationMode.EASE_IN_QUAD,
            onComplete: () => {
                try {
                    this.destroy();
                } catch {
                    // already destroyed by a rebuild
                }
            },
        });
    }
});

// Submit handling for the inline add entry. Clutter 18 removed
// Clutter.Text::activate, so Enter is caught on the wrapping menu item,
// whose vfunc_key_press_event receives the keys the focused entry lets
// bubble up.
const AddEntryItem = GObject.registerClass(
class AddEntryItem extends PopupMenu.PopupBaseMenuItem {
    _init(entry) {
        super._init({reactive: false, hover: false});
        this.remove_style_class_name('popup-menu-item');
        this.add_style_class_name('pqv-addrow');
        this._entry = entry;
        this._onSubmit = () => {};
        this._onEscape = () => {};
        this.add_child(entry);
    }

    vfunc_key_press_event(_actor, event) {
        const sym = event.get_key_symbol();
        if (sym === Clutter.KEY_Return || sym === Clutter.KEY_KP_Enter) {
            this._onSubmit();
            return Clutter.EVENT_STOP;
        }
        if (sym === Clutter.KEY_Escape) {
            this._onEscape();
            return Clutter.EVENT_STOP;
        }
        return Clutter.EVENT_PROPAGATE;
    }
});

// PopupMenu is a Signals.EventEmitter (not a GObject), so this subclass is
// a plain JS class — plain classes only ever call constructor(), never _init().
class QuickViewMenu extends PopupMenu.PopupMenu {
    constructor(sourceActor, store, settings) {
        super(sourceActor, 0.0, St.Side.TOP);

        this._store = store;
        this._settings = settings;
        this._rows = [];
        this._closing = false;
        this._animSourceId = 0;
        this._pending = new Map();   // taskId -> GLib.Source id
        this._expandedRow = null;
        this._lastSubmitAt = 0;

        this.actor.add_style_class_name('pqv-menu');
        this.box.add_style_class_name('pqv-content');

        this._buildHeader();
        this._buildList();
        this._buildFooter();

        // Hover tooltip was removed by design: the fold-out already gives
        // access to the full title.
    }

    setStore(store) {
        this._store = store;
    }

    _buildHeader() {
        const header = new St.BoxLayout({style_class: 'pqv-header'});

        const col = new St.BoxLayout({
            orientation: Clutter.Orientation.VERTICAL,
            style_class: 'pqv-header-col',
            x_expand: true,
        });
        col.add_child(new St.Label({
            text: _('Today'),
            style_class: 'pqv-header-title',
            y_align: Clutter.ActorAlign.CENTER,
        }));
        this._headerSubtitle = new St.Label({style_class: 'pqv-header-sub'});
        col.add_child(this._headerSubtitle);

        this._quickAddButton = new St.Button({
            style_class: 'pqv-iconbtn',
            child: new St.Icon({
                gicon: Gio.ThemedIcon.new('list-add-symbolic'),
                icon_size: 16,
            }),
            y_align: Clutter.ActorAlign.CENTER,
        });
        this._quickAddButton.connect('clicked', () => {
            this._toggleAddEntry();
        });

        header.add_child(col);
        header.add_child(this._quickAddButton);
        this.box.add_child(header);
    }

    _toggleAddEntry() {
        const show = !this._addRow.visible;
        this._addRow.visible = show;
        if (show)
            this._addEntry.grab_key_focus();
    }

    /** Test-only: run the submit path for a given text. */
    _submitAddEntryFor(text) {
        const previous = this._addEntry.text;
        this._addEntry.text = text;
        this._submitAddEntry();
        this._addEntry.text = previous;
    }

    _submitAddEntry() {
        const text = this._addEntry.text.trim();
        if (text === '') {
            this._toggleAddEntry();
            return;
        }
        // Four redundant key paths call this per Enter; keep one.
        const now = GLib.get_monotonic_time();
        if (now - this._lastSubmitAt < 500_000)
            return;
        this._lastSubmitAt = now;
        logInfo(`quick-add submitting: ${text}`);
        this._store.addTaskToday(text);
        this._addEntry.text = '';
    }

    _buildList() {
        this._scroll = new St.ScrollView({
            style_class: 'pqv-scroll vfade',
            overlay_scrollbars: true,
            x_expand: true,
        });
        this._scroll.set_policy(St.PolicyType.NEVER, St.PolicyType.AUTOMATIC);
        this._list = new St.BoxLayout({
            orientation: Clutter.Orientation.VERTICAL,
            style_class: 'pqv-list',
        });
        this._scroll.set_child(this._list);
        this.box.add_child(this._scroll);

        // Inline quick-add: new tasks are created due today (this popup is
        // the today view). Enter adds, empty Enter hides, the popup's
        // Escape dismisses everything.
        this._addEntry = new St.Entry({
            hint_text: _('Add a task for today…'),
            style_class: 'pqv-addentry',
            x_expand: true,
        });
        // Redundant submit paths: Clutter 18 has no reliable key signal on
        // Clutter.Text, so Enter is caught at every level that can see it.
        this._addEntry.clutter_text.connect('activate', () => this._submitAddEntry());
        try {
            this._addEntry.clutter_text.connect('key-press-event', (_t, event) => {
                if (event.get_key_symbol() === Clutter.KEY_Return ||
                    event.get_key_symbol() === Clutter.KEY_KP_Enter) {
                    this._submitAddEntry();
                    return Clutter.EVENT_STOP;
                }
                return Clutter.EVENT_PROPAGATE;
            });
        } catch (e) {
            logWarn(`text key path: ${e.message}`);
        }
        try {
            this._addEntry.connect('key-press-event', (_a, event) => {
                if (event.get_key_symbol() === Clutter.KEY_Return ||
                    event.get_key_symbol() === Clutter.KEY_KP_Enter) {
                    this._submitAddEntry();
                    return Clutter.EVENT_STOP;
                }
                return Clutter.EVENT_PROPAGATE;
            });
        } catch (e) {
            logWarn(`entry key path: ${e.message}`);
        }
        const addRow = new AddEntryItem(this._addEntry);
        addRow._onSubmit = () => this._submitAddEntry();
        addRow._onEscape = () => this._toggleAddEntry();
        addRow.visible = false;
        this.box.insert_child_below(addRow, this._scroll);
        this._addRow = addRow;

        this._empty = new St.BoxLayout({
            orientation: Clutter.Orientation.VERTICAL,
            style_class: 'pqv-empty',
            x_align: Clutter.ActorAlign.CENTER,
            x_expand: true,
        });
        this._empty.add_child(new St.Icon({
            gicon: Gio.ThemedIcon.new('object-select-symbolic'),
            icon_size: 34,
            style_class: 'pqv-empty-icon',
        }));
        this._emptyTitle = new St.Label({
            text: _('Nothing due today'),
            style_class: 'pqv-empty-title',
            x_align: Clutter.ActorAlign.CENTER,
        });
        this._emptySub = new St.Label({
            text: _('Enjoy the rest of your day'),
            style_class: 'pqv-empty-sub',
            x_align: Clutter.ActorAlign.CENTER,
        });
        this._empty.add_child(this._emptyTitle);
        this._empty.add_child(this._emptySub);
        this.box.add_child(this._empty);
    }

    _buildFooter() {
        const footer = new PopupMenu.PopupBaseMenuItem({reactive: true, can_focus: true});
        footer.remove_style_class_name('popup-menu-item');
        footer.add_style_class_name('pqv-footer');
        footer.add_child(new St.Icon({
            gicon: Gio.ThemedIcon.new(APP_ID),
            icon_size: 16,
        }));
        footer.add_child(new St.Label({
            text: _('Open Planify'),
            style_class: 'pqv-footer-label',
            x_expand: true,
            y_align: Clutter.ActorAlign.CENTER,
        }));
        footer.connect('activate', () => {
            this._store.launchApp();
            this.close();
        });
        this.addMenuItem(footer);

        const settings = new PopupMenu.PopupBaseMenuItem({reactive: true, can_focus: true});
        settings.remove_style_class_name('popup-menu-item');
        settings.add_style_class_name('pqv-footer');
        settings.add_child(new St.Icon({
            gicon: Gio.ThemedIcon.new('emblem-system-symbolic'),
            icon_size: 16,
        }));
        settings.add_child(new St.Label({
            text: _('Settings'),
            style_class: 'pqv-footer-label',
            x_expand: true,
            y_align: Clutter.ActorAlign.CENTER,
        }));
        settings.connect('activate', () => {
            this._openPrefs();
            this.close();
        });
        this.addMenuItem(settings);
    }

    /** Open the extension preferences via the shell's extensions service. */
    _openPrefs() {
        Gio.DBus.session.call('org.gnome.Shell.Extensions',
            '/org/gnome/Shell/Extensions', 'org.gnome.Shell.Extensions',
            'LaunchExtensionPrefs', new GLib.Variant('(s)', [EXT_UUID]),
            null, Gio.DBusCallFlags.NONE, -1, null, (conn, res) => {
                try {
                    conn.call_finish(res);
                } catch (e) {
                    logWarn(`open prefs failed: ${e.message}`);
                }
            });
    }

    _updateHeader(snapshot) {
        const n = snapshot.tasks.length;
        const done = snapshot.doneToday;
        if (!snapshot.dbFound) {
            this._headerSubtitle.text = _('Planify database not found');
        } else if (n === 0 && done === 0) {
            this._headerSubtitle.text = new Intl.DateTimeFormat(undefined,
                {weekday: 'long', month: 'long', day: 'numeric'}).format(new Date());
        } else {
            this._headerSubtitle.text =
                ngettext('%d open · %d done today', '%d open · %d done today', n)
                    .format(n, done);
        }

        this._quickAddButton.visible = snapshot.dbFound;
        this._scroll.visible = n > 0;
        this._empty.visible = snapshot.dbFound && n === 0;
        this._emptyTitle.text = done > 0
            ? _('All caught up!')
            : _('Nothing due today');
    }

    _clearRows() {
        for (const row of this._rows)
            row.destroy();
        this._rows = [];
        this._list.remove_all_children();
    }

    _makeLabel(text, styleClass) {
        this._list.add_child(new St.Label({
            text,
            style_class: `pqv-section ${styleClass}`,
        }));
    }

    _rebuild(snapshot) {
        this._clearRows();

        let sawPinned = false;
        let sawOverdue = false;
        let sawToday = false;
        for (const task of snapshot.tasks.slice(0, this._settings.get_int('max-rows'))) {
            if (task.isPinned && !sawPinned) {
                this._makeLabel(_('Pinned'), 'pqv-section-pinned');
                sawPinned = true;
            }
            if (task.isOverdue && !sawOverdue) {
                this._makeLabel(_('Overdue'), 'pqv-section-overdue');
                sawOverdue = true;
            } else if (!task.isOverdue && sawOverdue && !sawToday) {
                // .pqv-section-today is intentionally unstyled — same look
                // as the base section label.
                this._makeLabel(_('Today'), 'pqv-section-today');
                sawToday = true;
            }
            const row = new TaskRow(task);
            row.connect('activate', (item, event) => {
                this._onRowActivate(row, event)
                    .catch(e => logWarn(`row activate: ${e.message}`));
            });
            this._list.add_child(row);
            this._rows.push(row);
        }

        this._updateHeader(snapshot);
    }

    async _onRowActivate(row, event) {
        if (row.done || !this._store)
            return;
        const task = row.task;
        if (!this._store || !this._rows.includes(row))
            return; // extension disabled or list rebuilt meanwhile

        if (row.hitsCheckbox(event)) {
            // Circle click: complete after an undo window (misclicks).
            if (this._pending.has(task.id)) {
                this._cancelPending(task.id);
                row.setPending(false);
                return;
            }
            const delay = this._settings.get_int('complete-delay-seconds');
            if (delay <= 0) {
                this._completeRow(row, task.id);
                return;
            }
            row.setPending(true);
            const sourceId = GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, delay, () => {
                this._pending.delete(task.id);
                if (this._rows.includes(row)) {
                    row.setPending(false);
                    this._completeRow(row, task.id);
                } else {
                    // Row was rebuilt meanwhile; the intent stands.
                    this._store.requestComplete(task.id);
                }
                return GLib.SOURCE_REMOVE;
            });
            this._pending.set(task.id, sourceId);
        } else {
            // Text click: fold the description in/out. Clicks inside the
            // description are left alone so text can be selected. Only
            // one row stays expanded: opening one collapses the previous.
            if (row.hitsDescription(event))
                return;
            if (this._expandedRow && this._expandedRow !== row)
                this._expandedRow.toggleExpand();
            row.toggleExpand();
            this._expandedRow = row.expanded ? row : null;
        }
    }

    _completeRow(row, taskId) {
        row.markDone();
        this._store.requestComplete(taskId);
        if (this._animSourceId)
            GLib.Source.remove(this._animSourceId);
        this._animSourceId = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 450, () => {
            this._animSourceId = 0;
            if (this._rows.includes(row)) {
                this._rows = this._rows.filter(r => r !== row);
                row.animateOut();
            }
            return GLib.SOURCE_REMOVE;
        });
    }

    _cancelPending(taskId) {
        const sourceId = this._pending.get(taskId);
        if (sourceId !== undefined) {
            GLib.Source.remove(sourceId);
            this._pending.delete(taskId);
        }
    }

    /** Staggered row choreography after the card itself animates in. */
    _playRowsIn() {
        if (!St.Settings.get().enable_animations)
            return;
        this._rows.slice(0, 15).forEach((row, i) => {
            row.remove_all_transitions();
            row.set({opacity: 0, translation_y: 10});
            row.ease({
                opacity: 255,
                translation_y: 0,
                duration: 190,
                delay: 60 + i * 22,
                mode: Clutter.AnimationMode.EASE_OUT_QUAD,
            });
        });
    }

    _duration() {
        const v = this._settings.get_int('animation-duration');
        return v > 0 ? v : OPEN_MS;
    }

    _closeDuration() {
        const v = this._settings.get_int('animation-duration');
        return v > 0 ? Math.round(v * CLOSE_MS / OPEN_MS) : CLOSE_MS;
    }

    open(animate = true) {
        if (this._closing)
            this._finishClose(); // cancel a pending close animation
        if (this.isOpen)
            return;

        const reduced = !St.Settings.get().enable_animations;
        // BoxPointer positioning happens in open(); with PopupAnimation.NONE
        // the card appears at its final geometry and we own the animation.
        super.open(BoxPointer.PopupAnimation.NONE);

        this._store.refresh()
            .then(() => this._playRowsIn())
            .catch(e => logWarn(`refresh on open: ${e.message}`));

        if (!animate || reduced)
            return;

        this.actor.remove_all_transitions();
        // Scale toward the top edge = growing out of the panel icon.
        this.actor.set_pivot_point(0.5, 0);
        this.actor.set({
            opacity: 0,
            scale_x: 0.94,
            scale_y: 0.94,
            translation_y: -10,
        });
        this.actor.ease({
            opacity: 255,
            scale_x: 1,
            scale_y: 1,
            translation_y: 0,
            duration: this._duration(),
            mode: Clutter.AnimationMode.EASE_OUT_QUINT,
        });
    }

    close(animate = true) {
        if (!this.isOpen || this._closing)
            return;

        const reduced = !St.Settings.get().enable_animations;
        if (!animate || reduced) {
            this._finishClose();
            return;
        }

        // Animate toward the panel first, then let super close + release grab.
        this._closing = true;
        this.actor.remove_all_transitions();
        this.actor.set_pivot_point(0.5, 0);
        this.actor.ease({
            opacity: 0,
            scale_x: 0.95,
            scale_y: 0.95,
            translation_y: -8,
            duration: this._closeDuration(),
            mode: Clutter.AnimationMode.EASE_IN_QUAD,
            onComplete: () => this._finishClose(),
        });
    }

    _finishClose() {
        this._closing = false;
        this.actor.remove_all_transitions();
        if (this.isOpen)
            super.close(BoxPointer.PopupAnimation.NONE);
    }

    /** Push a fresh snapshot into the UI without animation (live updates). */
    update(snapshot) {
        this._rebuild(snapshot);
    }

    destroy() {
        if (this._animSourceId) {
            GLib.Source.remove(this._animSourceId);
            this._animSourceId = 0;
        }
        this._clearRows();
        super.destroy();
    }
}

const QuickViewIndicator = GObject.registerClass(
class QuickViewIndicator extends PanelMenu.Button {
    _init() {
        super._init(0.0, _('Planify Quick View'), true);

        const box = new St.BoxLayout({style_class: 'panel-status-menu-box pqv-panelbox'});
        this._icon = new St.Icon({
            gicon: Gio.ThemedIcon.new(`${APP_ID}-symbolic`),
            icon_size: 16,
            fallback_icon_name: 'view-list-bullet-symbolic',
        });
        this._badge = new St.Label({
            text: '0',
            style_class: 'pqv-badge',
            y_align: Clutter.ActorAlign.CENTER,
            visible: false,
        });
        box.add_child(this._icon);
        box.add_child(this._badge);
        this.add_child(box);
    }

    setMode(mode) {
        this._mode = mode;
        this._badge.remove_style_class_name('pqv-badge-dot');
        if (mode === 'dot')
            this._badge.add_style_class_name('pqv-badge-dot');
    }

    setCount(count) {
        switch (this._mode) {
        case 'dot':
            this._badge.text = BADGE_DOT_CHAR;
            this._badge.visible = count > 0;
            break;
        case 'hidden':
            this._badge.visible = false;
            break;
        default:
            this._badge.text = String(count);
            this._badge.visible = count > 0;
        }
    }

    get center() {
        const [x, y] = this.get_transformed_position();
        const [w, h] = this.get_size();
        return {x, y, w, h};
    }
});

export default class PlanifyQuickViewExtension extends Extension {
    enable() {
        this._settings = this.getSettings();
        this._store = new PlanifyStore(this._settings, () => this._syncBadge());
        this._indicator = new QuickViewIndicator();
        this._indicator.setMode(this._settings.get_string('badge-mode'));
        this._menu = new QuickViewMenu(this._indicator, this._store, this._settings);
        this._indicator.setMenu(this._menu);
        Main.panel.addToStatusArea(this.uuid, this._indicator);

        this._badgeModeSettingId = this._settings.connect('changed::badge-mode', () => {
            this._indicator?.setMode(this._settings.get_string('badge-mode'));
            this._syncBadge();
        });

        this._dbPathSettingId = this._settings.connect('changed::database-path', () => {
            this._store.destroy();
            this._store = new PlanifyStore(this._settings, () => this._syncBadge());
            this._menu.setStore(this._store);
            this._store.refresh()
                .catch(e => logWarn(`refresh after db-path change: ${e.message}`));
        });

        this._installKeybinding();
        this._installRolloverPoll();

        this._store.refresh()
            .catch(e => logWarn(`initial refresh: ${e.message}`));

        if (this._settings.get_boolean('debug-dbus'))
            this._installDebugDbus();
        this._debugSettingId = this._settings.connect('changed::debug-dbus', () => {
            if (this._settings.get_boolean('debug-dbus'))
                this._installDebugDbus();
            else
                this._uninstallDebugDbus();
        });
    }

    _installKeybinding() {
        Main.wm.addKeybinding('toggle-quick-view',
            this._settings,
            Meta.KeyBindingFlags.IGNORE_AUTOREPEAT,
            Shell.ActionMode.NORMAL | Shell.ActionMode.POPUP,
            () => this._menu.toggle());
    }

    _installRolloverPoll() {
        // Keeps the badge and list honest across midnight and out-of-band
        // changes the file monitor might have missed.
        this._pollId = GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT,
            ROLLOVER_POLL_SECONDS, () => {
                this._store.refresh().catch(() => {});
                return GLib.SOURCE_CONTINUE;
            });
    }

    _syncBadge() {
        this._indicator?.setCount(this._store.tasks.length);
        if (this._menu?.isOpen)
            this._menu.update(this._store.snapshot());
    }

    _installDebugDbus() {
        if (this._debugOwnerId)
            return;
        this._debugOwnerId = Gio.DBus.session.own_name(DEBUG_DBUS_NAME,
            Gio.BusNameOwnerFlags.NONE,
            conn => this._exportDebugOn(conn),
            () => {});
    }

    _exportDebugOn(conn) {
        this._debugConn = conn;
        const info = Gio.DBusNodeInfo.new_for_xml(DEBUG_IFACE_XML);
        // GJS 1.88: the old (path, node, closure) convenience is gone; the
        // binding wants the GDBusInterfaceInfo plus user_data/destroy.
        this._debugObjectId = conn.register_object(DEBUG_DBUS_PATH, info.interfaces[0],
            (connection, sender, path, iface, method, params, invocation) =>
                this._onDebugCall(method, params, invocation),
            null, null);
    }

    _onDebugCall(method, params, invocation) {
        switch (method) {
        case 'Toggle':
            this._menu.toggle();
            invocation.return_value(null);
            break;
        case 'Open':
            this._menu.open();
            invocation.return_value(null);
            break;
        case 'Close':
            this._menu.close();
            invocation.return_value(null);
            break;
        case 'Status': {
            this._store.isAppRunning().then(running => {
                const state = {
                    open: this._menu.isOpen,
                    tasks: this._store.tasks.length,
                    doneToday: this._store.doneToday,
                    dbFound: this._store.dbFound,
                    dbPath: this._store.dbPath,
                    appRunning: running,
                    button: this._indicator?.center ?? null,
                    rows: this._menu._rows.length,
                };
                invocation.return_value(new GLib.Variant('(s)', [JSON.stringify(state)]));
            }).catch(e => {
                invocation.return_value(new GLib.Variant('(s)',
                    [JSON.stringify({error: e.message})]));
            });
            break;
        }
        case 'Capture': {
            // Test-only endpoint: never write outside /tmp (normalized so
            // /tmp/../home/… traversal cannot sneak through).
            let path = params.deepUnpack()[0];
            try {
                path = Gio.File.new_for_path(path).get_path();
            } catch {
                path = '';
            }
            if (!path || !path.startsWith('/tmp/')) {
                invocation.return_value(new GLib.Variant('(b)', [false]));
                break;
            }
            this._capture(path)
                .then(ok => invocation.return_value(new GLib.Variant('(b)', [ok])))
                .catch(() => invocation.return_value(new GLib.Variant('(b)', [false])));
            break;
        }
        case 'RowDebug': {
            const idx = params.deepUnpack()[0];
            const row = this._menu._rows[idx];
            if (!row) {
                invocation.return_value(new GLib.Variant('(s)', [JSON.stringify({error: 'no row'})]));
                break;
            }
            let info;
            try {
                const layout = row._title.clutter_text.get_layout();
                const ct = row._title.clutter_text;
                const [, ctW] = ct.get_preferred_width(-1);
                const [, ctH280] = ct.get_preferred_height(280);
                const [, lbH280] = row._title.get_preferred_height(280);
                info = {
                    expanded: row.expanded,
                    ellipsize: ct.ellipsize,
                    wrap: ct.line_wrap,
                    single: ct.single_line_mode,
                    truncated: layout ? layout.is_ellipsized() : null,
                    titleW: row._title.get_size()[0],
                    titleH: row._title.get_size()[1],
                    rowH: row.get_size()[1],
                    ctPrefW: ctW, ctPrefH280: ctH280, lbPrefH280: lbH280,
                    labelSetH: row._title.get_height(),
                };
            } catch (e) {
                info = {error: e.message};
            }
            invocation.return_value(new GLib.Variant('(s)', [JSON.stringify(info)]));
            break;
        }
        case 'ToggleExpand': {
            const idx2 = params.deepUnpack()[0];
            const row2 = this._menu._rows[idx2];
            if (row2)
                row2.toggleExpand();
            invocation.return_value(null);
            break;
        }
        case 'ToggleAdd': {
            this._menu._toggleAddEntry();
            invocation.return_value(null);
            break;
        }
        case 'DebugSubmit': {
            const text2 = params.deepUnpack()[0];
            this._menu._submitAddEntryFor(text2);
            invocation.return_value(null);
            break;
        }
        case 'Repaint': {
            // Test helper for headless sessions: without a visible surface the
            // frame clock never ticks, so animations and captures would stall.
            const start = params.deepUnpack()[0];
            if (start && !this._repaintId) {
                this._repaintId = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 16, () => {
                    global.stage.queue_redraw();
                    return GLib.SOURCE_CONTINUE;
                });
            } else if (!start && this._repaintId) {
                GLib.Source.remove(this._repaintId);
                this._repaintId = 0;
            }
            invocation.return_value(null);
            break;
        }
        default:
            invocation.return_value(null);
        }
    }

    /** Internal screenshot (bypasses the restricted D-Bus screenshot API). */
    _capture(path) {
        return new Promise(resolve => {
            let stream;
            try {
                stream = Gio.File.new_for_path(path)
                    .replace(null, false, Gio.FileCreateFlags.NONE, null);
            } catch (e) {
                logWarn(`capture create: ${e.message}`);
                resolve(false);
                return;
            }
            try {
                const shot = new Shell.Screenshot();
                shot.screenshot(false, stream, (src, res) => {
                    try {
                        stream.close(null);
                    } catch {
                        // best effort
                    }
                    try {
                        const [ok] = shot.screenshot_finish(res);
                        resolve(!!ok);
                    } catch {
                        resolve(false);
                    }
                });
            } catch (e) {
                logWarn(`capture: ${e.message}`);
                try {
                    stream.close(null);
                } catch {
                    // best effort
                }
                resolve(false);
            }
        });
    }

    _uninstallDebugDbus() {
        if (this._repaintId) {
            GLib.Source.remove(this._repaintId);
            this._repaintId = 0;
        }
        if (this._debugObjectId !== undefined && this._debugConn) {
            this._debugConn.unregister_object(this._debugObjectId);
            this._debugObjectId = undefined;
        }
        if (this._debugOwnerId) {
            Gio.bus_unown_name(this._debugOwnerId);
            this._debugOwnerId = 0;
        }
        this._debugConn = null;
    }

    disable() {
        this._uninstallDebugDbus();

        if (this._badgeModeSettingId) {
            this._settings.disconnect(this._badgeModeSettingId);
            this._badgeModeSettingId = 0;
        }
        if (this._dbPathSettingId) {
            this._settings.disconnect(this._dbPathSettingId);
            this._dbPathSettingId = 0;
        }
        if (this._debugSettingId) {
            this._settings.disconnect(this._debugSettingId);
            this._debugSettingId = 0;
        }

        if (this._pollId) {
            GLib.Source.remove(this._pollId);
            this._pollId = 0;
        }

        Main.wm.removeKeybinding('toggle-quick-view');

        this._indicator?.destroy();
        this._indicator = null;
        this._menu = null;
        this._store.destroy();
        this._store = null;
        this._settings = null;
    }
}
