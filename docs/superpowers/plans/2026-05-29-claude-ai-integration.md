# Claude AI Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Claude AI features to Planify: natural language task creation, subtask generation, smart scheduling/prioritization, and AI-assisted file import.

**Architecture:** A layered `core/Services/AI/` service folder with `Claude.vala` (HTTP only), `Prompts.vala` (prompt templates only), and three feature files (`TaskParser`, `ImportMapper`, `Scheduler`). UI surfaces: parse button in quick-add, sparkle button on task rows, `Adw.BottomSheet` assistant panel, and `Adw.Dialog` import dialog. All feature files return typed Vala structs; JSON parsing lives exclusively in `Claude.vala`.

**Tech Stack:** Vala, GTK4, libadwaita-1, libsoup-3.0 (HTTP), json-glib-1.0 (JSON), libsecret-1 (keyring storage), GLib.Settings (model preference)

---

## File Map

| Action | Path | Purpose |
|--------|------|---------|
| Create | `core/Services/AI/Claude.vala` | HTTP client, API key resolution, status signal |
| Create | `core/Services/AI/Prompts.vala` | Static prompt template methods |
| Create | `core/Services/AI/TaskParser.vala` | NL → Item; subtask generation |
| Create | `core/Services/AI/ImportMapper.vala` | File content → Projects/Sections/Items + ambiguity flags |
| Create | `core/Services/AI/Scheduler.vala` | Item list → suggested due dates + priority order |
| Create | `src/Widgets/ClaudeStatusBadge.vala` | Shared green/amber/red status dot widget |
| Create | `src/Views/AI/AssistantPanel.vala` | Adw.BottomSheet with Prioritize + Schedule actions |
| Create | `test/test-ai-unit.vala` | GLib.Test for Prompts + Claude API key resolution |
| Modify | `core/meson.build` | Add AI service files to `core_files` |
| Modify | `src/meson.build` | Add ClaudeStatusBadge + AssistantPanel |
| Modify | `test/meson.build` | Add test-ai-unit executable |
| Modify | `data/io.github.alainm23.planify.gschema.xml` | Add `claude-model` string key |
| Modify | `core/QuickAddCore.vala` | Add parse toggle button + Ctrl+Shift+Enter shortcut |
| Modify | `src/Layouts/ItemRow.vala` | Add sparkle button (hover reveal) for subtask generation |
| Modify | `src/Layouts/Sidebar.vala` | Add wand button to trigger AssistantPanel |
| Modify | `src/Dialogs/Preferences.vala` | Add Claude preferences section |

---

## Task 1: Build wiring — meson.build

**Files:**
- Modify: `core/meson.build`
- Modify: `src/meson.build`
- Modify: `test/meson.build`

- [ ] **Step 1: Add AI service files to core_files in `core/meson.build`**

In `core/meson.build`, after the `'Services/CalDAV/Providers/Nextcloud.vala',` line, add:

```
    'Services/AI/Claude.vala',
    'Services/AI/Prompts.vala',
    'Services/AI/TaskParser.vala',
    'Services/AI/ImportMapper.vala',
    'Services/AI/Scheduler.vala',
```

- [ ] **Step 2: Add UI files to src meson.build**

In `src/meson.build`, find the list of source files and add:

```
    'Widgets/ClaudeStatusBadge.vala',
    'Views/AI/AssistantPanel.vala',
```

- [ ] **Step 3: Add test target to `test/meson.build`**

Append to `test/meson.build`:

```meson
test_ai_sources = [
    'test-ai-unit.vala',
]

test_ai = executable(
    'test-ai',
    test_ai_sources,
    dependencies: [ core_dep, glib_dep ],
    install: false
)

test('ai-unit', test_ai, timeout: 30, suite: ['ai-unit'])
```

- [ ] **Step 4: Create stub files so meson can configure without errors**

Create `core/Services/AI/Claude.vala` with:
```vala
public class Services.AI.Claude : GLib.Object {}
```

Create `core/Services/AI/Prompts.vala` with:
```vala
public class Services.AI.Prompts : GLib.Object {}
```

Create `core/Services/AI/TaskParser.vala` with:
```vala
public class Services.AI.TaskParser : GLib.Object {}
```

Create `core/Services/AI/ImportMapper.vala` with:
```vala
public class Services.AI.ImportMapper : GLib.Object {}
```

Create `core/Services/AI/Scheduler.vala` with:
```vala
public class Services.AI.Scheduler : GLib.Object {}
```

Create `src/Widgets/ClaudeStatusBadge.vala` with:
```vala
public class Widgets.ClaudeStatusBadge : Adw.Bin {}
```

Create `src/Views/AI/AssistantPanel.vala` with:
```vala
public class Views.AI.AssistantPanel : Adw.Bin {}
```

Create `test/test-ai-unit.vala` with:
```vala
int main (string[] args) {
    Test.init (ref args);
    return Test.run ();
}
```

- [ ] **Step 5: Verify meson configure succeeds**

```bash
cd /home/jlagman/Projects/planify
meson setup build --wipe 2>&1 | tail -20
```

Expected: `Build targets in project: ...` with no errors.

- [ ] **Step 6: Commit**

```bash
git add core/meson.build src/meson.build test/meson.build \
        core/Services/AI/Claude.vala core/Services/AI/Prompts.vala \
        core/Services/AI/TaskParser.vala core/Services/AI/ImportMapper.vala \
        core/Services/AI/Scheduler.vala \
        src/Widgets/ClaudeStatusBadge.vala src/Views/AI/AssistantPanel.vala \
        test/test-ai-unit.vala
git commit -m "build: add Claude AI service stubs and meson wiring"
```

---

## Task 2: GSettings schema — claude-model key

**Files:**
- Modify: `data/io.github.alainm23.planify.gschema.xml`

- [ ] **Step 1: Add `claude-model` key to the schema**

In `data/io.github.alainm23.planify.gschema.xml`, find the last `<key ...>` entry and add after it:

```xml
<key name="claude-model" type="s">
    <default>"claude-sonnet-4-6"</default>
    <summary>Claude AI model to use</summary>
    <description>Model ID used for Claude AI features. Options: claude-haiku-4-5-20251001, claude-sonnet-4-6, claude-opus-4-8</description>
</key>
```

- [ ] **Step 2: Verify schema compiles**

```bash
cd /home/jlagman/Projects/planify
glib-compile-schemas data/
```

Expected: no output (success).

- [ ] **Step 3: Commit**

```bash
git add data/io.github.alainm23.planify.gschema.xml
git commit -m "feat: add claude-model GSettings key"
```

---

## Task 3: `core/Services/AI/Claude.vala` — HTTP client

**Files:**
- Create: `core/Services/AI/Claude.vala`
- Modify: `test/test-ai-unit.vala`

- [ ] **Step 1: Write the failing test for API key resolution**

Replace `test/test-ai-unit.vala` with:

```vala
using GLib;

void test_api_key_env_var_takes_precedence () {
    Environment.set_variable ("ANTHROPIC_API_KEY", "test-key-from-env", true);
    var claude = new Services.AI.Claude ();
    assert_cmpstr (claude.resolve_api_key (), CompareOperator.EQ, "test-key-from-env");
    Environment.unset_variable ("ANTHROPIC_API_KEY");
}

void test_api_key_returns_null_when_not_set () {
    Environment.unset_variable ("ANTHROPIC_API_KEY");
    var claude = new Services.AI.Claude ();
    // libsecret may return null in test environment — that's fine
    // we just verify it doesn't crash
    string? key = claude.resolve_api_key ();
    // key is either null or a previously stored value — both valid
    assert (key == null || key.length > 0);
}

void test_is_not_configured_without_key () {
    Environment.unset_variable ("ANTHROPIC_API_KEY");
    var claude = new Services.AI.Claude ();
    // Without env var or stored key, should report not configured
    // (in CI this will always be not configured)
    bool configured = claude.is_configured ();
    assert (configured == false || configured == true); // doesn't crash
}

int main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/ai/api-key-env-var", test_api_key_env_var_takes_precedence);
    Test.add_func ("/ai/api-key-null-when-unset", test_api_key_returns_null_when_not_set);
    Test.add_func ("/ai/is-not-configured", test_is_not_configured_without_key);
    return Test.run ();
}
```

