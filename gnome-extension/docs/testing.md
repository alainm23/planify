# Testing guide & results

Environment: Fedora 44, GNOME Shell 50.4 (Wayland), Planify 4.20.0
(Flatpak, real user data — all reads strictly read-only).

## Test rigs

| Rig | What it validates | Limitation |
|---|---|---|
| `tests/e2e-nested.sh` — headless GNOME Shell in `dbus-run-session` with its own dconf | install → enable → DB read → state machine → teardown, zero extension JS errors | headless mutter on real GPUs paints no frames, so no screenshots/animations |
| `tests/e2e-real.sh` — the user's graphical session | real ydotool clicks on the panel button, Escape, outside-click, keybinding, screenshots | requires the extension to be loaded in the session (fresh local installs load at next login) |
| `tests/animclient.mjs`, `debug-dbus` (`Toggle/Open/Close/Status/Capture/Repaint`) | test tooling only; debug D-Bus is off by default | — |

## Results (September 2026, Shell 50.4)

### Functional suite — `e2e-nested.sh` — ALL PASS

```
PASS: database found (real user data) (True)
   today+overdue tasks visible to the shell: 16
PASS: closed initially (False)
PASS: open after Open() (True)
PASS: task rows rendered (True)
PASS: double-open is a no-op (True)
PASS: closed after Close() (False)
PASS: double-close is a no-op (False)
PASS: Toggle opens (True)
PASS: Toggle closes (False)
PASS: status snapshot well-formed (dbPath=~/.var/app/.../database.db)
PASS: debug D-Bus gone after disable (clean teardown)
PASS: no extension JS errors (0)
```

The 16 tasks are the real user's due-today data; the extension rendered 12
rows (`max-rows`) in the popup.

### Issues found and fixed during the loop

1. `gi://Gtk?version=3.0` → GNOME 50's shell has GTK 4.0 loaded; use an
   unversioned `Gtk` import — and in fact **no `Gtk` import at all**:
   `St.ScrollView.set_policy` takes `St.PolicyType` (St dropped its GTK
   dependency).
2. `GObject.registerClass` on a `PopupMenu.PopupMenu` subclass is invalid
   (EventEmitter base) — and a plain JS subclass must use `constructor`,
   never `_init` (which GObject classes get via registerClass).
3. GJS 1.88 `register_object` needs
   `(path, nodeInfo.interfaces[0], closure, null, null)`.
4. `gnome-extensions install <zip>` does not live-load into a running
   shell (EGO-website installs are the only live path) — the panel button
   appears at next login; `InstallRemoteExtension` downloads from EGO only.
5. Planify `due` JSON can carry an **empty** `date` string; the SQL filters
   `COALESCE(json_extract('$.date'),'') != ''` (otherwise no-date tasks
   sort as "overdue").
6. Done-today counts must survive an empty task list (sentinel row via
   `UNION ALL` in the same statement).
7. `new Clutter.Point({...})` is not constructible in GJS — use
   `actor.set_pivot_point(x, y)`.
8. `Gio.DBusConnection.call` has **no auto-promise in GJS 1.88** (9-arg
   await throws "at least 10 arguments"): `Gio._promisify(
   Gio.DBusConnection.prototype, 'call')` at import scope — without this,
   `isAppRunning` silently returned false and `ActivateAction` calls threw.
9. `Shell.Screenshot.screenshot` on GNOME 50 takes
   `(include_cursor, Gio.OutputStream, callback)` — a file path is not
   accepted; create the output stream first.

### Peer review (two independent subagent reviews + one fix verification)

- **Code review vs EGO guidelines**: verdict *SHIP AFTER FIXES*; all
  MAJOR+ findings fixed (subprocess init failure path, Capture endpoint
  restricted to `/tmp/` with normalized paths, tracked animation source
  with teardown guards, Status replies on every path, settings restore in
  test scripts, quick-add desktop-file launch, reduced-motion animateOut,
  ngettext plurals, dead code removed, classname↔CSS audit, color/path
  sanitization).
- **GNOME 50 API audit** (runtime-verified against the installed 50.4
  typelibs and shell sources): found the three runtime breakers in 8–9
  above plus `St.PolicyType`; all fixed.
