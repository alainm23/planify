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
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA
 *
 * Authored by: Alain M. <alainmh23@gmail.com>
 */

public class Services.Deck.Core : GLib.Object {

    private Gee.HashMap<string, Services.Deck.DeckClient> clients;

    private static Core? _instance;
    public static Core get_default () {
        if (_instance == null) {
            _instance = new Core ();
        }
        return _instance;
    }

    public Core () {
        clients = new Gee.HashMap<string, Services.Deck.DeckClient> ();
    }

    public Services.Deck.DeckClient get_client (Objects.Source source) {
        if (!clients.has_key (source.id)) {
            var client = new Services.Deck.DeckClient (
                source.caldav_data.deck_base_url,
                source.caldav_data.username,
                source.caldav_data.password
            );
            clients[source.id] = client;
        }
        return clients[source.id];
    }

    public void remove_client (string source_id) {
        clients.unset (source_id);
    }

    // Probe — check if Deck is installed on this Nextcloud instance
    public async bool probe (Objects.Source source) {
        Services.LogService.get_default ().info ("Deck.Core", "Probing Deck API");
        var client = get_client (source);
        return yield client.probe ();
    }

    public async void sync (Objects.Source source) {
        if (!source.caldav_data.use_deck) return;

        Services.LogService.get_default ().info ("Deck.Core", "Starting Deck sync");

        var client = get_client (source);

        try {
            var boards = yield client.get_boards ();

            boards.foreach_element ((array, index, node) => {
                var board = node.get_object ();
                if (board.get_int_member ("deletedAt") > 0) return;

                int board_id = (int) board.get_int_member ("id");
                string board_etag = board.get_string_member ("ETag");
                string title = board.get_string_member ("title");
                string color = "#%s".printf (board.get_string_member ("color"));
                bool board_archived = board.get_boolean_member ("archived");

                // Find or create project
                Objects.Project? project = get_project_by_board_id (source, board_id);

                if (project == null) {
                    project = new Objects.Project ();
                    project.id = Util.get_default ().generate_id (project);
                    project.source_id = source.id;
                    project.name = title;
                    project.color = color;
                    project.is_archived = board_archived;
                    project.extra_data = build_board_extra_data (board_id, board_etag);
                    Services.Store.instance ().insert_project (project);
                    Services.LogService.get_default ().debug ("Deck.Core", "Inserted board: %s".printf (title));
                } else {
                    bool was_archived = project.is_archived;
                    project.name = title;
                    project.color = color;
                    project.is_archived = board_archived;
                    project.extra_data = build_board_extra_data (board_id, board_etag);
                    Services.Store.instance ().update_project (project);

                    if (was_archived != board_archived) {
                        Services.Store.instance ().archive_project (project);
                    }
                }

                // Sync stacks for this board
                sync_stacks.begin (client, source, project, board_id);
            });

            // Delete local projects whose boards no longer exist on server
            var server_board_ids = new Gee.HashSet<int> ();
            boards.foreach_element ((array, index, node) => {
                if (node.get_object ().get_int_member ("deletedAt") == 0) {
                    server_board_ids.add ((int) node.get_object ().get_int_member ("id"));
                }
            });
            foreach (var local_project in Services.Store.instance ().get_projects_by_source (source.id)) {
                int local_board_id = (int) Utils.JsonUtils.get_int (local_project.extra_data, "deck_board_id");
                if (local_board_id > 0 && !server_board_ids.contains (local_board_id)) {
                    Services.Store.instance ().delete_project (local_project);
                }
            }

            // Update last sync timestamp (must be in English IMF-fixdate format)
            source.caldav_data.deck_last_sync = new GLib.DateTime.now_utc ().format_iso8601 ();
            Services.Store.instance ().update_source (source);

            Services.LogService.get_default ().info ("Deck.Core", "Deck sync completed");
        } catch (Error e) {
            Services.LogService.get_default ().error ("Deck.Core", "Sync failed: %s".printf (e.message));
        }
    }

