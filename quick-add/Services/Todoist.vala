/*
* Copyright © 2019 Alain M. (https://github.com/alainm23/planner)
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

public class Services.Todoist : GLib.Object {
    private Soup.Session session;
    private Json.Parser parser;

    private const string TODOIST_SYNC_URL = "https://api.todoist.com/sync/v9/sync";

    private static Todoist? _instance;
    public static Todoist get_default () {
        if (_instance == null) {
            _instance = new Todoist ();
        }

        return _instance;
    }


    public Todoist () {
        session = new Soup.Session ();
        parser = new Json.Parser ();
    }

    public async string? add (Objects.BaseObject object) {
        string temp_id = Util.get_default ().generate_string ();
        string uuid = Util.get_default ().generate_string ();
        string? id = null;

        string url = "%s?commands=%s".printf (
            TODOIST_SYNC_URL,
            object.get_add_json (temp_id, uuid)
        );

        var message = new Soup.Message ("POST", url);
        message.request_headers.append ("Authorization", "Bearer %s".printf (Services.Settings.get_default ().settings.get_string ("todoist-access-token")));

        try {
            GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);
            parser.load_from_data ((string) stream.get_data ());
            
            // Debug
            print_root (parser.get_root ());

            var sync_status = parser.get_root ().get_object ().get_object_member ("sync_status");
            var uuid_member = sync_status.get_member (uuid);

            if (uuid_member.get_node_type () == Json.NodeType.VALUE) {
                Services.Settings.get_default ().settings.set_string ("todoist-sync-token", parser.get_root ().get_object ().get_string_member ("sync_token"));
                id = parser.get_root ().get_object ().get_object_member ("temp_id_mapping").get_string_member (temp_id);
            } else {
                debug_error (
                    (int32) sync_status.get_object_member (uuid).get_int_member ("http_code"),
                    sync_status.get_object_member (uuid).get_string_member ("error")
                );
            }
        } catch (Error e) {
            if (Util.get_default ().is_todoist_error ((int32) message.status_code)) {
                debug_error (
                    (int32) message.status_code,
                    Util.get_default ().get_todoist_error ((int32) message.status_code)
                );
            } else if ((int32) message.status_code == 0) {
                debug_error (
                    (int32) message.status_code,
                    e.message
                );
            } else {
                id = Util.get_default ().generate_id ();

                object.id = id;

                var queue = new Objects.Queue ();
                queue.uuid = uuid;
                queue.object_id = id;
                queue.temp_id = temp_id;
                queue.query = object.type_add;
                queue.args = object.to_json ();

                Services.Database.get_default ().insert_queue (queue);
                Services.Database.get_default ().insert_CurTempIds (object.id, temp_id, object.object_type_string);
            }
        }

        return id;
    }

    private void debug_error (int status_code, string message) {
        debug ("Code: %d - %s".printf (status_code, message));
    }
    
    private void print_root (Json.Node root) {
        Json.Generator generator = new Json.Generator ();
        generator.set_root (root);
        debug (generator.to_data (null) + "\n");
    }
}