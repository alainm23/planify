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

public class Services.TodoistAuth : GLib.Object {
    private Soup.Session session;

    private const string TODOIST_SYNC_URL = "https://api.todoist.com/api/v1/sync";
    private const string RESOURCE_TYPES = "[\"user\", \"projects\", \"sections\", \"items\", \"labels\", \"reminders\"]";
    private const string PROJECTS_COLLECTION = "projects";
    private const string SECTIONS_COLLECTION = "sections";
    private const string ITEMS_COLLECTION = "items";
    private const string LABELS_COLLECTION = "labels";
    private const string REMINDERS_COLLECTION = "reminders";

    public TodoistAuth (Soup.Session session) {
        this.session = session;
    }

    public async HttpResponse login (string _url, Objects.Source? migrate_source = null) {
        string code = _url.split ("=")[1];
        code = code.split ("&")[0];

        string url = "https://todoist.com/oauth/access_token?client_id=%s&client_secret=%s&code=%s".printf (
            Constants.TODOIST_CLIENT_ID, Constants.TODOIST_CLIENT_SECRET, code);

        var message = new Soup.Message ("POST", url);
        HttpResponse response = new HttpResponse ();

        try {
            GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);
            var parser = new Json.Parser ();
            parser.load_from_data ((string) stream.get_data ());

            var root = parser.get_root ().get_object ();
            var token = root.get_string_member ("access_token");

            yield add_todoist_account (token, response, migrate_source);
        } catch (Error e) {
            response.error_code = e.code;
            response.error = e.message;
            Services.LogService.get_default ().error ("Todoist", "Login failed: %s".printf (e.message));
        }

