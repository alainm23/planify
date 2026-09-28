# Architecture decision: how tasks reach a GNOME Shell popup

## 0. Embedding the app window: impossible

The extension's UI consists of `St`/`Clutter` actors inside the
`gnome-shell` process; Planify is a GTK4 widget tree in its own process.
GTK4 removed the X11-era `GtkPlug`/`GtkSocket` XEmbed pair entirely, and on
Wayland no client may reparent or composite another client's surface. GNOME
Shell *is* the compositor: Mutter surfaces are managed from the outside and
cannot be inserted into an St tree. The community-endorsed pattern is to
build the popup in St widgets and move **data, not pixels**.

## 1. Candidate architectures

### A. Extension reads the SQLite DB directly (read-only)

The extension spawns `sqlite3 -readonly -json <db>` via `Gio.Subprocess`.

- Proven viable *in this exact project*: Planify's own GNOME Shell search
  provider opens the same database read-only while the app runs
  (`search-provider/search-repository.vala`).
- Risks: default DELETE journal means a writer's commit takes an EXCLUSIVE
  lock → readers can see `SQLITE_BUSY` ("database is locked"). Todoist sync
  writes in the background (`core/Services/Todoist/Todoist.vala`), so this
  is real, not theoretical. Mitigations: `.timeout 400`, short `LIMIT`ed
  queries, one retry. **Never `?immutable=1`** (SQLite docs: incorrect
  results / `SQLITE_CORRUPT` on a changing file).
- Schema coupling: the extension replicates Planify's "Today" semantics
  (local-date comparison against the JSON `due.date`). Recurrence
  advancement is *not* replicated — completion is delegated to the app.
- Task IDs can change during Todoist sync (temp-ID remapping) → re-query on
  every open/refresh, never cache IDs long-term.

### B. In-app D-Bus API (Phase 2)

Planify already owns the session-bus name `io.github.alainm23.planify`
(GApplication uniqueness), exports GActions (`complete`, `show-item`,
`snooze-10/30/60`) usable via `org.freedesktop.Application.ActivateAction`,
and has a small `DBusServer` (`add_item` + `item_added` signal) whose
implementation currently collides with the GApplication-owned name
(`src/Services/DBusServer.vala` owns the same name the app already owns —
the latent bug is documented in the repo exploration).

Phase 2 = fix the collision via the `dbus_register` vfunc (the pattern the
search provider already uses), then export `GetTasks(range)` + a
`TasksChanged` signal. Optionally host the read API in the existing
D-Bus-activated **search provider process** so it works when the GUI is
closed. Precedents: gnome-pomodoro (`org.gnome.Pomodoro` consumed by its
panel extension), MPRIS (canonical app→shell state feed), GSConnect.

- Kills lock contention and schema coupling; push updates instead of polls;
  survives Flatpak sandboxing cleanly; the app keeps semantic control
  (recurrence, filters).

### C. State file / GSettings bridge

App writes a JSON summary the extension reads. Simple and crash-tolerant,
but pull-only with a stale window, adds an app-side write path, and
GSettings-for-state is an anti-pattern (dconf is user config). Strictly
worse than B whenever B is available.

### D. Others

- `planify` CLI: useless for reading from the shell — GApplication
  single-instance semantics mean a spawn merely activates the running
  instance.
- EDS (Evolution Data Server) tasks: ruled out — Planify stores tasks in
  its own SQLite; EDS is an opt-in calendar-events display only.
- Portals/GVfs: expose nothing of another app's private data.

## 2. Decision matrix

| | A: read-only SQLite | B: in-app D-Bus | C: state file |
|---|---|---|---|
| Upstream changes | none | small, additive | small |
| Robustness | medium (BUSY retries, schema coupling) | high (no locks, versioned API) | medium (stale window) |
| EGO review-friendliness | medium (subprocess + disclosed home-dir read; search-provider precedent) | high (ordinary bus proxy, pomodoro/MPRIS pattern) | medium |
| Latency | ~10–50 ms on open + monitor refresh | push, instant | poll interval |
| Works when app closed | yes | needs fallback | yes (stale) |

## 3. Recommendation

**Phase 1 (this extension)**: Architecture A, hardened — read-only
subprocess with busy-timeout and retry, file monitor + poll, completion
delegated to the app through the existing `complete` GAction, task-opening
through `show-item`, empty states when the DB is missing. Zero upstream
changes required.

**Phase 2 (upstream PR to Planify)**: fix the `DBusServer` name collision
and export a versioned read API + `TasksChanged` signal (optionally hosted
in the search-provider process); the extension then prefers D-Bus and keeps
the file read as a fallback when the app is not running.

**Optional one-line upstream improvement**: `PRAGMA journal_mode=WAL` in
`core/Services/Database.vala` would remove reader/writer contention for
both the search provider and this extension.

## 4. Sources

- GTK4 migration guide (GtkPlug/Socket removal): docs.gtk.org/gtk4/migrating-3to4
- GJS GIO/D-Bus guide: gjs.guide/guides/gio/dbus.html
- SQLite open flags / immutable warning: sqlite.org/c3ref/open.html
- SQLITE_BUSY analysis: tenthousandmeters.com (SQLite concurrent writes)
- Pomodoro extension consuming org.gnome.Pomodoro: extensions.gnome.org/extension/520
- Repo evidence: `src/App.vala` (GActions), `src/Services/DBusServer.vala`
  (name collision), `core/Services/Database.vala` (schema, no WAL),
  `search-provider/` (read-only consumer precedent).
