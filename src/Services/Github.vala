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

public class Services.Github : GLib.Object {
    private Soup.Session session;

    private string GITHUB_URI = "https://api.github.com";

    public signal void user_is_valid (bool valid);
    public signal void completed_user (Objects.User user);
    public Github () {
        session = new Soup.Session ();
        session.ssl_strict = false;
    }

    public void check_username (string username) {
        var uri_user = "%s/users/%s".printf (GITHUB_URI, username);

        var message = new Soup.Message ("GET", uri_user);
        message.request_headers.append ("User-Agent", "Planner");
        session.send_message (message);

        var response = (string) message.response_body.flatten ().data;

        if ("Not Found" in response) {
            user_is_valid (false);
        } else {
            user_is_valid (true);

            try {
                var parser = new Json.Parser ();
                parser.load_from_data (response, -1);

                get_username_data (parser);
            } catch (Error e) {
                stderr.printf ("Failed to connect to Github service.\n");
            }
        }
    }

    public void get_username_data (Json.Parser parser) {
        var nodo = parser.get_root ().get_object ();

        var user = new Objects.User ();
        user.id = nodo.get_int_member ("id");

        if (nodo.get_string_member ("name") == "" || nodo.get_string_member ("name") == null) {
            user.name = "";
        } else {
            user.name = nodo.get_string_member ("name");
        }

        if (nodo.get_string_member ("login") == "" || nodo.get_string_member ("login") == null) {
            user.login = "";
        } else {
            user.login = nodo.get_string_member ("login");
        }

        if (nodo.get_string_member ("avatar_url") == "" || nodo.get_string_member ("avatar_url") == null) {
            user.avatar_url = "";
        } else {
            user.avatar_url = nodo.get_string_member ("avatar_url");
        }

        if (Application.database.add_user (user) == Sqlite.DONE) {
            // Create file
            var cache_folder = GLib.Path.build_filename (GLib.Environment.get_user_cache_dir (), "com.github.alainm23.planner");
            var profile_folder = GLib.Path.build_filename (cache_folder, "profile");
            var image_path = GLib.Path.build_filename (profile_folder, ("%i.jpg").printf ((int) user.id));

            // Create avatar image file 
            var file_path = File.new_for_path (image_path);
            var file_from_uri = File.new_for_uri (user.avatar_url);


            MainLoop loop = new MainLoop ();
            
            file_from_uri.copy_async.begin (file_path, 0, Priority.DEFAULT, null, (current_num_bytes, total_num_bytes) => {
		    // Report copy-status:
		        print ("%" + int64.FORMAT + " bytes of %" + int64.FORMAT + " bytes copied.\n",
			        current_num_bytes, total_num_bytes);
	        }, (obj, res) => {
		        try {
                    if (file_from_uri.copy_async.end (res)) {
                        completed_user (user);

                        get_repos (user.login, user.id);
                    }
		        } catch (Error e) {
			        print ("Error: %s\n", e.message);
	    	    }

		        loop.quit ();
	        });

	        loop.run ();
        }
    }

    public void get_repos (string username, int64 user_id) {
        new Thread<void*> ("scan_local_files", () => {
            var uri_repos = "%s/users/%s/repos".printf (GITHUB_URI, username);

            var message = new Soup.Message ("GET", uri_repos);
            message.request_headers.append ("User-Agent", "planner");
            session.send_message (message);

            try {
                var parser = new Json.Parser ();
                parser.load_from_data ((string) message.response_body.flatten ().data, -1);

                var root = parser.get_root ().get_array ();

                foreach (var item in root.get_elements ()) {
                    var item_details = item.get_object ();

                    if (item_details.get_boolean_member ("fork") == false) {
                        if (Application.database.repository_exists (item_details.get_int_member ("id")) == false) {
                            var repo = new Objects.Repository ();
                            repo.id = item_details.get_int_member ("id");
                            repo.name = item_details.get_string_member ("name");
                            repo.user_id = user_id;

                            Application.database.add_repository (repo);
                        }
                    }
                }


            } catch (Error e) {
                stderr.printf ("Failed to connect to Github service.\n");
            }

            return null;
        });
    }
}