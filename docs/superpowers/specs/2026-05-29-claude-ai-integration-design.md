# Claude AI Integration — Design Spec
**Date:** 2026-05-29
**Scope:** Sub-project 1 of 2 (Claude AI Features). Sub-project 2 (Export: Excel/CSV/MD/OmniFocus) is a separate spec.

---

## 1. Architecture

New folder: `core/Services/AI/`

| File | Responsibility |
|------|---------------|
| `Claude.vala` | HTTP client (libsoup-3.0). Resolves API key. Holds selected model. Sends requests, parses JSON responses into typed structs, maps errors. The only file that touches the network. |
| `Prompts.vala` | Static class. One method per feature returning a complete prompt string. Never calls anything. |
| `TaskParser.vala` | Calls `Claude` + `Prompts`. Two methods: `parse_natural_language()` (raw string → `Objects.Item`) and `generate_subtasks()` (parent Item → list of sub-Items). |
| `ImportMapper.vala` | Calls `Claude` + `Prompts`. Input: file content + mime hint. Output: list of Projects/Sections/Items + ambiguity flags. |
| `Scheduler.vala` | Calls `Claude` + `Prompts`. Input: list of Items. Output: list of suggested due dates / priority order with human-readable reasons. |

**Key constraint:** Feature files (`TaskParser`, `ImportMapper`, `Scheduler`) return typed Vala structs only — they never expose `json-glib` types to callers. All JSON parsing lives in `Claude.vala`.

### API Key Resolution (runtime order)
1. `ANTHROPIC_API_KEY` environment variable
2. libsecret stored value (service: `io.github.alainm23.planify.claude`)
3. `null` → AI features disable with amber status indicator

---

## 2. UI Surfaces

### 2a. Quick-add bar (`quick-add/QuickAddCore.vala`)
- Icon-only "Parse with Claude" toggle button next to the submit button
- When active, submit sends raw text to `TaskParser` instead of creating a literal task
- Result pre-populates quick-add fields (title, due date, priority, labels) for user review before saving
- Keyboard shortcut: `Ctrl+Shift+Enter` to parse without toggling
- **Hidden entirely** (not dimmed) when Claude is unavailable

### 2b. Task row inline (`src/Widgets/ProjectItemRow.vala`)
- Sparkle icon (✦) appears on hover at right edge of task row
- Click → calls `TaskParser.generate_subtasks()` with the parent task
- Suggestions appear as a popover checklist (max 300px wide for small screens)
- User checks which subtasks to keep → confirm creates them as sub-items
- Dimmed and non-interactive when Claude is unavailable

### 2c. AI Assistant panel (`src/Views/AI/AssistantPanel.vala`, new)
- Triggered by a wand icon button in the sidebar
- Rendered as `Adw.BottomSheet` — slides up from bottom, preserves full task list width when closed
- Two actions: **Prioritize** (reorders tasks by Claude's suggested priority) and **Schedule** (assigns due dates to undated tasks)
- Changes shown as a diff-style preview with Claude's `reason` strings before applying
- When Claude unavailable: sheet opens to an error state explaining configuration

### 2d. Import dialog (`src/Dialogs/ImportDialog.vala`, new or extended)
- Rendered as `Adw.Dialog` (centered modal; full-screen on small displays via libadwaita responsive breakpoint)
- After file selection, `ImportMapper` runs and produces a tree preview (projects → sections → tasks)
- Ambiguous rows highlighted in amber with an inline edit button
- User can fix, dismiss, or accept all → final import commits to database
- If file >100KB: chunked, mapped in sections, merged into one preview
- If file unrecognizable: shows "Claude couldn't identify any tasks — try a different file"

---

## 3. Data Flow & API Contract

All Claude calls are single-turn, non-streaming `messages` API requests.

**TaskParser**
```
parse_natural_language():
  Input:  raw string
  Output: Objects.Item { title, due_date, due_time, priority, labels[] }

generate_subtasks():
  Input:  parent Objects.Item
  Output: list of Objects.Item (sub-items, no due date set)
```

**ImportMapper**
```
Input:  file_content (string), mime_hint ("md" | "json")
Output: list of { Project, Section[], Item[] }
        ambiguity_flags: list of { line, reason, suggested_fix }
```

**Scheduler**
```
Input:  list of Items { item_id, title, due_date?, priority }
Output: list of { item_id, suggested_due_date, suggested_priority, reason }
```

---

## 4. Settings & API Key Management

New "Claude" section in `src/Dialogs/Preferences.vala`:

- **API key field** — `Adw.PasswordEntryRow` with built-in show/hide eye icon toggle. Shows "●●●●●●●● (saved)" when a key exists. Stored via libsecret.
- **Model selector** — `Gtk.DropDown` with three options (stored in GSettings):
  - Haiku 4.5 — fastest
  - Sonnet 4.6 — balanced *(default)*
  - Opus 4.8 — most capable
- **Status row** — `ClaudeStatusBadge` + "Test connection" button (sends minimal API ping, updates badge live)
- **Disclosure** — one-line notice: "Task content is sent to Anthropic's API to process your requests."

`ClaudeStatusBadge` widget (`src/Widgets/ClaudeStatusBadge.vala`):

| State | Appearance |
|-------|-----------|
| Configured + reachable | Green dot |
| Not configured | Amber dot + tooltip "Claude not configured — add API key in Preferences" |
| Configured + error | Red dot + tooltip showing last error message |

---

## 5. Error Handling & Edge Cases

| Scenario | Behaviour |
|----------|-----------|
| No API key / network down | Amber badge on all AI surfaces; sparkle buttons dimmed; quick-add parse toggle hidden; bottom sheet opens to config error state |
| API timeout / rate limit / malformed response | Toast: "Claude request failed — try again" with retry button; no app state modified |
| Import file >100KB | Split into ~50KB chunks, each mapped separately, results merged into one preview |
| Completely unrecognizable import file | Interactive review shows "Claude couldn't identify any tasks — try a different file" |
| Env var key set | Silent — no libsecret interaction, no "key saved" indicator in preferences |

---

## Out of Scope (this spec)
- Export formats (Excel, CSV, Markdown, OmniFocus) — Sub-project 2
- OpenAI / Gemini / local LLM provider support
- Streaming responses
- Conversation history / multi-turn Claude sessions
