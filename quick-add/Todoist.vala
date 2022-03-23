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
    private const string PROJECTS_COLLECTION = "projects";
    private const string SECTIONS_COLLECTION = "sections";
    private const string ITEMS_COLLECTION = "items";
    private const string LABELS_COLLECTION = "labels";

    private static Todoist? _instance;
    public static Todoist get_default () {
        if (_instance == null) {
            _instance = new Todoist ();
        }

        return _instance;
    }

    public Todoist () {
        session = new Soup.Session ();
        session.ssl_strict = false;

        parser = new Json.Parser ();
    }

    public async int64? add_item (Objects.Item item) {
        string temp_id = QuickAddUtil.generate_string ();
        string uuid = QuickAddUtil.generate_string ();
        int64? id = null;

        string url = "%s?token=%s&commands=%s".printf (
            TODOIST_SYNC_URL,
            PlannerQuickAdd.settings.get_string ("todoist-access-token"),
            item.get_add_json (temp_id, uuid)
        );

        var message = new Soup.Message ("POST", url);

        try {
            var stream = yield session.send_async (message, null);
            yield parser.load_from_stream_async (stream);

            // Debug
            print_root (parser.get_root ());

            var sync_status = parser.get_root ().get_object ().get_object_member ("sync_status");
            var uuid_member = sync_status.get_member (uuid);

            if (uuid_member.get_node_type () == Json.NodeType.VALUE) {
                PlannerQuickAdd.settings.set_string ("todoist-sync-token", parser.get_root ().get_object ().get_string_member ("sync_token"));
                id = parser.get_root ().get_object ().get_object_member ("temp_id_mapping").get_int_member (temp_id);
            } else {
                // project_added_error (
                //     temp_id_mapping,
                //     (int32) sync_status.get_object_member (uuid).get_int_member ("http_code"),
                //     sync_status.get_object_member (uuid).get_string_member ("error")
                // );
            }
        } catch (Error e) {
            debug (e.message);
        }

        return id;
    }

    private void print_root (Json.Node root) {
        Json.Generator generator = new Json.Generator ();
        generator.set_root (root);
        debug (generator.to_data (null) + "\n");
    }
}