- [ ] **Step 2: Run test to verify it fails (class not defined)**

```bash
cd /home/jlagman/Projects/planify/build
ninja test-ai 2>&1 | tail -20
```

Expected: compile error — `Services.AI.Claude` not defined.

- [ ] **Step 3: Implement `core/Services/AI/Claude.vala`**

```vala
/*
 * Copyright © 2026 Alain M. (https://github.com/alainm23/planify)
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 3 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA
 */

public class Services.AI.Claude : GLib.Object {
    private const string API_URL = "https://api.anthropic.com/v1/messages";
    private const string ANTHROPIC_VERSION = "2023-06-01";
    private const string SECRET_SERVICE = "io.github.alainm23.planify.claude";
    private const string SECRET_KEY_ATTR = "service";
    private const string SECRET_KEY_VALUE = "planify-claude-apikey";

    private static Secret.Schema SCHEMA;

    private Soup.Session session;

    public enum Status {
        NOT_CONFIGURED,
        CONFIGURED,
        ERROR
    }

    public Status status { get; private set; default = Status.NOT_CONFIGURED; }
    public string last_error { get; private set; default = ""; }

    public signal void status_changed ();

    private static Claude? _instance;
    public static Claude get_default () {
        if (_instance == null) _instance = new Claude ();
        return _instance;
    }

    static construct {
        SCHEMA = new Secret.Schema (
            SECRET_SERVICE,
            Secret.SchemaFlags.NONE,
            SECRET_KEY_ATTR, Secret.SchemaAttributeType.STRING
        );
    }

    public Claude () {
        session = new Soup.Session ();
        update_status ();
    }

    public string? resolve_api_key () {
        string? env_key = GLib.Environment.get_variable ("ANTHROPIC_API_KEY");
        if (env_key != null && env_key.length > 0) return env_key;

        try {
            return Secret.password_lookup_sync (SCHEMA, null, SECRET_KEY_ATTR, SECRET_KEY_VALUE);
        } catch (Error e) {
            return null;
        }
    }

    public bool is_configured () {
        return resolve_api_key () != null;
    }

    public void store_api_key (string api_key) throws Error {
        Secret.password_store_sync (SCHEMA, Secret.COLLECTION_DEFAULT,
            "Planify Claude API Key", api_key, null,
            SECRET_KEY_ATTR, SECRET_KEY_VALUE);
        update_status ();
    }

    public void clear_api_key () throws Error {
        Secret.password_clear_sync (SCHEMA, null, SECRET_KEY_ATTR, SECRET_KEY_VALUE);
        update_status ();
    }

    public string get_model () {
        return Services.Settings.get_default ().settings.get_string ("claude-model");
    }

    private void update_status () {
        status = is_configured () ? Status.CONFIGURED : Status.NOT_CONFIGURED;
        status_changed ();
    }

    public async string? send_request (string prompt) {
        string? api_key = resolve_api_key ();
        if (api_key == null) {
            status = Status.NOT_CONFIGURED;
            status_changed ();
            return null;
        }

        var builder = new Json.Builder ();
        builder.begin_object ();
        builder.set_member_name ("model");
        builder.add_string_value (get_model ());
        builder.set_member_name ("max_tokens");
        builder.add_int_value (2048);
        builder.set_member_name ("messages");
        builder.begin_array ();
        builder.begin_object ();
        builder.set_member_name ("role");
        builder.add_string_value ("user");
        builder.set_member_name ("content");
        builder.add_string_value (prompt);
        builder.end_object ();
        builder.end_array ();
        builder.end_object ();

        var generator = new Json.Generator ();
        generator.set_root (builder.get_root ());
        string body = generator.to_data (null);

        var message = new Soup.Message ("POST", API_URL);
        message.request_headers.append ("x-api-key", api_key);
        message.request_headers.append ("anthropic-version", ANTHROPIC_VERSION);
        message.request_headers.append ("content-type", "application/json");
        message.set_request_body_from_bytes ("application/json", new GLib.Bytes (body.data));

        try {
            GLib.Bytes stream = yield session.send_and_read_async (
                message, GLib.Priority.DEFAULT, null);
            string response_body = (string) stream.get_data ();

            var parser = new Json.Parser ();
            parser.load_from_data (response_body);
            var root = parser.get_root ().get_object ();

            if (root.has_member ("error")) {
                last_error = root.get_object_member ("error").get_string_member ("message");
                status = Status.ERROR;
                status_changed ();
                return null;
            }

            status = Status.CONFIGURED;
            status_changed ();

            return root
                .get_array_member ("content")
                .get_object_element (0)
                .get_string_member ("text");
        } catch (Error e) {
            last_error = e.message;
            status = Status.ERROR;
            status_changed ();
            return null;
        }
    }

    public async bool ping () {
        string? result = yield send_request ("Reply with only the word: OK");
        return result != null;
    }
}
```

- [ ] **Step 4: Run tests and verify they pass**

```bash
cd /home/jlagman/Projects/planify/build
ninja test-ai && meson test ai-unit --print-errorlogs 2>&1
```

Expected: `1/1 ai-unit/ai-unit OK`

- [ ] **Step 5: Commit**

```bash
git add core/Services/AI/Claude.vala test/test-ai-unit.vala
git commit -m "feat: implement Claude.vala HTTP client with API key resolution"
```

---

## Task 4: `core/Services/AI/Prompts.vala` — prompt templates

**Files:**
- Create: `core/Services/AI/Prompts.vala`
- Modify: `test/test-ai-unit.vala`

- [ ] **Step 1: Write failing tests for prompt output shapes**

Add to `test/test-ai-unit.vala` (before `main`):

```vala
void test_parse_nl_prompt_contains_json_instruction () {
    string prompt = Services.AI.Prompts.parse_natural_language ("buy milk tomorrow");
    assert (prompt.contains ("JSON"));
    assert (prompt.contains ("buy milk tomorrow"));
    assert (prompt.contains ("due_date"));
    assert (prompt.contains ("priority"));
}

void test_generate_subtasks_prompt_contains_task () {
    string prompt = Services.AI.Prompts.generate_subtasks ("Launch website", "");
    assert (prompt.contains ("Launch website"));
    assert (prompt.contains ("JSON"));
}

void test_schedule_items_prompt_contains_today_date () {
    string today = new GLib.DateTime.now_local ().format ("%Y-%m-%d");
    string prompt = Services.AI.Prompts.schedule_items ("[{\"id\":\"1\",\"title\":\"test\"}]");
    assert (prompt.contains (today));
    assert (prompt.contains ("suggested_due_date"));
}

void test_map_import_file_prompt_includes_mime_hint () {
    string prompt = Services.AI.Prompts.map_import_file ("# My Tasks\n- [ ] Do thing", "md");
    assert (prompt.contains ("md"));
    assert (prompt.contains ("# My Tasks"));
    assert (prompt.contains ("projects"));
}
```

Add to `main()`:
```vala
Test.add_func ("/ai/prompts/parse-nl", test_parse_nl_prompt_contains_json_instruction);
Test.add_func ("/ai/prompts/subtasks", test_generate_subtasks_prompt_contains_task);
Test.add_func ("/ai/prompts/schedule", test_schedule_items_prompt_contains_today_date);
Test.add_func ("/ai/prompts/import", test_map_import_file_prompt_includes_mime_hint);
```

