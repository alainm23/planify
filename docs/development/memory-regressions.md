# Memory regression checks

Follow-up to [issue 2186's heaptrack findings](https://github.com/alainm23/planify/issues/2186#issuecomment-5285666939).

## Changes

- Navigation cleans up every non-visible page, including its row subscriptions,
  instead of retaining several widget trees for a minute or more. Pending project
  layout transitions and section-loading idles are cancelled before disconnecting
  rows, so they cannot recreate a discarded page's widgets.
- Sidebar, source-row and project-row subscriptions have explicit cleanup paths.
  Replacing the sidebar's filter layout also cleans up flowbox children.
- Task back-references do not own parents, projects or sections. Invalidating
  subtask lists releases their contents immediately. Deletion invalidates the
  project cache again after removal: recursive deletion can rebuild it while the
  parent is still present.
- Store startup defers `extra_data` payloads until first access. Edits and sync
  continue using the same task instances; writing an item loads its existing
  payload before persisting it. The parsed JSON cache invalidates on assignment
  without retaining another copy of the original JSON string.
- Calendar scrolling retains at most twelve months and supports loading in both
  directions. Selecting a distant date rebuilds a small window around that date,
  rather than creating every intervening month. Day signals pass their date as an
  argument, avoiding a closure cycle that retained removed months.
- File backups serialize tasks directly from the SQLite cursor to the output
  stream, retaining one exported task and its JSON at a time. The existing string
  export API remains available for callers that need a string.

Timestamp and subtask caching, hoisting the Store's current-time calculations out
of loops, and completed-task pagination already existed before this follow-up.

## Automated checks

Configure with the optional integrations appropriate to your environment, for example:

```sh
meson setup build -Dportal=false -Devolution=false -Dgoa=false -Dspelling=disabled
meson compile -C build
dbus-run-session -- xvfb-run -a meson test -C build \
  --suite core --suite cli --suite widgets --print-errorlogs
```

GTK tests skip with exit code 77 when a display is unavailable. The build creates
an isolated settings schema; the tests use the memory settings backend and scratch
databases under the build directory. No real user database is needed.

Regression coverage includes deletion of cached parent/child models, preservation
of deferred payloads during edits, backup JSON escaping, calendar bounds and month
release, and cancellation of project/section widget creation.

## Profiling normal interaction

Use a disposable database with several projects containing hundreds of tasks and
completed tasks. Build with debug symbols and run under heaptrack. Repeatedly:

1. Open projects, Today, Scheduled, Labels and filters, including rapid navigation
   before project layout transitions complete.
2. Change project list/board style, navigate away immediately, then return.
3. Add, complete, reparent and delete tasks and projects. Verify counters and
   subsequent navigation show current data.
4. Scroll the date picker in both directions, choose dates decades away, then use
   Today and reopen the selected date.
5. Switch sidebar list/grid mode and create a backup; import the backup into a
   separate disposable profile and compare its contents.

Compare live allocation counts after repeated cycles, not just RSS: GTK/font
caches and the system allocator can retain freed memory. These changes do not
establish the report's estimated MB savings; that needs a comparable heaptrack run.

## Architectural limits

The Store still retains task metadata for global search, counters and sync.
Deferring payloads is not full database pagination. Visible task rows still have
individual subscriptions; this change bounds their lifetime rather than replacing
all routing with a view-level dispatcher. Completed rows retain the existing
pagination instead of switching to a virtualized list. Those wider redesigns need
separate profiling and behavior coverage.
