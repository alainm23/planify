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

    public signal void item_completed_started (Objects.Item item);
    public signal void item_completed_completed (Objects.Item item);
    public signal void item_completed_error (Objects.Item item, int error_code, string error_message);

    public signal void item_uncompleted_started (Objects.Item item);
    public signal void item_uncompleted_completed (Objects.Item item);
    public signal void item_uncompleted_error (Objects.Item item, int error_code, string error_message);

    public signal void item_moved_started (int64 id);
    public signal void item_moved_completed (int64 id);
    public signal void item_moved_error (int64 id, int error_code, string error_message);

    public signal void avatar_downloaded ();

    public Gee.ArrayList<Objects.Item?> items_to_complete;
    public Gee.ArrayList<Objects.Item?> items_to_delete;

    private uint comple_timeout = 0;
    private uint delete_timeout = 0;

    public Todoist () {
        session = new Soup.Session ();

        items_to_complete = new Gee.ArrayList<Objects.Item?> ();
        items_to_delete = new Gee.ArrayList<Objects.Item?> ();
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
                        Application.settings.set_boolean ("inbox-project-sync", true);
                        Application.settings.set_int64 ("inbox-project", user_object.get_int_member ("inbox_project"));

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
                            s.collapsed = 1;
                            
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
                            
                            if (object.get_member ("due").get_node_type () == Json.NodeType.OBJECT) {
                                var due_object = object.get_object_member ("due");
                                var datetime = Application.utils.get_todoist_datetime (due_object.get_string_member ("date"));
                                i.due_date = datetime.to_string ();

                                i.due_timezone = due_object.get_string_member ("timezone");
                                i.due_string = due_object.get_string_member ("string");
                                i.due_lang = due_object.get_string_member ("lang");
                                if (due_object.get_boolean_member ("is_recurring")) {
                                    i.due_is_recurring = 1;
                                }
                            }

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

            return null;
        });
    }

    /*
        Collaborators
    */

    public void share_project (int64 project_id, string email) {
        new Thread<void*> ("todoist_share_project", () => {
            string temp_id = Application.utils.generate_string ();
            string uuid = Application.utils.generate_string ();

            string url = "%s?token=%s&commands=%s".printf (
                TODOIST_SYNC_URL, 
                Application.settings.get_string ("todoist-access-token"),
                get_share_project_json (project_id, email, temp_id, uuid)
            );

            var message = new Soup.Message ("POST", url);

            session.queue_message (message, (sess, mess) => {
                if (mess.status_code == 200) {
                    try {
                        print ("----------------------\n");
                        print ("%s\n".printf ((string) mess.response_body.flatten ().data));
                        print ("----------------------\n");
                        
                        var parser = new Json.Parser ();
                        parser.load_from_data ((string) mess.response_body.flatten ().data, -1);

                        var node = parser.get_root ().get_object ();
    
                        var sync_status = node.get_object_member ("sync_status");
                        var uuid_member = sync_status.get_member (uuid);

                        if (uuid_member.get_node_type () == Json.NodeType.VALUE) {
                            string sync_token = node.get_string_member ("sync_token");
                            Application.settings.set_string ("todoist-sync-token", sync_token);


                        } else {
                            //var http_code = (int32) sync_status.get_object_member (uuid).get_int_member ("http_code");
                            //var error_message = sync_status.get_object_member (uuid).get_string_member ("error");

                            //project_added_error (http_code, error_message);
                        }
                    } catch (Error e) {
                        //project_added_error ((int32) mess.status_code, e.message);
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
        project_updated_started (project.id);

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
                                project_updated_completed (project.id);
                            }
                        } else {
                            var http_code = (int32) sync_status.get_object_member (uuid).get_int_member ("http_code");
                            var error_message = sync_status.get_object_member (uuid).get_string_member ("error");

                            project_updated_error (project.id, http_code, error_message);
                        }
                    } catch (Error e) {
                        project_updated_error (project.id, (int32) mess.status_code, e.message);
                    }
                } else {
                    project_updated_error (project.id, (int32) mess.status_code, _("Connection error"));
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
        project_deleted_started (project.id);

        new Thread<void*> ("todoist_delete_project", () => {
            string uuid = Application.utils.generate_string ();

            string url = "%s?token=%s&commands=%s".printf (
                TODOIST_SYNC_URL, 
                Application.settings.get_string ("todoist-access-token"),
                get_delete_json (project.id, "project_delete", uuid)
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
                                project_deleted_completed (project.id);
                            }
                        } else {
                            var http_code = (int32) sync_status.get_object_member (uuid).get_int_member ("http_code");
                            var error_message = sync_status.get_object_member (uuid).get_string_member ("error");

                            project_deleted_error (project.id, http_code, error_message);
                        }
                    } catch (Error e) {
                        project_deleted_error (project.id, (int32) mess.status_code, e.message);
                    }  
                } else {
                    project_deleted_error (project.id, (int32) mess.status_code, _("Connection error"));
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
            string temp_id = Application.utils.generate_string ();
            string uuid = Application.utils.generate_string ();

            string url = "%s?token=%s&commands=%s".printf (
                TODOIST_SYNC_URL, 
                Application.settings.get_string ("todoist-access-token"),
                get_add_section_json (section, temp_id, uuid)
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

                            section.id = node.get_object_member ("temp_id_mapping").get_int_member (temp_id);

                            if (Application.database.insert_section (section)) {
                                print ("Section creado: %s\n".printf (section.name));
                                section_added_completed (temp_id_mapping);
                            }
                        } else {
                            var http_code = (int32) sync_status.get_object_member (uuid).get_int_member ("http_code");
                            var error_message = sync_status.get_object_member (uuid).get_string_member ("error");

                            section_added_error (temp_id_mapping, http_code, error_message);
                        }
                    } catch (Error e) {
                        section_added_error (temp_id_mapping, (int32) mess.status_code, e.message);
                    }
                } else {
                    section_added_error (temp_id_mapping, (int32) mess.status_code, _("Connection error"));
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
            string uuid = Application.utils.generate_string ();

            string url = "%s?token=%s&commands=%s".printf (
                TODOIST_SYNC_URL, 
                Application.settings.get_string ("todoist-access-token"),
                get_update_section_json (section, uuid)
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

                            if (Application.database.update_section (section)) { 
                                print ("Section Actualizado: %s\n".printf (section.name));
                                section_updated_completed (section.id);
                            }
                        } else {
                            var http_code = (int32) sync_status.get_object_member (uuid).get_int_member ("http_code");
                            var error_message = sync_status.get_object_member (uuid).get_string_member ("error");

                            section_updated_error (section.id, http_code, error_message);
                        }
                    } catch (Error e) {
                        section_updated_error (section.id, (int32) mess.status_code, e.message);
                    }
                } else {
                    section_updated_error (section.id, (int32) mess.status_code, _("Connection error"));
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
            string uuid = Application.utils.generate_string ();

            string url = "%s?token=%s&commands=%s".printf (
                TODOIST_SYNC_URL, 
                Application.settings.get_string ("todoist-access-token"),
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
                            Application.settings.set_string ("todoist-sync-token", sync_token);

                            if (Application.database.delete_section (section)) {
                                print ("Eliminado: %s\n".printf (section.name));
                                section_deleted_completed (section.id);
                            }
                        } else {
                            var http_code = (int32) sync_status.get_object_member (uuid).get_int_member ("http_code");
                            var error_message = sync_status.get_object_member (uuid).get_string_member ("error");

                            section_deleted_error (section.id, http_code, error_message);
                        }
                    } catch (Error e) {
                        section_deleted_error (section.id, (int32) mess.status_code, e.message);
                    }  
                } else {
                    section_deleted_error (section.id, (int32) mess.status_code, _("Connection error"));
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
            string uuid = Application.utils.generate_string ();

            string url = "%s?token=%s&commands=%s".printf (
                TODOIST_SYNC_URL, 
                Application.settings.get_string ("todoist-access-token"),
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
                            Application.settings.set_string ("todoist-sync-token", sync_token);

                            if (Application.database.move_section (section, id)) {
                                print ("Movido: %s\n".printf (section.name));
                                section_moved_completed (section.id);
                            }
                        } else {
                            var http_code = (int32) sync_status.get_object_member (uuid).get_int_member ("http_code");
                            var error_message = sync_status.get_object_member (uuid).get_string_member ("error");

                            section_moved_error (section.id, http_code, error_message);
                        }
                    } catch (Error e) {
                        section_moved_error (section.id, (int32) mess.status_code, e.message);
                    }  
                } else {
                    section_moved_error (section.id, (int32) mess.status_code, _("Connection error"));
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

    public void add_item (Objects.Item item, int index, bool has_index, int64 id) {
        item_added_started (id);
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

                            if (Application.database.insert_item (item, index, has_index)) {
                                print ("Item creado: %s\n".printf (item.content));
                                item_added_completed (id);
                            }
                        } else {
                            var http_code = (int32) sync_status.get_object_member (uuid).get_int_member ("http_code");
                            var error_message = sync_status.get_object_member (uuid).get_string_member ("error");

                            item_added_error (id, http_code, error_message);
                        }
                    } catch (Error e) {
                        item_added_error (id, (int32) mess.status_code, e.message);
                    }
                } else {
                    item_added_error (id, (int32) mess.status_code, _("Connection error"));
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

    public void move_item (Objects.Item item, int64 project_id) {
        item_moved_started (item.id);

        new Thread<void*> ("todoist_move_item", () => {
            string uuid = Application.utils.generate_string ();

            string url = "%s?token=%s&commands=%s".printf (
                TODOIST_SYNC_URL, 
                Application.settings.get_string ("todoist-access-token"),
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
                            Application.settings.set_string ("todoist-sync-token", sync_token);

                            if (Application.database.move_item (item, project_id)) {
                                //print ("Movido: %s\n".printf (item.content));
                                item_moved_completed (item.id);
                            }
                        } else {
                            var http_code = (int32) sync_status.get_object_member (uuid).get_int_member ("http_code");
                            var error_message = sync_status.get_object_member (uuid).get_string_member ("error");

                            item_moved_error (item.id, http_code, error_message);
                        }
                    } catch (Error e) {
                        item_moved_error (item.id, (int32) mess.status_code, e.message);
                    }  
                } else {
                    item_moved_error (item.id, (int32) mess.status_code, _("Connection error"));
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

            if (item.due_date != "") {
                builder.set_member_name ("due");
                builder.begin_object ();

                builder.set_member_name ("date");
                builder.add_string_value (new GLib.DateTime.from_iso8601 (item.due_date, new GLib.TimeZone.local ()).format ("%F"));

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
        //item_moved_started (item.id);

        new Thread<void*> ("todoist_move_item_to_section", () => {
            string uuid = Application.utils.generate_string ();

            string url = "%s?token=%s&commands=%s".printf (
                TODOIST_SYNC_URL, 
                Application.settings.get_string ("todoist-access-token"),
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
                            Application.settings.set_string (
                                "todoist-sync-token", 
                                node.get_string_member ("sync_token")
                            );

                            print ("Movido: %s\n".printf (item.content));
                            //if (Application.database.move_item (item, project_id)) {
                                //
                            //    item_moved_completed (item.id);
                            //}
                        } else {
                            var http_code = (int32) sync_status.get_object_member (uuid).get_int_member ("http_code");
                            var error_message = sync_status.get_object_member (uuid).get_string_member ("error");

                            //item_moved_error (item.id, http_code, error_message);
                        }
                    } catch (Error e) {
                        //item_moved_error (item.id, (int32) mess.status_code, e.message);
                    }  
                } else {
                    //item_moved_error (item.id, (int32) mess.status_code, _("Connection error"));
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

    public bool add_complete_item (Objects.Item item) {
        if (comple_timeout != 0) {
            Source.remove (comple_timeout);
            comple_timeout = 0;
        }

        comple_timeout = Timeout.add (500, () => {
            complete_items ();
            
            Source.remove (comple_timeout);
            comple_timeout = 0;
            return false;
        });

        return items_to_complete.add (item);
    }

    private void complete_items () {
        new Thread<void*> ("todoist_complete_item", () => {
            string url = "%s?token=%s&commands=%s".printf (
                TODOIST_SYNC_URL, 
                Application.settings.get_string ("todoist-access-token"),
                get_complete_items_json ()
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

                        string sync_token = node.get_string_member ("sync_token");
                        Application.settings.set_string ("todoist-sync-token", sync_token);
                        

                        foreach (var i in items_to_complete) {
                            if (Application.database.update_item_completed (i)) { 
                                print ("Actualizado: %s\n".printf (i.content));
                                item_completed_completed (i);
                            }
                        }

                        items_to_complete.clear ();
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

    private string get_complete_items_json () {
        var builder = new Json.Builder ();
        builder.begin_array ();

        foreach (var i in items_to_complete) {
            builder.begin_object ();
            builder.set_member_name ("type");
            builder.add_string_value ("item_complete");

            builder.set_member_name ("uuid");
            builder.add_string_value (Application.utils.generate_string ());

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
                Application.settings.get_string ("todoist-access-token"),
                get_delete_items_json ()
            );

            var message = new Soup.Message ("POST", url);

            session.queue_message (message, (sess, mess) => {
                if (mess.status_code == 200) {
                    try {
                        var parser = new Json.Parser ();
                        parser.load_from_data ((string) mess.response_body.flatten ().data, -1);

                        print ("delete_items: %s\n".printf ((string) mess.response_body.flatten ().data));

                        var node = parser.get_root ().get_object ();

                        var sync_status = node.get_object_member ("sync_status");

                        string sync_token = node.get_string_member ("sync_token");
                        Application.settings.set_string ("todoist-sync-token", sync_token);
                         
                        foreach (var i in items_to_delete) {
                            if (Application.database.delete_item (i)) { 
                                print ("Eliminado: %s\n".printf (i.content));
                            }
                        }

                        items_to_delete.clear ();
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

    private string get_delete_items_json () {
        var builder = new Json.Builder ();
        builder.begin_array ();

        foreach (var i in items_to_delete) {
            builder.begin_object ();
            builder.set_member_name ("type");
            builder.add_string_value ("item_delete");

            builder.set_member_name ("uuid");
            builder.add_string_value (Application.utils.generate_string ());

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
            string uuid = Application.utils.generate_string ();

            string url = "%s?token=%s&commands=%s".printf (
                TODOIST_SYNC_URL, 
                Application.settings.get_string ("todoist-access-token"),
                get_uncomplete_item_json (item, uuid)
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

                            if (Application.database.update_item_completed (item)) { 
                                print ("Actualizado: %s\n".printf (item.content));
                                item_uncompleted_completed (item);
                            }
                        } else {
                            var http_code = (int32) sync_status.get_object_member (uuid).get_int_member ("http_code");
                            var error_message = sync_status.get_object_member (uuid).get_string_member ("error");
                            item_uncompleted_error (item, http_code, error_message);
                        }
                    } catch (Error e) {
                        item_uncompleted_error (item, (int32) mess.status_code, e.message);
                    }
                } else {
                    item_uncompleted_error (item, (int32) mess.status_code, _("Connection error"));
                }
            });

            return null;
        });
    }
    
    private string get_uncomplete_item_json (Objects.Item item, string uuid) {
        var builder = new Json.Builder ();
        builder.begin_array ();
        builder.begin_object ();
        
        // Set type
        builder.set_member_name ("type");
        builder.add_string_value ("item_uncomplete");

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