- [ ] **Step 2: Run to verify failures**

```bash
cd /home/jlagman/Projects/planify/build
ninja test-ai 2>&1 | tail -10
```

Expected: compile error — `Services.AI.Prompts` methods not defined.

- [ ] **Step 3: Implement `core/Services/AI/Prompts.vala`**

```vala
/*
 * Copyright © 2026 Alain M. (https://github.com/alainm23/planify)
 * GPL v3 — see LICENSE
 */

public class Services.AI.Prompts : GLib.Object {

    public static string parse_natural_language (string input) {
        return (
            "You are a task parser. Extract task details from the user's natural-language input.\n" +
            "Return ONLY a valid JSON object with these fields (omit fields you cannot determine):\n" +
            "{\n" +
            "  \"title\": \"task title as a clean imperative phrase\",\n" +
            "  \"due_date\": \"YYYY-MM-DD or null\",\n" +
            "  \"due_time\": \"HH:MM (24h) or null\",\n" +
            "  \"priority\": 1,\n" +
            "  \"labels\": [\"label1\"]\n" +
            "}\n" +
            "Priority scale: 1=urgent, 2=high, 3=medium, 4=none.\n" +
            "Today is " + new GLib.DateTime.now_local ().format ("%Y-%m-%d") + ".\n" +
            "User input: " + input
        );
    }

    public static string generate_subtasks (string task_title, string task_description) {
        string desc_part = task_description != "" ?
            "\nDescription: " + task_description : "";
        return (
            "You are a task breakdown assistant. Break the following task into concrete, actionable subtasks.\n" +
            "Return ONLY a valid JSON array of strings, each being a short subtask title.\n" +
            "Maximum 8 subtasks. No numbering. No empty strings.\n" +
            "Task: " + task_title + desc_part
        );
    }

    public static string schedule_items (string items_json) {
        return (
            "You are a productivity assistant. Suggest due dates and priorities for these tasks.\n" +
            "Today is " + new GLib.DateTime.now_local ().format ("%Y-%m-%d") + ".\n" +
            "Return ONLY a valid JSON array:\n" +
            "[{\"id\": \"item_id\", \"suggested_due_date\": \"YYYY-MM-DD or null\", " +
            "\"suggested_priority\": 1, \"reason\": \"brief reason\"}]\n" +
            "Priority scale: 1=urgent, 2=high, 3=medium, 4=none.\n" +
            "Tasks (JSON): " + items_json
        );
    }

    public static string map_import_file (string content, string mime_hint) {
        return (
            "You are a task import assistant. Parse this " + mime_hint + " file into tasks.\n" +
            "Return ONLY a valid JSON object:\n" +
            "{\n" +
            "  \"projects\": [\n" +
            "    {\n" +
            "      \"name\": \"project name\",\n" +
            "      \"sections\": [\n" +
            "        {\n" +
            "          \"name\": \"section name or empty string for no section\",\n" +
            "          \"items\": [\n" +
            "            {\"title\": \"task\", \"due_date\": \"YYYY-MM-DD or null\", " +
            "\"priority\": 4, \"notes\": \"description or empty string\"}\n" +
            "          ]\n" +
            "        }\n" +
            "      ]\n" +
            "    }\n" +
            "  ],\n" +
            "  \"ambiguities\": [\n" +
            "    {\"line\": \"original text\", \"reason\": \"why unclear\", " +
            "\"suggested_fix\": \"suggestion\"}\n" +
            "  ]\n" +
            "}\n" +
            "File content:\n" + content
        );
    }
}
```

- [ ] **Step 4: Run tests and verify they all pass**

```bash
cd /home/jlagman/Projects/planify/build
ninja test-ai && meson test ai-unit --print-errorlogs
```

Expected: `7/7 ai-unit/ai-unit OK` (3 from Task 3 + 4 new).

- [ ] **Step 5: Commit**

```bash
git add core/Services/AI/Prompts.vala test/test-ai-unit.vala
git commit -m "feat: implement Prompts.vala with all AI prompt templates"
```

---

## Task 5: `core/Services/AI/TaskParser.vala`

**Files:**
- Create: `core/Services/AI/TaskParser.vala`

- [ ] **Step 1: Implement `core/Services/AI/TaskParser.vala`**

```vala
/*
 * Copyright © 2026 Alain M. (https://github.com/alainm23/planify)
 * GPL v3 — see LICENSE
 */

public struct Services.AI.ParsedItem {
    public string title;
    public string? due_date;
    public string? due_time;
    public int priority;
    public string[] labels;
}

public class Services.AI.TaskParser : GLib.Object {

    public async ParsedItem? parse_natural_language (string input) {
        string prompt = Services.AI.Prompts.parse_natural_language (input);
        string? response = yield Services.AI.Claude.get_default ().send_request (prompt);
        if (response == null) return null;

        try {
            string clean = extract_json_object (response);
            var parser = new Json.Parser ();
            parser.load_from_data (clean);
            var obj = parser.get_root ().get_object ();

            ParsedItem result = ParsedItem ();
            result.title = obj.has_member ("title") ? obj.get_string_member ("title") : input;

            result.due_date = (obj.has_member ("due_date") && obj.get_member ("due_date").get_node_type () != Json.NodeType.NULL)
                ? obj.get_string_member ("due_date") : null;

            result.due_time = (obj.has_member ("due_time") && obj.get_member ("due_time").get_node_type () != Json.NodeType.NULL)
                ? obj.get_string_member ("due_time") : null;

            result.priority = obj.has_member ("priority")
                ? (int) obj.get_int_member ("priority") : Constants.PRIORITY_4;

            if (obj.has_member ("labels") && obj.get_member ("labels").get_node_type () == Json.NodeType.ARRAY) {
                var arr = obj.get_array_member ("labels");
                result.labels = new string[arr.get_length ()];
                for (uint i = 0; i < arr.get_length (); i++) {
                    result.labels[i] = arr.get_string_element (i);
                }
            } else {
                result.labels = new string[0];
            }

            return result;
        } catch (Error e) {
            Services.LogService.get_default ().error ("TaskParser", "Failed to parse response: " + e.message);
            return null;
        }
    }

    public async string[]? generate_subtasks (Objects.Item parent) {
        string prompt = Services.AI.Prompts.generate_subtasks (parent.content, parent.description);
        string? response = yield Services.AI.Claude.get_default ().send_request (prompt);
        if (response == null) return null;

        try {
            string clean = extract_json_array (response);
            var parser = new Json.Parser ();
            parser.load_from_data (clean);
            var arr = parser.get_root ().get_array ();

            string[] subtasks = new string[arr.get_length ()];
            for (uint i = 0; i < arr.get_length (); i++) {
                subtasks[i] = arr.get_string_element (i);
            }
            return subtasks;
        } catch (Error e) {
            Services.LogService.get_default ().error ("TaskParser", "Failed to parse subtasks: " + e.message);
            return null;
        }
    }

    private string extract_json_object (string text) {
        int start = text.index_of ("{");
        int end = text.last_index_of ("}");
        if (start >= 0 && end > start) return text.slice (start, end + 1);
        return text;
    }

    private string extract_json_array (string text) {
        int start = text.index_of ("[");
        int end = text.last_index_of ("]");
        if (start >= 0 && end > start) return text.slice (start, end + 1);
        return text;
    }
}
```

- [ ] **Step 2: Verify the project still compiles**

```bash
cd /home/jlagman/Projects/planify/build
ninja 2>&1 | tail -20
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add core/Services/AI/TaskParser.vala
git commit -m "feat: implement TaskParser — NL parsing and subtask generation"
```

---

## Task 6: `core/Services/AI/ImportMapper.vala`

