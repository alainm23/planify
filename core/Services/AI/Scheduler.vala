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
                s.item_id = obj.has_member ("id") ? obj.get_string_member ("id") : "";
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
