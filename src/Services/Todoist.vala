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
    public Todoist () {
        session = new Soup.Session ();
    }

    public void get_todoist_token (string url) {
        string code = url.split ("=") [2];
        string response = "";

        string command = "curl \"https://todoist.com/oauth/access_token\" ";
        command = command + "-d \"client_id=b0dd7d3714314b1dbbdab9ee03b6b432\" ";
        command = command + "-d \"client_secret=7de1fc35b5124b2285d7ddc07576c438\" ";
        command = command + "-d \"code=" + code + "\"";

        Process.spawn_command_line_sync (command, out response);

        try {
            var parser = new Json.Parser ();
            parser.load_from_data (response, -1);
            
            var root_oa = parser.get_root ().get_object ();
            var token = root_oa.get_string_member ("access_token");

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

        session.send_message (message);
        
        var response = (string) message.response_body.flatten ().data;

        try {
            var parser = new Json.Parser ();
            parser.load_from_data (response, -1);

            var root = parser.get_root ().get_object ();

            // Create user
            var todoist_user = root.get_object_member ("user");

            var user = new Objects.User ();
            user.id = todoist_user.get_int_member ("id");
            user.full_name = todoist_user.get_string_member ("full_name");
            user.email = todoist_user.get_string_member ("email");
            user.token = token;
            user.sync_token = root.get_string_member ("sync_token");
            user.is_todoist = 1;
            user.join_date = todoist_user.get_string_member ("join_date");
            user.inbox_project = todoist_user.get_int_member ("inbox_project");
            user.avatar = todoist_user.get_string_member ("avatar_s640");

            if (todoist_user.get_boolean_member ("is_premium")) {
                user.is_premium = 1; 
            } 
            
            // Create Inbox Project
            var inbox_project = new Objects.Project ();
            inbox_project.icon = "planner-inbox";
            inbox_project.is_todoist = 1; 
            inbox_project.id = user.inbox_project;
            inbox_project.name = _("Inbox");

            // Download Avatar
            download_profile_image (user.id.to_string (), user.avatar);

            if (Application.database.create_user (user) == Sqlite.DONE) {
                Application.user = user;
                
                if (Application.database.add_project (inbox_project) == Sqlite.DONE) {
                    sync_finished ();
                }
            }

        } catch (Error e) {
            stderr.printf ("Failed to connect to Todoist API service.\n");
        }
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
}