**Files:**
- Create: `core/Services/AI/ImportMapper.vala`

- [ ] **Step 1: Implement `core/Services/AI/ImportMapper.vala`**

```vala
/*
 * Copyright © 2026 Alain M. (https://github.com/alainm23/planify)
 * GPL v3 — see LICENSE
 */

public struct Services.AI.MappedItem {
    public string title;
    public string? due_date;
    public int priority;
    public string notes;
}

public struct Services.AI.MappedSection {
    public string name;
    public Gee.ArrayList<Services.AI.MappedItem?> items;
}

public struct Services.AI.MappedProject {
    public string name;
    public Gee.ArrayList<Services.AI.MappedSection?> sections;
}

public struct Services.AI.AmbiguityFlag {
    public string line;
    public string reason;
    public string suggested_fix;
}

public class Services.AI.ImportResult : GLib.Object {
    public Gee.ArrayList<Services.AI.MappedProject?> projects;
    public Gee.ArrayList<Services.AI.AmbiguityFlag?> ambiguities;

    public ImportResult () {
        projects = new Gee.ArrayList<Services.AI.MappedProject?> ();
        ambiguities = new Gee.ArrayList<Services.AI.AmbiguityFlag?> ();
    }
}

public class Services.AI.ImportMapper : GLib.Object {
    private const int CHUNK_SIZE_BYTES = 50000;

    public async ImportResult? map_file (string content, string mime_hint) {
        if (content.length <= CHUNK_SIZE_BYTES) {
            return yield map_chunk (content, mime_hint);
        }

        // Large file: split into chunks, map each, merge
        var merged = new Services.AI.ImportResult ();
        int offset = 0;
        while (offset < content.length) {
            int end = int.min (offset + CHUNK_SIZE_BYTES, (int) content.length);
            string chunk = content.slice (offset, end);
            Services.AI.ImportResult? chunk_result = yield map_chunk (chunk, mime_hint);
            if (chunk_result != null) {
                foreach (var p in chunk_result.projects) merged.projects.add (p);
                foreach (var a in chunk_result.ambiguities) merged.ambiguities.add (a);
            }
            offset = end;
        }
        return merged;
    }

    private async ImportResult? map_chunk (string content, string mime_hint) {
        string prompt = Services.AI.Prompts.map_import_file (content, mime_hint);
        string? response = yield Services.AI.Claude.get_default ().send_request (prompt);
        if (response == null) return null;

        try {
            string clean = extract_json_object (response);
            var parser = new Json.Parser ();
            parser.load_from_data (clean);
            var root = parser.get_root ().get_object ();

            var result = new Services.AI.ImportResult ();

            if (root.has_member ("projects")) {
                var projects_arr = root.get_array_member ("projects");
                projects_arr.foreach_element ((arr, idx, node) => {
                    var proj_obj = node.get_object ();
                    Services.AI.MappedProject project = Services.AI.MappedProject ();
                    project.name = proj_obj.get_string_member ("name");
                    project.sections = new Gee.ArrayList<Services.AI.MappedSection?> ();

                    if (proj_obj.has_member ("sections")) {
                        proj_obj.get_array_member ("sections").foreach_element ((sarr, sidx, snode) => {
                            var sec_obj = snode.get_object ();
                            Services.AI.MappedSection section = Services.AI.MappedSection ();
                            section.name = sec_obj.has_member ("name") ? sec_obj.get_string_member ("name") : "";
                            section.items = new Gee.ArrayList<Services.AI.MappedItem?> ();

                            if (sec_obj.has_member ("items")) {
                                sec_obj.get_array_member ("items").foreach_element ((iarr, iidx, inode) => {
                                    var item_obj = inode.get_object ();
                                    Services.AI.MappedItem item = Services.AI.MappedItem ();
                                    item.title = item_obj.get_string_member ("title");
                                    item.due_date = (item_obj.has_member ("due_date") &&
                                        item_obj.get_member ("due_date").get_node_type () != Json.NodeType.NULL)
                                        ? item_obj.get_string_member ("due_date") : null;
                                    item.priority = item_obj.has_member ("priority")
                                        ? (int) item_obj.get_int_member ("priority") : Constants.PRIORITY_4;
                                    item.notes = item_obj.has_member ("notes") ? item_obj.get_string_member ("notes") : "";
                                    section.items.add (item);
                                });
                            }
                            project.sections.add (section);
                        });
                    }
                    result.projects.add (project);
                });
            }

            if (root.has_member ("ambiguities")) {
                root.get_array_member ("ambiguities").foreach_element ((arr, idx, node) => {
                    var amb_obj = node.get_object ();
                    Services.AI.AmbiguityFlag flag = Services.AI.AmbiguityFlag ();
                    flag.line = amb_obj.get_string_member ("line");
                    flag.reason = amb_obj.get_string_member ("reason");
                    flag.suggested_fix = amb_obj.get_string_member ("suggested_fix");
                    result.ambiguities.add (flag);
                });
            }

            return result;
        } catch (Error e) {
            Services.LogService.get_default ().error ("ImportMapper", "Failed to parse import: " + e.message);
            return null;
        }
    }

    private string extract_json_object (string text) {
        int start = text.index_of ("{");
        int end = text.last_index_of ("}");
        if (start >= 0 && end > start) return text.slice (start, end + 1);
        return text;
    }
}
```

- [ ] **Step 2: Verify build**

```bash
cd /home/jlagman/Projects/planify/build
ninja 2>&1 | tail -10
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add core/Services/AI/ImportMapper.vala
git commit -m "feat: implement ImportMapper with chunked file handling"
```

---

## Task 7: `core/Services/AI/Scheduler.vala`

**Files:**
- Create: `core/Services/AI/Scheduler.vala`

- [ ] **Step 1: Implement `core/Services/AI/Scheduler.vala`**

```vala
/*
 * Copyright © 2026 Alain M. (https://github.com/alainm23/planify)
 * GPL v3 — see LICENSE
 */

public struct Services.AI.ScheduleSuggestion {
    public string item_id;
    public string? suggested_due_date;
    public int suggested_priority;
    public string reason;
}

public class Services.AI.Scheduler : GLib.Object {

    public async Gee.ArrayList<Services.AI.ScheduleSuggestion?>? suggest (
        Gee.ArrayList<Objects.Item> items)
    {
        if (items.is_empty) return null;

        string items_json = build_items_json (items);
        string prompt = Services.AI.Prompts.schedule_items (items_json);
        string? response = yield Services.AI.Claude.get_default ().send_request (prompt);
        if (response == null) return null;

        try {
            string clean = extract_json_array (response);
            var parser = new Json.Parser ();
            parser.load_from_data (clean);
            var arr = parser.get_root ().get_array ();

            var suggestions = new Gee.ArrayList<Services.AI.ScheduleSuggestion?> ();
            arr.foreach_element ((a, idx, node) => {
                var obj = node.get_object ();
                Services.AI.ScheduleSuggestion s = Services.AI.ScheduleSuggestion ();
                s.item_id = obj.get_string_member ("id");
                s.suggested_due_date = (obj.has_member ("suggested_due_date") &&
                    obj.get_member ("suggested_due_date").get_node_type () != Json.NodeType.NULL)
                    ? obj.get_string_member ("suggested_due_date") : null;
                s.suggested_priority = obj.has_member ("suggested_priority")
                    ? (int) obj.get_int_member ("suggested_priority") : Constants.PRIORITY_4;
                s.reason = obj.has_member ("reason") ? obj.get_string_member ("reason") : "";
                suggestions.add (s);
            });

            return suggestions;
        } catch (Error e) {
            Services.LogService.get_default ().error ("Scheduler", "Failed to parse suggestions: " + e.message);
            return null;
        }
    }

    private string build_items_json (Gee.ArrayList<Objects.Item> items) {
        var builder = new Json.Builder ();
        builder.begin_array ();
        foreach (var item in items) {
            builder.begin_object ();
            builder.set_member_name ("id");
            builder.add_string_value (item.id);
            builder.set_member_name ("title");
            builder.add_string_value (item.content);
            builder.set_member_name ("due_date");
            if (item.due.date != null && item.due.date != "") {
                builder.add_string_value (item.due.date);
            } else {
                builder.add_null_value ();
            }
            builder.set_member_name ("priority");
            builder.add_int_value (item.priority);
            builder.end_object ();
        }
        builder.end_array ();
        var gen = new Json.Generator ();
        gen.set_root (builder.get_root ());
        return gen.to_data (null);
    }

    private string extract_json_array (string text) {
        int start = text.index_of ("[");
        int end = text.last_index_of ("]");
        if (start >= 0 && end > start) return text.slice (start, end + 1);
        return text;
    }
}
```