        return response;
    }

    public async HttpResponse login_token (string token, Objects.Source? migrate_source = null) {
        Services.LogService.get_default ().info ("Todoist", "Starting login with API token");
        var response = new HttpResponse ();

        try {
            yield add_todoist_account (token, response, migrate_source);
        } catch (Error e) {
            Services.LogService.get_default ().error ("Todoist", "Login with token failed: %s".printf (e.message));
            response.error_code = e.code;
            response.error = e.message;
        }

        return response;
    }

    public async void add_todoist_account (string token, HttpResponse response, Objects.Source? migrate_source = null) {
        Services.LogService.get_default ().info ("Todoist", "Adding Todoist account");

        var message = new Soup.Message ("POST", TODOIST_SYNC_URL);
        message.request_headers.append ("Authorization", "Bearer %s".printf (token));

        string form_data = "sync_token=*&resource_types=%s".printf (RESOURCE_TYPES);
        message.set_request_body_from_bytes ("application/x-www-form-urlencoded", new GLib.Bytes (form_data.data));

        try {
            GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);
            var parser = new Json.Parser ();

            if (message.status_code != 200) {
                Services.LogService.get_default ().error ("Todoist", "Authentication failed: HTTP %u".printf (message.status_code));
                response.error_code = (int) message.status_code;
                response.error = _ ("Invalid API token");
                response.status = false;
                return;
            }

            Services.LogService.get_default ().info ("Todoist", "Token validated successfully");
            parser.load_from_data ((string) stream.get_data ());

            var source = new Objects.Source ();
            source.id = Util.get_default ().generate_id ();
            source.source_type = SourceType.TODOIST;
            Objects.SourceTodoistData todoist_data = new Objects.SourceTodoistData ();

            todoist_data.sync_token = parser.get_root ().get_object ().get_string_member ("sync_token");
            todoist_data.access_token = token;
            todoist_data.api_version = "v1";
            source.sync_server = true;

            var user_object = parser.get_root ().get_object ().get_object_member ("user");
            todoist_data.user_id = user_object.get_string_member ("id");
            if (user_object.get_null_member ("image_id") == false) {
                todoist_data.user_image_id = user_object.get_string_member ("image_id");
                todoist_data.user_avatar = user_object.get_string_member ("avatar_s640");
            }

            todoist_data.user_name = user_object.get_string_member ("full_name");
            todoist_data.user_email = user_object.get_string_member ("email");
            todoist_data.user_is_premium = user_object.get_boolean_member ("is_premium");
            source.display_name = user_object.get_string_member ("email");
            source.data = todoist_data;

            if (Services.Store.instance ().source_todoist_exists (todoist_data.user_email)) {
                if (migrate_source == null || migrate_source.todoist_data.user_email != todoist_data.user_email) {
                    response.error_code = 409;
                    response.error = "Source already exists";
                    response.status = false;
                    return;
                }
            }

            Services.Store.instance ().insert_source (source);

            unowned Json.Array labels = parser.get_root ().get_object ().get_array_member (LABELS_COLLECTION);
            foreach (unowned Json.Node _node in labels.get_elements ()) {
                Objects.Label _label = new Objects.Label.from_json (_node);
                _label.source_id = source.id;
                Services.Store.instance ().insert_label (_label);
            }

            unowned Json.Array projects = parser.get_root ().get_object ().get_array_member (PROJECTS_COLLECTION);
            foreach (unowned Json.Node _node in projects.get_elements ()) {
                var _project = new Objects.Project.from_json (_node);
                _project.source_id = source.id;

                if (!_node.get_object ().get_null_member ("parent_id")) {
                    Objects.Project ? project = Services.Store.instance ().get_project (_node.get_object ().get_string_member ("parent_id"));
                    if (project != null) {
                        project.add_subproject_if_not_exists (_project);
                    }
                } else {
                    Services.Store.instance ().insert_project (_project);
                }
            }

            unowned Json.Array sections = parser.get_root ().get_object ().get_array_member (SECTIONS_COLLECTION);
            foreach (unowned Json.Node _node in sections.get_elements ()) {
                Services.Todoist.get_default ().add_section_if_not_exists (_node);
            }

            unowned Json.Array items = parser.get_root ().get_object ().get_array_member (ITEMS_COLLECTION);
            foreach (unowned Json.Node _node in items.get_elements ()) {
                Services.Todoist.get_default ().add_item_if_not_exists (_node);
            }

            unowned Json.Array reminders = parser.get_root ().get_object ().get_array_member (REMINDERS_COLLECTION);
            foreach (unowned Json.Node _node in reminders.get_elements ()) {
                Objects.Reminder reminder = new Objects.Reminder.from_json (_node);
                Objects.Item ? item = Services.Store.instance ().get_item (reminder.item_id);
                if (item != null) {
                    item.add_reminder_if_not_exists (reminder);
                }
            }

            if (user_object.get_null_member ("image_id") == false) {
                Util.get_default ().download_profile_image (
                    source.todoist_data.user_image_id, user_object.get_string_member ("avatar_s640")
                );
            }

            source.last_sync = new GLib.DateTime.now_local ().to_string ();
            source.save ();

            if (migrate_source != null) {
                check_and_update_inbox_project (migrate_source);
                migrate_source.delete_source.begin ();
            }

            response.status = true;
            Services.LogService.get_default ().info ("Todoist", "Account added successfully");
        } catch (Error e) {
            Services.LogService.get_default ().error ("Todoist", "Failed to add account: %s".printf (e.message));
            response.error_code = e.code;
            response.error = e.message;
        }
    }

    private void check_and_update_inbox_project (Objects.Source migrate_source) {
        string current_inbox_id = Services.Settings.get_default ().settings.get_string ("local-inbox-project-id");
        Objects.Project? current_inbox = Services.Store.instance ().get_project (current_inbox_id);

        if (current_inbox != null && current_inbox.source_id == migrate_source.id) {
            Objects.Project? local_inbox = get_local_inbox_project ();
            if (local_inbox != null) {
                Services.Settings.get_default ().settings.set_string ("local-inbox-project-id", local_inbox.id);
            }
        }
    }

    private Objects.Project? get_local_inbox_project () {
        foreach (Objects.Project project in Services.Store.instance ().projects) {
            if (project.source_id == SourceType.LOCAL.to_string () && project.inbox_project) {
                return project;
            }
        }
        return null;
    }

}
