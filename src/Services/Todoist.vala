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
    private const string TODOIST_SYNC_URL = "https://api.todoist.com/sync/v8/sync";
    
    public signal void first_sync_started ();
    public signal void first_sync_finished ();

    public signal void project_added_started ();
    public signal void project_added_completed ();
    public signal void project_added_error (int error_code, string error_message);

    public signal void project_updated_started ();
    public signal void project_updated_completed ();
    public signal void project_updated_error (int error_code, string error_message);

    public signal void project_deleted_started ();
    public signal void project_deleted_completed ();
    public signal void project_deleted_error (int error_code, string error_message);

    public signal void item_added_started (int64 id);
    public signal void item_added_completed (int64 id);
    public signal void item_added_error (int64 id, int error_code, string error_message);

    public signal void avatar_downloaded ();

    public Todoist () {
        session = new Soup.Session ();
    }

    public void get_todoist_token (string url) {
        first_sync_started ();
        new Thread<void*> ("get_todoist_token", () => {
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

            return null;
        });
    }

    public void first_sync (string token) {
        string url = TODOIST_SYNC_URL;
        url = url + "?token=" + token;
        url = url + "&sync_token=" + "*";
        url = url + "&resource_types=" + "[\"all\"]";

        var message = new Soup.Message ("POST", url);
        session.queue_message (message, (sess, mess) => {
            if (mess.status_code == 200) {
                var parser = new Json.Parser ();
                
                try {
                    print ("----------------------\n");
                    print ("%s\n".printf ((string) mess.response_body.flatten ().data));
                    print ("----------------------\n");

                    parser.load_from_data ((string) mess.response_body.flatten ().data, -1);

                    var node = parser.get_root ().get_object ();

                    // Create user
                    var user_object = node.get_object_member ("user");
        
                    Application.settings.set_boolean ("todoist-full-sync", node.get_boolean_member ("full_sync"));
                    Application.settings.set_string ("todoist-sync-token", node.get_string_member ("sync_token"));
                    Application.settings.set_string ("todoist-access-token", token);

                    Application.settings.set_int ("todoist-user-id", (int32) user_object.get_int_member ("id"));
                    Application.settings.set_int64 ("inbox-project", user_object.get_int_member ("inbox_project"));
                    Application.settings.set_boolean ("inbox-project-sync", true);

                    Application.settings.set_string ("user-name", user_object.get_string_member ("full_name"));
                    Application.settings.set_string ("todoist-user-email", user_object.get_string_member ("email"));
                    Application.settings.set_string ("todoist-user-join-date", user_object.get_string_member ("join_date"));

                    Application.settings.set_string ("todoist-user-avatar", user_object.get_string_member ("avatar_s640"));
                    Application.settings.set_boolean ("todoist-user-is-premium", user_object.get_boolean_member ("is_premium"));
                    Application.settings.set_boolean ("todoist-account", true);

                    // Create projects
                    unowned Json.Array projects = node.get_array_member ("projects");
                    foreach (unowned Json.Node item in projects.get_elements ()) {
                        var object = item.get_object ();

                        var project = new Objects.Project ();

                        project.id = object.get_int_member ("id"); 
                        project.name = object.get_string_member ("name");
                        project.color = (int32) object.get_int_member ("color");

                        if (object.get_boolean_member ("team_inbox")) {
                            project.team_inbox = 1;
                        } else {
                            project.team_inbox = 0;
                        }

                        if (object.get_boolean_member ("inbox_project")) {
                            project.inbox_project = 1;
                        } else {
                            project.inbox_project = 0;
                        }

                        if (object.get_boolean_member ("shared")) {
                            project.shared = 1;
                        } else {
                            project.shared = 0;
                        }

                        project.is_deleted = (int32) object.get_int_member ("is_deleted");
                        project.is_archived = (int32) object.get_int_member ("is_archived");
                        project.is_favorite = (int32) object.get_int_member ("is_favorite");
                        project.is_todoist = 1;
                        project.is_sync = 1;

                        Application.database.insert_project (project);
                    }

                    // Create Sections 
                    unowned Json.Array sections = node.get_array_member ("sections");
                    foreach (unowned Json.Node item in sections.get_elements ()) {
                        var object = item.get_object ();

                        var s = new Objects.Section ();

                        s.id = object.get_int_member ("id");
                        s.project_id = object.get_int_member ("project_id");
                        s.sync_id = object.get_int_member ("sync_id");
                        s.name = object.get_string_member ("name");
                        s.date_added = object.get_string_member ("date_added");
                        s.date_archived = object.get_string_member ("date_archived");
                        s.is_deleted = (int32) object.get_int_member ("is_deleted");
                        s.is_archived = (int32) object.get_int_member ("is_archived");

                        if (object.get_boolean_member ("collapsed")) {
                            s.collapsed = 1;
                        } else {
                            s.collapsed = 0;
                        }

                        Application.database.insert_section (s);
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
                        i.responsible_uid = object.get_int_member ("responsible_uid");
                        i.sync_id = object.get_int_member ("sync_id");
                        
                        if (object.get_null_member ("section_id") == false) {
                            i.section_id = object.get_int_member ("section_id");
                        }

                        if (object.get_null_member ("parent_id") == false) {
                            i.parent_id = object.get_int_member ("parent_id");
                        }
        
                        i.content = object.get_string_member ("content");
                        i.checked = (int32) object.get_int_member ("checked");
                        i.priority = (int32) object.get_int_member ("priority");
                        i.is_deleted = (int32) object.get_int_member ("is_deleted");
                        i.date_added = object.get_string_member ("date_added");
                        i.date_completed = object.get_string_member ("date_completed");
                        
                        Application.database.insert_item (i);
                    }
                    
                    // Download Profile Image
                    Application.utils.download_profile_image (user_object.get_string_member ("avatar_s640"));

                    first_sync_finished ();
                } catch (Error e) {
                    show_message("Request page fail", e.message, "dialog-error");
                }
            } else {
                show_message("Request page fail", @"status code: $(mess.status_code)", "dialog-error");
            }
        });
    }

    public void add_project (Objects.Project project) {
        project_added_started ();
        new Thread<void*> ("todoist_add_project", () => {
            string temp_id = Application.utils.generate_string ();
            string uuid = Application.utils.generate_string ();

            string url = "%s?token=%s&commands=%s".printf (
                TODOIST_SYNC_URL, 
                Application.settings.get_string ("todoist-access-token"),
                get_add_project_json (project, temp_id, uuid)
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
                            Application.settings.set_string ("todoist-sync-token", sync_token);

                            project.id = node.get_object_member ("temp_id_mapping").get_int_member (temp_id);

                            if (Application.database.insert_project (project)) {
                                print ("Proyecto creado: %s\n".printf (project.name));
                                project_added_completed ();
                            }
                        } else {
                            var http_code = (int32) sync_status.get_object_member (uuid).get_int_member ("http_code");
                            var error_message = sync_status.get_object_member (uuid).get_string_member ("error");

                            project_added_error (http_code, error_message);
                        }
                    } catch (Error e) {
                        project_added_error ((int32) mess.status_code, e.message);
                    }
                } else {
                    project_added_error ((int32) mess.status_code, _("Connection error"));
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
        project_updated_started ();

        new Thread<void*> ("todoist_update_project", () => {
            string uuid = Application.utils.generate_string ();

            string url = "%s?token=%s&commands=%s".printf (
                TODOIST_SYNC_URL, 
                Application.settings.get_string ("todoist-access-token"),
                get_update_project_json (project, uuid)
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
                            Application.settings.set_string ("todoist-sync-token", sync_token);

                            if (Application.database.update_project (project)) { 
                                print ("Actualizado: %s\n".printf (project.name));
                                project_updated_completed ();
                            }
                        } else {
                            var http_code = (int32) sync_status.get_object_member (uuid).get_int_member ("http_code");
                            var error_message = sync_status.get_object_member (uuid).get_string_member ("error");

                            project_updated_error (http_code, error_message);
                        }
                    } catch (Error e) {
                        project_updated_error ((int32) mess.status_code, e.message);
                    }
                } else {
                    project_updated_error ((int32) mess.status_code, _("Connection error"));
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

            /*
            builder.set_member_name ("is_favorite");    
            builder.add_int_value (project.is_favorite);    
            */

            builder.end_object ();
        
        builder.end_object ();
        builder.end_array ();


        Json.Generator generator = new Json.Generator ();
	    Json.Node root = builder.get_root ();
        generator.set_root (root);

        return generator.to_data (null);
    }

    public void delete_project (Objects.Project project) {
        project_deleted_started ();

        new Thread<void*> ("todoist_delete_project", () => {
            string uuid = Application.utils.generate_string ();

            string url = "%s?token=%s&commands=%s".printf (
                TODOIST_SYNC_URL, 
                Application.settings.get_string ("todoist-access-token"),
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
                            Application.settings.set_string ("todoist-sync-token", sync_token);

                            if (Application.database.delete_project (project)) {
                                print ("Eliminado: %s\n".printf (project.name));
                                project_deleted_completed ();
                            }
                        } else {
                            var http_code = (int32) sync_status.get_object_member (uuid).get_int_member ("http_code");
                            var error_message = sync_status.get_object_member (uuid).get_string_member ("error");

                            project_updated_error (http_code, error_message);
                        }
                    } catch (Error e) {
                        project_updated_error ((int32) mess.status_code, e.message);
                    }  
                } else {
                    project_updated_error ((int32) mess.status_code, _("Connection error"));
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

    /*
        Items
    */

    public void add_item (Objects.Item item, int? index=null) {
        item_added_started (item.project_id);
        new Thread<void*> ("todoist_add_project", () => {
            string temp_id = Application.utils.generate_string ();
            string uuid = Application.utils.generate_string ();

            string url = "%s?token=%s&commands=%s".printf (
                TODOIST_SYNC_URL, 
                Application.settings.get_string ("todoist-access-token"),
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
                            Application.settings.set_string ("todoist-sync-token", sync_token);

                            item.id = node.get_object_member ("temp_id_mapping").get_int_member (temp_id);

                            if (Application.database.insert_item (item, index)) {
                                print ("Item creado: %s\n".printf (item.content));
                                item_added_completed (item.project_id);
                            }
                        } else {
                            var http_code = (int32) sync_status.get_object_member (uuid).get_int_member ("http_code");
                            var error_message = sync_status.get_object_member (uuid).get_string_member ("error");

                            item_added_error (item.project_id, http_code, error_message);
                        }
                    } catch (Error e) {
                        item_added_error (item.project_id, (int32) mess.status_code, e.message);
                    }
                } else {
                    item_added_error (item.project_id, (int32) mess.status_code, _("Connection error"));
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

            builder.end_object ();        
        builder.end_object ();
        builder.end_array ();

        Json.Generator generator = new Json.Generator ();
	    Json.Node root = builder.get_root ();
        generator.set_root (root);

        return generator.to_data (null);
    }

    public void update_item (Objects.Item item) {
        new Thread<void*> ("todoist_update_item", () => {
            string uuid = Application.utils.generate_string ();

            string url = "%s?token=%s&commands=%s".printf (
                TODOIST_SYNC_URL, 
                Application.settings.get_string ("todoist-access-token"),
                get_update_item_json (item, uuid)
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
                            Application.settings.set_string ("todoist-sync-token", sync_token);

                            if (Application.database.update_item (item)) { 
                                print ("Actualizado: %s\n".printf (item.content));
                            }
                        } else {
                            var http_code = (int32) sync_status.get_object_member (uuid).get_int_member ("http_code");
                            var error_message = sync_status.get_object_member (uuid).get_string_member ("error");
                            //project_updated_error (http_code, error_message);
                        }
                    } catch (Error e) {
                        //project_updated_error ((int32) mess.status_code, e.message);
                    }
                } else {
                    //project_updated_error ((int32) mess.status_code, _("Connection error"));
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