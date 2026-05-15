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
    private TodoistAuth _auth;
    private TodoistItems _items;
    private TodoistProjects _projects;

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
        _auth = new TodoistAuth (session);
        _items = new TodoistItems (session);
        _projects = new TodoistProjects (session);
    }

    /*
     * Auth
     */

    public async HttpResponse login (string _url, Objects.Source? migrate_source = null) {
        return yield _auth.login (_url, migrate_source);
    }

    public async HttpResponse login_token (string token, Objects.Source? migrate_source = null) {
        return yield _auth.login_token (token, migrate_source);
    }

    public async void add_todoist_account (string token, HttpResponse response, Objects.Source? migrate_source = null) {
        yield _auth.add_todoist_account (token, response, migrate_source);
    }

    /*
     * Sync
     */

    public async void sync (Objects.Source source) {
        if (source.todoist_data.access_token == null) {
            return;
        }

        if (source.needs_migration ()) {
            source.sync_failed ();
            return;
        }

        source.sync_started ();

        var message = new Soup.Message ("POST", TODOIST_SYNC_URL);
        message.request_headers.append ("Authorization", "Bearer %s".printf (source.todoist_data.access_token));

        string form_data = "sync_token=%s&resource_types=%s".printf (
            source.todoist_data.sync_token, RESOURCE_TYPES
        );
        message.set_request_body_from_bytes ("application/x-www-form-urlencoded", new GLib.Bytes (form_data.data));

        try {
            GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.LOW, null);
            var parser = new Json.Parser ();
            parser.load_from_data ((string) stream.get_data ());

            if (!parser.get_root ().get_object ().has_member ("error")) {
                source.todoist_data.sync_token = parser.get_root ().get_object ().get_string_member ("sync_token");

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
            Services.LogService.get_default ().error ("Todoist", "Failed to sync: %s".printf (e.message));
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
     * Queue
     */

    public async void queue (Objects.Source source) {
        Gee.ArrayList<Objects.Queue ?> queue_collection = Services.Database.get_default ().get_all_queue ();
        if (queue_collection.size <= 0) {
            return;
        }

        string json = get_queue_json (queue_collection);

        var message = new Soup.Message ("POST", TODOIST_SYNC_URL);
        message.request_headers.append ("Authorization", "Bearer %s".printf (source.todoist_data.access_token));
        message.set_request_body_from_bytes ("application/json", new Bytes (json.data));

        try {
            GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.LOW, null);
            var parser = new Json.Parser ();
            parser.load_from_data ((string) stream.get_data ());

            var node = parser.get_root ().get_object ();
            source.todoist_data.sync_token = node.get_string_member ("sync_token");

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

    private void begin_command (Json.Builder builder, string type, string uuid, string? temp_id = null) {
        builder.begin_object ();
        builder.set_member_name ("type"); builder.add_string_value (type);
        builder.set_member_name ("uuid"); builder.add_string_value (uuid);
        if (temp_id != null) {
            builder.set_member_name ("temp_id"); builder.add_string_value (temp_id);
        }
        builder.set_member_name ("args");
        builder.begin_object ();
    }

    private void end_command (Json.Builder builder) {
        builder.end_object ();
        builder.end_object ();
    }

    public string get_queue_json (Gee.ArrayList<Objects.Queue ?> queue) {
        var builder = new Json.Builder ();
        builder.begin_object ();
        builder.set_member_name ("commands");
        builder.begin_array ();

        foreach (var q in queue) {
            if (q.query == "project_add") {
                begin_command (builder, "project_add", q.uuid, q.temp_id);
                builder.set_member_name ("name"); builder.add_string_value (Utils.JsonUtils.get_string (q.args, "name"));
                builder.set_member_name ("color"); builder.add_string_value (Utils.JsonUtils.get_string (q.args, "color"));
                end_command (builder);
            } else if (q.query == "project_update") {
                begin_command (builder, "project_update", q.uuid);
                builder.set_member_name ("id"); builder.add_string_value (Utils.JsonUtils.get_string (q.args, "id"));
                builder.set_member_name ("name"); builder.add_string_value (Utils.JsonUtils.get_string (q.args, "name"));
                builder.set_member_name ("color"); builder.add_string_value (Utils.JsonUtils.get_string (q.args, "color"));
                end_command (builder);
            } else if (q.query == "project_delete") {
                begin_command (builder, "project_delete", q.uuid);
                builder.set_member_name ("id"); builder.add_string_value (Utils.JsonUtils.get_string (q.args, "id"));
                end_command (builder);
            } else if (q.query == "section_add") {
                begin_command (builder, "section_add", q.uuid, q.temp_id);
                builder.set_member_name ("name"); builder.add_string_value (Utils.JsonUtils.get_string (q.args, "name"));
                builder.set_member_name ("project_id"); builder.add_string_value (Utils.JsonUtils.get_string (q.args, "project_id"));
                end_command (builder);
            } else if (q.query == "section_update") {
                begin_command (builder, "section_update", q.uuid);
                builder.set_member_name ("id"); builder.add_string_value (Utils.JsonUtils.get_string (q.args, "id"));
                builder.set_member_name ("name"); builder.add_string_value (Utils.JsonUtils.get_string (q.args, "name"));
                end_command (builder);
            } else if (q.query == "section_delete") {
                begin_command (builder, "section_delete", q.uuid);
                builder.set_member_name ("id"); builder.add_string_value (Utils.JsonUtils.get_string (q.args, "id"));
                end_command (builder);
            } else if (q.query == "section_move") {
                begin_command (builder, "section_move", q.uuid);
                builder.set_member_name ("id"); builder.add_string_value (Utils.JsonUtils.get_string (q.args, "id"));
                builder.set_member_name ("project_id"); builder.add_string_value (Utils.JsonUtils.get_string (q.args, "project_id"));
                end_command (builder);
            } else if (q.query == "item_add") {
                begin_command (builder, "item_add", q.uuid, q.temp_id);
                builder.set_member_name ("content"); builder.add_string_value (Utils.JsonUtils.get_string (q.args, "content"));
                builder.set_member_name ("description"); builder.add_string_value (Utils.JsonUtils.get_string (q.args, "description"));
                builder.set_member_name ("priority"); builder.add_int_value (Utils.JsonUtils.get_int (q.args, "priority"));
                builder.set_member_name ("project_id"); builder.add_string_value (Utils.JsonUtils.get_string (q.args, "project_id"));
                builder.set_member_name ("section_id"); builder.add_string_value (Utils.JsonUtils.get_string (q.args, "section_id"));
                builder.set_member_name ("parent_id"); builder.add_string_value (Utils.JsonUtils.get_string (q.args, "parent_id"));
                end_command (builder);
            } else if (q.query == "item_update") {
                begin_command (builder, "item_update", q.uuid);
                builder.set_member_name ("id"); builder.add_string_value (Utils.JsonUtils.get_string (q.args, "id"));
                builder.set_member_name ("content"); builder.add_string_value (Utils.JsonUtils.get_string (q.args, "content"));
                builder.set_member_name ("description"); builder.add_string_value (Utils.JsonUtils.get_string (q.args, "description"));
                builder.set_member_name ("priority"); builder.add_int_value (Utils.JsonUtils.get_int (q.args, "priority"));
                if (Utils.JsonUtils.is_null_member (q.args, "due")) {
                    builder.set_member_name ("due"); builder.add_null_value ();
                } else {
                    builder.set_member_name ("due");
                    builder.begin_object ();
                    builder.set_member_name ("date"); builder.add_string_value (Utils.JsonUtils.get_object_member (q.args, "due").get_string_member ("date"));
                    builder.end_object ();
                }
                end_command (builder);
            } else if (q.query == "item_delete") {
                begin_command (builder, "item_delete", q.uuid);
                builder.set_member_name ("id"); builder.add_string_value (Utils.JsonUtils.get_string (q.args, "id"));
                end_command (builder);
            } else if (q.query == "item_move") {
                begin_command (builder, "item_move", q.uuid);
                builder.set_member_name ("id"); builder.add_string_value (Utils.JsonUtils.get_string (q.args, "id"));
                string move_type = Utils.JsonUtils.get_string (q.args, "type");
                builder.set_member_name (move_type); builder.add_string_value (Utils.JsonUtils.get_string (q.args, move_type));
                end_command (builder);
            } else if (q.query == "item_complete" || q.query == "item_uncomplete") {
                begin_command (builder, q.query, q.uuid);
                builder.set_member_name ("id"); builder.add_string_value (Utils.JsonUtils.get_string (q.args, "id"));
                end_command (builder);
            }
        }

        builder.end_array ();
        builder.end_object ();

        var generator = new Json.Generator ();
        generator.set_root (builder.get_root ());
        return generator.to_data (null);
    }

    public string get_delete_json (string id, string type, string uuid) {
        var builder = new Json.Builder ();
        builder.begin_object ();
        builder.set_member_name ("commands");
        builder.begin_array ();
        begin_command (builder, type, uuid);
        builder.set_member_name ("id"); builder.add_string_value (id);
        end_command (builder);
        builder.end_array ();
        builder.end_object ();

        var generator = new Json.Generator ();
        generator.set_root (builder.get_root ());
        return generator.to_data (null);
    }

    /*
     * Items — delegated to TodoistItems
     */

    public async HttpResponse add (Objects.BaseObject object) {
        return yield _items.add (object);
    }

    public async HttpResponse update (Objects.BaseObject object) {
        return yield _items.update (object);
    }

    public async HttpResponse delete (Objects.BaseObject object) {
        return yield _items.delete (object);
    }

    public async HttpResponse complete_item (Objects.Item item) {
        return yield _items.complete_item (item);
    }

    public async HttpResponse move_item (Objects.Item item, string type, string id) {
        return yield _items.move_item (item, type, id);
    }

    public async void update_items (Gee.ArrayList<Objects.Item> objects) {
        yield _items.update_items (objects);
    }

    /*
     * Projects — delegated to TodoistProjects
     */

    public async HttpResponse move_project_section (Objects.BaseObject base_object, string project_id) {
        return yield _projects.move_project_section (base_object, project_id);
    }

    public async HttpResponse duplicate_project (Objects.Project project) {
        return yield _projects.duplicate_project (project);
    }

    /*
     * Helpers
     */

    public void add_item_if_not_exists (Json.Node node) {
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

    public void add_section_if_not_exists (Json.Node node) {
        string _id = node.get_object ().get_string_member ("project_id");
        Objects.Project ? project = Services.Store.instance ().get_project (_id);
        if (project != null) {
            project.add_section_if_not_exists (new Objects.Section.from_json (node));
        }
    }

    public bool is_todoist_error (uint status_code) {
        return (status_code == 400 || status_code == 401 ||
                status_code == 403 || status_code == 404 ||
                status_code == 429 || status_code == 500 ||
                status_code == 503);
    }

    public string get_todoist_error (uint code) {
        switch (code) {
            case 400: return _ ("The request was incorrect.");
            case 401: return _ ("Authentication is required, and has failed, or has not yet been provided.");
            case 403: return _ ("The request was valid, but for something that is forbidden.");
            case 404: return _ ("The requested resource could not be found.");
            case 429: return _ ("The user has sent too many requests in a given amount of time.");
            case 500: return _ ("The request failed due to a server error.");
            case 503: return _ ("The server is currently unable to handle the request.");
            default: return _ ("Unknown error");
        }
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