- **Fix verification**: all 15 fix items VERIFIED, full-file re-scan
  CLEAN (only debug-endpoint hardening notes, since applied).

### Known environment facts (this machine)

- `org.gnome.Shell.Screenshot` D-Bus is allowlisted (AccessDenied from
  normal processes); the extension's debug `Capture` uses the in-process
  `Shell.Screenshot` class instead.
- Headless nested mutter renders no frames here (no page flips): eases,
  screenshots and screencasts all stall. Hence the functional/visual split
  across the two suites.
- `ydotool`/`ydotoold` are available for genuine input injection; the user
  is in the `input` group.

## Round 3 — real-session fixes (September 27, after the user's first relogin)

The validator auto-ran on the user's login and the user then tested by hand.
Three issues were reported and root-caused from the shell journal plus a
`gjs` reproduction probe:

1. **Row clicks silently did nothing.** `org.freedesktop.Application.
   ActivateAction` parameters were built as `new GLib.Variant('(sava)', …)`;
   GJS 1.88 cannot JS-convert the `'av'` slot of that signature ("Invalid
   GVariant signature ()"), the synchronous throw inside the async click
   handler became an unhandled rejection (verified in `gjs`; even
   pre-built child variants fail inside the tuple). Fix: activate the app's
   exported GActions through `Gio.DBusActionGroup`, which uses the action's
   native `'s'` parameter type — no `'av'` anywhere. The click handler now
   also `.catch()`es and logs.
2. **"+" button did nothing.** `flatpak run <quick-add-app-id>` fails
   ("app not installed" — quick-add is a binary inside the Planify
   sandbox). Fix: `flatpak run --command=<quick-add> <app-id>`. Also
   `Gio.DesktopAppInfo` moved to `GioUnix.DesktopAppInfo` in GNOME 50
   (lazy dynamic import with a Gio fallback).
3. **"Weird blur" artifact.** Pixel forensics (vision agent diffing the
   screenshot against the raw wallpaper) showed it was not blur: the
   stylesheet-dark.css variant is what the shell actually loads in
   prefer-dark mode, and it only contained color overrides — all
   structural rules (radii, spacing, widths) were missing, leaving the
   WhiteSur theme's square outer box + inset rounded outline showing.
   Fix: every variant file is now self-sufficient, the card is styled on
   `.popup-menu-content.pqv-content` (specificity beats the theme), the
   BoxPointer stays transparent, and the whole sheet was redesigned to
   match the Planify app (project-colored circle checkboxes, priority
   flag dots, pill due chips, slim scrollbar). Verified live via a
   user-theme hot-swap preview + vision review: **9/10**.

Validation: nested functional e2e 12/12 PASS after the fixes; visual
iteration done live (CSS-only) via the theme-copy trick since JS changes
require a session restart.

## Round 4 — per-zone clicks, undo window, closed-app completion (September 27)

User-verified: CLI completion with the app closed works. Follow-up fixes:

1. **Completion undo window**: `complete-delay-seconds` (default 3, 0 =
   instant). Checkbox click enters a pending state (accent circle +
   undo glyph); clicking again cancels; after the window the completion
   goes through the same app-open/app-closed paths. Pending timeouts live
   on the menu, so a mid-window list rebuild still honors the intent.
2. **Per-zone clicks**: circle completes, text opens the task. Routing
   reads the click position from the activate event against the checkbox
   allocation (single gesture path; keyboard Enter opens the task).
3. **Text click fixes**: the deep link is now launched explicitly through
   Planify's own desktop file (`launch_uris(['planify://item/<id>'])`),
   and the extension raises/focuses the Planify window from the shell
   (`Meta.Window.raise()` + `focus_window`) — a running Planify cannot
   raise itself over other windows on Wayland (focus-stealing
   prevention), which is why text clicks previously looked like no-ops.

## Round 5 — title wrap fix + inline quick-add (September 27, afternoon)

The user reported title reveal + hover tooltip still broken in their
session. Root causes found via in-session state introspection
(`RowDebug`/`ToggleExpand` debug methods added for exactly this):

1. **Tooltip invisible**: the tooltip label was added to `Main.uiGroup`
   *before* the popup actor, so the opaque card painted over it. Fixed by
   re-raising after `setMenu` (`set_child_above_sibling`).
2. **Title didn't wrap**: St-18's `St.Label` has **no height-for-width**
   (its preferred height ignores the wrap width), and `Clutter.BoxLayout`
   doesn't propagate it either — the wrapped second line was allocated 0px
   and never painted. Fix: measure the line height pre-wrap and the text's
   natural width, compute `lines = ceil(naturalWidth / rowWidth)`, and pin
   the label with inline `min-height` + explicit height (verified: row
   50→100px, second line "passthrough" fully painted, neighbors reflow
   cleanly — vision-verified).
3. **Inline quick-add**: the header + button now reveals an in-popup
   `St.Entry`; Enter creates the task **due today** via Planify's CLI
   (`add --content … --due YYYY-MM-DD` — the CLI only parses ISO dates, so
   the extension computes today itself). The quick-add window is no longer
   opened.

Note for testers: `tests/e2e-nested.sh` wipes /tmp/pqv-nested — keep
scratch scripts outside that directory.

## Round 6 — titles longer than 2 wrapped lines (September 28)

`ceil(naturalWidth / rowWidth)` under-counts wrapped lines because word
boundaries waste width, so titles needing 3+ lines were cropped after 2.
Fix: a self-correcting pass re-measures the LIVE Pango layout
(`get_line_count()` + `get_pixel_size()`) ~60 ms after the fold-out and
re-pins the label height exactly. Verified in the clean-room against a
throwaway database (schema copied read-only from the real one — zero
contact with user data) with a 258-character title: all 6 wrapped lines
rendered, no ellipsis, description + copy icon intact, clean neighbor
reflow (vision-verified). The extension's `database-path` GSettings key
made this test possible without touching the real database.

## Round 7 — Enter submit final fix, tooltip removed (September 28)

The vfunc item alone still didn't catch Enter in the user's session.
Platform verification (proper GObject introspection, not the broken
python query): Clutter 18 has **no signal-based key API at all** —
Clutter.Text, Clutter.Actor, and the gesture controllers expose no
usable key signals; the shell's own popupMenu.js still uses
`actor.connect('key-press-event', …)` (50.4 lines 978/1164), which does
work on focused actors. The entry now wires Enter at every level that
can see it: Clutter.Text 'key-press-event' + St.Entry
'key-press-event' + the AddEntryItem vfunc + the legacy 'activate' —
all four call `_submitAddEntry()` (journal-logged).

Hover tooltip removed by user decision (the fold-out already shows the
full title); tooltip actor, wiring, CSS and the enable-time raise call
removed.

## Round 8 — settings window API drift (September 28)

The user's Settings click crashed in the extensions service. Two
libadwaita 1.9 API drifts, both caught by headless verification
(nested session → LaunchExtensionPrefs → shell capture → vision):

1. `Adw.SpinRow.new_with_range` is a convenience function, not a
   constructor (`new` throws) and takes no title — use
   `Adw.SpinRow.new_with_range(min, max, step)` + `set_title`.
2. `Adw.EntryRow` lost `set_subtitle` (no longer an ActionRow subclass
   in adw 1.9) — subtitles dropped from entry rows.

Verified headlessly: LaunchExtensionPrefs opens the real window, three
pages present, Task list page fully rendered with bound values.

## Running after a fresh login

```bash
cd gnome-extension
./tests/e2e-real.sh    # clicks the real panel button, Escape, outside click
```

Interactive manual checklist (visual sign-off):

1. Panel icon shows the Planify symbolic icon + a count badge.
2. Click → card scales/fades in under the button, rows stagger in.
3. Rows show checkbox ring (priority-colored), title, project dot + name,
   due/Overdue label, recurring mark (↻).
4. Click a row with Planify running → check fills with the accent color,
   row fades out, badge count decreases; the task is completed in Planify.
5. `Escape` / outside click → card scales back into the panel icon.
6. Dark and light color schemes both readable (automatic stylesheets).