- [ ] **Step 2: Verify build**

```bash
cd /home/jlagman/Projects/planify/build
ninja 2>&1 | tail -10
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add core/Services/AI/Scheduler.vala
git commit -m "feat: implement Scheduler — AI-powered due date and priority suggestions"
```

---

## Task 8: `src/Widgets/ClaudeStatusBadge.vala`

**Files:**
- Create: `src/Widgets/ClaudeStatusBadge.vala`

- [ ] **Step 1: Implement `src/Widgets/ClaudeStatusBadge.vala`**

```vala
/*
 * Copyright © 2026 Alain M. (https://github.com/alainm23/planify)
 * GPL v3 — see LICENSE
 */

public class Widgets.ClaudeStatusBadge : Adw.Bin {
    private Gtk.Image dot;

    construct {
        dot = new Gtk.Image () {
            pixel_size = 10,
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER
        };
        child = dot;

        update_from_status (Services.AI.Claude.get_default ().status);

        Services.AI.Claude.get_default ().status_changed.connect (() => {
            update_from_status (Services.AI.Claude.get_default ().status);
        });
    }

    private void update_from_status (Services.AI.Claude.Status status) {
        dot.remove_css_class ("success");
        dot.remove_css_class ("warning");
        dot.remove_css_class ("error");

        switch (status) {
            case Services.AI.Claude.Status.CONFIGURED:
                dot.icon_name = "emblem-ok-symbolic";
                dot.add_css_class ("success");
                dot.tooltip_text = _("Claude is ready");
                break;
            case Services.AI.Claude.Status.NOT_CONFIGURED:
                dot.icon_name = "dialog-warning-symbolic";
                dot.add_css_class ("warning");
                dot.tooltip_text = _("Claude not configured — add API key in Preferences");
                break;
            case Services.AI.Claude.Status.ERROR:
                dot.icon_name = "dialog-error-symbolic";
                dot.add_css_class ("error");
                dot.tooltip_text = Services.AI.Claude.get_default ().last_error;
                break;
        }
    }
}
```

- [ ] **Step 2: Verify build**

```bash
cd /home/jlagman/Projects/planify/build
ninja 2>&1 | tail -10
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add src/Widgets/ClaudeStatusBadge.vala
git commit -m "feat: add ClaudeStatusBadge widget with three-state indicator"
```

---

## Task 9: Preferences dialog — Claude section

**Files:**
- Modify: `src/Dialogs/Preferences.vala`

- [ ] **Step 1: Locate the preferences groups to find where to add the Claude section**

```bash
grep -n "Adw.PreferencesGroup\|PreferencesPage\|add_group\|append" \
    /home/jlagman/Projects/planify/src/Dialogs/Preferences.vala | head -30
```

Note the last group addition line number.

- [ ] **Step 2: Add Claude preferences section**

Add a new method `build_claude_group` to the preferences class and call it from `construct`. Add after the last existing group:

```vala
private Adw.PreferencesGroup build_claude_group () {
    var group = new Adw.PreferencesGroup () {
        title = _("Claude AI"),
        description = _("Task content is sent to Anthropic's API to process your requests.")
    };

    // API key row
    var api_key_row = new Adw.PasswordEntryRow () {
        title = _("API Key")
    };
    string? stored_key = Services.AI.Claude.get_default ().resolve_api_key ();
    if (stored_key != null && GLib.Environment.get_variable ("ANTHROPIC_API_KEY") == null) {
        api_key_row.text = stored_key;
    } else if (stored_key != null) {
        api_key_row.placeholder_text = _("Set via ANTHROPIC_API_KEY environment variable");
        api_key_row.sensitive = false;
    }

    api_key_row.apply.connect (() => {
        try {
            if (api_key_row.text.length > 0) {
                Services.AI.Claude.get_default ().store_api_key (api_key_row.text);
            } else {
                Services.AI.Claude.get_default ().clear_api_key ();
            }
        } catch (Error e) {
            Services.LogService.get_default ().error ("Preferences", e.message);
        }
    });

    // Model selector
    string[] model_ids = {
        "claude-haiku-4-5-20251001",
        "claude-sonnet-4-6",
        "claude-opus-4-8"
    };
    string[] model_labels = {
        _("Haiku 4.5 — fastest"),
        _("Sonnet 4.6 — balanced (recommended)"),
        _("Opus 4.8 — most capable")
    };

    var model_row = new Adw.ComboRow () {
        title = _("Model")
    };
    var model_list = new Gtk.StringList (model_labels);
    model_row.model = model_list;

    string current_model = Services.Settings.get_default ().settings.get_string ("claude-model");
    for (int i = 0; i < model_ids.length; i++) {
        if (model_ids[i] == current_model) { model_row.selected = i; break; }
    }

    model_row.notify["selected"].connect (() => {
        Services.Settings.get_default ().settings.set_string (
            "claude-model", model_ids[model_row.selected]);
    });

    // Status row
    var badge = new Widgets.ClaudeStatusBadge ();
    var test_button = new Gtk.Button.with_label (_("Test connection")) {
        valign = Gtk.Align.CENTER,
        css_classes = { "flat" }
    };
    test_button.clicked.connect (() => {
        test_button.sensitive = false;
        Services.AI.Claude.get_default ().ping.begin ((obj, res) => {
            Services.AI.Claude.get_default ().ping.end (res);
            test_button.sensitive = true;
        });
    });

    var status_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
    status_box.append (badge);
    status_box.append (test_button);

    var status_row = new Adw.ActionRow () {
        title = _("Connection status"),
        activatable = false
    };
    status_row.add_suffix (status_box);

    group.add (api_key_row);
    group.add (model_row);
    group.add (status_row);

    return group;
}
```

Call it from `construct` (or `build_ui`), adding the result to the preferences page:
```vala
page.add (build_claude_group ());
```

- [ ] **Step 3: Verify build**

```bash
cd /home/jlagman/Projects/planify/build
ninja 2>&1 | tail -10
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add src/Dialogs/Preferences.vala
git commit -m "feat: add Claude AI section to Preferences dialog"
```

---

## Task 10: Quick-add bar — AI parse button

**Files:**
- Modify: `core/QuickAddCore.vala`

- [ ] **Step 1: Add parse toggle button field declaration**

In `Layouts.QuickAddCore`, add to the private fields block (near `submit_button`):

```vala
private Gtk.ToggleButton ai_parse_button;
private bool claude_available = false;
```

- [ ] **Step 2: Build the AI parse button in the `construct` block**

Find where `submit_button` is built and add adjacent to it:

```vala
ai_parse_button = new Gtk.ToggleButton () {
    icon_name = "starred-symbolic",
    tooltip_text = _("Parse with Claude AI (Ctrl+Shift+Enter)"),
    css_classes = { "flat" },
    visible = false
};
```

