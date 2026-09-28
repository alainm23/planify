# Feature & polish roadmap

Compiled 2027-09-27 from a research pass over prior-art extensions (Todoit,
Cronomix/Timepp, Todo.txt, Focus Tasks), GNOME HIG + review guidelines, and
the Planify app source. Updated after user feedback rounds.

## Key facts shaping this list

- Planify **already has** in-app reminder notifications:
  `src/Services/Notification.vala` fires `GLib.Notification` with buttons
  **Complete / Snooze 10/30/60** (backed by `app.complete`, `app.snooze-*`
  actions) — but only same-day reminders and only while the app runs.
- The app already ships a GNOME Shell search provider (`search-provider/`).
- Read-only-queryable today: `pinned`, `priority`, `labels`, `parent_id`,
  `Reminders`, per-project colors.

## A. Quick wins (< 1 day)

| Item | Value/Effort | Notes |
|---|---|---|
| prefs.js Adwaita settings UI (db path, max rows, undo window, keybinding, animation) | High/Low | Gtk4+Adw in prefs process; **never** import Clutter/Meta/St/Shell there |
| Pinboard section (pinned tasks even when nothing is due) | High/Low | `Items.pinned = 1`; app models it (PinnedItemsBox) |
| ~~Row keyboard navigation~~ **DROPPED** (user decision — mouse-first use) | — | — |
| ~~Labels as tiny colored chips~~ **SKIPPED** (user decision, 2026-09-28: zero label usage in their data + needs Todoist-color-name → hex map) | — | revisit if labels get used |
| ~~Badge variants~~ **SHIPPED 2026-09-28** (count / dot / hidden via badge-mode) | Done | prefs ComboRow + indicator modes |
| Overdue-only badge + warning accent | Low/Low | extend badge-mode |
| Completed-today collapsible section | Med/Low | second union block in TASKS_SQL; fold-out code exists |
| Recurring glyph in due pill | Med/Low | `due.is_recurring` already parsed |

## B. Medium (1–3 days)

| Item | Value/Effort | Notes |
|---|---|---|
| Project filter tabs / grouping | High/Med | client-side filter over cached rows |
| Subtask indenting | High/Med | `parent_id` already selected |
| ~~Middle-click snooze (30 min)~~ **SHIPPED 2026-09-28** | Done | `snooze-30` GAction via action group, app-open gated |
| **Reschedule / change due date from the popup** | High/Med | CLI supports it today (`cli update --task-id X --due "…"`, TaskValidator date parsing); UI: small date popover (St calendar widget pattern from the shell's date menu) or preset chips (Tomorrow / Next week / Custom). Upstream later: a proper `reschedule` GAction/D-Bus method so it works app-open with live refresh |
| Inline quick-add entry (St.Entry) | High/Med | or spawn the quick-add window |
| Remember expanded rows + scroll position | Med/Low | Set of ids + adjustment save/restore |
| "Tomorrow" preview section | Med/Low | `date('now','localtime','+1 day')` |
| Quick Settings tile (opt-in) | Med/Med | `QuickSettings.SystemIndicator` + `addExternalIndicator` |
| End-of-day recap notification (opt-in) | Med/Med | `Main.notify` / system-source Notification with actions |
| Priority/label filter row | Med/Med | keep to 2–3 filters max |

## C. Big / upstream

| Item | Notes |
|---|---|
| Phase-2 D-Bus API (GetTasks + TasksChanged, hosted in the search-provider process) | removes sqlite3-spawn review friction + push updates |
| Systray variant | planned; separate branch |
| Upstream reminder hardening | reminders currently same-day only + GUI-only; the notification UI (Complete/Snooze) already exists — ask upstream for cross-day scheduling + firing from a headless D-Bus-activated process. Prefer this over reimplementing reminders in the extension |
| Task editing from the popup | blocked on a Phase-2 write API; never write the DB directly (recurring/sync consistency) |

## D. Anti-patterns to avoid (EGO review)

1. No clipboard monitoring (declare the copy button in the description).
2. Don't duplicate per-task reminders in the extension (HIG: don't spam;
   the app owns reminders) — only a daily recap is defensible.
3. Don't add a search provider (Planify has one).
4. Stay event-driven (file monitor), no aggressive polling.
5. Declare the sqlite3 spawn in the EGO description.
6. No Gtk/Adw in extension.js, no St/Clutter in prefs.js.
7. Don't extend session modes without cleanup comments in disable().
8. Don't turn the popup into a second Planify.
9. EGO rejects AI-generated submissions — human-review before upload.
10. No telemetry.

## Shipped

- Fold-out task descriptions with selectable text + copy button
- Per-zone row clicks (circle completes, text folds description)
- Completion undo window (`complete-delay-seconds`)
- Completion with the app closed (CLI path)
- Title reveal on expand (any length — self-correcting wrapped height)
- Inline quick-add due today (Enter + button paths)
- Single-expanded-row behavior; native-weight card; hover fixes
- (Removed by decision: hover tooltip — the fold-out covers it)

## Recommended order

1. prefs.js settings UI
2. Pinboard section
3. Row keyboard navigation
4. Labels as chips
5. Badge variants
6. Middle-click snooze
