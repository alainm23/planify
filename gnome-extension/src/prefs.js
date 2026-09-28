// Planify Quick View — preferences window (Gtk4 + Adw, separate process).
// Never import Clutter/Meta/St/Shell here.
import Adw from 'gi://Adw';
import Gio from 'gi://Gio';
import Gtk from 'gi://Gtk';
import {ExtensionPreferences, gettext as _} from 'resource:///org/gnome/Shell/Extensions/js/extensions/prefs.js';

export default class PlanifyQuickViewPreferences extends ExtensionPreferences {
    fillPreferencesWindow(window) {
        const settings = this.getSettings();

        const listPage = new Adw.PreferencesPage({
            title: _('Task list'),
            icon_name: 'view-list-bullet-symbolic',
        });

        const listGroup = new Adw.PreferencesGroup({title: _('Task list')});
        const maxRows = Adw.SpinRow.new_with_range(3, 50, 1);
        maxRows.set_title(_('Maximum rows shown'));
        maxRows.set_subtitle(_('Pinned tasks always count first'));
        settings.bind('max-rows', maxRows, 'value', Gio.SettingsBindFlags.DEFAULT);
        listGroup.add(maxRows);

        const badgeRow = new Adw.ComboRow({title: _('Panel badge')});
        const badgeModes = ['count', 'dot', 'hidden'];
        badgeRow.model = new Gtk.StringList({
            strings: [_('Task count'), _('Dot'), _('Hidden')],
        });
        badgeRow.selected = Math.max(0,
            badgeModes.indexOf(settings.get_string('badge-mode')));
        badgeRow.connect('notify::selected', () => {
            settings.set_string('badge-mode', badgeModes[badgeRow.selected] ?? 'count');
        });
        listGroup.add(badgeRow);
        listPage.add(listGroup);

        const behaviorPage = new Adw.PreferencesPage({
            title: _('Behavior'),
            icon_name: 'preferences-system-symbolic',
        });

        const completeGroup = new Adw.PreferencesGroup({title: _('Completion')});
        const undoRow = Adw.SpinRow.new_with_range(0, 30, 1);
        undoRow.set_title(_('Undo window (seconds)'));
        undoRow.set_subtitle(_('Click the checkbox again to cancel; 0 completes instantly'));
        settings.bind('complete-delay-seconds', undoRow, 'value',
            Gio.SettingsBindFlags.DEFAULT);
        completeGroup.add(undoRow);

        const animRow = Adw.SpinRow.new_with_range(0, 2000, 10);
        animRow.set_title(_('Animation duration (ms)'));
        animRow.set_subtitle(_('0 uses the built-in default (220 ms open / 160 ms close)'));
        settings.bind('animation-duration', animRow, 'value',
            Gio.SettingsBindFlags.DEFAULT);
        completeGroup.add(animRow);
        behaviorPage.add(completeGroup);

        const keyGroup = new Adw.PreferencesGroup({title: _('Keyboard')});
        const keyRow = new Adw.EntryRow({
            title: _('Toggle popup (e.g. <Super><Shift>p)'),
        });
        keyRow.text = settings.get_strv('toggle-quick-view').join(', ');
        keyRow.connect('notify::text', () => {
            const value = keyRow.text.trim();
            settings.set_strv('toggle-quick-view', value ? [value] : []);
        });
        keyGroup.add(keyRow);
        behaviorPage.add(keyGroup);

        const advancedPage = new Adw.PreferencesPage({
            title: _('Advanced'),
            icon_name: 'applications-engineering-symbolic',
        });

        const dbGroup = new Adw.PreferencesGroup({title: _('Planify database')});
        const dbRow = new Adw.EntryRow({
            title: _('Database path (empty = automatic)'),
        });
        settings.bind('database-path', dbRow, 'text', Gio.SettingsBindFlags.DEFAULT);
        dbGroup.add(dbRow);

        const debugGroup = new Adw.PreferencesGroup({title: _('Developer')});
        const debugRow = new Adw.SwitchRow({
            title: _('Debug D-Bus interface'),
            subtitle: _('Test hook (Toggle/Open/Status/Capture); keep off in daily use'),
        });
        settings.bind('debug-dbus', debugRow, 'active', Gio.SettingsBindFlags.DEFAULT);
        debugGroup.add(debugRow);
        advancedPage.add(dbGroup);
        advancedPage.add(debugGroup);

        window.add(listPage);
        window.add(behaviorPage);
        window.add(advancedPage);
    }
}