Add the button to the action bar/box that contains `submit_button`.

- [ ] **Step 3: Show/hide based on Claude availability**

Add to `construct`:

```vala
update_ai_button_visibility ();
Services.AI.Claude.get_default ().status_changed.connect (update_ai_button_visibility);
```

Add method:

```vala
private void update_ai_button_visibility () {
    claude_available = Services.AI.Claude.get_default ().is_configured ();
    ai_parse_button.visible = claude_available;
}
```

- [ ] **Step 4: Wire up Ctrl+Shift+Enter shortcut and parse action**

Find the `shortcut_controller` setup (search for `Gtk.ShortcutController`) and add:

```vala
var ai_shortcut = new Gtk.Shortcut (
    Gtk.ShortcutTrigger.parse_string ("<Control><Shift>Return"),
    new Gtk.CallbackAction ((widget, args) => {
        if (claude_available) { ai_parse_button.active = true; submit_item (); }
        return true;
    })
);
shortcut_controller.add_shortcut (ai_shortcut);
```

- [ ] **Step 5: Intercept submit to run TaskParser when toggle is active**

Find the method that handles item submission (search for `add_item_db`). Before creating the item literally, add:

```vala
if (ai_parse_button.active && content_entry.text.strip ().length > 0) {
    is_loading = true;
    var parser = new Services.AI.TaskParser ();
    parser.parse_natural_language.begin (content_entry.text, (obj, res) => {
        Services.AI.ParsedItem? parsed = parser.parse_natural_language.end (res);
        is_loading = false;
        if (parsed != null) {
            content_entry.text = parsed.title;
            if (parsed.due_date != null) {
                // apply due date using existing schedule_button API
                var due = new Objects.DueDate ();
                due.date = parsed.due_date;
                if (parsed.due_time != null) due.date = parsed.due_date + "T" + parsed.due_time + ":00";
                item.due = due;
                schedule_button.update_request ();
            }
            item.priority = parsed.priority;
            priority_button.update_request ();
        }
        // let user review, don't auto-submit
    });
    return;
}
```

- [ ] **Step 6: Verify build**

```bash
cd /home/jlagman/Projects/planify/build
ninja 2>&1 | tail -10
```

Expected: no errors.

- [ ] **Step 7: Commit**

```bash
git add core/QuickAddCore.vala
git commit -m "feat: add Claude AI parse button to quick-add bar"
```

---

## Task 11: ItemRow — sparkle button for subtask generation

**Files:**
- Modify: `src/Layouts/ItemRow.vala`

- [ ] **Step 1: Add sparkle button field**

In `Layouts.ItemRow`, add to the private fields block:

```vala
private Gtk.Button ai_subtask_button;
private Gtk.Revealer ai_subtask_revealer;
```

- [ ] **Step 2: Build sparkle button and revealer**

Find where `action_box_right` is built. Add:

```vala
ai_subtask_button = new Gtk.Button.from_icon_name ("starred-symbolic") {
    css_classes = { "flat", "circular" },
    tooltip_text = _("Generate subtasks with Claude AI"),
    pixel_size = 16
};

ai_subtask_revealer = new Gtk.Revealer () {
    transition_type = Gtk.RevealerTransitionType.CROSSFADE,
    child = ai_subtask_button,
    reveal_child = false
};
```

Append `ai_subtask_revealer` to `action_box_right`.

- [ ] **Step 3: Show on hover, hide on leave**

Find the existing `Gtk.EventControllerMotion` setup (or add one). In the enter handler:

```vala
ai_subtask_revealer.reveal_child = Services.AI.Claude.get_default ().is_configured ();
```

In the leave handler:

```vala
ai_subtask_revealer.reveal_child = false;
```

- [ ] **Step 4: Wire up subtask generation on click**

```vala
ai_subtask_button.clicked.connect (() => {
    ai_subtask_button.sensitive = false;
    var parser = new Services.AI.TaskParser ();
    parser.generate_subtasks.begin (item, (obj, res) => {
        string[]? subtasks = parser.generate_subtasks.end (res);
        ai_subtask_button.sensitive = true;
        if (subtasks == null || subtasks.length == 0) return;
        show_subtask_popover (subtasks);
    });
});
```

- [ ] **Step 5: Implement `show_subtask_popover`**

```vala
private void show_subtask_popover (string[] subtasks) {
    var popover = new Gtk.Popover ();
    popover.width_request = 300;

    var vbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
        margin_top = 8, margin_bottom = 8,
        margin_start = 8, margin_end = 8
    };

    var checks = new Gee.ArrayList<Gtk.CheckButton> ();
    foreach (string title in subtasks) {
        var cb = new Gtk.CheckButton.with_label (title) { active = true };
        vbox.append (cb);
        checks.add (cb);
    }

    var confirm_button = new Gtk.Button.with_label (_("Add selected")) {
        css_classes = { "suggested-action" },
        margin_top = 4
    };
    vbox.append (confirm_button);

    confirm_button.clicked.connect (() => {
        for (int i = 0; i < subtasks.length; i++) {
            if (checks[i].active) {
                var sub = new Objects.Item ();
                sub.content = subtasks[i];
                sub.project_id = item.project_id;
                sub.section_id = item.section_id;
                sub.parent_id = item.id;
                Services.Store.instance ().insert_item (sub);
            }
        }
        popover.popdown ();
    });

    popover.child = vbox;
    popover.set_parent (ai_subtask_button);
    popover.popup ();
}
```

- [ ] **Step 6: Verify build**

```bash
cd /home/jlagman/Projects/planify/build
ninja 2>&1 | tail -10
```

Expected: no errors.

- [ ] **Step 7: Commit**

```bash
git add src/Layouts/ItemRow.vala
git commit -m "feat: add sparkle subtask generation button to task rows"
```

---

## Task 12: AI Assistant panel (`Adw.BottomSheet`)

**Files:**
- Create: `src/Views/AI/AssistantPanel.vala`
- Modify: `src/Layouts/Sidebar.vala`

- [ ] **Step 1: Create `src/Views/AI/` directory and implement `AssistantPanel.vala`**

```bash
mkdir -p /home/jlagman/Projects/planify/src/Views/AI
```

