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

public class Services.Todoist : GLib.Object {
    private Soup.Session session;
    private Json.Parser parser;

    private const string TODOIST_SYNC_URL = "https://api.todoist.com/api/v1/sync";
    private const string RESOURCE_TYPES = "[\"user\", \"projects\", \"sections\", \"items\", \"labels\", \"reminders\"]";
    private const string PROJECTS_COLLECTION = "projects";
    private const string SECTIONS_COLLECTION = "sections";
    private const string ITEMS_COLLECTION = "items";
    private const string LABELS_COLLECTION = "labels";
    private const string REMINDERS_COLLECTION = "reminders";

    private static Todoist ? _instance;
    public static Todoist get_default () {
        if (_instance == null) {
            _instance = new Todoist ();
        }

        return _instance;
    }

    public Todoist () {
        session = new Soup.Session ();
        parser = new Json.Parser ();
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

            parser.load_from_data ((string) stream.get_data ());

            var root = parser.get_root ().get_object ();
            var token = root.get_string_member ("access_token");

            yield add_todoist_account (token, response, migrate_source);
        } catch (Error e) {
            response.error_code = e.code;
            response.error = e.message;
            error (e.message);
        }

        return response;
    }

    public async HttpResponse login_token (string token, Objects.Source? migrate_source = null) {
        var response = new HttpResponse ();

        try {
            yield add_todoist_account (token, response, migrate_source);
        } catch (Error e) {
            response.error_code = e.code;
            response.error = e.message;
            error (e.message);
        }

        return response;
    }

    public async void add_todoist_account (string token, HttpResponse response, Objects.Source? migrate_source = null) {
        var message = new Soup.Message ("POST", TODOIST_SYNC_URL);
        message.request_headers.append ("Authorization", "Bearer %s".printf (token));
        
        string form_data = "sync_token=*&resource_types=%s".printf (RESOURCE_TYPES);
        message.set_request_body_from_bytes ("application/x-www-form-urlencoded", new GLib.Bytes (form_data.data));

        try {
            GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);

            parser.load_from_data ((string) stream.get_data ());

            var source = new Objects.Source ();
            source.id = Util.get_default ().generate_id ();
            source.source_type = SourceType.TODOIST;
            Objects.SourceTodoistData todoist_data = new Objects.SourceTodoistData ();

            todoist_data.sync_token = parser.get_root ().get_object ().get_string_member ("sync_token");
            todoist_data.access_token = token;
            todoist_data.api_version = "v1";
            source.sync_server = true;

            // Create user
            var user_object = parser.get_root ().get_object ().get_object_member ("user");
            todoist_data.user_id = user_object.get_string_member ("id");
            if (user_object.get_null_member ("image_id") == false) {
                todoist_data.user_image_id = user_object.get_string_member ("image_id");
                todoist_data.user_avatar = user_object.get_string_member ("avatar_s640");
            }

            // Set Inbox
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

            // Create Labels
            unowned Json.Array labels = parser.get_root ().get_object ().get_array_member (LABELS_COLLECTION);
            foreach (unowned Json.Node _node in labels.get_elements ()) {
                Objects.Label _label = new Objects.Label.from_json (_node);
                _label.source_id = source.id;

                Services.Store.instance ().insert_label (_label);
            }

            // Create Projects
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

            // Create Reminders
            unowned Json.Array reminders = parser.get_root ().get_object ().get_array_member (REMINDERS_COLLECTION);
            foreach (unowned Json.Node _node in reminders.get_elements ()) {
                Objects.Reminder reminder = new Objects.Reminder.from_json (_node);
                Objects.Item ? item = Services.Store.instance ().get_item (reminder.item_id);
                if (item != null) {
                    item.add_reminder_if_not_exists (reminder);
                }
            }

            // Download Profile Image
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
        } catch (Error e) {
            response.error_code = e.code;
            response.error = e.message;
            debug (e.message);
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
            if (project.backend_type == SourceType.LOCAL && project.inbox_project) {
                return project;
            }
        }
        return null;
    }

    /*
     *   Sync
     */

    public async void sync (Objects.Source source) {
        if (source.todoist_data.access_token == null) {
            return;
        }

        // Don't sync if account needs migration
        if (source.needs_migration ()) {
            source.sync_failed ();
            return;
        }

        source.sync_started ();

        var message = new Soup.Message ("POST", TODOIST_SYNC_URL);
        message.request_headers.append ("Authorization", "Bearer %s".printf (source.todoist_data.access_token));
        
        string form_data = "sync_token=%s&resource_types=%s".printf (
            source.todoist_data.sync_token,
            RESOURCE_TYPES
        );
        message.set_request_body_from_bytes ("application/x-www-form-urlencoded", new GLib.Bytes (form_data.data));

        try {
            GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.LOW, null);

            parser.load_from_data ((string) stream.get_data ());

            if (!parser.get_root ().get_object ().has_member ("error")) {
                // Update sync token
                source.todoist_data.sync_token = parser.get_root ().get_object ().get_string_member ("sync_token");

                // Update user
                if (parser.get_root ().get_object ().has_member ("user")) {
                    var user_object = parser.get_root ().get_object ().get_object_member ("user");
                    source.todoist_data.user_id = user_object.get_string_member ("id");
                    source.todoist_data.user_is_premium = user_object.get_boolean_member ("is_premium");
                    source.todoist_data.user_email = user_object.get_string_member ("email");
                    source.todoist_data.user_name = user_object.get_string_member ("full_name");
                }

                // Labels
                unowned Json.Array _labels = parser.get_root ().get_object ().get_array_member (LABELS_COLLECTION);
                foreach (unowned Json.Node _node in _labels.get_elements ()) {
                    string _id = _node.get_object ().get_string_member ("id");
                    Objects.Label ? label = Services.Store.instance ().get_label (_id);
                    if (label != null) {
                        if (_node.get_object ().get_boolean_member ("is_deleted")) {
                            Services.Store.instance ().delete_label (label);
                        } else {
                            label.update_from_json (_node);
                            Services.Store.instance ().update_label (label);
                        }
                    } else {
                        Objects.Label _label = new Objects.Label.from_json (_node);
                        _label.source_id = source.id;

                        Services.Store.instance ().insert_label (_label);
                    }
                }

                // Projects
                unowned Json.Array projects = parser.get_root ().get_object ().get_array_member (PROJECTS_COLLECTION);
                foreach (unowned Json.Node _node in projects.get_elements ()) {
                    Objects.Project ? project = Services.Store.instance ().get_project (_node.get_object ().get_string_member ("id"));
                    if (project != null) {
                        if (_node.get_object ().get_boolean_member ("is_deleted")) {
                            Services.Store.instance ().delete_project (project);
                        } else {
                            string old_parent_id = project.parent_id;
                            bool old_is_favorite = project.is_favorite;

                            project.update_from_json (_node);
                            Services.Store.instance ().update_project (project);

                            if (project.parent_id != old_parent_id) {
                                Services.EventBus.get_default ().project_parent_changed (project, old_parent_id);
                            }

                            if (project.is_favorite != old_is_favorite) {
                                Services.EventBus.get_default ().favorite_toggled (project);
                            }
                        }
                    } else {
                        var _project = new Objects.Project.from_json (_node);
                        _project.source_id = source.id;

                        Services.Store.instance ().insert_project (_project);
                    }
                }

                foreach (var project in Services.Store.instance ().get_projects_by_source (source.id)) {
                    project.freeze_update = true;
                }

                // Sections
                unowned Json.Array sections = parser.get_root ().get_object ().get_array_member (SECTIONS_COLLECTION);
                foreach (unowned Json.Node _node in sections.get_elements ()) {
                    Objects.Section ? section = Services.Store.instance ().get_section (_node.get_object ().get_string_member ("id"));
                    if (section != null) {
                        if (_node.get_object ().get_boolean_member ("is_deleted")) {
                            Services.Store.instance ().delete_section (section);
                        } else {
                            section.update_from_json (_node);
                            Services.Store.instance ().update_section (section);
                        }
                    } else {
                        add_section_if_not_exists (_node);
                    }
                }

                // Items
                unowned Json.Array items = parser.get_root ().get_object ().get_array_member (ITEMS_COLLECTION);
                foreach (unowned Json.Node _node in items.get_elements ()) {
                    Objects.Item ? item = Services.Store.instance ().get_item (_node.get_object ().get_string_member ("id"));
                    if (item != null) {
                        if (_node.get_object ().get_boolean_member ("is_deleted")) {
                            Services.Store.instance ().delete_item (item);
                        } else {
                            string old_project_id = item.project_id;
                            string old_section_id = item.section_id;
                            string old_parent_id = item.parent_id;
                            bool old_checked = item.checked;

                            item.update_from_json (_node);
                            Services.Store.instance ().update_item (item);

                            if (old_project_id != item.project_id || old_section_id != item.section_id ||
                                old_parent_id != item.parent_id) {
                                Services.EventBus.get_default ().item_moved (item, old_project_id, old_section_id, old_parent_id);
                            }

                            if (old_checked != item.checked) {
                                Services.Store.instance ().complete_item (item, old_checked);
                            }
                        }
                    } else {
                        add_item_if_not_exists (_node);
                    }
                }

                // Reminders
                unowned Json.Array reminders = parser.get_root ().get_object ().get_array_member (REMINDERS_COLLECTION);
                foreach (unowned Json.Node _node in reminders.get_elements ()) {
                    Objects.Reminder ? reminder = Services.Store.instance ().get_reminder (_node.get_object ().get_string_member ("id"));

                    if (reminder != null) {
                        if (_node.get_object ().get_boolean_member ("is_deleted")) {
                            Services.Store.instance ().delete_reminder (reminder);
                        }
                    } else {
                        reminder = new Objects.Reminder.from_json (_node);

                        Objects.Item ? item = Services.Store.instance ().get_item (reminder.item_id);
                        if (item != null) {
                            item.add_reminder_if_not_exists (reminder);
                        }
                    }
                }

                yield queue (source);
            }
        } catch (Error e) {
            debug ("Failed to sync: " + e.message);
            source.sync_failed ();
        }

        source.last_sync = new GLib.DateTime.now_local ().to_string ();
        foreach (var project in Services.Store.instance ().get_projects_by_source (source.id)) {
            project.freeze_update = false;
            project.count_update ();
            Services.Store.instance ().update_project (project);
        }

        source.sync_finished ();
    }

    /*
     *   Queue
     */

    public async void queue (Objects.Source source) {
        Gee.ArrayList<Objects.Queue ?> queue_collection = Services.Database.get_default ().get_all_queue ();
        if (queue_collection.size <= 0) {
            return;
        }

        string json = get_queue_json (queue_collection);

        var message = new Soup.Message ("POST", TODOIST_SYNC_URL);
        message.request_headers.append (
            "Authorization",
            "Bearer %s".printf (source.todoist_data.access_token)
        );
        message.set_request_body_from_bytes ("application/json", new Bytes (json.data));

        try {
            GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.LOW, null);

            parser.load_from_data ((string) stream.get_data ());

            var node = parser.get_root ().get_object ();
            string sync_token = node.get_string_member ("sync_token");
            source.todoist_data.sync_token = sync_token;

            foreach (var q in queue_collection) {
                var uuid_member = node.get_object_member ("sync_status").get_member (q.uuid);
                if (uuid_member.get_node_type () == Json.NodeType.VALUE) {
                    if (q.query == "project_add") {
                        var id = node.get_object_member ("temp_id_mapping").get_string_member (q.temp_id);
                        Services.Store.instance ().update_project_id (q.object_id, id);
                        Services.Database.get_default ().remove_CurTempIds (q.object_id);
                    }

                    if (q.query == "section_add") {
                        var id = node.get_object_member ("temp_id_mapping").get_string_member (q.temp_id);
                        Services.Store.instance ().update_section_id (q.object_id, id);
                        Services.Database.get_default ().remove_CurTempIds (q.object_id);
                    }

                    if (q.query == "item_add") {
                        var id = node.get_object_member ("temp_id_mapping").get_string_member (q.temp_id);
                        Services.Store.instance ().update_item_id (q.object_id, id);
                        Services.Database.get_default ().remove_CurTempIds (q.object_id);
                    }

                    Services.Database.get_default ().remove_queue (q.uuid);
                }
            }
        } catch (Error e) {
            debug (e.message);
        }
    }

    public string get_queue_json (Gee.ArrayList<Objects.Queue ?> queue) {
        var builder = new Json.Builder ();
        builder.begin_object ();
        builder.set_member_name ("commands");

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
                builder.add_string_value (get_string_member_by_object (q.args, "color"));

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
                builder.add_string_value (get_string_member_by_object (q.args, "id"));

                builder.set_member_name ("name");
                builder.add_string_value (get_string_member_by_object (q.args, "name"));

                builder.set_member_name ("color");
                builder.add_string_value (get_string_member_by_object (q.args, "color"));

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
                builder.add_string_value (get_string_member_by_object (q.args, "id"));

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
                    builder.add_string_value (get_string_member_by_object (q.args, "project_id"));
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
                builder.add_string_value (get_string_member_by_object (q.args, "id"));

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
                builder.add_string_value (get_string_member_by_object (q.args, "id"));

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
                builder.add_string_value (get_string_member_by_object (q.args, "id"));

                builder.set_member_name ("project_id");
                builder.add_string_value (get_string_member_by_object (q.args, "project_id"));

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

                builder.set_member_name ("description");
                builder.add_string_value (get_string_member_by_object (q.args, "description"));

                builder.set_member_name ("priority");
                builder.add_int_value (get_int_member_by_object (q.args, "priority"));

                builder.set_member_name ("project_id");
                builder.add_string_value (get_string_member_by_object (q.args, "project_id"));

                builder.set_member_name ("section_id");
                builder.add_string_value (get_string_member_by_object (q.args, "section_id"));

                builder.set_member_name ("parent_id");
                builder.add_string_value (get_string_member_by_object (q.args, "parent_id"));

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
                builder.add_string_value (get_string_member_by_object (q.args, "id"));

                builder.set_member_name ("content");
                builder.add_string_value (get_string_member_by_object (q.args, "content"));

                builder.set_member_name ("description");
                builder.add_string_value (get_string_member_by_object (q.args, "description"));

                builder.set_member_name ("priority");
                builder.add_int_value (get_int_member_by_object (q.args, "priority"));

                if (is_null_member (q.args, "due")) {
                    builder.set_member_name ("due");
                    builder.add_null_value ();
                } else {
                    builder.set_member_name ("due");
                    builder.begin_object ();

                    Json.Object due = get_object_member_by_object (q.args, "due");

                    builder.set_member_name ("date");
                    builder.add_string_value (due.get_string_member ("date"));

                    builder.end_object ();
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
                builder.add_string_value (get_string_member_by_object (q.args, "id"));

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
                builder.add_string_value (get_string_member_by_object (q.args, "id"));

                string type = get_string_member_by_object (q.args, "type");

                builder.set_member_name (type);
                builder.add_string_value (get_string_member_by_object (q.args, type));

                builder.end_object ();
                builder.end_object ();
            } else if (q.query == "item_complete" || q.query == "item_uncomplete") {
                builder.set_member_name ("type");
                builder.add_string_value (q.query);

                builder.set_member_name ("uuid");
                builder.add_string_value (q.uuid);

                builder.set_member_name ("args");
                builder.begin_object ();

                builder.set_member_name ("id");
                builder.add_string_value (get_string_member_by_object (q.args, "id"));

                builder.end_object ();
                builder.end_object ();
            }

            builder.end_object ();
        }

        builder.end_array ();
        builder.end_object ();

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

    public Json.Object get_object_member_by_object (string object, string member) {
        return get_object_by_string (object).get_object_member (member);
    }

    public GLib.Type get_type_by_member (string object, string member) {
        return get_object_by_string (object).get_member (member).get_value_type ();
    }

    public bool is_null_member (string object, string member) {
        return get_object_by_string (object).get_null_member (member);
    }

    private void add_item_if_not_exists (Json.Node node) {
        if (!node.get_object ().get_null_member ("parent_id")) {
            Objects.Item ? item = Services.Store.instance ().get_item (node.get_object ().get_string_member ("parent_id"));
            if (item != null) {
                item.add_item_if_not_exists (new Objects.Item.from_json (node));
            }

            return;
        }

        if (!node.get_object ().get_null_member ("section_id")) {
            Objects.Section ? section = Services.Store.instance ().get_section (node.get_object ().get_string_member ("section_id"));
            if (section != null) {
                section.add_item_if_not_exists (new Objects.Item.from_json (node));
            }
        } else {
            Objects.Project ? project = Services.Store.instance ().get_project (node.get_object ().get_string_member ("project_id"));
            if (project != null) {
                project.add_item_if_not_exists (new Objects.Item.from_json (node));
            }
        }
    }

    public async HttpResponse add (Objects.BaseObject object) {
        string temp_id = Util.get_default ().generate_string ();
        string uuid = Util.get_default ().generate_string ();
        string id;
        string json = object.get_add_json (temp_id, uuid);

        var message = new Soup.Message ("POST", TODOIST_SYNC_URL);
        message.request_headers.append (
            "Authorization",
            "Bearer %s".printf (object.source.todoist_data.access_token)
        );
        message.set_request_body_from_bytes ("application/json", new Bytes (json.data));

        HttpResponse response = new HttpResponse ();

        try {
            GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);

            parser.load_from_data ((string) stream.get_data ());

            if (is_todoist_error (message.status_code)) {
                response.from_error_json (parser.get_root ());

                debug_error (
                    message.status_code,
                    get_todoist_error (message.status_code)
                );
            } else {
                var sync_status = parser.get_root ().get_object ().get_object_member ("sync_status");
                var uuid_member = sync_status.get_member (uuid);

                if (uuid_member.get_node_type () == Json.NodeType.VALUE) {
                    object.source.todoist_data.sync_token = parser.get_root ().get_object ().get_string_member ("sync_token");
                    object.source.last_sync = new GLib.DateTime.now_local ().to_string ();
                    object.source.save ();

                    id = parser.get_root ().get_object ().get_object_member ("temp_id_mapping").get_string_member (temp_id);

                    response.status = true;
                    response.data = id;
                } else {
                    response.error = sync_status.get_object_member (uuid).get_string_member ("error");

                    debug_error (
                        (uint) sync_status.get_object_member (uuid).get_int_member ("http_code"),
                        sync_status.get_object_member (uuid).get_string_member ("error")
                    );
                }
            }
        } catch (Error e) {
            if (is_todoist_error (message.status_code)) {
                response.error = e.message;

                debug_error (
                    message.status_code,
                    e.message
                );
            } else {
                id = Util.get_default ().generate_id (object);

                var queue = new Objects.Queue ();
                queue.uuid = uuid;
                queue.object_id = id;
                queue.temp_id = temp_id;
                queue.query = object.type_add;
                queue.args = object.to_json ();

                Services.Database.get_default ().insert_queue (queue);
                Services.Database.get_default ().insert_CurTempIds (object.id, temp_id, object.object_type_string);

                response.status = true;
                response.data = queue.object_id;
            }
        }

        return response;
    }

    private void debug_error (uint status_code, string message) {
        debug ("Code: %s - %s".printf (status_code.to_string (), message));
    }

    public async HttpResponse update (Objects.BaseObject object) {
        string uuid = Util.get_default ().generate_string ();
        string json = object.get_update_json (uuid);

        Objects.Source source = object.source;

        var message = new Soup.Message ("POST", TODOIST_SYNC_URL);
        message.request_headers.append (
            "Authorization",
            "Bearer %s".printf (source.todoist_data.access_token)
        );
        message.set_request_body_from_bytes ("application/json", new Bytes (json.data));

        HttpResponse response = new HttpResponse ();

        try {
            GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);

            parser.load_from_data ((string) stream.get_data ());

            if (is_todoist_error (message.status_code)) {
                response.from_error_json (parser.get_root ());

                debug_error (
                    message.status_code,
                    get_todoist_error (message.status_code)
                );
            } else {
                var sync_status = parser.get_root ().get_object ().get_object_member ("sync_status");
                var uuid_member = sync_status.get_member (uuid);

                if (uuid_member.get_node_type () == Json.NodeType.VALUE) {
                    source.todoist_data.sync_token = parser.get_root ().get_object ().get_string_member ("sync_token");
                    response.status = true;

                    source.last_sync = new GLib.DateTime.now_local ().to_string ();
                    source.save ();
                } else {
                    response.error = sync_status.get_object_member (uuid).get_string_member ("error");

                    debug_error (
                        (uint) sync_status.get_object_member (uuid).get_int_member ("http_code"),
                        sync_status.get_object_member (uuid).get_string_member ("error")
                    );
                }
            }
        } catch (Error e) {
            if (is_todoist_error (message.status_code)) {
                response.error = e.message;

                debug_error (
                    message.status_code,
                    e.message
                );
            } else {
                var queue = new Objects.Queue ();
                queue.uuid = uuid;
                queue.object_id = object.id;
                queue.query = object.type_update;
                queue.args = object.to_json ();

                Services.Database.get_default ().insert_queue (queue);
                response.status = true;
            }
        }

        return response;
    }

    public async void update_items (Gee.ArrayList<Objects.Item> objects) {
        string json = get_update_items_json (objects);

        Objects.Source ? source = null;
        foreach (Objects.Item item in objects) {
            if (item.source != null) {
                source = item.source;
                break;
            }
        }

        if (source == null) {
            warning ("No valid source found in items");
            return;
        }

        var message = new Soup.Message ("POST", TODOIST_SYNC_URL);
        message.request_headers.append (
            "Authorization",
            "Bearer %s".printf (source.todoist_data.access_token)
        );
        message.set_request_body_from_bytes ("application/json", new Bytes (json.data));

        try {
            GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);

            parser.load_from_data ((string) stream.get_data ());

            if (is_todoist_error (message.status_code)) {
                debug_error (
                    message.status_code,
                    get_todoist_error (message.status_code)
                );
            } else {
                source.todoist_data.sync_token = parser.get_root ().get_object ().get_string_member ("sync_token");
                source.last_sync = new GLib.DateTime.now_local ().to_string ();
                source.save ();
            }
        } catch (Error e) {
            error (e.message);
        }
    }

    public string get_update_items_json (Gee.ArrayList<Objects.Item> objects) {
        var builder = new Json.Builder ();

        builder.begin_object ();
        builder.set_member_name ("commands");

        builder.begin_array ();
        foreach (var item in objects) {
            builder.begin_object ();

            builder.set_member_name ("type");
            builder.add_string_value ("item_update");

            builder.set_member_name ("uuid");
            builder.add_string_value (Util.get_default ().generate_string ());

            builder.set_member_name ("args");
            builder.begin_object ();

            builder.set_member_name ("id");
            builder.add_string_value (item.id);

            builder.set_member_name ("content");
            builder.add_string_value (Util.get_default ().get_encode_text (item.content));

            builder.set_member_name ("description");
            builder.add_string_value (Util.get_default ().get_encode_text (item.description));

            builder.set_member_name ("priority");
            if (item.priority == 0) {
                builder.add_int_value (Constants.PRIORITY_4);
            } else {
                builder.add_int_value (item.priority);
            }

            if (item.has_due) {
                builder.set_member_name ("due");
                builder.begin_object ();

                builder.set_member_name ("date");
                builder.add_string_value (item.due.date);

                builder.end_object ();
            } else {
                builder.set_member_name ("due");
                builder.add_null_value ();
            }

            builder.set_member_name ("labels");
            builder.begin_array ();
            foreach (Objects.Label label in item.labels) {
                builder.add_string_value (label.name);
            }
            builder.end_array ();
            builder.end_object ();
            builder.end_object ();
        }
        builder.end_array ();
        builder.end_object ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);
        return generator.to_data (null);
    }

    public async HttpResponse delete (Objects.BaseObject object) {
        string uuid = Util.get_default ().generate_string ();
        string json = get_delete_json (object.id, object.type_delete, uuid);

        var message = new Soup.Message ("POST", TODOIST_SYNC_URL);
        message.request_headers.append (
            "Authorization",
            "Bearer %s".printf (object.source.todoist_data.access_token)
        );
        message.set_request_body_from_bytes ("application/json", new Bytes (json.data));

        HttpResponse response = new HttpResponse ();

        try {
            GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);

            parser.load_from_data ((string) stream.get_data ());

            if (is_todoist_error (message.status_code)) {
                response.from_error_json (parser.get_root ());

                debug_error (
                    message.status_code,
                    get_todoist_error (message.status_code)
                );
            } else {
                var sync_status = parser.get_root ().get_object ().get_object_member ("sync_status");
                var uuid_member = sync_status.get_member (uuid);

                if (uuid_member.get_node_type () == Json.NodeType.VALUE) {
                    object.source.todoist_data.sync_token = parser.get_root ().get_object ().get_string_member ("sync_token");
                    object.source.last_sync = new GLib.DateTime.now_local ().to_string ();
                    object.source.save ();

                    response.status = true;
                } else {
                    response.error = sync_status.get_object_member (uuid).get_string_member ("error");

                    debug_error (
                        (uint) sync_status.get_object_member (uuid).get_int_member ("http_code"),
                        sync_status.get_object_member (uuid).get_string_member ("error")
                    );
                }
            }
        } catch (Error e) {
            if (is_todoist_error (message.status_code)) {
                response.error = e.message;

                debug_error (
                    message.status_code,
                    e.message
                );
            } else {
                var queue = new Objects.Queue ();
                queue.uuid = uuid;
                queue.object_id = object.id;
                queue.query = object.type_delete;
                queue.args = object.to_json ();

                Services.Database.get_default ().insert_queue (queue);
                response.status = true;
            }
        }

        return response;
    }

    /*
        Sections
     */

    private void add_section_if_not_exists (Json.Node node) {
        string _id = node.get_object ().get_string_member ("project_id");
        Objects.Project ? project = Services.Store.instance ().get_project (_id);
        if (project != null) {
            project.add_section_if_not_exists (new Objects.Section.from_json (node));
        }
    }

    /*
        Items
     */

    public async HttpResponse complete_item (Objects.Item item) {
        string uuid = Util.get_default ().generate_string ();
        string json = item.get_check_json (uuid, item.checked ? "item_complete" : "item_uncomplete");
        Objects.Source source = item.source;

        var message = new Soup.Message ("POST", TODOIST_SYNC_URL);
        message.request_headers.append (
            "Authorization",
            "Bearer %s".printf (source.todoist_data.access_token)
        );
        message.set_request_body_from_bytes ("application/json", new Bytes (json.data));

        HttpResponse response = new HttpResponse ();

        try {
            GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);

            parser.load_from_data ((string) stream.get_data ());

            if (is_todoist_error (message.status_code)) {
                response.from_error_json (parser.get_root ());

                debug_error (
                    message.status_code,
                    get_todoist_error (message.status_code)
                );
            } else {
                var sync_status = parser.get_root ().get_object ().get_object_member ("sync_status");
                var uuid_member = sync_status.get_member (uuid);

                if (uuid_member.get_node_type () == Json.NodeType.VALUE) {
                    source.todoist_data.sync_token = parser.get_root ().get_object ().get_string_member ("sync_token");
                    response.status = true;

                    source.last_sync = new GLib.DateTime.now_local ().to_string ();
                    source.save ();
                } else {
                    response.error = sync_status.get_object_member (uuid).get_string_member ("error");

                    debug_error (
                        (uint) sync_status.get_object_member (uuid).get_int_member ("http_code"),
                        sync_status.get_object_member (uuid).get_string_member ("error")
                    );
                }
            }
        } catch (Error e) {
            if (is_todoist_error (message.status_code)) {
                response.error = e.message;

                debug_error (
                    message.status_code,
                    e.message
                );
            } else {
                var queue = new Objects.Queue ();
                queue.uuid = uuid;
                queue.object_id = item.id;
                queue.query = item.checked ? "item_complete" : "item_uncomplete";
                queue.args = item.to_json ();

                Services.Database.get_default ().insert_queue (queue);
                response.status = true;
            }
        }

        return response;
    }

    private void print_root (Json.Node root) {
        Json.Generator generator = new Json.Generator ();
        generator.set_root (root);
        debug (generator.to_data (null) + "\n");
    }

    public string get_delete_json (string id, string type, string uuid) {
        var builder = new Json.Builder ();
        builder.begin_object ();
        builder.set_member_name ("commands");
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
        builder.add_string_value (id);

        builder.end_object ();

        builder.end_object ();
        builder.end_array ();
        builder.end_object ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);

        return generator.to_data (null);
    }

    public async HttpResponse move_item (Objects.Item item, string type, string id) {
        string uuid = Util.get_default ().generate_string ();
        string json = item.get_move_item (uuid, type, id);
        Objects.Source source = item.source;

        var message = new Soup.Message ("POST", TODOIST_SYNC_URL);
        message.request_headers.append (
            "Authorization",
            "Bearer %s".printf (source.todoist_data.access_token)
        );
        message.set_request_body_from_bytes ("application/json", new Bytes (json.data));

        HttpResponse response = new HttpResponse ();

        try {
            GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);

            parser.load_from_data ((string) stream.get_data ());

            if (is_todoist_error (message.status_code)) {
                response.from_error_json (parser.get_root ());

                debug_error (
                    message.status_code,
                    get_todoist_error (message.status_code)
                );
            } else {
                var sync_status = parser.get_root ().get_object ().get_object_member ("sync_status");
                var uuid_member = sync_status.get_member (uuid);

                if (uuid_member.get_node_type () == Json.NodeType.VALUE) {
                    source.todoist_data.sync_token = parser.get_root ().get_object ().get_string_member ("sync_token");
                    response.status = true;

                    source.last_sync = new GLib.DateTime.now_local ().to_string ();
                    source.save ();
                } else {
                    response.error = sync_status.get_object_member (uuid).get_string_member ("error");

                    debug_error (
                        (uint) sync_status.get_object_member (uuid).get_int_member ("http_code"),
                        sync_status.get_object_member (uuid).get_string_member ("error")
                    );
                }
            }
        } catch (Error e) {
            if (is_todoist_error (message.status_code)) {
                response.error = e.message;

                debug_error (
                    message.status_code,
                    e.message
                );
            } else {
                var queue = new Objects.Queue ();
                queue.uuid = uuid;
                queue.object_id = item.id;
                queue.query = "item_move";
                queue.args = item.to_move_json (type, id);

                Services.Database.get_default ().insert_queue (queue);
                response.status = true;
            }
        }

        return response;
    }

    public async HttpResponse move_project_section (Objects.BaseObject base_object, string project_id) {
        string uuid = Util.get_default ().generate_string ();
        string json = base_object.get_move_json (uuid, project_id);

        var message = new Soup.Message ("POST", TODOIST_SYNC_URL);
        message.request_headers.append (
            "Authorization",
            "Bearer %s".printf (base_object.source.todoist_data.access_token)
        );
        message.set_request_body_from_bytes ("application/json", new Bytes (json.data));

        HttpResponse response = new HttpResponse ();

        try {
            GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);

            parser.load_from_data ((string) stream.get_data ());

            if (is_todoist_error (message.status_code)) {
                response.from_error_json (parser.get_root ());

                debug_error (
                    message.status_code,
                    get_todoist_error (message.status_code)
                );
            } else {
                var sync_status = parser.get_root ().get_object ().get_object_member ("sync_status");
                var uuid_member = sync_status.get_member (uuid);

                if (uuid_member.get_node_type () == Json.NodeType.VALUE) {
                    base_object.source.todoist_data.sync_token = parser.get_root ().get_object ().get_string_member ("sync_token");
                    response.status = true;

                    base_object.source.last_sync = new GLib.DateTime.now_local ().to_string ();
                    base_object.source.save ();
                } else {
                    response.error = sync_status.get_object_member (uuid).get_string_member ("error");

                    debug_error (
                        (uint) sync_status.get_object_member (uuid).get_int_member ("http_code"),
                        sync_status.get_object_member (uuid).get_string_member ("error")
                    );
                }
            }
        } catch (Error e) {
            if (is_todoist_error (message.status_code)) {
                response.error = e.message;

                debug_error (
                    message.status_code,
                    e.message
                );
            } else {
                var queue = new Objects.Queue ();
                queue.uuid = uuid;
                queue.object_id = base_object.id;
                if (base_object is Objects.Project) {
                    queue.query = "project_move";
                } else {
                    queue.query = "section_move";
                }

                queue.args = base_object.to_json ();
                response.status = true;

                Services.Database.get_default ().insert_queue (queue);
            }
        }

        return response;
    }

    public async HttpResponse duplicate_project (Objects.Project project) {
        string json = get_duplicate_project_json (project);

        var message = new Soup.Message ("POST", TODOIST_SYNC_URL);
        message.request_headers.append (
            "Authorization",
            "Bearer %s".printf (project.source.todoist_data.access_token)
        );
        message.set_request_body_from_bytes ("application/json", new Bytes (json.data));

        HttpResponse response = new HttpResponse ();

        try {
            GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);

            parser.load_from_data ((string) stream.get_data ());

            if (is_todoist_error (message.status_code)) {
                response.from_error_json (parser.get_root ());

                debug_error (
                    message.status_code,
                    get_todoist_error (message.status_code)
                );
            } else {
                response.status = true;
            }
        } catch (Error e) {
        }

        return response;
    }

    private string get_duplicate_project_json (Objects.Project project) {
        var builder = new Json.Builder ();

        builder.begin_object ();
        builder.set_member_name ("commands");
        builder.begin_array ();
        // New Project
        builder.begin_object ();

        builder.set_member_name ("type");
        builder.add_string_value ("project_add");

        builder.set_member_name ("temp_id");
        builder.add_string_value ("_" + project.id);

        builder.set_member_name ("uuid");
        builder.add_string_value (Util.get_default ().generate_string ());

        builder.set_member_name ("args");
        builder.begin_object ();

        builder.set_member_name ("name");
        builder.add_string_value (project.name);

        builder.set_member_name ("color");
        builder.add_string_value (project.color);

        builder.end_object ();
        builder.end_object ();

        // Sections
        foreach (Objects.Section section in project.sections) {
            builder.begin_object ();

            builder.set_member_name ("type");
            builder.add_string_value ("section_add");

            builder.set_member_name ("temp_id");
            builder.add_string_value ("_" + section.id);

            builder.set_member_name ("uuid");
            builder.add_string_value (Util.get_default ().generate_string ());

            builder.set_member_name ("args");
            builder.begin_object ();
            builder.set_member_name ("name");
            builder.add_string_value (section.name);

            builder.set_member_name ("project_id");
            builder.add_string_value ("_" + section.project_id);
            builder.end_object ();
            builder.end_object ();
        }

        // Items
        foreach (Objects.Item item in project.all_items) {
            builder.begin_object ();

            builder.set_member_name ("type");
            builder.add_string_value ("item_add");

            builder.set_member_name ("temp_id");
            builder.add_string_value ("_" + item.id);

            builder.set_member_name ("uuid");
            builder.add_string_value (Util.get_default ().generate_string ());

            builder.set_member_name ("args");
            builder.begin_object ();
            builder.set_member_name ("content");
            builder.add_string_value (item.content);

            builder.set_member_name ("description");
            builder.add_string_value (item.description);

            builder.set_member_name ("project_id");
            builder.add_string_value ("_" + item.project_id);

            if (item.parent_id != "") {
                builder.set_member_name ("parent_id");
                builder.add_string_value ("_" + item.parent_id);
            }

            if (item.section_id != "") {
                builder.set_member_name ("section_id");
                builder.add_string_value ("_" + item.section_id);
            }

            builder.set_member_name ("priority");
            if (item.priority == 0) {
                builder.add_int_value (Constants.PRIORITY_4);
            } else {
                builder.add_int_value (item.priority);
            }

            if (item.has_due) {
                builder.set_member_name ("due");
                builder.begin_object ();

                builder.set_member_name ("date");
                builder.add_string_value (item.due.date);

                builder.end_object ();
            }

            builder.set_member_name ("labels");
            builder.begin_array ();
            foreach (Objects.Label label in item.labels) {
                builder.add_string_value (label.name);
            }
            builder.end_array ();
            builder.end_object ();
            builder.end_object ();
            builder.end_object ();
        }
        builder.end_array ();
        builder.end_object ();
        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);

        return generator.to_data (null);
    }

    public bool is_todoist_error (uint status_code) {
        return (status_code == 400 || status_code == 401 ||
                status_code == 403 || status_code == 404 ||
                status_code == 429 || status_code == 500 ||
                status_code == 503);
    }

    public string get_todoist_error (uint code) {
        var messages = new Gee.HashMap<uint, string> ();

        messages.set (400, _("The request was incorrect."));
        messages.set (401, _("Authentication is required, and has failed, or has not yet been provided."));
        messages.set (403, _("The request was valid, but for something that is forbidden."));
        messages.set (404, _("The requested resource could not be found."));
        messages.set (429, _("The user has sent too many requests in a given amount of time."));
        messages.set (500, _("The request failed due to a server error."));
        messages.set (503, _("The server is currently unable to handle the request."));

        // TODO: use soup messages as fallback?
        return messages.has_key (code) ? messages.get (code) : _("Unknown error");
    }
}

public class HttpResponse {
    public bool status { get; set; }
    public string error { get; set; default = ""; }
    public int error_code { get; set; default = 0; }
    public int http_code { get; set; default = 0; }

    public string data { get; set; }
    public GLib.Value data_object { get; set; }

    public void from_error_json (Json.Node node) {
        status = false;
        error_code = (int) node.get_object ().get_int_member ("error_code");
        error = node.get_object ().get_string_member ("error");
        http_code = (int) node.get_object ().get_int_member ("http_code");
    }

    public void from_error_xml (GXml.DomDocument doc, int error_code) {
        status = false;
        this.error_code = error_code;
        http_code = error_code;
        error = doc.get_elements_by_tag_name ("o:hint").get_element (0).text_content;
    }
}
