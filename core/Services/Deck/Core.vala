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
            GLib.TlsCertificate? client_cert = null;
            try {
                client_cert = source.caldav_data.load_client_certificate ();
            } catch (Error e) {
                Services.LogService.get_default ().error ("Deck.Core", "Failed to load client certificate: %s".printf (e.message));
            }

            var client = new Services.Deck.DeckClient (
                source.caldav_data.deck_base_url,
                source.caldav_data.username,
                source.caldav_data.password,
                client_cert
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

    /*
     * Offline support for cards
     *
     * Card writes go through save_card, move_card and delete_card. When the server
     * can't be reached, the change is applied locally and remembered in the Queue table,
     * then sent at the start of the next Deck sync, before reading the boards:
     *   - deck_card_put: upload the card with its state at that moment. Creates it if it
     *     has no card id yet, moves it if its stack changed, then updates it and its
     *     labels. Several offline edits become one upload.
     *   - deck_card_delete: delete the card. args keeps its Deck ids, as the task is gone.
     * Rows point at the Planify id of the task; the Deck ids are read when sending, so a
     * card created offline needs no temporary id.
     *
     * Limits: a create whose answer was lost (timeout) is sent again and makes a second
     * card. There is no conflict check: the local version overwrites the server one.
     */

    private const string PENDING_CARD_PUT = "deck_card_put";
    private const string PENDING_CARD_DELETE = "deck_card_delete";

    /*
     * Stacks work the same way, through save_stack and delete_stack:
     *   - deck_stack_put: create the stack if it has no stack id yet, otherwise update
     *     its title and order.
     *   - deck_stack_delete: delete the stack. args keeps its Deck ids. The deletes of
     *     its cards are queued before it.
     * Stack uploads are sent before the rest, so a card created offline in a new stack
     * has a stack id to go to. A card whose stack still has no id stays in the queue.
     *
     * Moving an existing card to another board offline queues a create on the target
     * board (deck_card_put with no card id) and a delete of the old card.
     */
    private const string PENDING_STACK_PUT = "deck_stack_put";
    private const string PENDING_STACK_DELETE = "deck_stack_delete";

    private Gee.HashSet<string> pending_card_item_ids = new Gee.HashSet<string> ();
    private Gee.HashSet<int> pending_deleted_card_ids = new Gee.HashSet<int> ();
    private Gee.HashSet<string> pending_stack_section_ids = new Gee.HashSet<string> ();
    private Gee.HashSet<int> pending_deleted_stack_ids = new Gee.HashSet<int> ();

    private enum FlushResult {
        SENT,
        WAIT,
        OFFLINE
    }

    private static int stack_id_of_section (Objects.Section section) {
        return (int) Utils.JsonUtils.get_int (section.extra_data, "deck_stack_id");
    }

    private static int board_id_of_section (Objects.Section section) {
        return (int) Utils.JsonUtils.get_int (section.project.extra_data, "deck_board_id");
    }

    private static int card_id_of (Objects.Item item) {
        return (int) Utils.JsonUtils.get_int (item.extra_data, "deck_card_id");
    }

    private static int stack_id_of (Objects.Item item) {
        return (int) Utils.JsonUtils.get_int (item.extra_data, "deck_stack_id");
    }

    private static int board_id_of (Objects.Item item) {
        return (int) Utils.JsonUtils.get_int (item.project.extra_data, "deck_board_id");
    }

    private static int target_stack_id_of (Objects.Item item) {
        if (item.section_id != "" && item.section != null) {
            return (int) Utils.JsonUtils.get_int (item.section.extra_data, "deck_stack_id");
        }

        return stack_id_of (item);
    }

    private static string? duedate_of (Objects.Item item) {
        if (!item.has_due) return null;
        if (item.has_time) {
            return item.due.datetime.to_utc ().format ("%FT%T");
        }

        return item.due.datetime.format ("%FT12:00:00");
    }

    private static string? done_of (Objects.Item item) {
        if (!item.checked) return null;

        GLib.DateTime? completed = null;
        if (item.completed_at != "") {
            completed = new GLib.DateTime.from_iso8601 (item.completed_at, new GLib.TimeZone.local ());
        }

        return (completed ?? new GLib.DateTime.now_local ()).to_utc ().format_iso8601 ();
    }

    private void add_pending_row (string kind, Objects.Item item, string args) {
        var queue = new Objects.Queue ();
        queue.uuid = "%s-%s".printf (kind, item.id);
        queue.object_id = item.id;
        queue.query = kind;
        queue.args = args;
        queue.source_id = item.project.source_id;

        Services.Database.get_default ().insert_queue (queue);
        Services.LogService.get_default ().info ("Deck.Core", "Offline, %s kept for later: '%s'".printf (kind, item.content));
    }

    private void queue_card_put (Objects.Item item) {
        add_pending_row (PENDING_CARD_PUT, item, "");
        pending_card_item_ids.add (item.id);
    }

    private void forget_card_put (Objects.Item item) {
        Services.Database.get_default ().remove_queue ("%s-%s".printf (PENDING_CARD_PUT, item.id));
        pending_card_item_ids.remove (item.id);
    }

    private void queue_card_delete (Objects.Item item) {
        forget_card_put (item);

        int card_id = card_id_of (item);
        if (card_id <= 0) {
            return;
        }

        queue_card_delete_ids (item, (int) Utils.JsonUtils.get_int (item.extra_data, "deck_board_id"), stack_id_of (item), card_id);
    }

    private void queue_card_delete_ids (Objects.Item item, int board_id, int stack_id, int card_id) {
        add_pending_row (PENDING_CARD_DELETE, item, build_card_extra_data (card_id, stack_id, board_id, ""));
        pending_deleted_card_ids.add (card_id);
    }

    private void add_stack_row (string kind, Objects.Section section, string args) {
        var queue = new Objects.Queue ();
        queue.uuid = "%s-%s".printf (kind, section.id);
        queue.object_id = section.id;
        queue.query = kind;
        queue.args = args;
        queue.source_id = section.project.source_id;

        Services.Database.get_default ().insert_queue (queue);
        Services.LogService.get_default ().info ("Deck.Core", "Offline, %s kept for later: '%s'".printf (kind, section.name));
    }

    private void queue_stack_put (Objects.Section section) {
        add_stack_row (PENDING_STACK_PUT, section, "");
        pending_stack_section_ids.add (section.id);
    }

    private void forget_stack_put (Objects.Section section) {
        Services.Database.get_default ().remove_queue ("%s-%s".printf (PENDING_STACK_PUT, section.id));
        pending_stack_section_ids.remove (section.id);
    }

    private void queue_stack_delete (Objects.Section section) {
        forget_stack_put (section);

        int stack_id = stack_id_of_section (section);
        if (stack_id <= 0) {
            return;
        }

        add_stack_row (PENDING_STACK_DELETE, section, build_stack_extra_data (stack_id, board_id_of_section (section), ""));
        pending_deleted_stack_ids.add (stack_id);
    }

    private void reload_pending (Objects.Source source) {
        pending_card_item_ids.clear ();
        pending_deleted_card_ids.clear ();
        pending_stack_section_ids.clear ();
        pending_deleted_stack_ids.clear ();

        foreach (Objects.Queue q in Services.Database.get_default ().get_all_queue (source.id)) {
            if (q.query == PENDING_CARD_PUT) {
                pending_card_item_ids.add (q.object_id);
            } else if (q.query == PENDING_CARD_DELETE) {
                pending_deleted_card_ids.add ((int) Utils.JsonUtils.get_int (q.args, "deck_card_id"));
            } else if (q.query == PENDING_STACK_PUT) {
                pending_stack_section_ids.add (q.object_id);
            } else if (q.query == PENDING_STACK_DELETE) {
                pending_deleted_stack_ids.add ((int) Utils.JsonUtils.get_int (q.args, "deck_stack_id"));
            }
        }
    }

    public async HttpResponse save_stack (Objects.Section section) {
        var client = get_client (section.project.source);
        int board_id = board_id_of_section (section);
        int stack_id = stack_id_of_section (section);

        try {
            if (stack_id <= 0) {
                var stack = yield client.create_stack (board_id, section.name, section.section_order);
                stack_id = (int) stack.get_int_member ("id");
                string etag = stack.has_member ("ETag") ? stack.get_string_member ("ETag") : "";
                section.extra_data = build_stack_extra_data (stack_id, board_id, etag);
            } else {
                yield client.update_stack (board_id, stack_id, section.name, section.section_order);
            }

            forget_stack_put (section);
            return new HttpResponse () { status = true };
        } catch (Error e) {
            if (Services.CalDAV.CalDAVClient.is_offline_error (e)) {
                if (stack_id <= 0) {
                    section.extra_data = build_stack_extra_data (0, board_id, "");
                }

                queue_stack_put (section);
                return new HttpResponse () { status = true, offline = true };
            }

            Services.LogService.get_default ().error ("Deck.Core", "Failed to save stack: %s".printf (e.message));
            return error_response (e);
        }
    }

    public async HttpResponse delete_stack (Objects.Section section) {
        foreach (Objects.Item item in Services.Store.instance ().get_items_by_project (section.project)) {
            if (item.section_id == section.id) {
                yield delete_card (item);
            }
        }

        int stack_id = stack_id_of_section (section);
        if (stack_id <= 0) {
            queue_stack_delete (section);
            return new HttpResponse () { status = true };
        }

        var client = get_client (section.project.source);
        try {
            yield client.delete_stack (board_id_of_section (section), stack_id);
            forget_stack_put (section);
            return new HttpResponse () { status = true };
        } catch (Error e) {
            if (Services.CalDAV.CalDAVClient.is_offline_error (e)) {
                queue_stack_delete (section);
                return new HttpResponse () { status = true, offline = true };
            }

            Services.LogService.get_default ().error ("Deck.Core", "Failed to delete stack: %s".printf (e.message));
            return error_response (e);
        }
    }

    private async void upload_card (Objects.Item item) throws GLib.Error {
        var client = get_client (item.project.source);
        int board_id = board_id_of (item);
        int stack_id = target_stack_id_of (item);
        int card_id = card_id_of (item);
        string etag = Utils.JsonUtils.get_string (item.extra_data, "deck_etag");

        if (card_id <= 0) {
            var card = yield client.create_card (board_id, stack_id, item.content, item.description, duedate_of (item), item.child_order);
            card_id = (int) card.get_int_member ("id");
            etag = card.has_member ("ETag") ? card.get_string_member ("ETag") : "";
            item.extra_data = build_card_extra_data (card_id, stack_id, board_id, etag);

            if (!item.checked && item.labels.size <= 0) {
                return;
            }
        } else if (stack_id != stack_id_of (item)) {
            yield client.move_card (board_id, stack_id_of (item), card_id, stack_id, item.child_order);
            item.extra_data = build_card_extra_data (card_id, stack_id, board_id, etag);
        }

        yield client.update_card (board_id, stack_id, card_id, item.content, item.description, duedate_of (item), done_of (item), item.child_order);
        yield client.set_card_done (card_id, item.checked);
        yield sync_card_labels (client, item);
    }

    private HttpResponse error_response (GLib.Error e) {
        var response = new HttpResponse ();
        response.error = e.message;
        return response;
    }

    public async HttpResponse save_card (Objects.Item item) {
        if (target_stack_id_of (item) <= 0) {
            queue_card_put (item);
            return new HttpResponse () { status = true, offline = true };
        }

        try {
            yield upload_card (item);
            forget_card_put (item);
            return new HttpResponse () { status = true };
        } catch (Error e) {
            if (Services.CalDAV.CalDAVClient.is_offline_error (e)) {
                queue_card_put (item);
                return new HttpResponse () { status = true, offline = true };
            }

            Services.LogService.get_default ().error ("Deck.Core", "Failed to save card: %s".printf (e.message));
            return error_response (e);
        }
    }

    public async HttpResponse move_card (Objects.Item item) {
        int card_id = card_id_of (item);
        int target_stack_id = target_stack_id_of (item);

        if (card_id <= 0 || item.id in pending_card_item_ids || target_stack_id <= 0) {
            return yield save_card (item);
        }

        if (target_stack_id == stack_id_of (item)) {
            return new HttpResponse () { status = true };
        }

        var client = get_client (item.project.source);
        try {
            yield client.move_card (board_id_of (item), stack_id_of (item), card_id, target_stack_id, item.child_order);
            item.extra_data = Utils.JsonUtils.set_int (item.extra_data, "deck_stack_id", target_stack_id);
            return new HttpResponse () { status = true };
        } catch (Error e) {
            if (Services.CalDAV.CalDAVClient.is_offline_error (e)) {
                queue_card_put (item);
                return new HttpResponse () { status = true, offline = true };
            }

            Services.LogService.get_default ().error ("Deck.Core", "Failed to move card: %s".printf (e.message));
            return error_response (e);
        }
    }

    public async HttpResponse delete_card (Objects.Item item) {
        int card_id = card_id_of (item);
        if (card_id <= 0) {
            queue_card_delete (item);
            return new HttpResponse () { status = true };
        }

        var client = get_client (item.project.source);
        try {
            yield client.delete_card ((int) Utils.JsonUtils.get_int (item.extra_data, "deck_board_id"), stack_id_of (item), card_id);
            forget_card_put (item);
            return new HttpResponse () { status = true };
        } catch (Error e) {
            if (Services.CalDAV.CalDAVClient.is_offline_error (e)) {
                queue_card_delete (item);
                return new HttpResponse () { status = true, offline = true };
            }

            Services.LogService.get_default ().error ("Deck.Core", "Failed to delete card: %s".printf (e.message));
            return error_response (e);
        }
    }

    public async HttpResponse move_card_to_board (Objects.Item item, Objects.Project target_project, string target_section_id) {
        int old_board_id = (int) Utils.JsonUtils.get_int (item.extra_data, "deck_board_id");
        int old_stack_id = stack_id_of (item);
        int old_card_id = card_id_of (item);
        string old_project_id = item.project_id;
        string old_section_id = item.section_id;
        string old_extra_data = item.extra_data;

        int new_board_id = (int) Utils.JsonUtils.get_int (target_project.extra_data, "deck_board_id");
        int new_stack_id = 0;
        if (target_section_id != "") {
            var target_section = Services.Store.instance ().get_section (target_section_id);
            if (target_section != null) {
                new_stack_id = stack_id_of_section (target_section);
            }
        } else {
            var sections = Services.Store.instance ().get_sections_by_project (target_project);
            if (sections.size > 0) {
                new_stack_id = stack_id_of_section (sections[0]);
                target_section_id = sections[0].id;
            }
        }

        item.project_id = target_project.id;
        item.section_id = target_section_id;
        item.extra_data = build_card_extra_data (0, new_stack_id, new_board_id, "");
        forget_card_put (item);

        var response = yield save_card (item);
        if (!response.status) {
            item.project_id = old_project_id;
            item.section_id = old_section_id;
            item.extra_data = old_extra_data;
            return response;
        }

        if (old_card_id <= 0) {
            return response;
        }

        if (response.offline) {
            queue_card_delete_ids (item, old_board_id, old_stack_id, old_card_id);
            return response;
        }

        var client = get_client (target_project.source);
        try {
            yield client.delete_card (old_board_id, old_stack_id, old_card_id);
        } catch (Error e) {
            if (Services.CalDAV.CalDAVClient.is_offline_error (e)) {
                queue_card_delete_ids (item, old_board_id, old_stack_id, old_card_id);
            } else {
                Services.LogService.get_default ().error ("Deck.Core", "Failed to delete the old card after moving it: %s".printf (e.message));
            }
        }

        return response;
    }

    private async void flush_pending (Objects.Source source) {
        reload_pending (source);

        var stack_puts = new Gee.ArrayList<Objects.Queue> ();
        var others = new Gee.ArrayList<Objects.Queue> ();
        foreach (Objects.Queue q in Services.Database.get_default ().get_all_queue (source.id)) {
            if (q.query == PENDING_STACK_PUT) {
                stack_puts.add (q);
            } else if (q.query == PENDING_CARD_PUT || q.query == PENDING_CARD_DELETE || q.query == PENDING_STACK_DELETE) {
                others.add (q);
            }
        }

        var pending = new Gee.ArrayList<Objects.Queue> ();
        pending.add_all (stack_puts);
        pending.add_all (others);

        if (pending.size <= 0) {
            return;
        }

        Services.LogService.get_default ().info ("Deck.Core", "Sending %d changes made offline".printf (pending.size));

        foreach (Objects.Queue q in pending) {
            var result = yield flush_pending_row (q, source);
            if (result == FlushResult.OFFLINE) {
                Services.LogService.get_default ().warn ("Deck.Core", "Server still unreachable, keeping the remaining offline changes");
                break;
            }

            if (result == FlushResult.SENT) {
                Services.Database.get_default ().remove_queue (q.uuid);
            }
        }

        reload_pending (source);
    }

    private async FlushResult flush_pending_row (Objects.Queue q, Objects.Source source) {
        var client = get_client (source);

        if (q.query == PENDING_CARD_DELETE || q.query == PENDING_STACK_DELETE) {
            int board_id = (int) Utils.JsonUtils.get_int (q.args, "deck_board_id");
            int stack_id = (int) Utils.JsonUtils.get_int (q.args, "deck_stack_id");
            try {
                if (q.query == PENDING_CARD_DELETE) {
                    yield client.delete_card (board_id, stack_id, (int) Utils.JsonUtils.get_int (q.args, "deck_card_id"));
                } else {
                    yield client.delete_stack (board_id, stack_id);
                }
            } catch (Error e) {
                if (Services.CalDAV.CalDAVClient.is_offline_error (e)) {
                    return FlushResult.OFFLINE;
                }

                Services.LogService.get_default ().warn ("Deck.Core", "Offline %s failed, dropping it: %s".printf (q.query, e.message));
            }

            return FlushResult.SENT;
        }

        if (q.query == PENDING_STACK_PUT) {
            Objects.Section? section = Services.Store.instance ().get_section (q.object_id);
            if (section == null || section.project == null || !section.project.is_deck) {
                return FlushResult.SENT;
            }

            var response = yield save_stack (section);
            if (response.offline) {
                return FlushResult.OFFLINE;
            }

            if (response.status) {
                Services.Store.instance ().update_section (section);
            } else {
                Services.LogService.get_default ().warn ("Deck.Core", "Offline stack upload failed for '%s', dropping it: %s".printf (section.name, response.error));
            }

            return FlushResult.SENT;
        }

        Objects.Item? item = Services.Store.instance ().get_item (q.object_id);
        if (item == null || item.project == null || !item.project.is_deck) {
            return FlushResult.SENT;
        }

        if (target_stack_id_of (item) <= 0) {
            Services.LogService.get_default ().warn ("Deck.Core", "Card '%s' waits for its stack to be uploaded".printf (item.content));
            return FlushResult.WAIT;
        }

        try {
            yield upload_card (item);
            Services.Store.instance ().update_item (item);
        } catch (Error e) {
            if (Services.CalDAV.CalDAVClient.is_offline_error (e)) {
                return FlushResult.OFFLINE;
            }

            Services.LogService.get_default ().warn ("Deck.Core", "Offline card upload failed for '%s', dropping it: %s".printf (item.content, e.message));
        }

        return FlushResult.SENT;
    }

    public async void sync_card_labels (Services.Deck.DeckClient deck_client, Objects.Item item) throws Error {
        int board_id = (int) Utils.JsonUtils.get_int (item.extra_data, "deck_board_id");
        int stack_id = stack_id_of (item);
        int card_id = card_id_of (item);

        var board_labels = yield deck_client.get_board_labels (board_id);

        var board_label_map = new Gee.HashMap<string, int> ();
        board_labels.foreach_element ((a, i, node) => {
            var obj = node.get_object ();
            board_label_map[obj.get_string_member ("title")] = (int) obj.get_int_member ("id");
        });

        var stacks = yield deck_client.get_stacks (board_id, null);
        var current_card_label_ids = new Gee.HashSet<int> ();
        stacks.foreach_element ((a, i, stack_node) => {
            var stack_obj = stack_node.get_object ();
            if ((int) stack_obj.get_int_member ("id") != stack_id) return;
            if (!stack_obj.has_member ("cards") || stack_obj.get_null_member ("cards")) return;
            stack_obj.get_array_member ("cards").foreach_element ((b, j, card_node) => {
                var card_obj = card_node.get_object ();
                if ((int) card_obj.get_int_member ("id") != card_id) return;
                if (card_obj.has_member ("labels") && !card_obj.get_null_member ("labels")) {
                    card_obj.get_array_member ("labels").foreach_element ((c, k, lbl_node) => {
                        current_card_label_ids.add ((int) lbl_node.get_object ().get_int_member ("id"));
                    });
                }
            });
        });

        var desired_label_ids = new Gee.HashSet<int> ();
        foreach (var label in item.labels) {
            int deck_label_id = 0;
            if (board_label_map.has_key (label.name)) {
                deck_label_id = board_label_map[label.name];
            } else {
                string hex_color = Util.get_default ().get_color (label.color);
                var created = yield deck_client.create_label (board_id, label.name, hex_color);
                deck_label_id = (int) created.get_int_member ("id");
            }
            desired_label_ids.add (deck_label_id);
        }

        foreach (var lid in desired_label_ids) {
            if (!current_card_label_ids.contains (lid)) {
                yield deck_client.assign_label_to_card (board_id, stack_id, card_id, lid);
            }
        }

        foreach (var lid in current_card_label_ids) {
            if (!desired_label_ids.contains (lid)) {
                yield deck_client.remove_label_from_card (board_id, stack_id, card_id, lid);
            }
        }
    }

    public async void sync (Objects.Source source) {
        if (!source.caldav_data.use_deck) return;

        Services.LogService.get_default ().info ("Deck.Core", "Starting Deck sync");

        var client = get_client (source);

        yield flush_pending (source);

        try {
            var boards = yield client.get_boards ();

            var boards_to_sync = new Gee.HashMap<Objects.Project, int> ();

            boards.foreach_element ((array, index, node) => {
                var board = node.get_object ();
                if (board.get_int_member ("deletedAt") > 0) return;

                int board_id = (int) board.get_int_member ("id");
                string board_etag = board.get_string_member ("ETag");
                string title = board.get_string_member ("title");
                string color = "#%s".printf (board.get_string_member ("color"));
                bool board_archived = board.get_boolean_member ("archived");

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

                boards_to_sync[project] = board_id;
            });

            foreach (var entry in boards_to_sync.entries) {
                yield sync_stacks (client, source, entry.key, entry.value);
            }

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
                server_stack_ids.add (stack_id);

                if (stack_id in pending_deleted_stack_ids) {
                    return;
                }

                string stack_etag = stack.get_string_member ("ETag");
                string stack_title = stack.get_string_member ("title");
                int stack_order = (int) stack.get_int_member ("order");

                Objects.Section? section = get_section_by_stack_id (project, stack_id);

                if (section != null && section.id in pending_stack_section_ids) {
                    Services.LogService.get_default ().debug ("Deck.Core", "Keeping stack '%s', it has offline changes not sent yet".printf (section.name));
                } else if (section == null) {
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
                    // A card moved here offline is still in its old stack on the server.
                    if (local_item.id in pending_card_item_ids) continue;
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

        if (card_id in pending_deleted_card_ids) {
            return;
        }

        string card_etag = card.get_string_member ("ETag");
        string card_title = card.get_string_member ("title");
        string card_description = card.has_member ("description") && !card.get_null_member ("description")
            ? card.get_string_member ("description") : "";
        bool card_done = card.has_member ("done") && !card.get_null_member ("done");

        string? duedate_str = card.has_member ("duedate") && !card.get_null_member ("duedate")
            ? card.get_string_member ("duedate") : null;
        string? parsed_duedate = parse_deck_duedate (duedate_str);

        Objects.Item? item = get_item_by_card_id (project, card_id);

        // Changed offline and not sent yet: the local version wins.
        if (item != null && item.id in pending_card_item_ids) {
            Services.LogService.get_default ().debug ("Deck.Core", "Skipping card '%s', it has offline changes not sent yet".printf (item.content));
            return;
        }

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
