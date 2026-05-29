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
