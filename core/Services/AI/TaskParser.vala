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