    private async void sync_stacks (Services.Deck.DeckClient client, Objects.Source source, Objects.Project project, int board_id) {
        try {
            var stacks = yield client.get_stacks (board_id, null);

            var server_stack_ids = new Gee.HashSet<int> ();

            stacks.foreach_element ((array, index, node) => {
                var stack = node.get_object ();
                if (stack.get_int_member ("deletedAt") > 0) return;

                int stack_id = (int) stack.get_int_member ("id");
                string stack_etag = stack.get_string_member ("ETag");
                string stack_title = stack.get_string_member ("title");
                int stack_order = (int) stack.get_int_member ("order");
                server_stack_ids.add (stack_id);

                Objects.Section? section = get_section_by_stack_id (project, stack_id);

                if (section == null) {
                    section = new Objects.Section ();
                    section.id = Util.get_default ().generate_id (section);
                    section.project_id = project.id;
                    section.name = stack_title;
                    section.section_order = stack_order;
                    section.extra_data = build_stack_extra_data (stack_id, board_id, stack_etag);
                    Services.Store.instance ().insert_section (section);
                } else {
                    section.name = stack_title;
                    section.section_order = stack_order;
                    section.extra_data = build_stack_extra_data (stack_id, board_id, stack_etag);
                    Services.Store.instance ().update_section (section);
                }

                // Sync cards
                var server_card_ids = new Gee.HashSet<int> ();
                if (stack.has_member ("cards") && !stack.get_null_member ("cards")) {
                    stack.get_array_member ("cards").foreach_element ((a, i, card_node) => {
                        var card_obj = card_node.get_object ();
                        if (card_obj.get_int_member ("deletedAt") == 0) {
                            server_card_ids.add ((int) card_obj.get_int_member ("id"));
                        }
                        upsert_card (source, project, section, board_id, stack_id, card_obj);
                    });
                }

                // Delete local items whose cards no longer exist on server
                foreach (var local_item in Services.Store.instance ().get_items_by_project (project)) {
                    if (local_item.section_id != section.id) continue;
                    int local_card_id = (int) Utils.JsonUtils.get_int (local_item.extra_data, "deck_card_id");
                    if (local_card_id > 0 && !server_card_ids.contains (local_card_id)) {
                        Services.Store.instance ().delete_item (local_item);
                    }
                }
            });

            // Delete local sections no longer on server
            foreach (var local_section in Services.Store.instance ().get_sections_by_project (project)) {
                int local_stack_id = (int) Utils.JsonUtils.get_int (local_section.extra_data, "deck_stack_id");
                if (local_stack_id > 0 && !server_stack_ids.contains (local_stack_id)) {
                    Services.Store.instance ().delete_section (local_section);
                }
            }
        } catch (Error e) {
            Services.LogService.get_default ().error ("Deck.Core", "Sync stacks failed: %s".printf (e.message));
        }
    }

    private void upsert_card (Objects.Source source, Objects.Project project, Objects.Section section, int board_id, int stack_id, Json.Object card) {
        if (card.get_int_member ("deletedAt") > 0) return;

        int card_id = (int) card.get_int_member ("id");
        string card_etag = card.get_string_member ("ETag");
        string card_title = card.get_string_member ("title");
        string card_description = card.has_member ("description") && !card.get_null_member ("description")
            ? card.get_string_member ("description") : "";
        bool card_done = card.has_member ("done") && !card.get_null_member ("done");

        string? duedate_str = card.has_member ("duedate") && !card.get_null_member ("duedate")
            ? card.get_string_member ("duedate") : null;
        string? parsed_duedate = parse_deck_duedate (duedate_str);

        Objects.Item? item = get_item_by_card_id (project, card_id);

        if (item == null) {
            item = new Objects.Item ();
            item.id = Util.get_default ().generate_id (item);
            item.project_id = project.id;
            item.section_id = section.id;
            item.content = card_title;
            item.description = card_description;
            item.extra_data = build_card_extra_data (card_id, stack_id, board_id, card_etag);

            if (parsed_duedate != null) {
                item.due.date = parsed_duedate;
            }

            if (card_done) {
                item.checked = true;
                item.completed_at = new GLib.DateTime.now_local ().to_string ();
            }

            // Labels
            var card_labels = get_card_labels (source, card);
            item.labels = card_labels;

            Services.Store.instance ().insert_item (item, true);
        } else {
            item.content = card_title;
            item.description = card_description;
            item.section_id = section.id;
            item.extra_data = build_card_extra_data (card_id, stack_id, board_id, card_etag);

            if (parsed_duedate != null) {
                item.due.date = parsed_duedate;
            } else {
                item.due.reset ();
            }

            bool old_checked = item.checked;
            item.checked = card_done;
            if (item.checked) {
                item.completed_at = new GLib.DateTime.now_local ().to_string ();
            } else {
                item.completed_at = "";
            }

            // Detect section change (card moved between stacks)
            string old_section_id = item.section_id;
            if (old_section_id != section.id) {
                item.section_id = section.id;
                item.extra_data = build_card_extra_data (card_id, stack_id, board_id, card_etag);
                Services.Store.instance ().move_item (item, project.id, old_section_id, "");
                Services.EventBus.get_default ().item_moved (item, project.id, old_section_id, "");
            } else {
                item.extra_data = build_card_extra_data (card_id, stack_id, board_id, card_etag);
                Services.Store.instance ().update_item (item);
            }

            // Labels
            var card_labels = get_card_labels (source, card);
            var labels_map = new Gee.HashMap<string, Objects.Label> ();
            foreach (var l in card_labels) { labels_map[l.id] = l; }
            item.check_labels (labels_map);

            if (old_checked != item.checked) {
                Services.Store.instance ().complete_item (item, old_checked);
            }
        }
    }

