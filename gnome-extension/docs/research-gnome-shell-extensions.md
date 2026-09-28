# GNOME Shell extension research — panel popup quick view (GNOME 45 → 50)

Research compiled September 2026 from official sources (gjs.guide,
developer.gnome.org, the current `main`-branch GNOME Shell source, verified
by grep — not summaries), extensions.gnome.org metadata, and audited
extension source code. Verified against GNOME Shell **50.4** on Fedora 44.

## 1. Modern extension basics (GNOME 45+ ESM)

Since GNOME 45, GNOME Shell and all extensions are **ESM**. `import`/`export`
are mandatory; the legacy `imports.*` global is gone.

- GI libraries: `import GLib from 'gi://GLib'` (versioned only when needed:
  `gi://Gtk?version=3.0` — note GNOME 50's shell process already has
  **GTK 4.0** loaded, so an unversioned `gi://Gtk` import is required).
- Shell internals: `resource:///org/gnome/shell/ui/main.js`; in `prefs.js`
  the prefix is `resource:///org/gnome/Shell/Extensions/js/...`.
- Lifecycle rules: the `constructor()` initializes static resources only;
  **`enable()`** creates everything (UI, signals, sources) and
  **`disable()`** must undo everything — gjs.guide calls incomplete
  teardown *"the most common reason extensions are rejected in review"*.
- `metadata.json`: `uuid`, `name`, `description`, `shell-version` (majors
  only), `url` (required for EGO), optional `settings-schema`,
  `gettext-domain`. Do **not** set `version` (EGO assigns it).
- Packaging: zip the *contents* (metadata.json at root);
  `gnome-extensions install file.zip` unpacks via the CLI — a running shell
  **scans new extension directories only at session start** (verified in
  GNOME 50.4: the D-Bus `InstallRemoteExtension` path is the only
  live-load, and it downloads exclusively from extensions.gnome.org with
  hardcoded URLs). EGO website installs load instantly; local zip installs
  need a re-login.
- `enable`/`disable` are fully dynamic at runtime (GSettings watched), so
  settings changes apply without restarts; **code changes** need a new
  session (ESM cache per uuid).

## 2. Panel button + popup patterns

- `PanelMenu.Button(menuAlignment, accessibleName, dontCreateMenu)` +
  `Main.panel.addToStatusArea(uuid, indicator)`. `setMenu(menu)` installs a
  custom `PopupMenu.PopupMenu` (adds the `panel-menu` class, wires
  `open-state-changed`, reparents into `Main.uiGroup`).
- The panel owns **one shared `PopupMenuManager`**; registering your menu
  gives you for free: modal grab on open, **outside-click dismissal**,
  **Escape closes**, hover-switching between panel menus, and work-area
  clamping with automatic arrow-side flipping.
- `PopupMenu.PopupMenu` is a **`Signals.EventEmitter`, not a GObject** —
  subclasses must be plain JS classes whose `constructor()` calls
  `super(sourceActor, arrowAlignment, arrowSide)`. (GObject.registerClass
  throws "invalid base class"; and plain classes never call `_init`.)
  `PopupBaseMenuItem`, in contrast, *is* a GObject and supports
  `GObject.registerClass` with `_init`.
- Popup rows: `PopupBaseMenuItem` gives hover/`:selected` styling and
  keyboard activation for free. Avoid nesting interactive `St.Button`s
  inside menu items (gesture conflicts); one action per row.
- Rich content goes inside `menu.box`; `St.ScrollView` (`vfade` class,
  `overlay_scrollbars: true`) for scrollable lists. `set_policy` needs
  `Gtk.PolicyType` from whatever `Gtk` namespace the shell loaded.

## 3. Styling (Adwaita / macOS-card look)

- A `stylesheet.css` in the extension directory is **loaded automatically**
  on enable; `stylesheet-dark.css` / `stylesheet-light.css` are hot-swapped
  on `color-scheme` changes. Ship all three.
- **All selectors must be prefixed** (`pqv-…`): every extension's stylesheet
  loads into one global `St.Theme`.
