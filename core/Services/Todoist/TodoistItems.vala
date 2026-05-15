/*
 * Copyright © 2023 Alain M. (https://github.com/alainm23/planify)
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

public class Services.TodoistItems : GLib.Object {
    private Soup.Session session;

    private const string TODOIST_SYNC_URL = "https://api.todoist.com/api/v1/sync";
    private const string MIGRATE_MESSAGE = _ ("Todoist has updated their API. Please reconnect your account in Preferences to continue syncing.");

    public TodoistItems (Soup.Session session) {
        this.session = session;
    }

    public async HttpResponse add (Objects.BaseObject object) {
        HttpResponse response = new HttpResponse ();

        if (object.source.needs_migration ()) {
            response.status = false;
            response.error = MIGRATE_MESSAGE;
            response.error_code = 410;
            return response;
        }

        string temp_id = Util.get_default ().generate_string ();
        string uuid = Util.get_default ().generate_string ();
        string id;
        string json = object.get_add_json (temp_id, uuid);

        var message = new Soup.Message ("POST", TODOIST_SYNC_URL);
        message.request_headers.append ("Authorization", "Bearer %s".printf (object.source.todoist_data.access_token));
        message.set_request_body_from_bytes ("application/json", new Bytes (json.data));

        try {
            GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);
            var parser = new Json.Parser ();
            parser.load_from_data ((string) stream.get_data ());

            if (Services.Todoist.get_default ().is_todoist_error (message.status_code)) {
                response.from_error_json (parser.get_root ());
                debug_error (message.status_code, Services.Todoist.get_default ().get_todoist_error (message.status_code));
            } else {
                var sync_status = parser.get_root ().get_object ().get_object_member ("sync_status");
                var uuid_member = sync_status.get_member (uuid);

                if (uuid_member.get_node_type () == Json.NodeType.VALUE) {
                    object.source.todoist_data.sync_token = parser.get_root ().get_object ().get_string_member ("sync_token");
                    object.source.last_sync = new GLib.DateTime.now_local ().to_string ();
                    object.source.save ();

                    id = parser.get_root ().get_object ().get_object_member ("temp_id_mapping").get_string_member (temp_id);
                    response.status = true;
                    response.data = id;
                } else {
                    response.error = sync_status.get_object_member (uuid).get_string_member ("error");
                    debug_error (
                        (uint) sync_status.get_object_member (uuid).get_int_member ("http_code"),
                        sync_status.get_object_member (uuid).get_string_member ("error")
                    );
                }
            }
        } catch (Error e) {
            if (Services.Todoist.get_default ().is_todoist_error (message.status_code)) {
                response.error = e.message;
                debug_error (message.status_code, e.message);
            } else {
                id = Util.get_default ().generate_id (object);

                var queue = new Objects.Queue ();
                queue.uuid = uuid;
                queue.object_id = id;
                queue.temp_id = temp_id;
                queue.query = object.type_add;
                queue.args = object.to_json ();

                Services.Database.get_default ().insert_queue (queue);
                Services.Database.get_default ().insert_CurTempIds (object.id, temp_id, object.object_type_string);

                response.status = true;
                response.data = queue.object_id;
            }
        }

        return response;
    }

    public async HttpResponse update (Objects.BaseObject object) {
        HttpResponse response = new HttpResponse ();

        if (object.source.needs_migration ()) {
            response.status = false;
            response.error = MIGRATE_MESSAGE;
            response.error_code = 410;
            return response;
        }

        string uuid = Util.get_default ().generate_string ();
        string json = object.get_update_json (uuid);
        Objects.Source source = object.source;

        var message = new Soup.Message ("POST", TODOIST_SYNC_URL);
        message.request_headers.append ("Authorization", "Bearer %s".printf (source.todoist_data.access_token));
        message.set_request_body_from_bytes ("application/json", new Bytes (json.data));

        try {
            GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);
            var parser = new Json.Parser ();
            parser.load_from_data ((string) stream.get_data ());

            if (Services.Todoist.get_default ().is_todoist_error (message.status_code)) {
                response.from_error_json (parser.get_root ());
                debug_error (message.status_code, Services.Todoist.get_default ().get_todoist_error (message.status_code));
            } else {
                var sync_status = parser.get_root ().get_object ().get_object_member ("sync_status");
                var uuid_member = sync_status.get_member (uuid);

                if (uuid_member.get_node_type () == Json.NodeType.VALUE) {
                    source.todoist_data.sync_token = parser.get_root ().get_object ().get_string_member ("sync_token");
                    response.status = true;
                    source.last_sync = new GLib.DateTime.now_local ().to_string ();
                    source.save ();
                } else {
                    response.error = sync_status.get_object_member (uuid).get_string_member ("error");
                    debug_error (
                        (uint) sync_status.get_object_member (uuid).get_int_member ("http_code"),
                        sync_status.get_object_member (uuid).get_string_member ("error")
                    );
                }
            }
        } catch (Error e) {
            if (Services.Todoist.get_default ().is_todoist_error (message.status_code)) {
                response.error = e.message;
                debug_error (message.status_code, e.message);
            } else {
                var queue = new Objects.Queue ();
                queue.uuid = uuid;
                queue.object_id = object.id;
                queue.query = object.type_update;
                queue.args = object.to_json ();

                Services.Database.get_default ().insert_queue (queue);
                response.status = true;
            }
        }

        return response;
    }

    public async HttpResponse delete (Objects.BaseObject object) {
        HttpResponse response = new HttpResponse ();

        if (object.source.needs_migration ()) {
            response.status = false;
            response.error = MIGRATE_MESSAGE;
            response.error_code = 410;
            return response;
        }

        string uuid = Util.get_default ().generate_string ();
        string json = Services.Todoist.get_default ().get_delete_json (object.id, object.type_delete, uuid);

        var message = new Soup.Message ("POST", TODOIST_SYNC_URL);
        message.request_headers.append ("Authorization", "Bearer %s".printf (object.source.todoist_data.access_token));
        message.set_request_body_from_bytes ("application/json", new Bytes (json.data));

        try {
            GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);
            var parser = new Json.Parser ();
            parser.load_from_data ((string) stream.get_data ());

            if (Services.Todoist.get_default ().is_todoist_error (message.status_code)) {
                response.from_error_json (parser.get_root ());
                debug_error (message.status_code, Services.Todoist.get_default ().get_todoist_error (message.status_code));
            } else {
                var sync_status = parser.get_root ().get_object ().get_object_member ("sync_status");
                var uuid_member = sync_status.get_member (uuid);

                if (uuid_member.get_node_type () == Json.NodeType.VALUE) {
                    object.source.todoist_data.sync_token = parser.get_root ().get_object ().get_string_member ("sync_token");
                    object.source.last_sync = new GLib.DateTime.now_local ().to_string ();
                    object.source.save ();
                    response.status = true;
                } else {
                    response.error = sync_status.get_object_member (uuid).get_string_member ("error");
                    debug_error (
                        (uint) sync_status.get_object_member (uuid).get_int_member ("http_code"),
                        sync_status.get_object_member (uuid).get_string_member ("error")
                    );
                }
            }
        } catch (Error e) {
            if (Services.Todoist.get_default ().is_todoist_error (message.status_code)) {
                response.error = e.message;
                debug_error (message.status_code, e.message);
            } else {
                var queue = new Objects.Queue ();
                queue.uuid = uuid;
                queue.object_id = object.id;
                queue.query = object.type_delete;
                queue.args = object.to_json ();

                Services.Database.get_default ().insert_queue (queue);
                response.status = true;
            }
        }

        return response;
    }

    public async HttpResponse complete_item (Objects.Item item) {
        HttpResponse response = new HttpResponse ();

        if (item.source.needs_migration ()) {
            response.status = false;
            response.error = MIGRATE_MESSAGE;
            response.error_code = 410;
            return response;
        }

        string uuid = Util.get_default ().generate_string ();
        string json = item.get_check_json (uuid, item.checked ? "item_complete" : "item_uncomplete");
        Objects.Source source = item.source;

        var message = new Soup.Message ("POST", TODOIST_SYNC_URL);
        message.request_headers.append ("Authorization", "Bearer %s".printf (source.todoist_data.access_token));
        message.set_request_body_from_bytes ("application/json", new Bytes (json.data));

        try {
            GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);
            var parser = new Json.Parser ();
            parser.load_from_data ((string) stream.get_data ());

            if (Services.Todoist.get_default ().is_todoist_error (message.status_code)) {
                response.from_error_json (parser.get_root ());
                debug_error (message.status_code, Services.Todoist.get_default ().get_todoist_error (message.status_code));
            } else {
                var sync_status = parser.get_root ().get_object ().get_object_member ("sync_status");
                var uuid_member = sync_status.get_member (uuid);

                if (uuid_member.get_node_type () == Json.NodeType.VALUE) {
                    source.todoist_data.sync_token = parser.get_root ().get_object ().get_string_member ("sync_token");
                    response.status = true;
                    source.last_sync = new GLib.DateTime.now_local ().to_string ();
                    source.save ();
                } else {
                    response.error = sync_status.get_object_member (uuid).get_string_member ("error");
                    debug_error (
                        (uint) sync_status.get_object_member (uuid).get_int_member ("http_code"),
                        sync_status.get_object_member (uuid).get_string_member ("error")
                    );
                }
            }
        } catch (Error e) {
            if (Services.Todoist.get_default ().is_todoist_error (message.status_code)) {
                response.error = e.message;
                debug_error (message.status_code, e.message);
            } else {
                var queue = new Objects.Queue ();
                queue.uuid = uuid;
                queue.object_id = item.id;
                queue.query = item.checked ? "item_complete" : "item_uncomplete";
                queue.args = item.to_json ();

                Services.Database.get_default ().insert_queue (queue);
                response.status = true;
            }
        }

        return response;
    }

    public async HttpResponse move_item (Objects.Item item, string type, string id) {
        HttpResponse response = new HttpResponse ();

        if (item.source.needs_migration ()) {
            response.status = false;
            response.error = MIGRATE_MESSAGE;
            response.error_code = 410;
            return response;
        }

        string uuid = Util.get_default ().generate_string ();
        string json = item.get_move_item (uuid, type, id);
        Objects.Source source = item.source;

        var message = new Soup.Message ("POST", TODOIST_SYNC_URL);
        message.request_headers.append ("Authorization", "Bearer %s".printf (source.todoist_data.access_token));
        message.set_request_body_from_bytes ("application/json", new Bytes (json.data));

        try {
            GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);
            var parser = new Json.Parser ();
            parser.load_from_data ((string) stream.get_data ());

            if (Services.Todoist.get_default ().is_todoist_error (message.status_code)) {
                response.from_error_json (parser.get_root ());
                debug_error (message.status_code, Services.Todoist.get_default ().get_todoist_error (message.status_code));
            } else {
                var sync_status = parser.get_root ().get_object ().get_object_member ("sync_status");
                var uuid_member = sync_status.get_member (uuid);

                if (uuid_member.get_node_type () == Json.NodeType.VALUE) {
                    source.todoist_data.sync_token = parser.get_root ().get_object ().get_string_member ("sync_token");
                    response.status = true;
                    source.last_sync = new GLib.DateTime.now_local ().to_string ();
                    source.save ();
                } else {
                    response.error = sync_status.get_object_member (uuid).get_string_member ("error");
                    debug_error (
                        (uint) sync_status.get_object_member (uuid).get_int_member ("http_code"),
                        sync_status.get_object_member (uuid).get_string_member ("error")
                    );
                }
            }
        } catch (Error e) {
            if (Services.Todoist.get_default ().is_todoist_error (message.status_code)) {
                response.error = e.message;
                debug_error (message.status_code, e.message);
            } else {
                var queue = new Objects.Queue ();
                queue.uuid = uuid;
                queue.object_id = item.id;
                queue.query = "item_move";
                queue.args = item.to_move_json (type, id);

                Services.Database.get_default ().insert_queue (queue);
                response.status = true;
            }
        }

        return response;
    }

    public async void update_items (Gee.ArrayList<Objects.Item> objects) {
        string json = get_update_items_json (objects);

        Objects.Source ? source = null;
        foreach (Objects.Item item in objects) {
            if (item.source != null) {
                source = item.source;
                break;
            }
        }

        if (source == null) {
            warning ("No valid source found in items");
            return;
        }

        var message = new Soup.Message ("POST", TODOIST_SYNC_URL);
        message.request_headers.append ("Authorization", "Bearer %s".printf (source.todoist_data.access_token));
        message.set_request_body_from_bytes ("application/json", new Bytes (json.data));

        try {
            GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);
            var parser = new Json.Parser ();
            parser.load_from_data ((string) stream.get_data ());

            if (Services.Todoist.get_default ().is_todoist_error (message.status_code)) {
                debug_error (message.status_code, Services.Todoist.get_default ().get_todoist_error (message.status_code));
            } else {
                source.todoist_data.sync_token = parser.get_root ().get_object ().get_string_member ("sync_token");
                source.last_sync = new GLib.DateTime.now_local ().to_string ();
                source.save ();
            }
        } catch (Error e) {
            Services.LogService.get_default ().warn ("Todoist", "Failed to update items: %s".printf (e.message));
        }
    }

    public string get_update_items_json (Gee.ArrayList<Objects.Item> objects) {
        var builder = new Json.Builder ();
        builder.begin_object ();
        builder.set_member_name ("commands");
        builder.begin_array ();

        foreach (var item in objects) {
            builder.begin_object ();
            builder.set_member_name ("type"); builder.add_string_value ("item_update");
            builder.set_member_name ("uuid"); builder.add_string_value (Util.get_default ().generate_string ());
            builder.set_member_name ("args");
            builder.begin_object ();
            builder.set_member_name ("id"); builder.add_string_value (item.id);
            builder.set_member_name ("content"); builder.add_string_value (Util.get_default ().get_encode_text (item.content));
            builder.set_member_name ("description"); builder.add_string_value (Util.get_default ().get_encode_text (item.description));
            builder.set_member_name ("priority");
            builder.add_int_value (item.priority == 0 ? Constants.PRIORITY_4 : item.priority);

            if (item.has_due) {
                builder.set_member_name ("due");
                builder.begin_object ();
                builder.set_member_name ("date"); builder.add_string_value (item.due.date);
                builder.end_object ();
            } else {
                builder.set_member_name ("due"); builder.add_null_value ();
            }

            builder.set_member_name ("labels");
            builder.begin_array ();
            foreach (Objects.Label label in item.labels) {
                builder.add_string_value (label.name);
            }
            builder.end_array ();
            builder.end_object ();
            builder.end_object ();
        }

        builder.end_array ();
        builder.end_object ();

        var generator = new Json.Generator ();
        generator.set_root (builder.get_root ());
        return generator.to_data (null);
    }

    private void debug_error (uint status_code, string message) {
        debug ("Code: %s - %s".printf (status_code.to_string (), message));
    }
}