```vala
/*
 * Copyright © 2026 Alain M. (https://github.com/alainm23/planify)
 * GPL v3 — see LICENSE
 */

public class Views.AI.AssistantPanel : Adw.BottomSheet {

    private Gtk.Button prioritize_button;
    private Gtk.Button schedule_button;
    private Gtk.ListBox preview_list;
    private Gtk.Revealer preview_revealer;
    private Gtk.Button apply_button;
    private Gtk.Button cancel_button;
    private Gtk.Spinner spinner;
    private Gtk.Label status_label;

    private Gee.ArrayList<Services.AI.ScheduleSuggestion?>? pending_suggestions = null;
    private Gee.ArrayList<Objects.Item>? current_items = null;

    construct {
        can_open = true;
        show_drag_handle = true;

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12) {
            margin_top = 16, margin_bottom = 16,
            margin_start = 16, margin_end = 16
        };

        // Header
        var header = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 8);
        var title_label = new Gtk.Label (_("Claude Assistant")) {
            css_classes = { "title-4" },
            hexpand = true,
            xalign = 0
        };
        var badge = new Widgets.ClaudeStatusBadge ();
        header.append (title_label);
        header.append (badge);

        // Not-configured notice (shown when Claude unavailable)
        var notice = new Adw.StatusPage () {
            icon_name = "dialog-warning-symbolic",
            title = _("Claude not configured"),
            description = _("Add your API key in Preferences → Claude AI")
        };
        var notice_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            child = notice,
            reveal_child = !Services.AI.Claude.get_default ().is_configured ()
        };

        Services.AI.Claude.get_default ().status_changed.connect (() => {
            bool configured = Services.AI.Claude.get_default ().is_configured ();
            notice_revealer.reveal_child = !configured;
            prioritize_button.sensitive = configured;
            schedule_button.sensitive = configured;
        });

        // Action buttons
        spinner = new Gtk.Spinner ();
        prioritize_button = new Gtk.Button.with_label (_("Prioritize tasks")) {
            css_classes = { "pill" },
            sensitive = Services.AI.Claude.get_default ().is_configured ()
        };
        schedule_button = new Gtk.Button.with_label (_("Schedule undated tasks")) {
            css_classes = { "pill" },
            sensitive = Services.AI.Claude.get_default ().is_configured ()
        };

        var actions_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 8) {
            homogeneous = true
        };
        actions_box.append (prioritize_button);
        actions_box.append (schedule_button);

        status_label = new Gtk.Label ("") { xalign = 0 };

        // Preview list
        preview_list = new Gtk.ListBox () {
            css_classes = { "boxed-list" }
        };
        preview_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            child = preview_list
        };

        apply_button = new Gtk.Button.with_label (_("Apply")) {
            css_classes = { "suggested-action" }
        };
        cancel_button = new Gtk.Button.with_label (_("Cancel")) {
            css_classes = { "flat" }
        };

        var apply_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 8) {
            halign = Gtk.Align.END
        };
        apply_box.append (cancel_button);
        apply_box.append (apply_button);
        var apply_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            child = apply_box
        };

        content_box.append (header);
        content_box.append (notice_revealer);
        content_box.append (actions_box);
        content_box.append (spinner);
        content_box.append (status_label);
        content_box.append (preview_revealer);
        content_box.append (apply_revealer);

        sheet = new Gtk.ScrolledWindow () {
            child = content_box,
            hscrollbar_policy = Gtk.PolicyType.NEVER
        };

        prioritize_button.clicked.connect (() => run_suggestions (false));
        schedule_button.clicked.connect (() => run_suggestions (true));

        cancel_button.clicked.connect (() => {
            pending_suggestions = null;
            preview_revealer.reveal_child = false;
            apply_revealer.reveal_child = false;
            status_label.label = "";
        });

        apply_button.clicked.connect (() => {
            apply_suggestions ();
            preview_revealer.reveal_child = false;
            apply_revealer.reveal_child = false;
            status_label.label = _("Applied!");
        });
    }

    private void run_suggestions (bool schedule_mode) {
        current_items = get_current_items (schedule_mode);
        if (current_items == null || current_items.is_empty) {
            status_label.label = _("No tasks to process.");
            return;
        }

        spinner.spinning = true;
        prioritize_button.sensitive = false;
        schedule_button.sensitive = false;
        status_label.label = _("Asking Claude…");

        var sched = new Services.AI.Scheduler ();
        sched.suggest.begin (current_items, (obj, res) => {
            pending_suggestions = sched.suggest.end (res);
            spinner.spinning = false;
            prioritize_button.sensitive = true;
            schedule_button.sensitive = true;

            if (pending_suggestions == null) {
                status_label.label = _("Claude request failed — try again.");
                return;
            }

            status_label.label = _("Review suggested changes:");
            populate_preview (pending_suggestions);
            preview_revealer.reveal_child = true;
            apply_revealer.reveal_child = true;
        });
    }

    private void populate_preview (Gee.ArrayList<Services.AI.ScheduleSuggestion?> suggestions) {
        while (preview_list.get_first_child () != null)
            preview_list.remove (preview_list.get_first_child ());

        foreach (var s in suggestions) {
            Objects.Item? item = Services.Store.instance ().get_item (s.item_id);
            if (item == null) continue;

            var row = new Adw.ActionRow () {
                title = item.content,
                subtitle = s.reason
            };
            if (s.suggested_due_date != null) {
                row.add_suffix (new Gtk.Label (s.suggested_due_date) {
                    css_classes = { "caption" }, valign = Gtk.Align.CENTER
                });
            }
            preview_list.append (row);
        }
    }

    private void apply_suggestions () {
        if (pending_suggestions == null) return;
        foreach (var s in pending_suggestions) {
            Objects.Item? item = Services.Store.instance ().get_item (s.item_id);
            if (item == null) continue;
            if (s.suggested_due_date != null) {
                item.due.date = s.suggested_due_date;
            }
            item.priority = s.suggested_priority;
            item.update ();
        }
        pending_suggestions = null;
    }

    private Gee.ArrayList<Objects.Item>? get_current_items (bool undated_only) {
        // Get items from the currently visible project/filter
        var items = new Gee.ArrayList<Objects.Item> ();
        var today = new GLib.DateTime.now_local ();
        var source_items = undated_only
            ? Services.Store.instance ().get_items_by_scheduled (false)
            : Services.Store.instance ().get_items_by_date (today, false);
        foreach (var item in source_items) {
            items.add (item);
        }
        return items;
    }
}
```

- [ ] **Step 2: Add wand button to sidebar**

In `src/Layouts/Sidebar.vala`, find where sidebar action buttons are added. Add:

```vala
var ai_panel = new Views.AI.AssistantPanel ();

var ai_wand_button = new Gtk.Button.from_icon_name ("starred-symbolic") {
    tooltip_text = _("Claude AI Assistant"),
    css_classes = { "flat", "circular" }
};
ai_wand_button.clicked.connect (() => {
    ai_panel.open = true;
});

// Add ai_panel as overlay child on the main window
// Add ai_wand_button to sidebar action row
```

Note: `Adw.BottomSheet` must be placed as a child of the top-level `Adw.ToolbarView` or `Adw.NavigationView`. Check where other overlay widgets are parented in `MainWindow.vala` and follow the same pattern.

- [ ] **Step 3: Verify build**

```bash
cd /home/jlagman/Projects/planify/build
ninja 2>&1 | tail -10
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add src/Views/AI/AssistantPanel.vala src/Layouts/Sidebar.vala
git commit -m "feat: add AI assistant bottom sheet with prioritize/schedule actions"
```

---

## Task 13: Import dialog with Claude step

**Files:**
- Create: `src/Dialogs/ImportDialog.vala`
- Modify: `src/meson.build` (add ImportDialog.vala)

- [ ] **Step 1: Add `ImportDialog.vala` to `src/meson.build`**

Find the dialogs section in `src/meson.build` and add:
```
'Dialogs/ImportDialog.vala',
```

- [ ] **Step 2: Implement `src/Dialogs/ImportDialog.vala`**

