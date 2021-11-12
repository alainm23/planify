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

    private const string TODOIST_SYNC_URL = "https://api.todoist.com/sync/v8/sync";

    private static Todoist? _instance;
    public static Todoist get_default () {
        if (_instance == null) {
            _instance = new Todoist ();
        }

        return _instance;
    }

    public signal void oauth_closed (bool welcome);

    public signal void sync_started ();
    public signal void sync_finished ();
    
    public signal void first_sync_started ();
    public signal void first_sync_finished ();

    public Todoist () {
        session = new Soup.Session ();
        session.ssl_strict = false;

        parser = new Json.Parser ();
    }

    public void init () {
        if (valid_token (Planner.settings.get_string ("todoist-access-token"))) {
            var todoist_oauth = new Dialogs.TodoistOAuth ();
            todoist_oauth.destroy.connect (() => {
                oauth_closed (valid_token (Planner.settings.get_string ("todoist-access-token")));
            });
            todoist_oauth.show_all ();
        }
    }

    private bool valid_token (string token) {
        return token.strip () == "";
    }

    public void get_todoist_token (string url) {
        // sync_started ();
        new Thread<void*> ("get_todoist_token", () => {
            try {
                string code = url.split ("=") [1];
                string response = "";

                string command = "curl \"https://todoist.com/oauth/access_token\" ";
                command = command + "-d \"client_id=b0dd7d3714314b1dbbdab9ee03b6b432\" ";
                command = command + "-d \"client_secret=a86dfeb12139459da3e5e2a8c197c678\" ";
                command = command + "-d \"code=" + code + "\"";

                Process.spawn_command_line_sync (command, out response);

                parser.load_from_data (response, -1);

                var root = parser.get_root ().get_object ();
                var token = root.get_string_member ("access_token");

                first_sync_started ();
                first_sync.begin (token, (obj, res) => {
                    first_sync.end (res);
                    first_sync_finished ();
                });
            } catch (Error e) {
                debug (e.message);
            }

            return null;
        });
    }

    public async void first_sync (string token) {
        string url = TODOIST_SYNC_URL;
        url = url + "?token=" + token;
        url = url + "&sync_token=" + "*";
        url = url + "&resource_types=" + "[\"all\"]";

        var message = new Soup.Message ("POST", url);
        // session.send_message (message);
        try {
            var stream = yield session.send_async (message);
            yield parser.load_from_stream_async (stream);

            // parser.load_from_data ((string) message.response_body.flatten ().data, -1);
            // print ("%s\n".printf ((string) message.response_body.flatten ().data));
        } catch (Error e) {
            print (e.message);
        }

        var node = parser.get_root ().get_object ();

        Planner.settings.set_string ("todoist-sync-token", node.get_string_member ("sync_token"));
        Planner.settings.set_string ("todoist-access-token", token);
        Planner.settings.set_boolean ("todoist-sync-server", true);

        // Create user
        var user_object = node.get_object_member ("user");
        Planner.settings.set_int ("todoist-user-id", (int32) user_object.get_int_member ("id"));
        if (user_object.get_null_member ("image_id") == false) {
            Planner.settings.set_string ("todoist-user-image-id", user_object.get_string_member ("image_id"));
        }
        Planner.settings.set_boolean ("todoist-account", true);

        // Set Inbox Project
        Planner.settings.set_int64 ("inbox-project", user_object.get_int_member ("inbox_project"));
        Planner.settings.set_string ("todoist-user-name", user_object.get_string_member ("full_name"));
        Planner.settings.set_string ("todoist-user-email", user_object.get_string_member ("email"));
        Planner.settings.set_string ("todoist-user-join-date", user_object.get_string_member ("join_date"));
        
        Planner.settings.set_boolean ("todoist-user-is-premium", user_object.get_boolean_member ("is_premium"));
        Planner.settings.set_boolean ("todoist-sync-labels", true);

        // Create labels
        unowned Json.Array labels = node.get_array_member ("labels");
        foreach (unowned Json.Node _node in labels.get_elements ()) {
            Planner.database.insert_label (new Objects.Label.from_json (_node));
        }

        // Create projects
        unowned Json.Array projects = node.get_array_member ("projects");
        foreach (unowned Json.Node _node in projects.get_elements ()) {
            Planner.database.insert_project (new Objects.Project.from_json (_node));
        }

        // Download Profile Image
        if (user_object.get_null_member ("image_id") == false) {
            Util.get_default ().download_profile_image (
                user_object.get_string_member ("image_id"), user_object.get_string_member ("avatar_s640")
            );
        }
    }

    /*
    *   Sync
    */
    
    public void sync_async () {
        sync_started ();
        sync.begin ((obj, res) => {
            sync.end (res);
            sync_finished ();
        });
    }

    public async void sync () {
        string url = TODOIST_SYNC_URL;
        url = url + "?token=" + Planner.settings.get_string ("todoist-access-token");
        url = url + "&sync_token=" + Planner.settings.get_string ("todoist-sync-token");
        url = url + "&resource_types=" + "[\"all\"]";

        var message = new Soup.Message ("POST", url);
        // session.send_message (message);
        try {
            yield parser.load_from_stream_async (yield session.send_async (message));

            // parser.load_from_data ((string) message.response_body.flatten ().data, -1);
            // print ("%s\n".printf ((string) message.response_body.flatten ().data));
        } catch (Error e) {
            print (e.message);
        }

        var node = parser.get_root ().get_object ();
        var sync_token = node.get_string_member ("sync_token");

        // Update sync token
        Planner.settings.set_string ("todoist-sync-token", sync_token);

        // Update user
        if (node.has_member ("user")) {
            var user_object = node.get_object_member ("user");
            Planner.settings.set_boolean ("todoist-user-is-premium", user_object.get_boolean_member ("is_premium"));
            Planner.settings.set_string ("todoist-user-name", user_object.get_string_member ("full_name"));
            Planner.settings.set_string ("todoist-user-email", user_object.get_string_member ("email"));
        }

        // Labels
        unowned Json.Array labels = node.get_array_member ("labels");
        foreach (unowned Json.Node _node in labels.get_elements ()) {
            Objects.Label? label = Planner.database.get_label (_node.get_object ().get_int_member ("id"));
            if (label != null) {
                if ((int32) _node.get_object ().get_int_member ("is_deleted") == 1) {
                    Planner.database.delete_label (label);
                } else {
                    label.update_from_json (_node);
                    Planner.database.update_label (label);
                }
            } else {
                Planner.database.insert_label (new Objects.Label.from_json (_node));
            }
        }

        // Projects
        unowned Json.Array projects = node.get_array_member ("projects");
        foreach (unowned Json.Node _node in projects.get_elements ()) {
            Objects.Project? project = Planner.database.get_project (_node.get_object ().get_int_member ("id"));
            if (project != null) {
                if ((int32) _node.get_object ().get_int_member ("is_deleted") == 1) {
                    Planner.database.delete_project (project);
                } else {
                    int64 old_parent_id = project.parent_id;
                    int64 new_parent_id;
                    if (!_node.get_object ().get_null_member ("parent_id")) {
                        new_parent_id = _node.get_object ().get_int_member ("parent_id");
                    } else {
                        new_parent_id = 0;
                    }

                    project.update_from_json (_node);
                    Planner.database.update_project (project);

                    if (new_parent_id != old_parent_id) {
                        Planner.event_bus.delete_row_project (project);
                        Planner.database.project_added (project);
                    }
                }
            } else {
                Planner.database.insert_project (new Objects.Project.from_json (_node));
            }
        }
    }

    public async int64? add_project (Objects.Project project) {
        string temp_id = Util.get_default ().generate_string ();
        string uuid = Util.get_default ().generate_string ();

        string url = "%s?token=%s&commands=%s".printf (
            TODOIST_SYNC_URL,
            Planner.settings.get_string ("todoist-access-token"),
            project.get_add_json (temp_id, uuid)
        );

        var message = new Soup.Message ("POST", url);

        try {
            var stream = yield session.send_async (message, null);
            yield parser.load_from_stream_async (stream);
        } catch (Error e) {
            print (e.message);
        }

        var node = parser.get_root ().get_object ();
        var sync_status = node.get_object_member ("sync_status");
        var uuid_member = sync_status.get_member (uuid);
        int64? id = null;

        if (uuid_member.get_node_type () == Json.NodeType.VALUE) {
            string sync_token = node.get_string_member ("sync_token");
            Planner.settings.set_string ("todoist-sync-token", sync_token);
            id = node.get_object_member ("temp_id_mapping").get_int_member (temp_id);
        } else {
            // project_added_error (
            //     temp_id_mapping,
            //     (int32) sync_status.get_object_member (uuid).get_int_member ("http_code"),
            //     sync_status.get_object_member (uuid).get_string_member ("error")
            // );
        }

        return id;
    }

    public async void update_project (Objects.Project project) {
        string uuid = Util.get_default ().generate_string ();

        string url = "%s?token=%s&commands=%s".printf (
            TODOIST_SYNC_URL,
            Planner.settings.get_string ("todoist-access-token"),
            project.get_update_json (uuid)
        );

        var message = new Soup.Message ("POST", url);

        try {
            var stream = yield session.send_async (message, null);
            yield parser.load_from_stream_async (stream);
        } catch (Error e) {
            print (e.message);
        }

        var node = parser.get_root ().get_object ();

        var sync_status = node.get_object_member ("sync_status");
        var uuid_member = sync_status.get_member (uuid);

        if (uuid_member.get_node_type () == Json.NodeType.VALUE) {
            string sync_token = node.get_string_member ("sync_token");
            Planner.settings.set_string ("todoist-sync-token", sync_token);
            // project_updated_completed (project.id);
        } else {
            // project_updated_error (
            //     project.id,
            //     (int32) sync_status.get_object_member (uuid).get_int_member ("http_code"),
            //     sync_status.get_object_member (uuid).get_string_member ("error")
            // );
        }
    }
}
