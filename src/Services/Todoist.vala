/*
* Copyright © 2019 Alain M. (https://github.com/alainm23/planner)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
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
* Authored by: Alain M. <alain23@protonmail.com>
*/

public class Services.Todoist : GLib.Object {
    private Soup.Session session;
    private const string TODOIST_SYNC_URL = "https://todoist.com/api/v8/sync";
    
    public signal void sync_finished ();
    public signal void project_added ();
    public signal void project_updated (Objects.Project project);
    public signal void project_deleted (int64 id);
    public Todoist () {
        session = new Soup.Session ();
    }

    public void get_todoist_token (string url) {
        try {
            string code = url.split ("=") [2];
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

            first_sync (token);
        } catch (Error e) {
            debug (e.message);
        }
    }

    public void first_sync (string token) {
        string url = TODOIST_SYNC_URL;
        url = url + "?token=" + token;
        url = url + "&sync_token=" + "*";
        url = url + "&resource_types=" + "[\"all\"]";;

        var message = new Soup.Message ("POST", url);
        session.queue_message (message, (sess, mess) => {
            if (mess.status_code == 200) {
                var parser = new Json.Parser ();
                
                try {
                    parser.load_from_data ((string) mess.response_body.flatten ().data, -1);
                    
                    var node = parser.get_root ().get_object ();

                    // Create user
                    var todoist_user = node.get_object_member ("user");

                    var user = new Objects.User ();
                    user.id = todoist_user.get_int_member ("id");
                    user.full_name = todoist_user.get_string_member ("full_name");
                    user.email = todoist_user.get_string_member ("email");
                    user.todoist_token = token;
                    user.github_token = "";
                    user.sync_token = node.get_string_member ("sync_token");
                    user.is_todoist = true;
                    user.join_date = todoist_user.get_string_member ("join_date");
                    user.inbox_project = todoist_user.get_int_member ("inbox_project");
                    user.avatar = todoist_user.get_string_member ("avatar_s640");
                    user.is_premium = todoist_user.get_boolean_member ("is_premium");
                    
                    // Download Avatar
                    download_profile_image (user.id.to_string (), user.avatar);
                    
                    if (Application.database_v2.create_user (user)) {
                        Application.user = user;
                        
                        // Create projects
                        unowned Json.Array array = node.get_array_member ("projects");

                        foreach (unowned Json.Node item in array.get_elements ()) {
                            var object = item.get_object();

                            var project = new Objects.Project ();

                            project.id = object.get_int_member ("id");
                            project.name = object.get_string_member ("name");
                            project.color = (int32) object.get_int_member ("color");
                            project.team_inbox = object.get_boolean_member ("team_inbox");
                            project.inbox_project = object.get_boolean_member ("inbox_project");
                            project.child_order = (int32) object.get_int_member ("child_order");
                            project.is_deleted = (int32) object.get_int_member ("is_deleted");
                            project.is_archived = (int32) object.get_int_member ("is_archived");
                            project.is_favorite = (int32) object.get_int_member ("is_favorite");
                            project.is_todoist = true;

                            Application.database_v2.add_project (project);
                        }

                        sync_finished ();
                    }

                } catch (Error e) {
                    show_message("Request page fail", e.message, "dialog-error");
                }
            } else {
                show_message("Request page fail", @"status code: $(mess.status_code)", "dialog-error");
            }
        });
    }

    public void download_profile_image (string id, string avatar) {
        // Create file
        var image_path = GLib.Path.build_filename (Application.utils.PROFILE_FOLDER, ("avatar-%s.jpg").printf (id));

        var file_path = File.new_for_path (image_path);
        var file_from_uri = File.new_for_uri (avatar);
        if (file_path.query_exists () == false) {
            MainLoop loop = new MainLoop ();

            file_from_uri.copy_async.begin (file_path, 0, Priority.DEFAULT, null, (current_num_bytes, total_num_bytes) => {
                // Report copy-status:
                print ("%" + int64.FORMAT + " bytes of %" + int64.FORMAT + " bytes copied.\n", current_num_bytes, total_num_bytes);
            }, (obj, res) => {
                try {
                    if (file_from_uri.copy_async.end (res)) {
                        print ("Avatar Profile Downloaded\n");
                    }
                } catch (Error e) {
                    print ("Error: %s\n", e.message);
                }

                loop.quit ();
            });

            loop.run ();
        }
    }