    // Helpers to find objects by Deck IDs
    public Objects.Project? get_project_by_board_id (Objects.Source source, int board_id) {
        foreach (var project in Services.Store.instance ().get_projects_by_source (source.id)) {
            if ((int) Utils.JsonUtils.get_int (project.extra_data, "deck_board_id") == board_id) {
                return project;
            }
        }
        return null;
    }

    public Objects.Section? get_section_by_stack_id (Objects.Project project, int stack_id) {
        foreach (var section in Services.Store.instance ().get_sections_by_project (project)) {
            if ((int) Utils.JsonUtils.get_int (section.extra_data, "deck_stack_id") == stack_id) {
                return section;
            }
        }
        return null;
    }

    public Objects.Item? get_item_by_card_id (Objects.Project project, int card_id) {
        foreach (var item in Services.Store.instance ().get_items_by_project (project)) {
            if ((int) Utils.JsonUtils.get_int (item.extra_data, "deck_card_id") == card_id) {
                return item;
            }
        }
        return null;
    }

    private Gee.ArrayList<Objects.Label> get_card_labels (Objects.Source source, Json.Object card) {
        var result = new Gee.ArrayList<Objects.Label> ();
        if (!card.has_member ("labels") || card.get_null_member ("labels")) return result;

        card.get_array_member ("labels").foreach_element ((a, i, label_node) => {
            var label_obj = label_node.get_object ();
            string label_title = label_obj.get_string_member ("title");
            string label_color = "#%s".printf (label_obj.get_string_member ("color"));
            var label = find_or_create_label (source, label_title, label_color);
            result.add (label);
        });

        return result;
    }

    private Objects.Label find_or_create_label (Objects.Source source, string name, string color) {
        foreach (var label in Services.Store.instance ().get_labels_by_source (source.id)) {
            if (label.name == name) return label;
        }

        var label = new Objects.Label ();
        label.id = Util.get_default ().generate_id (label);
        label.name = name;
        label.color = color;
        label.backend_type = SourceType.CALDAV;
        label.source_id = source.id;
        Services.Store.instance ().insert_label (label);
        return label;
    }

    // extra_data builders
    public static string build_board_extra_data (int board_id, string etag) {
        var builder = new Json.Builder ();
        builder.begin_object ();
        builder.set_member_name ("deck_board_id"); builder.add_int_value (board_id);
        builder.set_member_name ("deck_etag"); builder.add_string_value (etag);
        builder.end_object ();
        var gen = new Json.Generator ();
        gen.set_root (builder.get_root ());
        return gen.to_data (null);
    }

    public static string build_stack_extra_data (int stack_id, int board_id, string etag) {
        var builder = new Json.Builder ();
        builder.begin_object ();
        builder.set_member_name ("deck_stack_id"); builder.add_int_value (stack_id);
        builder.set_member_name ("deck_board_id"); builder.add_int_value (board_id);
        builder.set_member_name ("deck_etag"); builder.add_string_value (etag);
        builder.end_object ();
        var gen = new Json.Generator ();
        gen.set_root (builder.get_root ());
        return gen.to_data (null);
    }

    public static string build_card_extra_data (int card_id, int stack_id, int board_id, string etag) {
        var builder = new Json.Builder ();
        builder.begin_object ();
        builder.set_member_name ("deck_card_id"); builder.add_int_value (card_id);
        builder.set_member_name ("deck_stack_id"); builder.add_int_value (stack_id);
        builder.set_member_name ("deck_board_id"); builder.add_int_value (board_id);
        builder.set_member_name ("deck_etag"); builder.add_string_value (etag);
        builder.end_object ();
        var gen = new Json.Generator ();
        gen.set_root (builder.get_root ());
        return gen.to_data (null);
    }

    // Converts Deck duedate (UTC) to Planify format.
    // If time is 12:00:00 UTC (our date-only marker), returns just the date.
    // Otherwise converts UTC to local time.
    public static string? parse_deck_duedate (string? duedate_str) {
        if (duedate_str == null || duedate_str == "") return null;

        // Deck format: "2026-07-14T12:00:00+00:00"
        var parts = duedate_str.split ("T");
        if (parts.length < 2) return duedate_str;

        string date_part = parts[0]; // "2026-07-14"
        string time_part = parts[1]; // "12:00:00+00:00"

        // Strip timezone suffix to get raw time
        string raw_time = time_part.split ("+")[0].split ("Z")[0]; // "12:00:00"

        if (raw_time == "12:00:00") {
            // Date-only marker: return just the date
            return date_part;
        }

        // Has real time: convert UTC to local
        var date_parts = date_part.split ("-");
        var time_parts = raw_time.split (":");
        var utc_dt = new GLib.DateTime.utc (
            int.parse (date_parts[0]),
            int.parse (date_parts[1]),
            int.parse (date_parts[2]),
            int.parse (time_parts[0]),
            int.parse (time_parts[1]),
            int.parse (time_parts[2])
        );
        var local_dt = utc_dt.to_local ();
        return local_dt.format ("%FT%T");
    }
}