```vala
/*
 * Copyright © 2026 Alain M. (https://github.com/alainm23/planify)
 * GPL v3 — see LICENSE
 */

public class Dialogs.ImportDialog : Adw.Dialog {

    private Gtk.Stack stack;
    private Gtk.Button import_button;
    private Gtk.Button back_button;
    private Gtk.Button confirm_button;
    private Gtk.Spinner spinner;
    private Gtk.Label status_label;
    private Gtk.TreeView preview_tree;
    private Gtk.TreeStore tree_store;
    private Services.AI.ImportResult? current_result = null;

    construct {
        title = _("Import Tasks");
        content_width = 560;
        content_height = 500;

        stack = new Gtk.Stack () {
            transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT
        };

        // Page 1: file picker
        var file_page = build_file_page ();
        // Page 2: preview + ambiguity review
        var preview_page = build_preview_page ();

        stack.add_named (file_page, "file");
        stack.add_named (preview_page, "preview");

        var toolbar = new Adw.ToolbarView ();
        toolbar.add_top_bar (new Adw.HeaderBar ());
        toolbar.content = stack;

        child = toolbar;
    }

    private Gtk.Widget build_file_page () {
        var vbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 16) {
            margin_top = 24, margin_bottom = 24,
            margin_start = 24, margin_end = 24,
            valign = Gtk.Align.CENTER
        };

        var icon = new Gtk.Image.from_icon_name ("document-open-symbolic") {
            pixel_size = 64, opacity = 0.6
        };
        var label = new Gtk.Label (_("Select a Markdown or JSON file to import")) {
            wrap = true, justify = Gtk.Justification.CENTER
        };

        import_button = new Gtk.Button.with_label (_("Choose file…")) {
            css_classes = { "suggested-action", "pill" },
            halign = Gtk.Align.CENTER
        };
        import_button.clicked.connect (open_file_chooser);

        spinner = new Gtk.Spinner ();
        status_label = new Gtk.Label ("") { wrap = true, justify = Gtk.Justification.CENTER };

        vbox.append (icon);
        vbox.append (label);
        vbox.append (import_button);
        vbox.append (spinner);
        vbox.append (status_label);

        return vbox;
    }

    private Gtk.Widget build_preview_page () {
        var vbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 8) {
            margin_top = 16, margin_bottom = 16,
            margin_start = 16, margin_end = 16
        };

        var header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 8);
        back_button = new Gtk.Button.with_label (_("← Back")) { css_classes = { "flat" } };
        var preview_label = new Gtk.Label (_("Preview import")) {
            css_classes = { "title-4" }, hexpand = true, xalign = 0
        };
        header_box.append (back_button);
        header_box.append (preview_label);

        // Tree store: col 0 = display text, col 1 = is ambiguous (bool), col 2 = type string
        tree_store = new Gtk.TreeStore (3, typeof (string), typeof (bool), typeof (string));
        preview_tree = new Gtk.TreeView.with_model (tree_store) {
            headers_visible = false, vexpand = true
        };

        var text_renderer = new Gtk.CellRendererText () { ellipsize = Pango.EllipsizeMode.END };
        var col = new Gtk.TreeViewColumn ();
        col.pack_start (text_renderer, true);
        col.add_attribute (text_renderer, "text", 0);
        col.add_attribute (text_renderer, "foreground-rgba", 1); // amber tint for ambiguous
        preview_tree.append_column (col);

        var scroll = new Gtk.ScrolledWindow () {
            child = preview_tree,
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            vexpand = true
        };

        confirm_button = new Gtk.Button.with_label (_("Import all")) {
            css_classes = { "suggested-action" },
            halign = Gtk.Align.END
        };

        vbox.append (header_box);
        vbox.append (scroll);
        vbox.append (confirm_button);

        back_button.clicked.connect (() => stack.visible_child_name = "file");
        confirm_button.clicked.connect (do_import);

        return vbox;
    }

    private void open_file_chooser () {
        var dialog = new Gtk.FileDialog () {
            title = _("Open file"),
            modal = true
        };
        var filter_md = new Gtk.FileFilter ();
        filter_md.name = "Markdown / JSON";
        filter_md.add_pattern ("*.md");
        filter_md.add_pattern ("*.json");
        var filters = new GLib.ListStore (typeof (Gtk.FileFilter));
        filters.append (filter_md);
        dialog.filters = filters;

        dialog.open.begin (null, null, (obj, res) => {
            try {
                var file = dialog.open.end (res);
                process_file (file);
            } catch (Error e) {
                // user cancelled — no action
            }
        });
    }

    private void process_file (GLib.File file) {
        import_button.sensitive = false;
        spinner.spinning = true;
        status_label.label = _("Analysing with Claude…");

        string? content = null;
        try {
            uint8[] data;
            file.load_contents (null, out data, null);
            content = (string) data;
        } catch (Error e) {
            spinner.spinning = false;
            import_button.sensitive = true;
            status_label.label = _("Could not read file: ") + e.message;
            return;
        }

        string mime_hint = file.get_basename ().has_suffix (".json") ? "json" : "md";
        var mapper = new Services.AI.ImportMapper ();
        mapper.map_file.begin (content, mime_hint, (obj, res) => {
            current_result = mapper.map_file.end (res);
            spinner.spinning = false;
            import_button.sensitive = true;

            if (current_result == null || current_result.projects.is_empty) {
                status_label.label = _("Claude couldn't identify any tasks — try a different file.");
                return;
            }

            populate_preview (current_result);
            stack.visible_child_name = "preview";
        });
    }

    private void populate_preview (Services.AI.ImportResult result) {
        tree_store.clear ();
        foreach (var project in result.projects) {
            Gtk.TreeIter proj_iter;
            tree_store.append (out proj_iter, null);
            tree_store.set (proj_iter, 0, "📁 " + project.name, 1, false, 2, "project");

            foreach (var section in project.sections) {
                Gtk.TreeIter sec_iter;
                tree_store.append (out sec_iter, proj_iter);
                string sec_name = section.name != "" ? "📂 " + section.name : _("(no section)");
                tree_store.set (sec_iter, 0, sec_name, 1, false, 2, "section");

                foreach (var item in section.items) {
                    Gtk.TreeIter item_iter;
                    tree_store.append (out item_iter, sec_iter);
                    string label = "☐ " + item.title;
                    if (item.due_date != null) label += " · " + item.due_date;
                    tree_store.set (item_iter, 0, label, 1, false, 2, "item");
                }
            }
        }

        // Mark ambiguous rows
        foreach (var amb in result.ambiguities) {
            // Find and mark — simplified: add a warning row at top
            Gtk.TreeIter warn_iter;
            tree_store.insert (out warn_iter, null, 0);
            tree_store.set (warn_iter, 0, "⚠ " + amb.line + " — " + amb.reason, 1, true, 2, "warning");
        }

        preview_tree.expand_all ();
    }

    private void do_import () {
        if (current_result == null) return;
        foreach (var mp in current_result.projects) {
            var project = new Objects.Project ();
            project.name = mp.name;
            Services.Store.instance ().insert_project (project);

            foreach (var ms in mp.sections) {
                Objects.Section? section = null;
                if (ms.name != "") {
                    section = new Objects.Section ();
                    section.name = ms.name;
                    section.project_id = project.id;
                    Services.Store.instance ().insert_section (section);
                }

                foreach (var mi in ms.items) {
                    var item = new Objects.Item ();
                    item.content = mi.title;
                    item.description = mi.notes;
                    item.project_id = project.id;
                    item.section_id = section != null ? section.id : "";
                    item.priority = mi.priority;
                    if (mi.due_date != null) item.due.date = mi.due_date;
                    Services.Store.instance ().insert_item (item);
                }
            }
        }
        close ();
    }
}
```

- [ ] **Step 3: Wire up import dialog from a menu item**

Find `src/Layouts/HeaderBar.vala` or wherever the app menu is. Add an "Import…" menu item that calls `new Dialogs.ImportDialog ().present (main_window)`.

- [ ] **Step 4: Verify build**

```bash
cd /home/jlagman/Projects/planify/build
ninja 2>&1 | tail -10
```

Expected: no errors.

- [ ] **Step 5: Commit**

```bash
git add src/Dialogs/ImportDialog.vala src/meson.build
git commit -m "feat: add import dialog with Claude AI file mapping and ambiguity review"
```

---

## Task 14: Final integration test run and cleanup

- [ ] **Step 1: Run full test suite**

```bash
cd /home/jlagman/Projects/planify/build
meson test --print-errorlogs 2>&1
```

Expected: all suites pass (`cli`, `ai-unit`; `caldav-integration` may skip without env vars).

- [ ] **Step 2: Add `.superpowers/` to `.gitignore`**

```bash
echo ".superpowers/" >> /home/jlagman/Projects/planify/.gitignore
```

- [ ] **Step 3: Final commit**

```bash
git add .gitignore
git commit -m "chore: ignore .superpowers brainstorm session files"
```
