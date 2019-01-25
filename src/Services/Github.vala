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

        if (Application.database.user_exists ()) {
            var user = Application.database.get_user ();
            get_repos (user.login, user.token, user.id);
        }
        
        init_server ();
    }

    private void init_server () {
        Timeout.add_seconds (1 * 60 * 10, () => {
            check_issues ();

            return true;
        });
    }

    public void check_issues () {
        if (Application.database.user_exists () && Application.database.repo_exists ()) {
            var user = Application.database.get_user ();

            var all_repos = new Gee.ArrayList<Objects.Repository?> ();
            all_repos = Application.database.get_all_repos ();

            foreach (var repo in all_repos) {
                if (repo.sensitive == 1) {
                    get_issues (user.login, user.token, repo);
                }
            }
        }
    }

    public void get_issues (string username, string token, Objects.Repository repo) {
        var uri_issues = "%s/repos/%s/%s/issues".printf (GITHUB_URI, username, repo.name);
        
        var message = new Soup.Message ("GET", uri_issues);
        message.request_headers.append ("User-Agent", "Planner");
        message.request_headers.append ("Authorization", "token " + token);

        session.send_message (message);

        try {
            var parser = new Json.Parser ();
            parser.load_from_data ((string) message.response_body.flatten ().data, -1);

            var root = parser.get_root ().get_array ();

            foreach (var item in root.get_elements ()) {
                var item_details = item.get_object ();
                
                var id = item_details.get_int_member ("id");

                if (!issue_exists (repo.issues, id)) {
                    // Add id to repo
                    repo.issues = repo.issues + id.to_string () + ";";

                    // New Task
                    var task = new Objects.Task ();
                    task.content = item_details.get_string_member ("title");
                    task.is_inbox = 1;
                    task.note = item_details.get_string_member ("body");

                    // Agregando tarea a la base de datos
                    task.id = Application.database.add_task_return_id (task);

                    // Send Noty
                    Application.notification.send_task_notification (
                        "Github Issues - %s".printf (repo.name), 
                        task,
                        "com.github.alainm23.planner"
                    );

                    // Update repo
                    Application.database.update_repository (repo);
                }
            }
        } catch (Error e) {
            stderr.printf ("Failed to connect to Github service.\n");
        }

    }

    public bool issue_exists (string issues, int64 id) {
        var _issues = issues.split (";");

        foreach (unowned string _id in _issues) {
            if (_id == id.to_string ()) {
                return true;
            }
        }

        return false;
    } 

    public void get_token (string username, string password) {
        var builder = new Json.Builder ();
        builder.begin_object ();
        builder.set_member_name ("client_id");
        builder.add_string_value ("c0fc83d4d56d7b6e006f");
        builder.set_member_name ("client_secret");
        builder.add_string_value ("cbd427556f7533d48483362592be1df4086a5015");
        builder.set_member_name ("scopes");
        builder.begin_array ();
        builder.add_string_value ("user");
        builder.add_string_value ("repo");
        builder.end_array ();
        builder.set_member_name ("note");
        builder.add_string_value ("planner");
        builder.set_member_name ("note_url");
        builder.add_string_value ("https://github.com/alainm23/planner");
        builder.end_object ();

        var generator = new Json.Generator ();
        var root = builder.get_root ();
        generator.set_root (root);
        string str = generator.to_data (null);
        
        var uri = "https://api.github.com/authorizations";
        
        var message = new Soup.Message ("POST", uri);
        var buffer = Soup.MemoryUse.COPY;
        message.request_headers.append ("User-Agent", "planner");
        message.set_request("application/json; charset=utf-8", buffer, str.data);
        string encoded = Base64.encode ((username + ":" + password).data);
        message.request_headers.append ("Authorization", "Basic " + encoded);
        session.send_message (message);

        var response = (string) message.response_body.flatten ().data;

        if ("Bad credentials" in response) {
            user_is_valid (false);
        } else {
            try {
                var parser = new Json.Parser ();
                parser.load_from_data (response, -1);

                var root_oa = parser.get_root ().get_object ();
                var token = root_oa.get_string_member ("token");
                
                if (token != "") {
                    get_username_data (username, token);
                }
            } catch (Error e) {
                debug (e.message);
            }
        }
    }

    public void get_username_data (string username, string token) {
        var uri_user = "%s/users/%s".printf (GITHUB_URI, username);

        var message = new Soup.Message ("GET", uri_user);
        message.request_headers.append ("User-Agent", "Planner");
        message.request_headers.append ("Authorization", "token " + token);
        
        session.send_message (message);
        
        var response = (string) message.response_body.flatten ().data;

        try {
            var parser = new Json.Parser ();
            parser.load_from_data (response, -1);

            var nodo = parser.get_root ().get_object ();

            var user = new Objects.User ();
            user.id = nodo.get_int_member ("id");
            user.token = token;

            if (nodo.get_string_member ("name") == null) {
                user.name = "";
            } else {
                user.name = nodo.get_string_member ("name");
            }
        
            if (nodo.get_string_member ("login") == null) {
                user.login = "";
            } else {
                user.login = nodo.get_string_member ("login");
            }
        
            if (nodo.get_string_member ("avatar_url") == null) {
                user.avatar_url = "";
            } else {
                user.avatar_url = nodo.get_string_member ("avatar_url");
            }

            if (Application.database.add_user (user) == Sqlite.DONE) {
                // Create file  
                var image_path = GLib.Path.build_filename (Application.utils.PROFILE_FOLDER, ("profile-%i.jpg").printf ((int) user.id));
        
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
        
                            get_repos (user.login, user.token, user.id);
                        }
                    } catch (Error e) {
                        print ("Error: %s\n", e.message);
                    }
        
                    loop.quit ();
                });
        
                loop.run ();
            }
        } catch (Error e) {
            stderr.printf ("Failed to connect to Github service.\n");
        }
    }

    public void get_repos (string username, string token, int64 user_id) {
        new Thread<void*> ("scan_local_files", () => {
            var uri_repos = "%s/users/%s/repos".printf (GITHUB_URI, username);

            var message = new Soup.Message ("GET", uri_repos);
            message.request_headers.append ("User-Agent", "planner");
            message.request_headers.append ("Authorization", "token " + token);

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

    public bool delete_account () {
        var user = Application.database.get_user ();
        var image_path = GLib.Path.build_filename (Application.utils.PROFILE_FOLDER, ("profile-%i.jpg").printf ((int) user.id));
        var file_path = File.new_for_path (image_path);
        
        if (file_path.query_exists ()) {
            try {
                file_path.delete ();
            } catch (Error e) {
                print ("Error: %s\n", e.message);
            }
        }

        if (Application.database.remove_all_users () == Sqlite.DONE && Application.database.remove_all_repos () == Sqlite.DONE) {
            return true;
        } else {
            return false;
        }
    }
}