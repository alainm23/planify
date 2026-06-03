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
            "Priority scale: 4=urgent, 3=high, 2=medium, 1=none.\n" +
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
            "\"suggested_priority\": 4, \"reason\": \"brief reason\"}]\n" +
            "Priority scale: 4=urgent, 3=high, 2=medium, 1=none.\n" +
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
            "Priority scale: 4=urgent, 3=high, 2=medium, 1=none.\n" +
            "File content:\n" + content
        );
    }
}
