# Upstream PR — package for alainm23/planify

This directory is designed to be proposed upstream as-is. This file contains
the ready-to-paste pull-request text and the exact steps to open the PR.

## Steps for you (the only manual part)

1. Push the branch to your GitHub fork:
   ```
   git push -u origin feat/gnome-shell-panel-popup
   ```
   (Create the fork on github.com first if it does not exist yet — GitHub's
   "Fork" button on alainm23/planify.)
2. Open the PR: github.com/alainm23/planify → "Compare & pull request"
   → base: `alainm23/planify` `master` (or current default), head: your
   fork's `feat/gnome-shell-panel-popup`.
3. Paste the title and body below into the PR form, replace the
   screenshot references if you moved them, and submit.

The PR adds the extension as a new self-contained top-level directory
(`gnome-extension/`), mirroring how the repo already carries `cli/`,
`quick-add/` and `search-provider/` — the app's own build is untouched.

---

## PR title

```
Add GNOME Shell extension: Planify Quick View (top-bar task popup)
```

## PR body

```markdown
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
```

---

## Notes before submitting (your call, not in the default text)

- **Development transparency**: the code was developed with heavy AI
  assistance (ZCode) under your direction, then human-reviewed. Some
  maintainers appreciate that being stated openly in the PR. Upstream
  and EGO policies differ on this; decide before posting.
- **shell-version matrix**: `metadata.json` declares `["50"]` (verified
  on 50.4). If alainm23 wants broader coverage, the APIs used are
  45+-safe per the porting guides, but only 50 was actually tested.
- **EGO listing** (extensions.gnome.org), separate from the upstream PR:
  upload `dist/planify-quick-view.zip` via build.sh; the description
  MUST disclose (a) reading the Planify SQLite database via the sqlite3
  CLI subprocess and (b) the copy-to-clipboard button.
