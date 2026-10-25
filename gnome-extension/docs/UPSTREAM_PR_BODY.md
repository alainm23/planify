# Planify Quick View — GNOME Shell top-bar extension

This PR adds `gnome-extension/`: a GNOME Shell extension that puts a
Planify button in the top bar. Clicking it opens a quick-view card with
the user's due-today and overdue tasks — completing tasks, snoozing and
reading descriptions without opening the app.

Screenshots: see `gnome-extension/docs/screenshots/`.

## What it does

- Panel button with a live count badge (count / dot / hidden modes)
- Quick-view card: Pinned, Overdue and Today sections, priority rings,
  project dots, due chips, fold-out task descriptions with a copy button
- Complete tasks (3-second undo window, configurable), snooze 30 min
  via middle-click, inline quick-add that creates tasks due today
- Keyboard shortcut to toggle the popup, Adwaita settings window
- Dark/light aware, follows the accent color, reduced-motion safe

## How it works (and why it is safe for upstream)

- The popup is native St UI inside gnome-shell. Task data is read
  **read-only** from the app's SQLite database using the `sqlite3` CLI
  in a subprocess — the exact data source and access pattern the app's
  own GNOME Shell search provider already uses
  (`search-provider/search-repository.vala` opens the same database
  read-only). The extension never writes to the database.
- Completing tasks is delegated to the app through its exported
  GActions (`complete`, `snooze-30`), so recurring tasks advance and
  sync bookkeeping stays in the app. Quick-add goes through
  `io.github.alainm23.planify.cli`, which uses the app's own
  Services.Store layer.
- The database file is located via XDG data dirs (native + Flatpak),
  overridable in the settings; reads retry on SQLITE_BUSY.
- Fully event-driven: a file monitor plus a low-frequency poll. No
  polling loops, no network access, no clipboard reading, no telemetry.

## Layout

Self-contained `gnome-extension/` directory (own meson-free installer,
docs, test suite), mirroring how the repo already ships `cli/` and
`quick-add/`. The app's build is not modified.

## Testing

- Functional e2e suite (`gnome-extension/tests/e2e-nested.sh`) runs the
  extension in an isolated headless GNOME Shell against a fixture
  database: install → enable → DB read → state machine → clean
  teardown, plus JS-error assertions.
- Interactive suite (`tests/e2e-real.sh`) verifies real input: clicks,
  typed quick-add, Escape, outside-click, keybinding.
- Developed and verified on Fedora 44 / GNOME Shell 50.4 (Wayland),
  Flatpak install of Planify 4.20.

## Phase 2 proposal (follow-up, not in this PR)

A versioned D-Bus API hosted by the existing search-provider process
(`GetTasks` + `TasksChanged`) would remove the CLI reads entirely and
enable task editing from the popup. Design notes are included in
`gnome-extension/docs/architecture-decision.md`.

License: GPL-3.0, same as the app.