    public void add_project (Objects.Project project) {
        new Thread<void*> ("todoist_add_project", () => {
            string temp_id = Application.utils.generate_string ();
            string uuid = Application.utils.generate_string ();

            string url = "%s?token=%s&commands=%s".printf (
                TODOIST_SYNC_URL, 
                Application.user.todoist_token,
                get_add_project_json (project, temp_id, uuid)
            );

            var message = new Soup.Message ("POST", url);

            session.queue_message (message, (sess, mess) => {
                if (mess.status_code == 200) {
                    try {
                        var parser = new Json.Parser ();
                        parser.load_from_data ((string) mess.response_body.flatten ().data, -1);

                        var node = parser.get_root ().get_object ();

                        string sync_token = node.get_string_member ("sync_token");

                        var temp_id_mapping = node.get_object_member ("temp_id_mapping");
                        project.id = temp_id_mapping.get_int_member (temp_id);

                        print ("sync_token:" + sync_token + "\n");
                        print ("Color:" + project.color.to_string () + "\n");
                        
                        if (Application.database_v2.add_project (project)) {
                            project_added ();
                        }
                        //Application.user.sync_token = sync_token;
                        //Application.database.update_sync_token (Application.user);

                        //Application.database.add_project (project);
                    } catch (Error e) {
                        show_message("Request page fail", e.message, "dialog-error");
                    }
                } else {
                    show_message("Request page fail", @"status code: $(mess.status_code)", "dialog-error");
                }
            });
            return null;
        });
    }

    public string get_add_project_json (Objects.Project project, string temp_id, string uuid) {
        var builder = new Json.Builder ();
        builder.begin_array ();
        builder.begin_object ();
        
        // Set type
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
        new Thread<void*> ("todoist_update_project", () => {
            string uuid = Application.utils.generate_string ();

            string url = "%s?token=%s&commands=%s".printf (
                TODOIST_SYNC_URL, 
                Application.user.todoist_token,
                get_update_project_json (project, uuid)
            );

            var message = new Soup.Message ("POST", url);

            session.queue_message (message, (sess, mess) => {
                if (mess.status_code == 200) {
                    try {
                        var parser = new Json.Parser ();
                        parser.load_from_data ((string) mess.response_body.flatten ().data, -1);

                        var node = parser.get_root ().get_object ();

                        string sync_token = node.get_string_member ("sync_token");

                        if (Application.database_v2.update_project (project)) {
                            project_updated (project);
                        }
                        //Application.user.sync_token = sync_token;
                        //Application.database.update_sync_token (Application.user);
                        //Application.database.add_project (project);
                    } catch (Error e) {
                        show_message("Request page fail", e.message, "dialog-error");
                    }
                    
                } else {
                    show_message("Request page fail", @"status code: $(mess.status_code)", "dialog-error");
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

            builder.set_member_name ("is_favorite");
            builder.add_int_value (project.is_favorite);

            builder.end_object ();
        
        builder.end_object ();
        builder.end_array ();


        Json.Generator generator = new Json.Generator ();
	    Json.Node root = builder.get_root ();
        generator.set_root (root);

        return generator.to_data (null);
    }

    public void delete_project (Objects.Project project) {
        new Thread<void*> ("todoist_delete_project", () => {
            string uuid = Application.utils.generate_string ();

            string url = "%s?token=%s&commands=%s".printf (
                TODOIST_SYNC_URL, 
                Application.user.todoist_token,
                get_delete_project_json (project, uuid)
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

                            if (Application.database_v2.delete_project (project.id)) {
                                project_deleted (project.id);
                            }
                        } else {
                            var http_code = (int32) sync_status.get_object_member (uuid).get_int_member ("http_code");
                            var error_message = sync_status.get_object_member (uuid).get_string_member ("error");

                            show_message("Error %i".printf (http_code), error_message, "dialog-error");
                        }

                        //var uuid_object = sync_status.get_object_member (uuid);

                        /*
                        string sync_token = node.get_string_member ("sync_token");

                        if (Application.database_v2.delete_project (project.id)) {
                            project_deleted (project.id);
                        }
                        //Application.user.sync_token = sync_token;
                        //Application.database.update_sync_token (Application.user);
                        //Application.database.add_project (project);
                        */
                    } catch (Error e) {
                        show_message("Request page fail", e.message, "dialog-error");
                    }
                    
                } else {
                    show_message("Request page fail", @"status code: $(mess.status_code)", "dialog-error");
                }
            });

            return null;
        });
    }

    public string get_delete_project_json (Objects.Project project, string uuid) {
        var builder = new Json.Builder ();
        builder.begin_array ();
        builder.begin_object ();
        
        // Set type
        builder.set_member_name ("type");
        builder.add_string_value ("project_delete");

        builder.set_member_name ("uuid");
        builder.add_string_value (uuid);

        builder.set_member_name ("args");
            builder.begin_object ();

            builder.set_member_name ("id");
            builder.add_int_value (project.id);

            builder.end_object ();
        
        builder.end_object ();
        builder.end_array ();


        Json.Generator generator = new Json.Generator ();
	    Json.Node root = builder.get_root ();
        generator.set_root (root);

        return generator.to_data (null);
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