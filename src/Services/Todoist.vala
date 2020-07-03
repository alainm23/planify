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
    private const string TODOIST_SYNC_URL = "https://api.todoist.com/sync/v8/sync";

    public signal void sync_started ();
    public signal void sync_finished ();

    public signal void first_sync_finished ();

    /*
        Project Signals
    */

    public signal void project_added_started ();
    public signal void project_added_completed ();
    public signal void project_added_error (int error_code, string error_message);

    public signal void project_updated_started (int64 id);
    public signal void project_updated_completed (int64 id);
    public signal void project_updated_error (int64 id, int error_code, string error_message);

    public signal void project_deleted_started (int64 id);
    public signal void project_deleted_completed (int64 id);
    public signal void project_deleted_error (int64 id, int error_code, string error_message);

    /*
        Section Signals
    */

    public signal void section_added_started (int64 id);
    public signal void section_added_completed (int64 id);
    public signal void section_added_error (int64 id, int error_code, string error_message);

    public signal void section_updated_started (int64 id);
    public signal void section_updated_completed (int64 id);
    public signal void section_updated_error (int64 id, int error_code, string error_message);

    public signal void section_deleted_started (int64 id);
    public signal void section_deleted_completed (int64 id);
    public signal void section_deleted_error (int64 id, int error_code, string error_message);

    public signal void section_moved_started (int64 id);
    public signal void section_moved_completed (int64 id);
    public signal void section_moved_error (int64 id, int error_code, string error_message);

    /*
        Item Signals
    */

    public signal void item_added_started (int64 id);
    public signal void item_added_completed (int64 id);
    public signal void item_added_error (int64 id, int error_code, string error_message);

    public signal void item_updated_started (int64 id);
    public signal void item_updated_completed (int64 id);
    public signal void item_updated_error (int64 id, int error_code, string error_message);

    public signal void item_completed_started (Objects.Item item);
    public signal void item_completed_completed (Objects.Item item);
    public signal void item_completed_error (Objects.Item item, int error_code, string error_message);

    public signal void item_uncompleted_started (Objects.Item item);
    public signal void item_uncompleted_completed (Objects.Item item);
    public signal void item_uncompleted_error (Objects.Item item, int error_code, string error_message);

    public signal void item_moved_started (int64 id);
    public signal void item_moved_completed (int64 id);
    public signal void item_moved_error (int64 id, int error_code, string error_message);

    public signal void avatar_downloaded (string id);

    public Gee.ArrayList<Objects.Item?> items_to_complete;
    public Gee.ArrayList<Objects.Item?> items_to_delete;

    private uint delete_timeout = 0;
    private uint server_timeout = 0;

    public Todoist () {
        session = new Soup.Session ();

        items_to_complete = new Gee.ArrayList<Objects.Item?> ();
        items_to_delete = new Gee.ArrayList<Objects.Item?> ();

        var network_monitor = GLib.NetworkMonitor.get_default ();
        network_monitor.network_changed.connect (() => {
            var available = GLib.NetworkMonitor.get_default ().network_available;

            if (available) {
                if (Planner.settings.get_boolean ("todoist-account") &&
                    Planner.settings.get_boolean ("todoist-sync-server")) {
                    sync ();
                }
            }
        });

        Planner.database.reset.connect (() => {
            if (this.server_timeout != 0) {
                Source.remove (this.server_timeout);
                this.server_timeout = 0;
            }
        });
    }

    public void log_out () {
        Planner.settings.set_string ("todoist-sync-token", "");
        Planner.settings.set_string ("todoist-access-token", "");
        Planner.settings.set_string ("todoist-last-sync", "");
        Planner.settings.set_string ("todoist-user-email", "");
        Planner.settings.set_string ("todoist-user-join-date", "");
        Planner.settings.set_string ("todoist-user-avatar", "");
        Planner.settings.set_string ("todoist-user-image-id", "");
        Planner.settings.set_boolean ("todoist-sync-server", false);
        Planner.settings.set_boolean ("todoist-account", false);
        Planner.settings.set_boolean ("todoist-user-is-premium", false);
        Planner.settings.set_int ("todoist-user-id", 0);

        // Delete all projects, sections and items
        foreach (var project in Planner.database.get_all_projects_by_todoist ()) {
            Planner.database.delete_project (project.id);
        }

        // Clear Queue
        Planner.database.clear_queue ();

        // Clear CurTempIds
        Planner.database.clear_cur_temp_ids ();

        // Remove server_timeout
        Source.remove (server_timeout);
        server_timeout = 0;
    }

    public void run_server () {
        if (Planner.settings.get_boolean ("todoist-account") && Planner.settings.get_boolean ("todoist-sync-server")) {
            sync ();
        }

        server_timeout = Timeout.add_seconds (15 * 60, () => {
            if (Planner.settings.get_boolean ("todoist-account") &&
                Planner.settings.get_boolean ("todoist-sync-server")) {
                sync ();
            }

            return true;
        });
    }

    public void get_todoist_token (string url, string view) {
        sync_started ();
        new Thread<void*> ("get_todoist_token", () => {
            try {
                string code = url.split ("=") [1];
                string response = "";

                string command = "curl \"https://todoist.com/oauth/access_token\" ";
                command = command + "-d \"client_id=b0dd7d3714314b1dbbdab9ee03b6b432\" ";
                command = command + "-d \"client_secret=a86dfeb12139459da3e5e2a8c197c678\" ";
                command = command + "-d \"code=" + code + "\"";

                Process.spawn_command_line_sync (command, out response);

                var parser = new Json.Parser ();
                parser.load_from_data (response, -1);

                var root = parser.get_root ().get_object ();
                var token = root.get_string_member ("access_token");

                first_sync (token, view);
            } catch (Error e) {
                debug (e.message);
            }

            return null;
        });
    }

    public void first_sync (string token, string view) {
        sync_started ();

        new Thread<void*> ("first_sync", () => {
            string url = TODOIST_SYNC_URL;
            url = url + "?token=" + token;
            url = url + "&sync_token=" + "*";
            url = url + "&resource_types=" + "[\"all\"]";

            var message = new Soup.Message ("POST", url);
            session.queue_message (message, (sess, mess) => {
                if (mess.status_code == 200) {
                    var parser = new Json.Parser ();

                    try {
                        //  print ("----------------------\n");
                        //  print ("%s\n".printf ((string) mess.response_body.flatten ().data));
                        //  print ("----------------------\n");

                        parser.load_from_data ((string) mess.response_body.flatten ().data, -1);

                        var node = parser.get_root ().get_object ();

                        // Create user
                        var user_object = node.get_object_member ("user");

                        Planner.settings.set_string ("todoist-sync-token", node.get_string_member ("sync_token"));
                        Planner.settings.set_string ("todoist-access-token", token);
                        Planner.settings.set_boolean ("todoist-sync-server", true);

                        // User
                        Planner.settings.set_int ("todoist-user-id", (int32) user_object.get_int_member ("id"));

                        Planner.settings.set_string ("todoist-user-image-id",
                            user_object.get_string_member ("image_id")
                        );

                        Planner.settings.set_boolean ("todoist-account", true);

                        if (view == "preferences") {
                            // Delete Old Inbox Project
                            Planner.database.delete_project (Planner.settings.get_int64 ("inbox-project"));
                        }

                        // Set Inbox Project
                        Planner.settings.set_int64 ("inbox-project", user_object.get_int_member ("inbox_project"));


                        Planner.settings.set_string ("user-name", user_object.get_string_member ("full_name"));
                        Planner.settings.set_string ("todoist-user-email", user_object.get_string_member ("email"));
                        Planner.settings.set_string ("todoist-user-join-date",
                            user_object.get_string_member ("join_date"));

                        Planner.settings.set_string ("todoist-user-avatar",
                            user_object.get_string_member ("avatar_s640")
                        );
                        Planner.settings.set_boolean ("todoist-user-is-premium",
                            user_object.get_boolean_member ("is_premium")
                        );


                        // Cretae Default Labels
                        Planner.utils.create_default_labels ();

                        // Create projects
                        unowned Json.Array projects = node.get_array_member ("projects");
                        foreach (unowned Json.Node item in projects.get_elements ()) {
                            var object = item.get_object ();

                            var p = new Objects.Project ();

                            p.id = object.get_int_member ("id");
                            p.name = object.get_string_member ("name");
                            p.color = (int32) object.get_int_member ("color");
                            p.is_deleted = (int32) object.get_int_member ("is_deleted");
                            p.is_archived = (int32) object.get_int_member ("is_archived");
                            p.is_favorite = (int32) object.get_int_member ("is_favorite");
                            p.is_todoist = 1;
                            p.is_sync = 1;

                            if (object.get_boolean_member ("team_inbox")) {
                                p.team_inbox = 1;
                            } else {
                                p.team_inbox = 0;
                            }

                            if (object.get_boolean_member ("inbox_project")) {
                                p.inbox_project = 1;
                            } else {
                                p.inbox_project = 0;
                            }

                            if (object.get_boolean_member ("shared")) {
                                p.shared = 1;
                            } else {
                                p.shared = 0;
                            }

                            Planner.database.insert_project (p);
                        }

                        // Create Sections
                        unowned Json.Array sections = node.get_array_member ("sections");
                        foreach (unowned Json.Node item in sections.get_elements ()) {
                            var object = item.get_object ();

                            var s = new Objects.Section ();

                            s.id = object.get_int_member ("id");
                            s.project_id = object.get_int_member ("project_id");
                            s.name = object.get_string_member ("name");
                            s.date_added = object.get_string_member ("date_added");
                            s.is_deleted = (int32) object.get_int_member ("is_deleted");
                            s.is_archived = (int32) object.get_int_member ("is_archived");
                            s.collapsed = 1;
                            s.is_todoist = 1;

                            if (object.get_null_member ("date_archived") == false) {
                                s.date_archived = object.get_string_member ("date_archived");
                            }

                            if (object.get_null_member ("sync_id") == false) {
                                s.sync_id = object.get_int_member ("sync_id");
                            }

                            Planner.database.insert_section (s);
                        }

                        // Create items
                        unowned Json.Array items = node.get_array_member ("items");
                        foreach (unowned Json.Node item in items.get_elements ()) {
                            var object = item.get_object ();

                            var i = new Objects.Item ();

                            i.id = object.get_int_member ("id");
                            i.project_id = object.get_int_member ("project_id");
                            i.user_id = object.get_int_member ("user_id");
                            i.assigned_by_uid = object.get_int_member ("assigned_by_uid");
                            i.content = object.get_string_member ("content");
                            i.checked = (int32) object.get_int_member ("checked");
                            i.priority = (int32) object.get_int_member ("priority");
                            i.is_deleted = (int32) object.get_int_member ("is_deleted");
                            i.date_added = object.get_string_member ("date_added");
                            i.is_todoist = 1;

                            if (object.get_null_member ("sync_id") == false) {
                                i.sync_id = object.get_int_member ("sync_id");
                            }

                            if (object.get_null_member ("responsible_uid") == false) {
                                i.responsible_uid = object.get_int_member ("responsible_uid");
                            }

                            if (object.get_null_member ("section_id") == false) {
                                i.section_id = object.get_int_member ("section_id");
                            }

                            if (object.get_null_member ("parent_id") == false) {
                                i.parent_id = object.get_int_member ("parent_id");
                            }

                            if (object.get_null_member ("date_completed") == false) {
                                i.date_completed = object.get_string_member ("date_completed");
                            }

                            if (object.get_member ("due").get_node_type () == Json.NodeType.OBJECT) {
                                var due_object = object.get_object_member ("due");
                                var datetime = Planner.utils.get_todoist_datetime (
                                    due_object.get_string_member ("date")
                                );
                                i.due_date = datetime.to_string ();

                                if (object.get_null_member ("timezone") == false) {
                                    i.due_timezone = due_object.get_string_member ("timezone");
                                }

                                i.due_string = due_object.get_string_member ("string");
                                i.due_lang = due_object.get_string_member ("lang");
                                if (due_object.get_boolean_member ("is_recurring")) {
                                    i.due_is_recurring = 1;
                                }
                            }

                            Planner.database.insert_item (i);
                        }

                        // Download Profile Image
                        Planner.utils.download_profile_image (
                            user_object.get_string_member ("image_id"), user_object.get_string_member ("avatar_s640")
                        );

                        // Run Reminder server
                        Planner.notifications.init_server ();

                        // Run Todoisr Sync server
                        run_server ();

                        // To do: Create a tutorial project
                        Planner.utils.pane_project_selected (Planner.utils.create_tutorial_project ().id, 0);

                        first_sync_finished ();
                    } catch (Error e) {
                        debug (e.message);
                    }
                } else {
                    show_message ("Request page fail", @"status code: $(mess.status_code)", "dialog-error");
                }
            });

            return null;
        });
    }

    /*
    *   Sync
    */

    public void sync () {
        sync_started ();

        new Thread<void*> ("todoist_share_project", () => {
            string url = TODOIST_SYNC_URL;
            url = url + "?token=" + Planner.settings.get_string ("todoist-access-token");
            url = url + "&sync_token=" + Planner.settings.get_string ("todoist-sync-token");
            url = url + "&resource_types=" + "[\"all\"]";

            var message = new Soup.Message ("POST", url);

            session.queue_message (message, (sess, mess) => {
                if (mess.status_code == 200) {
                    var parser = new Json.Parser ();

                    try {
                        parser.load_from_data ((string) mess.response_body.flatten ().data, -1);

                        //  var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (
                        //      "This is a primary text",
                        //      "This is a secondary, multiline, long text. This text usually extends the primary text and prints e.g: the details of an error.",
                        //      "applications-development",
                        //      Gtk.ButtonsType.CLOSE
                        //  );
                        //  message_dialog.show_error_details ((string) mess.response_body.flatten ().data);

                        //  message_dialog.run ();
                        //  message_dialog.destroy ();

                        var node = parser.get_root ().get_object ();
                        var sync_token = node.get_string_member ("sync_token");

                        // Update sync token
                        Planner.settings.set_string ("todoist-sync-token", sync_token);

                        // Projects
                        unowned Json.Array projects_array = node.get_array_member ("projects");
                        foreach (unowned Json.Node item in projects_array.get_elements ()) {
                            var object = item.get_object ();

                            if (Planner.database.project_exists (object.get_int_member ("id"))) {
                                if (object.get_int_member ("is_deleted") == 1) {
                                    Planner.database.delete_project (object.get_int_member ("id"));
                                } else {
                                    var project = Planner.database.get_project_by_id (object.get_int_member ("id"));

                                    project.name = object.get_string_member ("name");
                                    project.color = (int32) object.get_int_member ("color");
                                    project.is_favorite = (int32) object.get_int_member ("is_favorite");

                                    if (object.get_null_member ("shared") == false &&
                                        object.get_boolean_member ("shared")) {
                                        project.shared = 1;
                                    } else {
                                        project.shared = 0;
                                    }

                                    Planner.database.update_project (project);
                                }
                            } else {
                                var p = new Objects.Project ();

                                p.id = object.get_int_member ("id");
                                p.name = object.get_string_member ("name");
                                p.color = (int32) object.get_int_member ("color");
                                p.is_deleted = (int32) object.get_int_member ("is_deleted");
                                p.is_archived = (int32) object.get_int_member ("is_archived");
                                p.is_favorite = (int32) object.get_int_member ("is_favorite");
                                p.is_todoist = 1;
                                p.is_sync = 1;

                                if (object.get_boolean_member ("team_inbox")) {
                                    p.team_inbox = 1;
                                } else {
                                    p.team_inbox = 0;
                                }

                                if (object.get_boolean_member ("inbox_project")) {
                                    p.inbox_project = 1;
                                } else {
                                    p.inbox_project = 0;
                                }

                                if (object.get_boolean_member ("shared")) {
                                    p.shared = 1;
                                } else {
                                    p.shared = 0;
                                }

                                Planner.database.insert_project (p);
                            }
                        }

                        // Sections
                        unowned Json.Array sections_array = node.get_array_member ("sections");
                        foreach (unowned Json.Node item in sections_array.get_elements ()) {
                            var object = item.get_object ();

                            if (Planner.database.section_exists (object.get_int_member ("id"))) {
                                var section = Planner.database.get_section_by_id (object.get_int_member ("id"));

                                if (object.get_boolean_member ("is_deleted") == true) {
                                    Planner.database.delete_section (section);
                                } else {
                                    if (object.get_int_member ("project_id") != section.project_id) {
                                        Planner.database.move_section (section, object.get_int_member ("project_id"));
                                    }

                                    section.name = object.get_string_member ("name");

                                    Planner.database.update_section (section);
                                }
                            } else {
                                var s = new Objects.Section ();

                                s.id = object.get_int_member ("id");
                                s.project_id = object.get_int_member ("project_id");
                                s.name = object.get_string_member ("name");
                                s.date_added = object.get_string_member ("date_added");
                                s.is_deleted = (int32) object.get_int_member ("is_deleted");
                                s.is_archived = (int32) object.get_int_member ("is_archived");
                                s.collapsed = 1;
                                s.is_todoist = 1;

                                if (object.get_null_member ("date_archived") == false) {
                                    s.date_archived = object.get_string_member ("date_archived");
                                }

                                if (object.get_null_member ("sync_id") == false) {
                                    s.sync_id = object.get_int_member ("sync_id");
                                }

                                Planner.database.insert_section (s);
                            }
                        }

                        // Items
                        unowned Json.Array items = node.get_array_member ("items");
                        foreach (unowned Json.Node item in items.get_elements ()) {
                            var object = item.get_object ();

                            if (Planner.database.item_exists (object.get_int_member ("id"))) {
                                var i = Planner.database.get_item_by_id (object.get_int_member ("id"));

                                if (object.get_boolean_member ("is_deleted") == true) {
                                    Planner.database.delete_item (i);
                                } else {
                                    if ((int32) object.get_int_member ("checked") != i.checked) {
                                        i.checked = (int32) object.get_int_member ("checked");
                                        Planner.database.update_item_completed (i);
                                    }

                                    // Update data
                                    i.content = object.get_string_member ("content");
                                    i.is_todoist = 1;
                                    i.priority = (int32) object.get_int_member ("priority");
                                    i.checked = (int32) object.get_int_member ("checked");
                                    Planner.database.update_item (i);

                                    // Update duedate
                                    string due_date = "";
                                    if (object.get_member ("due").get_node_type () == Json.NodeType.OBJECT) {
                                        due_date = Planner.utils.get_todoist_datetime (
                                            object.get_object_member ("due").get_string_member ("date")
                                        ).to_string ();

                                        if (object.get_object_member ("due").get_boolean_member ("is_recurring")) {
                                            i.due_is_recurring = 1;
                                        } else {
                                            i.due_is_recurring = 0;
                                        }

                                        i.due_string = object.get_object_member ("due").get_string_member ("string");
                                        i.due_lang = object.get_object_member ("due").get_string_member ("lang");
                                    }

                                    if (due_date != i.due_date) {
                                        bool new_date = false;
                                        if (due_date != "") {
                                            if (i.due_date == "") {
                                                new_date = true;
                                            }
                                        }

                                        i.due_date = due_date;
                                        Planner.database.set_due_item (i, new_date);
                                    }


                                    if (object.get_int_member ("project_id") != i.project_id) {
                                        Planner.database.move_item (i, object.get_int_member ("project_id"));
                                    }

                                    int64 section_id;
                                    if (object.get_null_member ("section_id")) {
                                        section_id = 0;
                                    } else {
                                        section_id = object.get_int_member ("section_id");
                                    }

                                    if (section_id != i.section_id) {
                                        Planner.database.move_item_section (i, section_id);
                                    }
                                }
                            } else {
                                var i = new Objects.Item ();

                                i.id = object.get_int_member ("id");
                                i.project_id = object.get_int_member ("project_id");
                                i.user_id = object.get_int_member ("user_id");
                                i.assigned_by_uid = object.get_int_member ("assigned_by_uid");
                                i.content = object.get_string_member ("content");
                                i.checked = (int32) object.get_int_member ("checked");
                                i.priority = (int32) object.get_int_member ("priority");
                                i.is_deleted = (int32) object.get_int_member ("is_deleted");
                                i.date_added = object.get_string_member ("date_added");
                                i.is_todoist = 1;

                                if (object.get_null_member ("sync_id") == false) {
                                    i.sync_id = object.get_int_member ("sync_id");
                                }

                                if (object.get_null_member ("responsible_uid") == false) {
                                    i.responsible_uid = object.get_int_member ("responsible_uid");
                                }

                                if (object.get_null_member ("section_id") == false) {
                                    i.section_id = object.get_int_member ("section_id");
                                }

                                if (object.get_null_member ("parent_id") == false) {
                                    i.parent_id = object.get_int_member ("parent_id");
                                }

                                if (object.get_null_member ("date_completed") == false) {
                                    i.date_completed = object.get_string_member ("date_completed");
                                }

                                if (object.get_member ("due").get_node_type () == Json.NodeType.OBJECT) {
                                    var due_object = object.get_object_member ("due");
                                    var datetime = Planner.utils.get_todoist_datetime (
                                        due_object.get_string_member ("date")
                                    );
                                    i.due_date = datetime.to_string ();

                                    if (object.get_null_member ("timezone") == false) {
                                        i.due_timezone = due_object.get_string_member ("timezone");
                                    }

                                    i.due_string = due_object.get_string_member ("string");
                                    i.due_lang = due_object.get_string_member ("lang");
                                    if (due_object.get_boolean_member ("is_recurring")) {
                                        i.due_is_recurring = 1;
                                    }
                                }

                                Planner.database.insert_item (i);
                            }
                        }

                        queue ();
                    } catch (Error e) {
                        debug (e.message);
                        sync_finished ();
                    }
                } else {
                    sync_finished ();

                    string msg = """
                        Request todoist fail
                        status code: %i
                    """;

                    print (msg.printf (mess.status_code));
                }
            });

            return null;
        });
    }

    /*
        Queue
    */

    public void queue () {
        new Thread<void*> ("todoist_share_project", () => {
            Gee.ArrayList<Objects.Queue?> queue = Planner.database.get_all_queue ();

            string url = "%s?token=%s&commands=%s".printf (
                TODOIST_SYNC_URL,
                Planner.settings.get_string ("todoist-access-token"),
                get_queue_json (queue)
            );

            var message = new Soup.Message ("POST", url);

            session.queue_message (message, (sess, mess) => {
                if (mess.status_code == 200) {
                    var parser = new Json.Parser ();

                    try {
                        parser.load_from_data ((string) mess.response_body.flatten ().data, -1);

                        var node = parser.get_root ().get_object ();
                        var sync_status = node.get_object_member ("sync_status");
                        string sync_token = node.get_string_member ("sync_token");
                        Planner.settings.set_string ("todoist-sync-token", sync_token);

                        foreach (var q in queue) {
                            var uuid_member = sync_status.get_member (q.uuid);
                            if (uuid_member.get_node_type () == Json.NodeType.VALUE) {
                                if (q.query == "project_add") {
                                    var id = node.get_object_member ("temp_id_mapping").get_int_member (q.temp_id);
                                    Planner.database.update_project_id (q.object_id, id);
                                    Planner.database.remove_CurTempIds (q.object_id);
                                }

                                if (q.query == "section_add") {
                                    var id = node.get_object_member ("temp_id_mapping").get_int_member (q.temp_id);
                                    Planner.database.update_section_id (q.object_id, id);
                                    Planner.database.remove_CurTempIds (q.object_id);
                                }

                                if (q.query == "item_add") {
                                    var id = node.get_object_member ("temp_id_mapping").get_int_member (q.temp_id);
                                    Planner.database.update_item_id (q.object_id, id);
                                    Planner.database.remove_CurTempIds (q.object_id);
                                }

                                Planner.database.remove_queue (q.uuid);
                            } else {
                                //var http_code = (int32) sync_status.get_object_member (uuid).get_int_member ("http_code");
                                //var error_message = sync_status.get_object_member (uuid).get_string_member ("error");
                                //project_added_error (http_code, error_message);
                            }
                        }

                        sync_finished ();
                    } catch (Error e) {
                        debug (e.message);
                        sync_finished ();
                    }
                } else {
                    sync_finished ();
                }
            });

            return null;
        });
    }

    public string get_queue_json (Gee.ArrayList<Objects.Queue?> queue) {
        var builder = new Json.Builder ();
        builder.begin_array ();
        foreach (var q in queue) {
            builder.begin_object ();

            if (q.query == "project_add") {
                builder.set_member_name ("type");
                builder.add_string_value ("project_add");

                builder.set_member_name ("temp_id");
                builder.add_string_value (q.temp_id);

                builder.set_member_name ("uuid");
                builder.add_string_value (q.uuid);

                builder.set_member_name ("args");
                    builder.begin_object ();

                    builder.set_member_name ("name");
                    builder.add_string_value (get_string_member_by_object (q.args, "name"));

                    builder.set_member_name ("color");
                    builder.add_int_value (get_int_member_by_object (q.args, "color"));

                    builder.end_object ();
                builder.end_object ();
            } else if (q.query == "project_update") {
                builder.set_member_name ("type");
                builder.add_string_value ("project_update");

                builder.set_member_name ("uuid");
                builder.add_string_value (q.uuid);

                builder.set_member_name ("args");
                    builder.begin_object ();
                    builder.set_member_name ("id");
                    builder.add_int_value (get_int_member_by_object (q.args, "id"));

                    builder.set_member_name ("name");
                    builder.add_string_value (get_string_member_by_object (q.args, "name"));

                    builder.set_member_name ("color");
                    builder.add_int_value (get_int_member_by_object (q.args, "color"));

                    builder.end_object ();
                builder.end_object ();
            } else if (q.query == "project_delete") {
                builder.set_member_name ("type");
                builder.add_string_value ("project_delete");

                builder.set_member_name ("uuid");
                builder.add_string_value (q.uuid);

                builder.set_member_name ("args");
                    builder.begin_object ();

                    builder.set_member_name ("id");
                    builder.add_int_value (get_int_member_by_object (q.args, "id"));

                    builder.end_object ();
                builder.end_object ();
            } else if (q.query == "section_add") {
                builder.set_member_name ("type");
                builder.add_string_value ("section_add");

                builder.set_member_name ("temp_id");
                builder.add_string_value (q.temp_id);

                builder.set_member_name ("uuid");
                builder.add_string_value (q.uuid);

                builder.set_member_name ("args");
                    builder.begin_object ();

                    builder.set_member_name ("name");
                    builder.add_string_value (get_string_member_by_object (q.args, "name"));

                    builder.set_member_name ("project_id");
                    if (get_type_by_member (q.args, "project_id") == GLib.Type.STRING) {
                        builder.add_string_value (get_string_member_by_object (q.args, "project_id"));
                    } else {
                        builder.add_int_value (get_int_member_by_object (q.args, "project_id"));
                    }

                    builder.end_object ();
                builder.end_object ();
            } else if (q.query == "section_update") {
                builder.set_member_name ("type");
                builder.add_string_value ("section_update");

                builder.set_member_name ("uuid");
                builder.add_string_value (q.uuid);

                builder.set_member_name ("args");
                    builder.begin_object ();
                    builder.set_member_name ("id");
                    builder.add_int_value (get_int_member_by_object (q.args, "id"));

                    builder.set_member_name ("name");
                    builder.add_string_value (get_string_member_by_object (q.args, "name"));

                    builder.end_object ();
                builder.end_object ();
            } else if (q.query == "section_delete") {
                builder.set_member_name ("type");
                builder.add_string_value ("section_delete");

                builder.set_member_name ("uuid");
                builder.add_string_value (q.uuid);

                builder.set_member_name ("args");
                    builder.begin_object ();

                    builder.set_member_name ("id");
                    builder.add_int_value (get_int_member_by_object (q.args, "id"));

                    builder.end_object ();
                builder.end_object ();
            } else if (q.query == "section_move") {
                builder.set_member_name ("type");
                builder.add_string_value ("section_move");

                builder.set_member_name ("uuid");
                builder.add_string_value (q.uuid);

                builder.set_member_name ("args");
                    builder.begin_object ();

                    builder.set_member_name ("id");
                    builder.add_int_value (get_int_member_by_object (q.args, "id"));

                    builder.set_member_name ("project_id");
                    if (get_type_by_member (q.args, "project_id") == GLib.Type.STRING) {
                        builder.add_string_value (get_string_member_by_object (q.args, "project_id"));
                    } else {
                        builder.add_int_value (get_int_member_by_object (q.args, "project_id"));
                    }

                    builder.end_object ();
                builder.end_object ();
            } else if (q.query == "item_add") {
                builder.set_member_name ("type");
                builder.add_string_value ("item_add");

                builder.set_member_name ("temp_id");
                builder.add_string_value (q.temp_id);

                builder.set_member_name ("uuid");
                builder.add_string_value (q.uuid);

                builder.set_member_name ("args");
                    builder.begin_object ();

                    builder.set_member_name ("content");
                    builder.add_string_value (get_string_member_by_object (q.args, "content"));

                    builder.set_member_name ("priority");
                    builder.add_int_value (get_int_member_by_object (q.args, "priority"));

                    builder.set_member_name ("project_id");
                    if (get_type_by_member (q.args, "project_id") == GLib.Type.STRING) {
                        builder.add_string_value (get_string_member_by_object (q.args, "project_id"));
                    } else {
                        builder.add_int_value (get_int_member_by_object (q.args, "project_id"));
                    }

                    if (get_type_by_member (q.args, "section_id") == GLib.Type.STRING) {
                        builder.set_member_name ("section_id");
                        builder.add_string_value (get_string_member_by_object (q.args, "section_id"));
                    } else {
                        if (get_int_member_by_object (q.args, "section_id") != 0) {
                            builder.set_member_name ("section_id");
                            builder.add_int_value (get_int_member_by_object (q.args, "section_id"));
                        }
                    }

                    if (get_type_by_member (q.args, "parent_id") == GLib.Type.STRING) {
                        builder.set_member_name ("parent_id");
                        builder.add_string_value (get_string_member_by_object (q.args, "parent_id"));
                    } else {
                        if (get_int_member_by_object (q.args, "parent_id") != 0) {
                            builder.set_member_name ("parent_id");
                            builder.add_int_value (get_int_member_by_object (q.args, "parent_id"));
                        }
                    }

                    builder.end_object ();
                builder.end_object ();
            } else if (q.query == "item_update") {
                builder.set_member_name ("type");
                builder.add_string_value ("item_update");

                builder.set_member_name ("uuid");
                builder.add_string_value (q.uuid);

                builder.set_member_name ("args");
                    builder.begin_object ();

                    builder.set_member_name ("id");
                    builder.add_int_value (get_int_member_by_object (q.args, "id"));

                    builder.set_member_name ("content");
                    builder.add_string_value (get_string_member_by_object (q.args, "content"));

                    if (get_string_member_by_object (q.args, "due_date") != "") {
                        builder.set_member_name ("due");
                        builder.begin_object ();

                        builder.set_member_name ("date");
                        builder.add_string_value (new GLib.DateTime.from_iso8601 (
                            get_string_member_by_object (q.args, "due_date"),
                            new GLib.TimeZone.local ()).format ("%F")
                        );

                        builder.end_object ();
                    } else {
                        builder.set_member_name ("due");
                        builder.add_null_value ();
                    }

                    builder.end_object ();
                builder.end_object ();
                builder.begin_object ();
            } else if (q.query == "item_delete") {
                builder.set_member_name ("type");
                builder.add_string_value ("item_delete");

                builder.set_member_name ("uuid");
                builder.add_string_value (q.uuid);

                builder.set_member_name ("args");
                    builder.begin_object ();

                    builder.set_member_name ("id");
                    builder.add_int_value (get_int_member_by_object (q.args, "id"));

                    builder.end_object ();
                builder.end_object ();
            } else if (q.query == "item_move") {
                builder.set_member_name ("type");
                builder.add_string_value ("item_move");

                builder.set_member_name ("uuid");
                builder.add_string_value (q.uuid);

                builder.set_member_name ("args");
                    builder.begin_object ();

                    builder.set_member_name ("id");
                    builder.add_int_value (get_int_member_by_object (q.args, "id"));

                    builder.set_member_name ("project_id");
                    builder.add_int_value (get_int_member_by_object (q.args, "project_id"));

                    builder.end_object ();
                builder.end_object ();
            } else if (q.query == "item_move_section") {
                builder.set_member_name ("type");
                builder.add_string_value ("item_move");

                builder.set_member_name ("uuid");
                builder.add_string_value (q.uuid);

                builder.set_member_name ("args");
                    builder.begin_object ();

                    builder.set_member_name ("id");
                    builder.add_int_value (get_int_member_by_object (q.args, "id"));

                    if (get_int_member_by_object (q.args, "section_id") == 0) {
                        builder.set_member_name ("project_id");
                        builder.add_int_value (get_int_member_by_object (q.args, "project_id"));
                    } else {
                        builder.set_member_name ("section_id");
                        builder.add_int_value (get_int_member_by_object (q.args, "section_id"));
                    }

                    builder.end_object ();
                builder.end_object ();
            } else if (q.query == "item_move_parent") {
                builder.set_member_name ("type");
                builder.add_string_value ("item_move");

                builder.set_member_name ("uuid");
                builder.add_string_value (q.uuid);

                builder.set_member_name ("args");
                    builder.begin_object ();

                    builder.set_member_name ("id");
                    builder.add_int_value (get_int_member_by_object (q.args, "id"));

                    builder.set_member_name ("parent_id");
                    builder.add_int_value (get_int_member_by_object (q.args, "parent_id"));

                    builder.end_object ();
                builder.end_object ();
            } else if (q.query == "item_complete") {
                builder.set_member_name ("type");
                builder.add_string_value ("item_complete");

                builder.set_member_name ("uuid");
                builder.add_string_value (q.uuid);

                builder.set_member_name ("args");
                    builder.begin_object ();

                    builder.set_member_name ("id");
                    builder.add_int_value (get_int_member_by_object (q.args, "id"));

                    builder.end_object ();
                builder.end_object ();
            } else if (q.query == "item_uncomplete") {
                builder.set_member_name ("type");
                builder.add_string_value ("item_uncomplete");

                builder.set_member_name ("uuid");
                builder.add_string_value (q.uuid);

                builder.set_member_name ("args");
                    builder.begin_object ();

                    builder.set_member_name ("id");
                    builder.add_int_value (get_int_member_by_object (q.args, "id"));

                    builder.end_object ();
                builder.end_object ();
            }

            builder.end_object ();
        }

        builder.end_array ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);

        return generator.to_data (null);
    }

    public Json.Object get_object_by_string (string object) {
        var parser = new Json.Parser ();

        try {
            parser.load_from_data (object, -1);
        } catch (Error e) {
            debug (e.message);
        }

        return parser.get_root ().get_object ();
    }

    public int64 get_int_member_by_object (string object, string member) {
        return get_object_by_string (object).get_int_member (member);
    }

    public string get_string_member_by_object (string object, string member) {
        return get_object_by_string (object).get_string_member (member);
    }

    public GLib.Type get_type_by_member (string object, string member) {
        return get_object_by_string (object).get_member (member).get_value_type ();
    }

    /*
    *   Collaborators
    */

    public void share_project (int64 project_id, string email) {
        new Thread<void*> ("todoist_share_project", () => {
            string temp_id = Planner.utils.generate_string ();
            string uuid = Planner.utils.generate_string ();

            string url = "%s?token=%s&commands=%s".printf (
                TODOIST_SYNC_URL,
                Planner.settings.get_string ("todoist-access-token"),
                get_share_project_json (project_id, email, temp_id, uuid)
            );

            var message = new Soup.Message ("POST", url);

            session.queue_message (message, (sess, mess) => {
                if (mess.status_code == 200) {
                    try {
                        var parser = new Json.Parser ();
                        parser.load_from_data ((string) mess.response_body.flatten ().data, -1);

                        var node = parser.get_root ().get_object ();

                        var sync_status = node.get_object_member ("sync_status");
                        var uuid_member = sync_status.get_member (uuid);

                        if (uuid_member.get_node_type () == Json.NodeType.VALUE) {
                            string sync_token = node.get_string_member ("sync_token");
                            Planner.settings.set_string ("todoist-sync-token", sync_token);


                        } else {
                            //var http_code = (int32) sync_status.get_object_member (uuid).get_int_member ("http_code");
                            //var error_message = sync_status.get_object_member (uuid).get_string_member ("error");

                            //project_added_error (http_code, error_message);
                        }
                    } catch (Error e) {
                        debug (e.message);
                    }
                } else {
                    //project_added_error ((int32) mess.status_code, _("Connection error"));
                }
            });

            return null;
        });
    }

    private string get_share_project_json (int64 project_id, string email, string temp_id, string uuid) {
        var builder = new Json.Builder ();
        builder.begin_array ();
        builder.begin_object ();

        builder.set_member_name ("type");
        builder.add_string_value ("share_project");

        builder.set_member_name ("temp_id");
        builder.add_string_value (temp_id);

        builder.set_member_name ("uuid");
        builder.add_string_value (uuid);

        builder.set_member_name ("args");
            builder.begin_object ();

            builder.set_member_name ("project_id");
            builder.add_int_value (project_id);

            builder.set_member_name ("email");
            builder.add_string_value (email);

            builder.end_object ();
        builder.end_object ();
        builder.end_array ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);

        return generator.to_data (null);
    }

    /*
    *   Projects
    */

    public void add_project (Objects.Project project) {
        project_added_started ();
        new Thread<void*> ("todoist_add_project", () => {
            string temp_id = Planner.utils.generate_string ();
            string uuid = Planner.utils.generate_string ();

            string url = "%s?token=%s&commands=%s".printf (
                TODOIST_SYNC_URL,
                Planner.settings.get_string ("todoist-access-token"),
                get_add_project_json (project, temp_id, uuid)
            );

            var message = new Soup.Message ("POST", url);
            session.queue_message (message, (sess, mess) => {
                if (mess.status_code == 200) {
                    var parser = new Json.Parser ();

                    try {
                        parser.load_from_data ((string) mess.response_body.flatten ().data, -1);

                        var node = parser.get_root ().get_object ();

                        var sync_status = node.get_object_member ("sync_status");
                        var uuid_member = sync_status.get_member (uuid);

                        if (uuid_member.get_node_type () == Json.NodeType.VALUE) {
                            string sync_token = node.get_string_member ("sync_token");
                            Planner.settings.set_string ("todoist-sync-token", sync_token);

                            project.id = node.get_object_member ("temp_id_mapping").get_int_member (temp_id);

                            if (Planner.database.insert_project (project)) {
                                project_added_completed ();
                            }
                        } else {
                            project_added_error (
                                (int32) sync_status.get_object_member (uuid).get_int_member ("http_code"),
                                sync_status.get_object_member (uuid).get_string_member ("error")
                            );
                        }
                    } catch (Error e) {
                        project_added_error (
                            (int32) mess.status_code,
                            e.message
                        );
                    }
                } else {
                    if ((int32) mess.status_code == 400 || (int32) mess.status_code == 401 ||
                        (int32) mess.status_code == 403 || (int32) mess.status_code == 404 ||
                        (int32) mess.status_code == 429 || (int32) mess.status_code == 500 ||
                        (int32) mess.status_code == 503) {
                        project_added_error (
                            (int32) mess.status_code,
                            Planner.utils.get_todoist_error ((int32) mess.status_code)
                        );
                    } else {
                        project.id = Planner.utils.generate_id ();

                        var queue = new Objects.Queue ();
                        queue.uuid = uuid;
                        queue.object_id = project.id;
                        queue.temp_id = temp_id;
                        queue.query = "project_add";
                        queue.args = project.to_json ();

                        if (Planner.database.insert_project (project) &&
                            Planner.database.insert_queue (queue) &&
                            Planner.database.insert_CurTempIds (project.id, temp_id, "project")) {
                            project_added_completed ();
                        }
                    }
                }
            });

            return null;
        });
    }

    public string get_add_project_json (Objects.Project project, string temp_id, string uuid) {
        var builder = new Json.Builder ();
        builder.begin_array ();
        builder.begin_object ();

        builder.set_member_name ("type");
        builder.add_string_value ("project_add");

        builder.set_member_name ("temp_id");
        builder.add_string_value (temp_id);

        builder.set_member_name ("uuid");
        builder.add_string_value (uuid);

        builder.set_member_name ("args");
            builder.begin_object ();

            builder.set_member_name ("name");
            builder.add_string_value (project.name);

            builder.set_member_name ("color");
            builder.add_int_value (project.color);

            builder.end_object ();
        builder.end_object ();
        builder.end_array ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);

        return generator.to_data (null);
    }

    public void update_project (Objects.Project project) {
        project_updated_started (project.id);

        new Thread<void*> ("todoist_update_project", () => {
            string uuid = Planner.utils.generate_string ();

            string url = "%s?token=%s&commands=%s".printf (
                TODOIST_SYNC_URL,
                Planner.settings.get_string ("todoist-access-token"),
                get_update_project_json (project, uuid)
            );

            var message = new Soup.Message ("POST", url);

            session.queue_message (message, (sess, mess) => {
                if (mess.status_code == 200) {
                    var parser = new Json.Parser ();

                    try {
                        parser.load_from_data ((string) mess.response_body.flatten ().data, -1);

                        var node = parser.get_root ().get_object ();

                        var sync_status = node.get_object_member ("sync_status");
                        var uuid_member = sync_status.get_member (uuid);

                        if (uuid_member.get_node_type () == Json.NodeType.VALUE) {
                            string sync_token = node.get_string_member ("sync_token");
                            Planner.settings.set_string ("todoist-sync-token", sync_token);
                            project_updated_completed (project.id);
                        } else {
                            project_updated_error (
                                project.id,
                                (int32) sync_status.get_object_member (uuid).get_int_member ("http_code"),
                                sync_status.get_object_member (uuid).get_string_member ("error")
                            );
                        }
                    } catch (Error e) {
                        project_updated_error (
                            project.id,
                            (int32) mess.status_code,
                            e.message
                        );
                    }
                } else {
                    if ((int32) mess.status_code == 400 || (int32) mess.status_code == 401 ||
                        (int32) mess.status_code == 403 || (int32) mess.status_code == 404 ||
                        (int32) mess.status_code == 429 || (int32) mess.status_code == 500 ||
                        (int32) mess.status_code == 503) {
                        project_updated_error (
                            project.id,
                            (int32) mess.status_code,
                            Planner.utils.get_todoist_error ((int32) mess.status_code)
                        );
                    } else {
                        if (Planner.database.curTempIds_exists (project.id)) {
                            var queue = Planner.database.get_queue_by_object_id (project.id);
                            queue.args = project.to_json ();
                            Planner.database.update_queue (queue);
                        } else {
                            var queue = new Objects.Queue ();
                            queue.uuid = uuid;
                            queue.object_id = project.id;
                            queue.query = "project_update";
                            queue.args = project.to_json ();

                            if (Planner.database.insert_queue (queue)) {
                                project_updated_completed (project.id);
                            }
                        }
                    }
                }
            });

            return null;
        });
    }

    private string get_update_project_json (Objects.Project project, string uuid) {
        var builder = new Json.Builder ();
        builder.begin_array ();
        builder.begin_object ();

        // Set type
        builder.set_member_name ("type");
        builder.add_string_value ("project_update");

        builder.set_member_name ("uuid");
        builder.add_string_value (uuid);

        builder.set_member_name ("args");
            builder.begin_object ();

            builder.set_member_name ("id");
            builder.add_int_value (project.id);

            builder.set_member_name ("name");
            builder.add_string_value (project.name);

            builder.set_member_name ("color");
            builder.add_int_value (project.color);

            builder.end_object ();
        builder.end_object ();
        builder.end_array ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);

        return generator.to_data (null);
    }

    public void delete_project (Objects.Project project) {
        project_deleted_started (project.id);

        new Thread<void*> ("todoist_delete_project", () => {
            string uuid = Planner.utils.generate_string ();

            string url = "%s?token=%s&commands=%s".printf (
                TODOIST_SYNC_URL,
                Planner.settings.get_string ("todoist-access-token"),
                get_delete_json (project.id, "project_delete", uuid)
            );

            var message = new Soup.Message ("POST", url);

            session.queue_message (message, (sess, mess) => {
                if (mess.status_code == 200) {
                    var parser = new Json.Parser ();

                    try {
                        parser.load_from_data ((string) mess.response_body.flatten ().data, -1);

                        var node = parser.get_root ().get_object ();

                        var sync_status = node.get_object_member ("sync_status");
                        var uuid_member = sync_status.get_member (uuid);

                        if (uuid_member.get_node_type () == Json.NodeType.VALUE) {
                            string sync_token = node.get_string_member ("sync_token");
                            Planner.settings.set_string ("todoist-sync-token", sync_token);
                            project_deleted_completed (project.id);
                        } else {
                            project_deleted_error (
                                project.id,
                                (int32) sync_status.get_object_member (uuid).get_int_member ("http_code"),
                                sync_status.get_object_member (uuid).get_string_member ("error")
                            );
                        }
                    } catch (Error e) {
                        project_deleted_error (
                            project.id,
                            (int32) mess.status_code,
                            e.message
                        );
                    }
                } else {
                    if ((int32) mess.status_code == 400 || (int32) mess.status_code == 401 ||
                        (int32) mess.status_code == 403 || (int32) mess.status_code == 404 ||
                        (int32) mess.status_code == 429 || (int32) mess.status_code == 500 ||
                        (int32) mess.status_code == 503) {
                        project_deleted_error (
                            project.id,
                            (int32) mess.status_code,
                            Planner.utils.get_todoist_error ((int32) mess.status_code)
                        );
                    } else {
                        if (Planner.database.curTempIds_exists (project.id)) {
                            var queue = Planner.database.get_queue_by_object_id (project.id);
                            Planner.database.remove_queue (queue.uuid);
                            Planner.database.remove_CurTempIds (project.id);
                        } else {
                            var queue = new Objects.Queue ();
                            queue.uuid = uuid;
                            queue.object_id = project.id;
                            queue.query = "project_delete";
                            queue.args = project.to_json ();

                            if (Planner.database.insert_queue (queue)) {
                                project_deleted_completed (project.id);
                            }
                        }
                    }
                }
            });

            return null;
        });
    }

    /*
        Sections
    */

    public void add_section (Objects.Section section, int64 temp_id_mapping) {
        section_added_started (temp_id_mapping);
        new Thread<void*> ("todoist_add_section", () => {
            string temp_id = Planner.utils.generate_string ();
            string uuid = Planner.utils.generate_string ();

            string url = "%s?token=%s&commands=%s".printf (
                TODOIST_SYNC_URL,
                Planner.settings.get_string ("todoist-access-token"),
                get_add_section_json (section, temp_id, uuid)
            );

            var message = new Soup.Message ("POST", url);

            session.queue_message (message, (sess, mess) => {
                if (mess.status_code == 200) {
                    try {
                        var parser = new Json.Parser ();
                        parser.load_from_data ((string) mess.response_body.flatten ().data, -1);

                        var node = parser.get_root ().get_object ();

                        var sync_status = node.get_object_member ("sync_status");
                        var uuid_member = sync_status.get_member (uuid);

                        if (uuid_member.get_node_type () == Json.NodeType.VALUE) {
                            string sync_token = node.get_string_member ("sync_token");
                            Planner.settings.set_string ("todoist-sync-token", sync_token);

                            section.id = node.get_object_member ("temp_id_mapping").get_int_member (temp_id);

                            if (Planner.database.insert_section (section)) {
                                section_added_completed (temp_id_mapping);
                            }
                        } else {
                            section_added_error (
                                temp_id_mapping,
                                (int32) sync_status.get_object_member (uuid).get_int_member ("http_code"),
                                sync_status.get_object_member (uuid).get_string_member ("error")
                            );
                        }
                    } catch (Error e) {
                        section_added_error (
                            temp_id_mapping,
                            (int32) mess.status_code,
                            e.message
                        );
                    }
                } else {
                    if ((int32) mess.status_code == 400 || (int32) mess.status_code == 401 ||
                        (int32) mess.status_code == 403 || (int32) mess.status_code == 404 ||
                        (int32) mess.status_code == 429 || (int32) mess.status_code == 500 ||
                        (int32) mess.status_code == 503) {
                        section_added_error (
                            temp_id_mapping,
                            (int32) mess.status_code,
                            Planner.utils.get_todoist_error ((int32) mess.status_code)
                        );
                    } else {
                        section.id = Planner.utils.generate_id ();

                        var queue = new Objects.Queue ();
                        queue.uuid = uuid;
                        queue.object_id = section.id;
                        queue.temp_id = temp_id;
                        queue.query = "section_add";
                        queue.args = section.to_json ();

                        if (Planner.database.insert_section (section) &&
                            Planner.database.insert_queue (queue) &&
                            Planner.database.insert_CurTempIds (section.id, temp_id, "section")) {
                            section_added_completed (temp_id_mapping);
                        }
                    }
                }
            });

            return null;
        });
    }

    public string get_add_section_json (Objects.Section section, string temp_id, string uuid) {
        var builder = new Json.Builder ();
        builder.begin_array ();
        builder.begin_object ();

        builder.set_member_name ("type");
        builder.add_string_value ("section_add");

        builder.set_member_name ("temp_id");
        builder.add_string_value (temp_id);

        builder.set_member_name ("uuid");
        builder.add_string_value (uuid);

        builder.set_member_name ("args");
            builder.begin_object ();

            builder.set_member_name ("name");
            builder.add_string_value (section.name);

            builder.set_member_name ("project_id");
            builder.add_int_value (section.project_id);

            builder.end_object ();
        builder.end_object ();
        builder.end_array ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);

        return generator.to_data (null);
    }

    public void update_section (Objects.Section section) {
        section_updated_started (section.id);

        new Thread<void*> ("todoist_update_project", () => {
            string uuid = Planner.utils.generate_string ();

            string url = "%s?token=%s&commands=%s".printf (
                TODOIST_SYNC_URL,
                Planner.settings.get_string ("todoist-access-token"),
                get_update_section_json (section, uuid)
            );

            var message = new Soup.Message ("POST", url);

            session.queue_message (message, (sess, mess) => {
                if (mess.status_code == 200) {
                    try {
                        var parser = new Json.Parser ();
                        parser.load_from_data ((string) mess.response_body.flatten ().data, -1);

                        var node = parser.get_root ().get_object ();

                        var sync_status = node.get_object_member ("sync_status");
                        var uuid_member = sync_status.get_member (uuid);

                        if (uuid_member.get_node_type () == Json.NodeType.VALUE) {
                            string sync_token = node.get_string_member ("sync_token");
                            Planner.settings.set_string ("todoist-sync-token", sync_token);
                            section_updated_completed (section.id);
                        } else {
                            section_updated_error (
                                section.id,
                                (int32) sync_status.get_object_member (uuid).get_int_member ("http_code"),
                                sync_status.get_object_member (uuid).get_string_member ("error")
                            );
                        }
                    } catch (Error e) {
                        section_updated_error (
                            section.id,
                            (int32) mess.status_code,
                            e.message
                        );
                    }
                } else {
                    if ((int32) mess.status_code == 400 || (int32) mess.status_code == 401 ||
                        (int32) mess.status_code == 403 || (int32) mess.status_code == 404 ||
                        (int32) mess.status_code == 429 || (int32) mess.status_code == 500 ||
                        (int32) mess.status_code == 503) {
                        section_updated_error (
                            section.id,
                            (int32) mess.status_code,
                            Planner.utils.get_todoist_error ((int32) mess.status_code)
                        );
                    } else {
                        if (Planner.database.curTempIds_exists (section.id)) {
                            var queue = Planner.database.get_queue_by_object_id (section.id);
                            queue.args = section.to_json ();
                            Planner.database.update_queue (queue);
                        } else {
                            var queue = new Objects.Queue ();
                            queue.uuid = uuid;
                            queue.object_id = section.id;
                            queue.query = "section_update";
                            queue.args = section.to_json ();

                            if (Planner.database.insert_queue (queue)) {
                                section_updated_completed (section.id);
                            }
                        }
                    }
                }
            });

            return null;
        });
    }

    private string get_update_section_json (Objects.Section section, string uuid) {
        var builder = new Json.Builder ();
        builder.begin_array ();
        builder.begin_object ();

        // Set type
        builder.set_member_name ("type");
        builder.add_string_value ("section_update");

        builder.set_member_name ("uuid");
        builder.add_string_value (uuid);

        builder.set_member_name ("args");
            builder.begin_object ();

            builder.set_member_name ("id");
            builder.add_int_value (section.id);

            builder.set_member_name ("name");
            builder.add_string_value (section.name);

            builder.end_object ();

        builder.end_object ();
        builder.end_array ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);

        return generator.to_data (null);
    }

    public void delete_section (Objects.Section section) {
        section_deleted_started (section.id);

        new Thread<void*> ("todoist_delete_section", () => {
            string uuid = Planner.utils.generate_string ();

            string url = "%s?token=%s&commands=%s".printf (
                TODOIST_SYNC_URL,
                Planner.settings.get_string ("todoist-access-token"),
                get_delete_json (section.id, "section_delete", uuid)
            );

            var message = new Soup.Message ("POST", url);

            session.queue_message (message, (sess, mess) => {
                if (mess.status_code == 200) {
                    try {
                        var parser = new Json.Parser ();
                        parser.load_from_data ((string) mess.response_body.flatten ().data, -1);

                        var node = parser.get_root ().get_object ();

                        var sync_status = node.get_object_member ("sync_status");
                        var uuid_member = sync_status.get_member (uuid);

                        if (uuid_member.get_node_type () == Json.NodeType.VALUE) {
                            string sync_token = node.get_string_member ("sync_token");
                            Planner.settings.set_string ("todoist-sync-token", sync_token);
                            section_deleted_completed (section.id);
                        } else {
                            section_deleted_error (
                                section.id,
                                (int32) sync_status.get_object_member (uuid).get_int_member ("http_code"),
                                sync_status.get_object_member (uuid).get_string_member ("error")
                            );
                        }
                    } catch (Error e) {
                        section_deleted_error (
                            section.id,
                            (int32) mess.status_code,
                            e.message
                        );
                    }
                } else {
                    if ((int32) mess.status_code == 400 || (int32) mess.status_code == 401 ||
                        (int32) mess.status_code == 403 || (int32) mess.status_code == 404 ||
                        (int32) mess.status_code == 429 || (int32) mess.status_code == 500 ||
                        (int32) mess.status_code == 503) {
                        section_deleted_error (
                            section.id,
                            (int32) mess.status_code,
                            Planner.utils.get_todoist_error ((int32) mess.status_code)
                        );
                    } else {
                        if (Planner.database.curTempIds_exists (section.id)) {
                            var queue = Planner.database.get_queue_by_object_id (section.id);
                            Planner.database.remove_queue (queue.uuid);
                            Planner.database.remove_CurTempIds (section.id);
                        } else {
                            var queue = new Objects.Queue ();
                            queue.uuid = uuid;
                            queue.object_id = section.id;
                            queue.query = "section_delete";
                            queue.args = section.to_json ();

                            if (Planner.database.insert_queue (queue)) {
                                section_deleted_completed (section.id);
                            }
                        }
                    }
                }
            });

            return null;
        });
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

    public void move_section (Objects.Section section, int64 id) {
        section_moved_started (section.id);

        new Thread<void*> ("todoist_move_section", () => {
            string uuid = Planner.utils.generate_string ();

            string url = "%s?token=%s&commands=%s".printf (
                TODOIST_SYNC_URL,
                Planner.settings.get_string ("todoist-access-token"),
                get_move_json (section.id, "section_move", id, uuid)
            );

            var message = new Soup.Message ("POST", url);

            session.queue_message (message, (sess, mess) => {
                if (mess.status_code == 200) {
                    try {
                        var parser = new Json.Parser ();
                        parser.load_from_data ((string) mess.response_body.flatten ().data, -1);

                        var node = parser.get_root ().get_object ();

                        var sync_status = node.get_object_member ("sync_status");
                        var uuid_member = sync_status.get_member (uuid);

                        if (uuid_member.get_node_type () == Json.NodeType.VALUE) {
                            string sync_token = node.get_string_member ("sync_token");
                            Planner.settings.set_string ("todoist-sync-token", sync_token);
                            section_moved_completed (section.id);
                        } else {
                            section_moved_error (
                                section.id,
                                (int32) sync_status.get_object_member (uuid).get_int_member ("http_code"),
                                sync_status.get_object_member (uuid).get_string_member ("error")
                            );
                        }
                    } catch (Error e) {
                        section_moved_error (
                            section.id,
                            (int32) mess.status_code,
                            e.message
                        );
                    }
                } else {
                    if ((int32) mess.status_code == 400 || (int32) mess.status_code == 401 ||
                        (int32) mess.status_code == 403 || (int32) mess.status_code == 404 ||
                        (int32) mess.status_code == 429 || (int32) mess.status_code == 500 ||
                        (int32) mess.status_code == 503) {
                        section_moved_error (
                            section.id,
                            (int32) mess.status_code,
                            Planner.utils.get_todoist_error ((int32) mess.status_code)
                        );
                    } else {
                        section.project_id = id;

                        var queue = new Objects.Queue ();
                        queue.uuid = uuid;
                        queue.object_id = section.id;
                        queue.query = "section_move";
                        queue.args = section.to_json ();

                        if (Planner.database.insert_queue (queue)) {
                            section_moved_completed (section.id);
                        }
                    }
                }
            });

            return null;
        });
    }

    public string get_move_json (int64 id, string type, int64 project_id, string uuid) {
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

            builder.set_member_name ("project_id");
            builder.add_int_value (project_id);

            builder.end_object ();

        builder.end_object ();
        builder.end_array ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);

        return generator.to_data (null);
    }

    /*
        Items
    */

    public void add_item (Objects.Item item, int index, int64 temp_id_mapping) {
        item_added_started (temp_id_mapping);
        new Thread<void*> ("todoist_add_project", () => {
            string temp_id = Planner.utils.generate_string ();
            string uuid = Planner.utils.generate_string ();

            string url = "%s?token=%s&commands=%s".printf (
                TODOIST_SYNC_URL,
                Planner.settings.get_string ("todoist-access-token"),
                get_add_item_json (item, temp_id, uuid)
            );

            var message = new Soup.Message ("POST", url);

            session.queue_message (message, (sess, mess) => {
                if (mess.status_code == 200) {
                    try {
                        var parser = new Json.Parser ();
                        parser.load_from_data ((string) mess.response_body.flatten ().data, -1);

                        var node = parser.get_root ().get_object ();

                        var sync_status = node.get_object_member ("sync_status");
                        var uuid_member = sync_status.get_member (uuid);

                        if (uuid_member.get_node_type () == Json.NodeType.VALUE) {
                            string sync_token = node.get_string_member ("sync_token");
                            Planner.settings.set_string ("todoist-sync-token", sync_token);

                            item.id = node.get_object_member ("temp_id_mapping").get_int_member (temp_id);

                            if (Planner.database.insert_item (item, index)) {
                                item_added_completed (temp_id_mapping);
                            }
                        } else {
                            item_added_error (
                                temp_id_mapping,
                                (int32) sync_status.get_object_member (uuid).get_int_member ("http_code"),
                                sync_status.get_object_member (uuid).get_string_member ("error")
                            );
                        }
                    } catch (Error e) {
                        item_added_error (
                            temp_id_mapping,
                            (int32) mess.status_code,
                            e.message
                        );
                    }
                } else {
                    if ((int32) mess.status_code == 400 || (int32) mess.status_code == 401 ||
                        (int32) mess.status_code == 403 || (int32) mess.status_code == 404 ||
                        (int32) mess.status_code == 429 || (int32) mess.status_code == 500 ||
                        (int32) mess.status_code == 503) {
                        item_added_error (
                            temp_id_mapping,
                            (int32) mess.status_code,
                            Planner.utils.get_todoist_error ((int32) mess.status_code)
                        );
                    } else {
                        item.id = temp_id_mapping;

                        var queue = new Objects.Queue ();
                        queue.uuid = uuid;
                        queue.object_id = item.id;
                        queue.temp_id = temp_id;
                        queue.query = "item_add";
                        queue.args = item.to_json ();

                        if (Planner.database.insert_item (item, index) &&
                            Planner.database.insert_queue (queue) &&
                            Planner.database.insert_CurTempIds (item.id, temp_id, "item")) {
                            item_added_completed (temp_id_mapping);
                        }
                    }
                }
            });

            return null;
        });
    }

    public string get_add_item_json (Objects.Item item, string temp_id, string uuid) {
        var builder = new Json.Builder ();
        builder.begin_array ();
        builder.begin_object ();

        builder.set_member_name ("type");
        builder.add_string_value ("item_add");

        builder.set_member_name ("temp_id");
        builder.add_string_value (temp_id);

        builder.set_member_name ("uuid");
        builder.add_string_value (uuid);

        builder.set_member_name ("args");
            builder.begin_object ();

            builder.set_member_name ("content");
            builder.add_string_value (item.content);

            builder.set_member_name ("project_id");
            builder.add_int_value (item.project_id);

            if (item.parent_id != 0) {
                builder.set_member_name ("parent_id");
                builder.add_int_value (item.parent_id);
            }

            if (item.section_id != 0) {
                builder.set_member_name ("section_id");
                builder.add_int_value (item.section_id);
            }

            if (item.due_date != "") {
                builder.set_member_name ("due");
                builder.begin_object ();

                builder.set_member_name ("date");
                builder.add_string_value (new GLib.DateTime.from_iso8601 (
                    item.due_date,
                    new GLib.TimeZone.local ()).format ("%F")
                );

                builder.end_object ();
            }

            builder.end_object ();
        builder.end_object ();
        builder.end_array ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);

        return generator.to_data (null);
    }

    public void update_item (Objects.Item item) {
        item_updated_started (item.id);

        new Thread<void*> ("todoist_update_item", () => {
            string uuid = Planner.utils.generate_string ();

            string url = "%s?token=%s&commands=%s".printf (
                TODOIST_SYNC_URL,
                Planner.settings.get_string ("todoist-access-token"),
                get_update_item_json (item, uuid)
            );

            var message = new Soup.Message ("POST", url);

            session.queue_message (message, (sess, mess) => {
                if (mess.status_code == 200) {
                    try {
                        var parser = new Json.Parser ();
                        parser.load_from_data ((string) mess.response_body.flatten ().data, -1);

                        var node = parser.get_root ().get_object ();

                        var sync_status = node.get_object_member ("sync_status");
                        var uuid_member = sync_status.get_member (uuid);

                        if (uuid_member.get_node_type () == Json.NodeType.VALUE) {
                            string sync_token = node.get_string_member ("sync_token");
                            Planner.settings.set_string ("todoist-sync-token", sync_token);
                            item_updated_completed (item.id);
                        } else {
                            item_updated_error (
                                item.id,
                                (int32) sync_status.get_object_member (uuid).get_int_member ("http_code"),
                                sync_status.get_object_member (uuid).get_string_member ("error")
                            );
                        }
                    } catch (Error e) {
                        item_updated_error (
                            item.id,
                            (int32) mess.status_code,
                            e.message
                        );
                    }
                } else {
                    if ((int32) mess.status_code == 400 || (int32) mess.status_code == 401 ||
                        (int32) mess.status_code == 403 || (int32) mess.status_code == 404 ||
                        (int32) mess.status_code == 429 || (int32) mess.status_code == 500 ||
                        (int32) mess.status_code == 503) {
                        item_added_error (
                            item.id,
                            (int32) mess.status_code,
                            Planner.utils.get_todoist_error ((int32) mess.status_code)
                        );
                    } else {
                        if (Planner.database.curTempIds_exists (item.id)) {
                            var queue = Planner.database.get_queue_by_object_id (item.id);
                            queue.args = item.to_json ();
                            Planner.database.update_queue (queue);
                        } else {
                            var queue = new Objects.Queue ();
                            queue.uuid = uuid;
                            queue.object_id = item.id;
                            queue.query = "item_update";
                            queue.args = item.to_json ();

                            if (Planner.database.insert_queue (queue)) {
                                item_updated_completed (item.id);
                            }
                        }
                    }
                }
            });

            return null;
        });
    }

    public void move_item (Objects.Item item, int64 project_id) {
        item_moved_started (item.id);

        new Thread<void*> ("todoist_move_item", () => {
            string uuid = Planner.utils.generate_string ();

            string url = "%s?token=%s&commands=%s".printf (
                TODOIST_SYNC_URL,
                Planner.settings.get_string ("todoist-access-token"),
                get_move_json (item.id, "item_move", project_id, uuid)
            );

            var message = new Soup.Message ("POST", url);

            session.queue_message (message, (sess, mess) => {
                if (mess.status_code == 200) {
                    try {
                        var parser = new Json.Parser ();
                        parser.load_from_data ((string) mess.response_body.flatten ().data, -1);

                        var node = parser.get_root ().get_object ();

                        var sync_status = node.get_object_member ("sync_status");
                        var uuid_member = sync_status.get_member (uuid);

                        if (uuid_member.get_node_type () == Json.NodeType.VALUE) {
                            string sync_token = node.get_string_member ("sync_token");
                            Planner.settings.set_string ("todoist-sync-token", sync_token);
                            item_moved_completed (item.id);
                        } else {
                            item_moved_error (
                                item.id,
                                (int32) sync_status.get_object_member (uuid).get_int_member ("http_code"),
                                sync_status.get_object_member (uuid).get_string_member ("error")
                            );
                        }
                    } catch (Error e) {
                        item_moved_error (
                            item.id,
                            (int32) mess.status_code,
                            e.message
                        );
                    }
                } else {
                    if ((int32) mess.status_code == 400 || (int32) mess.status_code == 401 ||
                        (int32) mess.status_code == 403 || (int32) mess.status_code == 404 ||
                        (int32) mess.status_code == 429 || (int32) mess.status_code == 500 ||
                        (int32) mess.status_code == 503) {
                        item_moved_error (
                            item.id,
                            (int32) mess.status_code,
                            Planner.utils.get_todoist_error ((int32) mess.status_code)
                        );
                    } else {
                        item.project_id = project_id;

                        var queue = new Objects.Queue ();
                        queue.uuid = uuid;
                        queue.object_id = item.id;
                        queue.query = "item_move";
                        queue.args = item.to_json ();

                        if (Planner.database.insert_queue (queue)) {
                            item_moved_completed (item.id);
                        }
                    }
                }
            });

            return null;
        });
    }

    private string get_update_item_json (Objects.Item item, string uuid) {
        var builder = new Json.Builder ();
        builder.begin_array ();
        builder.begin_object ();

        // Set type
        builder.set_member_name ("type");
        builder.add_string_value ("item_update");

        builder.set_member_name ("uuid");
        builder.add_string_value (uuid);

        builder.set_member_name ("args");
            builder.begin_object ();

            builder.set_member_name ("id");
            builder.add_int_value (item.id);

            builder.set_member_name ("content");
            builder.add_string_value (item.content);

            builder.set_member_name ("priority");
            if (item.priority == 0) {
                builder.add_int_value (1);
            } else {
                builder.add_int_value (item.priority);
            }

            if (item.due_date != "") {
                builder.set_member_name ("due");
                builder.begin_object ();

                builder.set_member_name ("date");
                builder.add_string_value (
                    new GLib.DateTime.from_iso8601 (
                        item.due_date,
                        new GLib.TimeZone.local ()
                    ).format ("%F")
                );

                builder.set_member_name ("is_recurring");
                if (item.due_is_recurring == 0) {
                    builder.add_boolean_value (false);
                } else {
                    builder.add_boolean_value (true);
                }

                builder.set_member_name ("string");
                builder.add_string_value (item.due_string);

                builder.set_member_name ("lang");
                builder.add_string_value (item.due_lang);

                builder.end_object ();
            } else {
                builder.set_member_name ("due");
                builder.add_null_value ();
            }

            builder.end_object ();
        builder.end_object ();
        builder.end_array ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);

        return generator.to_data (null);
    }

    public void move_item_to_section (Objects.Item item, int64 section_id) {
        item_moved_started (item.id);

        new Thread<void*> ("todoist_move_item_to_section", () => {
            string uuid = Planner.utils.generate_string ();

            string url = "%s?token=%s&commands=%s".printf (
                TODOIST_SYNC_URL,
                Planner.settings.get_string ("todoist-access-token"),
                get_move_section_json (item, section_id, uuid)
            );

            var message = new Soup.Message ("POST", url);

            session.queue_message (message, (sess, mess) => {
                if (mess.status_code == 200) {
                    try {
                        var parser = new Json.Parser ();
                        parser.load_from_data ((string) mess.response_body.flatten ().data, -1);

                        var node = parser.get_root ().get_object ();

                        var sync_status = node.get_object_member ("sync_status");
                        var uuid_member = sync_status.get_member (uuid);

                        if (uuid_member.get_node_type () == Json.NodeType.VALUE) {
                            Planner.settings.set_string (
                                "todoist-sync-token",
                                node.get_string_member ("sync_token")
                            );
                            item_moved_completed (item.id);
                        } else {
                            item_moved_error (
                                item.id,
                                (int32) sync_status.get_object_member (uuid).get_int_member ("http_code"),
                                sync_status.get_object_member (uuid).get_string_member ("error")
                            );
                        }
                    } catch (Error e) {
                        item_moved_error (
                            item.id,
                            (int32) mess.status_code,
                            e.message
                        );
                    }
                } else {
                    if ((int32) mess.status_code == 400 || (int32) mess.status_code == 401 ||
                        (int32) mess.status_code == 403 || (int32) mess.status_code == 404 ||
                        (int32) mess.status_code == 429 || (int32) mess.status_code == 500 ||
                        (int32) mess.status_code == 503) {
                        item_moved_error (
                            item.id,
                            (int32) mess.status_code,
                            Planner.utils.get_todoist_error ((int32) mess.status_code)
                        );
                    } else {
                        item.section_id = section_id;

                        var queue = new Objects.Queue ();
                        queue.uuid = uuid;
                        queue.object_id = item.id;
                        queue.query = "item_move_section";
                        queue.args = item.to_json ();

                        if (Planner.database.insert_queue (queue)) {
                            item_moved_completed (item.id);
                        }
                    }
                }
            });

            return null;
        });
    }

    public string get_move_section_json (Objects.Item item, int64 section_id, string uuid) {
        var builder = new Json.Builder ();
        builder.begin_array ();
        builder.begin_object ();

        // Set type
        builder.set_member_name ("type");
        builder.add_string_value ("item_move");

        builder.set_member_name ("uuid");
        builder.add_string_value (uuid);

        builder.set_member_name ("args");
            builder.begin_object ();

            builder.set_member_name ("id");
            builder.add_int_value (item.id);

            if (section_id == 0) {
                builder.set_member_name ("project_id");
                builder.add_int_value (item.project_id);
            } else {
                builder.set_member_name ("section_id");
                builder.add_int_value (section_id);
            }

            builder.end_object ();

        builder.end_object ();
        builder.end_array ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);

        return generator.to_data (null);
    }

    public void move_item_to_parent (Objects.Item item, int64 parent_id) {
        item_moved_started (item.id);

        new Thread<void*> ("move_item_to_parent", () => {
            string uuid = Planner.utils.generate_string ();

            string url = "%s?token=%s&commands=%s".printf (
                TODOIST_SYNC_URL,
                Planner.settings.get_string ("todoist-access-token"),
                get_move_parent_json (item, parent_id, uuid)
            );

            var message = new Soup.Message ("POST", url);

            session.queue_message (message, (sess, mess) => {
                if (mess.status_code == 200) {
                    try {
                        var parser = new Json.Parser ();
                        parser.load_from_data ((string) mess.response_body.flatten ().data, -1);

                        var node = parser.get_root ().get_object ();

                        var sync_status = node.get_object_member ("sync_status");
                        var uuid_member = sync_status.get_member (uuid);

                        if (uuid_member.get_node_type () == Json.NodeType.VALUE) {
                            Planner.settings.set_string (
                                "todoist-sync-token",
                                node.get_string_member ("sync_token")
                            );
                            item_moved_completed (item.id);
                        } else {
                            item_moved_error (
                                item.id,
                                (int32) sync_status.get_object_member (uuid).get_int_member ("http_code"),
                                sync_status.get_object_member (uuid).get_string_member ("error")
                            );
                        }
                    } catch (Error e) {
                        item_moved_error (
                            item.id,
                            (int32) mess.status_code,
                            e.message
                        );
                    }
                } else {
                    if ((int32) mess.status_code == 400 || (int32) mess.status_code == 401 ||
                        (int32) mess.status_code == 403 || (int32) mess.status_code == 404 ||
                        (int32) mess.status_code == 429 || (int32) mess.status_code == 500 ||
                        (int32) mess.status_code == 503) {
                        item_moved_error (
                            item.id,
                            (int32) mess.status_code,
                            Planner.utils.get_todoist_error ((int32) mess.status_code)
                        );
                    } else {
                        item.parent_id = parent_id;

                        var queue = new Objects.Queue ();
                        queue.uuid = uuid;
                        queue.object_id = item.id;
                        queue.query = "item_move_parent";
                        queue.args = item.to_json ();

                        if (Planner.database.insert_queue (queue)) {
                            if (Planner.database.insert_queue (queue)) {
                                item_moved_completed (item.id);
                            }
                        }
                    }
                }
            });

            return null;
        });
    }

    public string get_move_parent_json (Objects.Item item, int64 parent_id, string uuid) {
        var builder = new Json.Builder ();
        builder.begin_array ();
        builder.begin_object ();

        // Set type
        builder.set_member_name ("type");
        builder.add_string_value ("item_move");

        builder.set_member_name ("uuid");
        builder.add_string_value (uuid);

        builder.set_member_name ("args");
            builder.begin_object ();

            builder.set_member_name ("id");
            builder.add_int_value (item.id);

            builder.set_member_name ("parent_id");
            builder.add_int_value (item.parent_id);

            builder.end_object ();

        builder.end_object ();
        builder.end_array ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);

        return generator.to_data (null);
    }

    public bool add_delete_item (Objects.Item item) {
        if (delete_timeout != 0) {
            Source.remove (delete_timeout);
            delete_timeout = 0;
        }

        delete_timeout = Timeout.add (1000, () => {
            delete_items ();

            Source.remove (delete_timeout);
            delete_timeout = 0;

            return false;
        });

        return items_to_delete.add (item);
    }

    private void delete_items () {
        new Thread<void*> ("todoist_delete_items", () => {
            string url = "%s?token=%s&commands=%s".printf (
                TODOIST_SYNC_URL,
                Planner.settings.get_string ("todoist-access-token"),
                get_delete_items_json ()
            );

            var message = new Soup.Message ("POST", url);

            session.queue_message (message, (sess, mess) => {
                if (mess.status_code == 200) {
                    try {
                        var parser = new Json.Parser ();
                        parser.load_from_data ((string) mess.response_body.flatten ().data, -1);

                        var node = parser.get_root ().get_object ();

                        string sync_token = node.get_string_member ("sync_token");
                        Planner.settings.set_string ("todoist-sync-token", sync_token);
                        items_to_delete.clear ();
                    } catch (Error e) {
                        debug (e.message);
                    }
                } else {
                    if ((int32) mess.status_code == 400 || (int32) mess.status_code == 401 ||
                        (int32) mess.status_code == 403 || (int32) mess.status_code == 404 ||
                        (int32) mess.status_code == 429 || (int32) mess.status_code == 500 ||
                        (int32) mess.status_code == 503) {
                        //  item_moved_error (
                        //      item.id,
                        //      (int32) mess.status_code,
                        //      Planner.utils.get_todoist_error ((int32) mess.status_code)
                        //  );
                    } else {
                        foreach (var i in items_to_delete) {
                            if (Planner.database.curTempIds_exists (i.id)) {
                                var queue = Planner.database.get_queue_by_object_id (i.id);
                                Planner.database.remove_queue (queue.uuid);
                                Planner.database.remove_CurTempIds (i.id);
                            } else {
                                var queue = new Objects.Queue ();
                                queue.uuid = Planner.utils.generate_string ();
                                queue.object_id = i.id;
                                queue.query = "item_delete";
                                queue.args = i.to_json ();

                                if (Planner.database.insert_queue (queue)) {
                                }
                            }
                        }

                        items_to_delete.clear ();
                    }
                }
            });

            return null;
        });
    }

    private string get_delete_items_json () {
        var builder = new Json.Builder ();
        builder.begin_array ();

        foreach (var i in items_to_delete) {
            builder.begin_object ();
            builder.set_member_name ("type");
            builder.add_string_value ("item_delete");

            builder.set_member_name ("uuid");
            builder.add_string_value (Planner.utils.generate_string ());

            builder.set_member_name ("args");
                builder.begin_object ();

                builder.set_member_name ("id");
                builder.add_int_value (i.id);

                builder.end_object ();
            builder.end_object ();
        }

        builder.end_array ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);

        return generator.to_data (null);
    }

    public void item_uncomplete (Objects.Item item) {
        item_uncompleted_started (item);

        new Thread<void*> ("todoist_item_uncomplete", () => {
            string uuid = Planner.utils.generate_string ();

            string url = "%s?token=%s&commands=%s".printf (
                TODOIST_SYNC_URL,
                Planner.settings.get_string ("todoist-access-token"),
                get_checked_item_json (item, uuid, "item_uncomplete")
            );

            var message = new Soup.Message ("POST", url);

            session.queue_message (message, (sess, mess) => {
                if (mess.status_code == 200) {
                    try {
                        var parser = new Json.Parser ();
                        parser.load_from_data ((string) mess.response_body.flatten ().data, -1);

                        var node = parser.get_root ().get_object ();

                        var sync_status = node.get_object_member ("sync_status");
                        var uuid_member = sync_status.get_member (uuid);

                        if (uuid_member.get_node_type () == Json.NodeType.VALUE) {
                            string sync_token = node.get_string_member ("sync_token");
                            Planner.settings.set_string ("todoist-sync-token", sync_token);
                            item_uncompleted_completed (item);
                        } else {
                            item_uncompleted_error (
                                item,
                                (int32) sync_status.get_object_member (uuid).get_int_member ("http_code"),
                                sync_status.get_object_member (uuid).get_string_member ("error")
                            );
                        }
                    } catch (Error e) {
                        item_uncompleted_error (
                            item,
                            (int32) mess.status_code,
                            e.message
                        );
                    }
                } else {
                    if ((int32) mess.status_code == 400 || (int32) mess.status_code == 401 ||
                        (int32) mess.status_code == 403 || (int32) mess.status_code == 404 ||
                        (int32) mess.status_code == 429 || (int32) mess.status_code == 500 ||
                        (int32) mess.status_code == 503) {
                        item_uncompleted_error (
                            item,
                            (int32) mess.status_code,
                            Planner.utils.get_todoist_error ((int32) mess.status_code)
                        );
                    } else {
                        var queue = new Objects.Queue ();
                        queue.uuid = uuid;
                        queue.object_id = item.id;
                        queue.query = "item_uncomplete";
                        queue.args = item.to_json ();

                        if (Planner.database.insert_queue (queue)) {
                            item_uncompleted_completed (item);
                        }
                    }
                }
            });

            return null;
        });
    }

    private string get_checked_item_json (Objects.Item item, string uuid, string type) {
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
            builder.add_int_value (item.id);

            builder.end_object ();
        builder.end_object ();
        builder.end_array ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);

        return generator.to_data (null);
    }

    public void item_complete (Objects.Item item) {
        item_completed_started (item);

        new Thread<void*> ("todoist_item_complete", () => {
            string uuid = Planner.utils.generate_string ();

            string url = "%s?token=%s&commands=%s".printf (
                TODOIST_SYNC_URL,
                Planner.settings.get_string ("todoist-access-token"),
                get_checked_item_json (item, uuid, "item_complete")
            );

            var message = new Soup.Message ("POST", url);

            session.queue_message (message, (sess, mess) => {
                if (mess.status_code == 200) {
                    try {
                        var parser = new Json.Parser ();
                        parser.load_from_data ((string) mess.response_body.flatten ().data, -1);

                        print ("%s\n".printf ((string) mess.response_body.flatten ().data));

                        var node = parser.get_root ().get_object ();

                        var sync_status = node.get_object_member ("sync_status");
                        var uuid_member = sync_status.get_member (uuid);

                        if (uuid_member.get_node_type () == Json.NodeType.VALUE) {
                            string sync_token = node.get_string_member ("sync_token");
                            Planner.settings.set_string ("todoist-sync-token", sync_token);
                            item_completed_completed (item);
                        } else {
                            item_completed_error (
                                item,
                                (int32) sync_status.get_object_member (uuid).get_int_member ("http_code"),
                                sync_status.get_object_member (uuid).get_string_member ("error")
                            );
                        }
                    } catch (Error e) {
                        item_completed_error (
                            item,
                            (int32) mess.status_code,
                            e.message
                        );
                    }
                } else {
                    if ((int32) mess.status_code == 400 || (int32) mess.status_code == 401 ||
                        (int32) mess.status_code == 403 || (int32) mess.status_code == 404 ||
                        (int32) mess.status_code == 429 || (int32) mess.status_code == 500 ||
                        (int32) mess.status_code == 503) {
                        item_completed_error (
                            item,
                            (int32) mess.status_code,
                            Planner.utils.get_todoist_error ((int32) mess.status_code)
                        );
                    } else {
                        var queue = new Objects.Queue ();
                        queue.uuid = uuid;
                        queue.object_id = item.id;
                        queue.query = "item_complete";
                        queue.args = item.to_json ();

                        if (Planner.database.insert_queue (queue)) {
                            item_completed_completed (item);
                        }
                    }
                }
            });

            return null;
        });
    }

    private void show_message (string txt_primary, string txt_secondary, string icon) {
        var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (
            txt_primary,
            txt_secondary,
            icon,
            Gtk.ButtonsType.CLOSE
        );

        message_dialog.run ();
        message_dialog.destroy ();
    }
}