- Supported: `border-radius`, `box-shadow` (single shadow, must be paired
  with a background), `text-shadow`, `-st-accent-color`/`-st-accent-fg-color`
  (GNOME 47+), pseudo-classes `:hover :active :focus :checked` (and
  `:selected` for menu items since 47). **No `backdrop-filter`** — frosted
  glass requires Clutter blur effects (Blur My Shell's approach).
- BoxPointer arrows are hidden via `-arrow-base: 0px; -arrow-rise: 0px;
  -arrow-border-width: 0px` — that is how GNOME's own quick settings get
  their arrowless floating-card look.

## 4. Animation

- Stock popup animation: 150 ms `EASE_OUT_QUAD` fade + scale 0.96→1 with
  `pivot_point` at the arrow edge; closing mirrors it. Durations in-tree:
  150 ms popups, 250 ms submenus.
- To own the animation: `super.open({animate: false})` positions the
  BoxPointer instantly, then `actor.ease({…})` on the menu actor (opacity,
  scale, translation toward the panel). For close, animate first and call
  `super.close({animate: false})` in `onComplete` (guard re-entry with a
  `_closing` flag — outside-click and Escape re-trigger `close()` during
  the animation).
- Row choreography: on open, stagger child rows (`delay: i * 22`), gated by
  `St.Settings.get().enable_animations`; `remove_all_transitions()` on
  close. Respect `reducedMotion` too (BoxPointer already skips slides).
- GNOME 50 adds `easeAsync()` and one-shot `GLib.*_once()` helpers.

## 5. Reading an app's SQLite DB from the shell

- GJS has **no SQLite bindings**. The accepted pattern (TaskWhisperer and
  others): spawn the `sqlite3` CLI via `Gio.Subprocess` with an **argv
  vector** (never a shell string), read `STDOUT_PIPE` with
  `communicate_utf8_async`, and cancel in-flight reads in `disable()`.
- Use `-readonly -json`; add `-cmd '.timeout 400'` for writer contention.
  Planify uses the default **rollback journal** (no WAL), so a reader can
  hit `SQLITE_BUSY` during Todoist sync writes — one short retry suffices.
  **Never use `?immutable=1`** (can observe torn state / report corruption).
- `sqlite3 -json` prints nothing for zero rows — treat empty output as `[]`.
- Change detection: `Gio.File.monitor()` + a ~250 ms debounce.
- Planify specifics (verified in `core/Services/Database.vala`):
  `Items.due` is a **JSON string** whose `date` field is `YYYY-MM-DD` or
  `YYYY-MM-DDTHH:MM:SS(+offset)` in **local** time — sometimes an **empty
  string** (must be filtered: `COALESCE(json_extract(...),'') != ''`).
  Completion = `checked` flag + `completed_at`; trash/deletion =
  `is_deleted` / `is_trash`; `item_type` distinguishes `task` vs `note`;
  priority follows Todoist (4 = P1, most urgent).

## 6. EGO review checklist (highlights)

1. Complete teardown in `disable()` (widgets destroyed and nulled, signals
   disconnected, sources removed, subprocesses cancelled).
2. No `Lang`/`Mainloop`/`ByteArray`; no `eval`; no remote code; no GTK in
   `extension.js`; no Clutter/St in `prefs.js`.
3. Subprocesses spawned carefully (argv vectors), exit cleanly.
4. Honest metadata; unique name; `shell-version` only what you tested;
   `url` required; no `version` field; gettext for user-visible strings.
5. GSettings schema under `org.gnome.shell.extensions.` with matching path;
   compiled schema in the package.
6. GPL-compatible license; disclose what the extension reads (we disclose
   the database read in the metadata description).
7. Prefix stylesheet classes; don't monkey-patch shell internals.

## 7. Prior art

- **No Planify extension existed** (EGO + GitHub searched September 2026).
- Studied: [Todoit](https://github.com/wassimbj/todoit-gnome) (tasks in
  `menu.box`, custom prefixed CSS, MIT, GNOME 45–50),
  [Cronomix](https://github.com/zagortenay333/cronomix) (todo file watch +
  card menus, MIT), [TaskWhisperer](https://github.com/cinatic/taskwhisperer)
  (subprocess read pattern, GPLv3), [Todo.txt
  extension](https://gitlab.com/todo.txt-gnome-shell-extension/todo-txt-gnome-shell-extension)
  (file-based, GPLv2+, GNOME 45–51), [Focus
  Tasks](https://github.com/hassanaziz0012/focus) (Google Tasks REST).

## 8. Compat traps verified on GNOME 50

- **GTK in the shell is 4.0** — `gi://Gtk?version=3.0` aborts the extension
  with "namespace 'Gtk' version '3.0', but '4.0' is already loaded".
- **`Gio.DBusConnection.register_object`**: the old 3-arg convenience is
  gone in GJS 1.88. The working form is
  `conn.register_object(path, nodeInfo.interfaces[0], methodCallClosure, null, null)`
  (must pass the **`GDBusInterfaceInfo`**, not the `GDBusNodeInfo`, plus
  explicit user_data/destroy). Verified with a standalone `gjs` probe.
- `Clutter.ClickAction`/`TapAction` removed in 49 (→ `Clutter.ClickGesture`);
  `Meta.Rectangle` → `Mtk.Rectangle`; `St.Widget` `vertical` deprecated →
  `orientation: Clutter.Orientation.VERTICAL`.
- `org.gnome.Shell.Eval` returns `(false, '')` and the `Screenshot` D-Bus
  API is allowlisted — both locked down for non-trusted callers; the
  in-process `Shell.Screenshot` class remains available to extensions.

## Recommended recipe (what this extension implements)

1. `PanelMenu.Button` + custom `PopupMenu` subclass via `setMenu`; keep the
   shared manager so grabs/Escape/outside-click come free.
2. Arrowless BoxPointer card (`-arrow-*: 0`), 18 px radius, layered shadow,
   `-st-accent-color` accents, dark/light/base stylesheets.
3. Stock open/close replaced by owned eases (EASE_OUT_QUINT open,
   EASE_IN_QUAD close toward the panel), row stagger, reduced-motion aware.
4. Data: read-only `sqlite3 -json` subprocess with busy-timeout + single
   retry, `Gio.File.monitor` + debounce, 120 s poll, cached snapshot.
5. Completion delegated to the Planify app via `ActivateAction`;
   deep-link/open fallback when the app is not running.
