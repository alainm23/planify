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

    public void log_out () {
        Planner.settings.set_string ("todoist-sync-token", "");
        Planner.settings.set_string ("todoist-access-token", "");
        Planner.settings.set_string ("todoist-last-sync", "");
        Planner.settings.set_string ("todoist-user-email", "");
        Planner.settings.set_string ("todoist-user-avatar", "");
        Planner.settings.set_string ("todoist-user-image-id", "");
        Planner.settings.set_boolean ("todoist-sync-server", false);
        Planner.settings.set_boolean ("todoist-user-is-premium", false);

        // Delete all projects, sections and items
        // foreach (var project in Planner.database.get_all_projects_by_todoist ()) {
        //     Planner.database.delete_project (project.id);
        // }

        // Clear Queue
        // Planner.database.clear_queue ();

        // Clear CurTempIds
        // Planner.database.clear_cur_temp_ids ();

        // Remove server_timeout
        // Source.remove (server_timeout);
        // server_timeout = 0;
    }

    public void init () {
        if (invalid_token ()) {
            var todoist_oauth = new Dialogs.TodoistOAuth ();
            todoist_oauth.destroy.connect (() => {
                oauth_closed (invalid_token ());
            });
            todoist_oauth.show_all ();
        }
    }

    public bool invalid_token () {
        return Planner.settings.get_string ("todoist-access-token").strip () == "";
    }

    public void get_todoist_token (string url) {
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
        try {
            var stream = yield session.send_async (message);
            yield parser.load_from_stream_async (stream);
        } catch (Error e) {
            debug (e.message);
        }

        // Debug
        print_root (parser.get_root ());

        Planner.settings.set_string ("todoist-sync-token", parser.get_root ().get_object ().get_string_member ("sync_token"));
        Planner.settings.set_string ("todoist-access-token", token);
        Planner.settings.set_boolean ("todoist-sync-server", true);

        // Create user
        var user_object = parser.get_root ().get_object ().get_object_member ("user");
        if (user_object.get_null_member ("image_id") == false) {
            Planner.settings.set_string ("todoist-user-image-id", user_object.get_string_member ("image_id"));
        }

        // Set Inbox Project
        Planner.settings.set_int64 ("inbox-project-id", user_object.get_int_member ("inbox_project_id"));
        Planner.settings.set_string ("todoist-user-name", user_object.get_string_member ("full_name"));
        Planner.settings.set_string ("todoist-user-email", user_object.get_string_member ("email"));
        Planner.settings.set_boolean ("todoist-user-is-premium", user_object.get_boolean_member ("is_premium"));

        // Create Labels
        unowned Json.Array labels = parser.get_root ().get_object ().get_array_member (LABELS_COLLECTION);
        foreach (unowned Json.Node _node in labels.get_elements ()) {
            Planner.database.insert_label (new Objects.Label.from_json (_node));
        }

        // Create Projects
        unowned Json.Array projects = parser.get_root ().get_object ().get_array_member (PROJECTS_COLLECTION);
        foreach (unowned Json.Node _node in projects.get_elements ()) {
            if (!_node.get_object ().get_null_member ("parent_id")) {
                Objects.Project? project = Planner.database.get_project (_node.get_object ().get_int_member ("parent_id"));
                if (project != null) {
                    project.add_subproject_if_not_exists (new Objects.Project.from_json (_node));
                }
            } else {
                Planner.database.insert_project (new Objects.Project.from_json (_node));
            }
        }

        // Create Sections
        unowned Json.Array sections = parser.get_root ().get_object ().get_array_member (SECTIONS_COLLECTION);
        foreach (unowned Json.Node _node in sections.get_elements ()) {
            add_section_if_not_exists (_node);
        }

        // Create Items
        unowned Json.Array items = parser.get_root ().get_object ().get_array_member (ITEMS_COLLECTION);
        foreach (unowned Json.Node _node in items.get_elements ()) {
            add_item_if_not_exists (_node);
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
        try {
            yield parser.load_from_stream_async (yield session.send_async (message));

            // Debug
            print_root (parser.get_root ());

            if (!parser.get_root ().get_object ().has_member ("error")) {
                // Update sync token
                Planner.settings.set_string ("todoist-sync-token", parser.get_root ().get_object ().get_string_member ("sync_token"));

                // Update user
                if (parser.get_root ().get_object ().has_member ("user")) {
                    var user_object = parser.get_root ().get_object ().get_object_member ("user");
                    Planner.settings.set_boolean ("todoist-user-is-premium", user_object.get_boolean_member ("is_premium"));
                    Planner.settings.set_string ("todoist-user-name", user_object.get_string_member ("full_name"));
                    Planner.settings.set_string ("todoist-user-email", user_object.get_string_member ("email"));
                }

                // Labels
                unowned Json.Array labels = parser.get_root ().get_object ().get_array_member (LABELS_COLLECTION);
                foreach (unowned Json.Node _node in labels.get_elements ()) {
                    Objects.Label? label = Planner.database.get_label (_node.get_object ().get_int_member ("id"));
                    if (label != null) {
                        if (_node.get_object ().get_boolean_member ("is_deleted")) {
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
                unowned Json.Array projects = parser.get_root ().get_object ().get_array_member (PROJECTS_COLLECTION);
                foreach (unowned Json.Node _node in projects.get_elements ()) {
                    Objects.Project? project = Planner.database.get_project (_node.get_object ().get_int_member ("id"));
                    if (project != null) {
                        if ((int32) _node.get_object ().get_int_member ("is_deleted") == Constants.ACTIVE) {
                            Planner.database.delete_project (project);
                        } else {
                            int64 old_parent_id = project.parent_id;
                            bool old_is_favorite = project.is_favorite;

                            project.update_from_json (_node);
                            Planner.database.update_project (project);

                            if (project.parent_id != old_parent_id) {
                                Planner.event_bus.project_parent_changed (project, old_parent_id);
                            }

                            if (project.is_favorite != old_is_favorite) {
                                Planner.event_bus.favorite_toggled (project);
                            }
                        }
                    } else {
                        Planner.database.insert_project (new Objects.Project.from_json (_node));
                    }
                }

                // Sections
                unowned Json.Array sections = parser.get_root ().get_object ().get_array_member (SECTIONS_COLLECTION);
                foreach (unowned Json.Node _node in sections.get_elements ()) {
                    Objects.Section? section = Planner.database.get_section (_node.get_object ().get_int_member ("id"));
                    if (section != null) {
                        if (_node.get_object ().get_boolean_member ("is_deleted")) {
                            Planner.database.delete_section (section);
                        } else {
                            section.update_from_json (_node);
                            Planner.database.update_section (section);
                        }
                    } else {
                        add_section_if_not_exists (_node);
                    }
                }

                // Items
                unowned Json.Array items = parser.get_root ().get_object ().get_array_member (ITEMS_COLLECTION);
                foreach (unowned Json.Node _node in items.get_elements ()) {
                    Objects.Item? item = Planner.database.get_item (_node.get_object ().get_int_member ("id"));
                    if (item != null) {
                        if (_node.get_object ().get_boolean_member ("is_deleted")) {
                            Planner.database.delete_item (item);
                        } else {
                            int64 old_project_id = item.project_id;
                            int64 old_section_id = item.section_id;
                            bool old_checked = item.checked;

                            item.update_from_json (_node);
                            item.update_labels_from_json (_node);
                            Planner.database.update_item (item);

                            if (old_project_id != item.project_id || old_section_id != item.section_id) {
                                Planner.event_bus.item_moved (item, old_project_id, old_section_id);
                            }

                            if (old_checked != item.checked) {
                                Planner.database.checked_toggled (item, old_checked);
                            }
                        }
                    } else {
                        add_item_if_not_exists (_node);
                    }
                }
            }
        } catch (Error e) {
            debug (e.message);
        }
    }

    private void add_item_if_not_exists (Json.Node node) {
        if (!node.get_object ().get_null_member ("parent_id")) {
            // Add to parent
            return;
        }
        
        if (!node.get_object ().get_null_member ("section_id")) {
            Objects.Section? section = Planner.database.get_section (node.get_object ().get_int_member ("section_id"));
            if (section != null) {
                section.add_item_if_not_exists (new Objects.Item.from_json (node));
            }
        } else {
            Objects.Project? project = Planner.database.get_project (node.get_object ().get_int_member ("project_id"));
            if (project != null) {
                project.add_item_if_not_exists (new Objects.Item.from_json (node));
            }
        }
    }

    public async int64? add (Objects.BaseObject object) {
        string temp_id = Util.get_default ().generate_string ();
        string uuid = Util.get_default ().generate_string ();
        int64? id = null;

        string url = "%s?token=%s&commands=%s".printf (
            TODOIST_SYNC_URL,
            Planner.settings.get_string ("todoist-access-token"),
            object.get_add_json (temp_id, uuid)
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
                Planner.settings.set_string ("todoist-sync-token", parser.get_root ().get_object ().get_string_member ("sync_token"));
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

    public async bool update (Objects.BaseObject object) {
        string uuid = Util.get_default ().generate_string ();
        bool success = false;

        string url = "%s?token=%s&commands=%s".printf (
            TODOIST_SYNC_URL,
            Planner.settings.get_string ("todoist-access-token"),
            object.get_update_json (uuid)
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
                Planner.settings.set_string ("todoist-sync-token", parser.get_root ().get_object ().get_string_member ("sync_token"));
                success = true;
            } else {
                // project_updated_error (
                //     project.id,
                //     (int32) sync_status.get_object_member (uuid).get_int_member ("http_code"),
                //     sync_status.get_object_member (uuid).get_string_member ("error")
                // );
            }
        } catch (Error e) {
            debug (e.message);
        }

        return success;
    }
    public async bool delete (Objects.BaseObject object) {
        string uuid = Util.get_default ().generate_string ();
        bool success = false;

        string url = "%s?token=%s&commands=%s".printf (
            TODOIST_SYNC_URL,
            Planner.settings.get_string ("todoist-access-token"),
            get_delete_json (object.id, object.type_delete, uuid)
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
                Planner.settings.set_string ("todoist-sync-token", parser.get_root ().get_object ().get_string_member ("sync_token"));
                success = true;
            } else {
                // project_updated_error (
                //     project.id,
                //     (int32) sync_status.get_object_member (uuid).get_int_member ("http_code"),
                //     sync_status.get_object_member (uuid).get_string_member ("error")
                // );
            }
        } catch (Error e) {
            debug (e.message);
        }

        return success;
    }
    /*
        Sections
    */

    private void add_section_if_not_exists (Json.Node node) {
        Objects.Project? project = Planner.database.get_project (node.get_object ().get_int_member ("project_id"));
        if (project != null) {
            project.add_section_if_not_exists (new Objects.Section.from_json (node));
        }
    }   
    
    /*
        Items
    */

    public async bool complete_item (Objects.Item item) {
        string uuid = Util.get_default ().generate_string ();

        string url = "%s?token=%s&commands=%s".printf (
            TODOIST_SYNC_URL,
            Planner.settings.get_string ("todoist-access-token"),
            item.get_check_json (uuid, item.checked ? "item_complete" : "item_uncomplete")
        );

        var message = new Soup.Message ("POST", url);

        try {
            var stream = yield session.send_async (message, null);
            yield parser.load_from_stream_async (stream);
        } catch (Error e) {
            debug (e.message);
        }

        // Debug
        print_root (parser.get_root ());

        var sync_status = parser.get_root ().get_object ().get_object_member ("sync_status");
        var uuid_member = sync_status.get_member (uuid);
        bool returned = false;

        if (uuid_member.get_node_type () == Json.NodeType.VALUE) {
            Planner.settings.set_string ("todoist-sync-token", parser.get_root ().get_object ().get_string_member ("sync_token"));
            returned = true;
        } else {
            // project_added_error (
            //     temp_id_mapping,
            //     (int32) sync_status.get_object_member (uuid).get_int_member ("http_code"),
            //     sync_status.get_object_member (uuid).get_string_member ("error")
            // );
        }

        return returned;
    }

    private void print_root (Json.Node root) {
        Json.Generator generator = new Json.Generator ();
        generator.set_root (root);
        debug (generator.to_data (null) + "\n");
    }

    public string get_delete_json (int64 id, string type, string uuid) {
        var builder = new Json.Builder ();
        builder.begin_array ();
        builder.begin_object ();

        // Set type
        builder.set_member_name ("type");
        builder.add_string_value (type);

        builder.set_member_name ("uuid");
        builder.add_string_value (uuid);

        builder.set_member_name ("args");
            builder.begin_object ();

            builder.set_member_name ("id");
            builder.add_int_value (id);

            builder.end_object ();

        builder.end_object ();
        builder.end_array ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);

        return generator.to_data (null);
    }

    public async bool move_item (Objects.Item item, string type, int64 id) {
        string uuid = Util.get_default ().generate_string ();
        bool success = false;

        string url = "%s?token=%s&commands=%s".printf (
            TODOIST_SYNC_URL,
            Planner.settings.get_string ("todoist-access-token"),
            item.get_move_item (uuid, type, id)
        );

        var message = new Soup.Message ("POST", url);

        try {
            var stream = yield session.send_async (message, null);
            yield parser.load_from_stream_async (stream);

            print_root (parser.get_root ());

            var sync_status = parser.get_root ().get_object ().get_object_member ("sync_status");
            var uuid_member = sync_status.get_member (uuid);

            if (uuid_member.get_node_type () == Json.NodeType.VALUE) {
                Planner.settings.set_string (
                    "todoist-sync-token",
                    parser.get_root ().get_object ().get_string_member ("sync_token")
                );
                success = true;
            } else {
                // project_updated_error (
                //     project.id,
                //     (int32) sync_status.get_object_member (uuid).get_int_member ("http_code"),
                //     sync_status.get_object_member (uuid).get_string_member ("error")
                // );
            }
        } catch (Error e) {
            debug (e.message);
        }

        return success;
    }
}
