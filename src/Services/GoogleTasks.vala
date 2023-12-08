/*
* Copyright © 2023 Alain M. (https://github.com/alainm23/planify)
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

public class Services.GoogleTasks : GLib.Object {
    private Soup.Session session;
    private Json.Parser parser;

    private static GoogleTasks? _instance;
    public static GoogleTasks get_default () {
        if (_instance == null) {
            _instance = new GoogleTasks ();
        }

        return _instance;
    }

    private const string CLIENT_ID = "507369778499-aqom2u384dbbqdk9j6fhrh32gfjevmnr.apps.googleusercontent.com";
    private const string CLIENT_SECRET = "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";
    private const string REDIRECT_URI = "https://github.com/alainm23/planify";
    private const string AUTH_ENDPOINT = "https://accounts.google.com/o/oauth2/auth";
    private const string TOKEN_ENDPOINT = "https://accounts.google.com/o/oauth2/token";
    private const string USERINFO_ENDPOINT = "https://www.googleapis.com/oauth2/v1/userinfo";
    private const string API_ENDPOINT = "https://tasks.googleapis.com/";

    public signal void sync_started ();
    public signal void sync_finished ();
    
    public signal void first_sync_started ();
    public signal void first_sync_finished ();
    public signal void first_sync_progress (double value);

    public signal void log_out ();
    public signal void log_in ();

    public GoogleTasks () {
        session = new Soup.Session ();
        parser = new Json.Parser ();
    }

    public async void request_access_token (string authorization_code) {
        string requestBody = "code=" + authorization_code +
                             "&client_id=" + CLIENT_ID +
                             "&client_secret=" + CLIENT_SECRET +
                             "&redirect_uri=" + REDIRECT_URI +
                             "&grant_type=authorization_code";
        
        var message = new Soup.Message ("POST", TOKEN_ENDPOINT);

        message.request_headers.append("Content-Type", "application/x-www-form-urlencoded");
        message.set_request_body_from_bytes("application/x-www-form-urlencoded", new GLib.Bytes (requestBody.data));

        try {
            GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);
            parser.load_from_data ((string) stream.get_data ());
            
            // Debug
            print_root (parser.get_root ());

            var root = parser.get_root ().get_object ();

            var access_token = root.get_string_member ("access_token");
            var refresh_token = root.get_string_member ("refresh_token");

            Services.Settings.get_default ().settings.set_string ("google-access-token", access_token);
            Services.Settings.get_default ().settings.set_string ("google-refresh-token", refresh_token);

            first_sync_started ();

            yield get_google_profile_user (access_token);
            yield get_taskslist (access_token);

            first_sync_finished ();
        } catch (Error e) {

        }
    }

    private async void get_google_profile_user (string access_token) {
        string url = USERINFO_ENDPOINT;

        var message = new Soup.Message ("GET", url);
        message.request_headers.append ("Authorization", "Bearer %s".printf (access_token));

        try {
            GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);
            parser.load_from_data ((string) stream.get_data ());

            // Debug
            print_root (parser.get_root ());

            if (!parser.get_root ().get_object ().has_member ("error")) {
                var user_object = parser.get_root ().get_object ();
                Services.Settings.get_default ().settings.set_string ("google-user-name", user_object.get_string_member ("name"));
                Services.Settings.get_default ().settings.set_string ("google-user-email", user_object.get_string_member ("email"));

                // Download Profile Image
                if (user_object.get_null_member ("picture") == false) {
                    Util.get_default ().download_profile_image (
                        "google-user", user_object.get_string_member ("picture")
                    );
                }
            }
        } catch (Error e) {
            debug (e.message);
        }
    }

    private async void  get_taskslist (string access_token) {
        string url = API_ENDPOINT + "tasks/v1/users/@me/lists";

        var message = new Soup.Message ("GET", url);
        message.request_headers.append ("Authorization", "Bearer %s".printf (access_token));

        try {
            GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);
            parser.load_from_data ((string) stream.get_data ());

            // Debug
            print_root (parser.get_root ());

            unowned Json.Array _taskslist = parser.get_root ().get_object ().get_array_member ("items");
            foreach (unowned Json.Node _node in _taskslist.get_elements ()) {
                Objects.Project? project = Services.Database.get_default ().get_project (_node.get_object ().get_string_member ("id"));
                if (project != null) {
                    //  if (_node.get_object ().get_boolean_member ("is_deleted")) {
                    //      Services.Database.get_default ().delete_project (project);
                    //  } else {
                    //      string old_parent_id = project.parent_id;
                    //      bool old_is_favorite = project.is_favorite;

                    //      project.update_from_json (_node);
                    //      Services.Database.get_default ().update_project (project);

                    //      if (project.parent_id != old_parent_id) {
                    //          Services.EventBus.get_default ().project_parent_changed (project, old_parent_id);
                    //      }

                    //      if (project.is_favorite != old_is_favorite) {
                    //          Services.EventBus.get_default ().favorite_toggled (project);
                    //      }
                    //  }
                } else {
                    Services.Database.get_default ().insert_project (new Objects.Project.from_google_tasklist_json (_node));
                }
            }
        } catch (Error e) {
            debug (e.message);
        }
    }

    public bool invalid_token () {
        return Services.Settings.get_default ().settings.get_string ("google-access-token").strip () == "";
    }

    public void init () {
        if (invalid_token ()) {
            var dialog = new Dialogs.GoogleOAuth ();            
            dialog.show ();
        }
    }

    public void remove_items () {
        Services.Settings.get_default ().settings.set_string ("google-access-token", "");
        Services.Settings.get_default ().settings.set_string ("google-refresh-token", "");
        Services.Settings.get_default ().settings.set_string ("google-user-email", "");
        Services.Settings.get_default ().settings.set_string ("google-user-name", "");

        log_out ();
    }

    public bool is_logged_in () {
        return !invalid_token ();
    }

    private void print_root (Json.Node root) {
        Json.Generator generator = new Json.Generator ();
        generator.set_root (root);
        print (generator.to_data (null) + "\n");
    }
}