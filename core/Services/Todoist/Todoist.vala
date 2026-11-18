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

public errordomain Services.TodoistError {
    RATE_LIMITED
}

public class Services.Todoist : GLib.Object {
    private Soup.Session session;

    private Gee.HashMap<string, int64?> blocked_until = new Gee.HashMap<string, int64?> ();
    private Gee.HashMap<string, int> backoff_level = new Gee.HashMap<string, int> ();

    private Gee.HashSet<string> retry_scheduled = new Gee.HashSet<string> ();
    private const int64 BACKOFF_MIN_SECONDS = 60;
    private const int64 BACKOFF_MAX_SECONDS = 30 * 60;

    private Gee.HashSet<string> syncing_sources = new Gee.HashSet<string> ();
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
        session = new Soup.Session () {
            timeout = Constants.SOUP_TIMEOUT
        };
        _auth = new TodoistAuth (session);
        _items = new TodoistItems (session);
        _projects = new TodoistProjects (session);
    }

    private string rate_limit_key (Soup.Message message) {
        return message.request_headers.get_one ("Authorization") ?? "";
    }

    public int64 rate_limit_remaining (Soup.Message message) {
        string key = rate_limit_key (message);
        if (!blocked_until.has_key (key)) {
            return 0;
        }

        int64 remaining = ((int64) blocked_until[key] - GLib.get_real_time ()) / TimeSpan.SECOND;
        return remaining > 0 ? remaining : 0;
    }

    public async GLib.Bytes send_request (Soup.Message message, int priority = GLib.Priority.DEFAULT) throws GLib.Error {
        string key = rate_limit_key (message);

        int64 remaining = rate_limit_remaining (message);
        if (remaining > 0) {
            throw new Services.TodoistError.RATE_LIMITED ("Rate limited by Todoist, retrying in %lld s".printf (remaining));
        }

        GLib.Bytes stream = yield session.send_and_read_async (message, priority, null);

        if (message.status_code == 429) {
            // Todoist sends very short Retry-After values (2, 3, 4 s...) even though the quota
            // only frees up as the 15 min window moves, so wait for the larger of that value
            // and our own backoff: 1, 2, 4, 8, 16 min, then 30 min.
            int level = backoff_level.has_key (key) ? backoff_level[key] : 0;
            int64 backoff = int64.min (BACKOFF_MIN_SECONDS << int.min (level, 5), BACKOFF_MAX_SECONDS);
            int64 seconds = int64.max (parse_retry_after (message.response_headers.get_one ("Retry-After")), backoff);
            backoff_level[key] = level + 1;

            block (key, seconds);
            throw new Services.TodoistError.RATE_LIMITED ("Rate limited by Todoist (HTTP 429), retrying in %lld s".printf (seconds));
        }

        backoff_level.unset (key);
        blocked_until.unset (key);
        return stream;
    }

    private void block (string key, int64 seconds) {
        blocked_until[key] = GLib.get_real_time () + seconds * TimeSpan.SECOND;
        Services.LogService.get_default ().warn ("Todoist", "Rate limited, pausing requests for %lld s".printf (seconds));
    }

    private int64 parse_retry_after (string? value) {
        if (value == null) {
            return 0;
        }

        int64 seconds;
        if (int64.try_parse (value.strip (), out seconds) && seconds > 0) {
            return int64.min (seconds, BACKOFF_MAX_SECONDS * 4);
        }

        return 0;
    }

    public static bool is_rate_limited_error (GLib.Error e) {
        return e is Services.TodoistError.RATE_LIMITED;
    }

    private void schedule_retry_sync (Objects.Source source, int64 seconds) {
        if (source.id in retry_scheduled) {
            return;
        }

        retry_scheduled.add (source.id);
        Timeout.add_seconds ((uint) int64.max (seconds, 1) + 1, () => {
            retry_scheduled.remove (source.id);
            Services.LogService.get_default ().info ("Todoist", "Rate limit over, syncing '%s'".printf (source.display_name));
            sync.begin (source);
            return GLib.Source.REMOVE;
        });
    }

    private void report_rate_limited (Objects.Source source, int64 seconds) {
        // A clock time instead of a countdown: the tooltip is static text.
        string resume_at = new GLib.DateTime.now_local ()
            .add_seconds ((double) int64.max (seconds, 1))
            .format (Utils.Datetime.get_default_time_format ());

        source.sync_status = new SyncStatus (
            SyncErrorType.SERVER_ERROR,
            _("Too Many Requests"),
            // TRANSLATORS: %s is a time, e.g. "14:02"
            _("Todoist is limiting how often Planify can sync.\nSyncing will resume automatically at %s.\nChanges you make in the meantime are saved\nand will be synced then.").printf (resume_at)
        );
        source.sync_failed (source.sync_status);
        schedule_retry_sync (source, seconds);
    }

    /*
     * Auth
     */

    public async TodoistResponse login (string _url, Objects.Source? migrate_source = null) {
        return yield _auth.login (_url, migrate_source);
    }

    public async TodoistResponse login_token (string token, Objects.Source? migrate_source = null) {
        return yield _auth.login_token (token, migrate_source);
    }

    public async void add_todoist_account (string token, TodoistResponse response, Objects.Source? migrate_source = null) {
        yield _auth.add_todoist_account (token, response, migrate_source);
    }

    /*
     * Sync
     */

    private void process_item_node (Json.Node _node) {
        Objects.Item ? item = Services.Store.instance ().get_item (_node.get_object ().get_string_member ("id"));
        if (item != null) {
            if (_node.get_object ().get_boolean_member ("is_deleted")) {
                Services.Store.instance ().delete_item (item);
            } else {
                string old_project_id = item.project_id;
                string old_section_id = item.section_id;
                string old_parent_id = item.parent_id;
                bool old_checked = item.checked;

                if (item.loading) {
                    return;
                }

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

    public async void sync (Objects.Source source) {
        if (source.todoist_data.access_token == null) {
            return;
        }

        if (source.needs_migration ()) {
            source.sync_failed ();
            return;
        }

        // Two syncs at once would reuse the same sync_token and send the pending
        // queue twice, so skip a new sync while one is running for this account.
        if (source.id in syncing_sources) {
            Services.LogService.get_default ().info ("Todoist", "Sync already in progress for '%s', skipping".printf (source.display_name));
            return;
        }

        var message = new Soup.Message ("POST", TODOIST_SYNC_URL);
        message.request_headers.append ("Authorization", "Bearer %s".printf (source.todoist_data.access_token));

        // Still rate limited: don't even start (no spinner, no request). A sync is
        // already scheduled for when the limit ends.
        int64 waiting = rate_limit_remaining (message);
        if (waiting > 0) {
            Services.LogService.get_default ().info ("Todoist", "Rate limited, skipping sync for '%s' (%lld s left)".printf (source.display_name, waiting));
            // Show again why it doesn't sync (e.g. the user pressed the sync button).
            report_rate_limited (source, waiting);
            return;
        }

        syncing_sources.add (source.id);

        source.sync_started ();

        string form_data = "sync_token=%s&resource_types=%s".printf (
            source.todoist_data.sync_token, RESOURCE_TYPES
        );
        message.set_request_body_from_bytes ("application/x-www-form-urlencoded", new GLib.Bytes (form_data.data));

        bool synced = false;

        try {
            GLib.Bytes stream = yield send_request (message, GLib.Priority.LOW);
            var parser = new Json.Parser ();
            parser.load_from_data ((string) stream.get_data ());

            if (is_todoist_error (message.status_code) || parser.get_root ().get_object ().has_member ("error")) {
                // An error answer used to be treated as a successful sync.
                Services.LogService.get_default ().error ("Todoist", "Sync failed: HTTP %u".printf (message.status_code));
                source.sync_failed ();
            } else {
                synced = true;
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
                    process_item_node (_node);
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
            if (is_rate_limited_error (e)) {
                Services.LogService.get_default ().warn ("Todoist", "Sync paused: %s".printf (e.message));
                report_rate_limited (source, rate_limit_remaining (message));
            } else {
                Services.LogService.get_default ().error ("Todoist", "Failed to sync: %s".printf (e.message));
                source.sync_failed ();
            }
        }

        // Only a successful sync counts as the last sync and stores the new token.
        if (synced) {
            source.sync_status = null;
            source.last_sync = new GLib.DateTime.now_local ().to_string ();
            source.save ();
        }

        foreach (var project in Services.Store.instance ().get_projects_by_source (source.id)) {
            project.freeze_update = false;
            project.count_update ();
            Services.Store.instance ().update_project (project);
        }

        syncing_sources.remove (source.id);
        source.sync_finished ();
    }

    /*
     * Queue
     */

    private bool _queue_running = false;

    public async void queue (Objects.Source source) {
        if (_queue_running) {
            Services.LogService.get_default ().debug ("Todoist", "Queue already running, skipping");
            return;
        }

        _queue_running = true;
        Gee.ArrayList<Objects.Queue ?> queue_collection = Services.Database.get_default ().get_all_queue (source.id);
        if (queue_collection.size <= 0) {
            _queue_running = false;
            return;
        }

        string json = get_queue_json (queue_collection, source.todoist_data.sync_token);
        Services.LogService.get_default ().info ("Todoist", "Flushing queue: %d items".printf (queue_collection.size));
        Services.LogService.get_default ().debug ("Todoist", "Queue JSON: %s".printf (json));

        var message = new Soup.Message ("POST", TODOIST_SYNC_URL);
        message.request_headers.append ("Authorization", "Bearer %s".printf (source.todoist_data.access_token));
        message.set_request_body_from_bytes ("application/json", new Bytes (json.data));

        try {
            // Throws on 429 / while rate limited, so the queued commands stay for later.
            GLib.Bytes stream = yield send_request (message, GLib.Priority.LOW);
            var parser = new Json.Parser ();
            parser.load_from_data ((string) stream.get_data ());

            var node = parser.get_root ().get_object ();
            source.todoist_data.sync_token = node.get_string_member ("sync_token");

            foreach (var q in queue_collection) {
                var uuid_member = node.get_object_member ("sync_status").get_member (q.uuid);
                Services.LogService.get_default ().debug ("Todoist", "Processing queue item — query: %s, uuid: %s, object_id: %s".printf (q.query, q.uuid, q.object_id));
                if (uuid_member.get_node_type () == Json.NodeType.VALUE) {
                    var temp_id_mapping = node.get_object_member ("temp_id_mapping");
                    var success = true;

                    if (q.query == "project_add") {
                        if (temp_id_mapping.has_member (q.temp_id)) {
                            var id = temp_id_mapping.get_string_member (q.temp_id);
                            Services.Store.instance ().update_project_id (q.object_id, id);
                            Services.Database.get_default ().remove_CurTempIds (q.object_id);
                        } else {
                            Services.LogService.get_default ().warn ("Todoist", "temp_id_mapping missing for project_add: %s".printf (q.temp_id));
                            success = false;
                        }
                    }

                    if (q.query == "section_add") {
                        if (temp_id_mapping.has_member (q.temp_id)) {
                            var id = temp_id_mapping.get_string_member (q.temp_id);
                            Services.Store.instance ().update_section_id (q.object_id, id);
                            Services.Database.get_default ().remove_CurTempIds (q.object_id);
                        } else {
                            Services.LogService.get_default ().warn ("Todoist", "temp_id_mapping missing for section_add: %s".printf (q.temp_id));
                            success = false;
                        }
                    }

                    if (q.query == "item_add") {
                        if (temp_id_mapping.has_member (q.temp_id)) {
                            var id = temp_id_mapping.get_string_member (q.temp_id);
                            Services.Store.instance ().update_item_id (q.object_id, id);
                            Services.Database.get_default ().remove_CurTempIds (q.object_id);
                        } else {
                            Services.LogService.get_default ().warn ("Todoist", "temp_id_mapping missing for item_add: %s".printf (q.temp_id));
                            success = false;
                        }
                    }
                    if (success) {
                        Services.Database.get_default ().remove_queue (q.uuid);
                    }
                } else {
                    var sync_status = node.get_object_member ("sync_status");
                    if (sync_status.has_member (q.uuid)) {
                        var error_obj = sync_status.get_object_member (q.uuid);
                        Services.LogService.get_default ().warn ("Todoist",
                            "Queue item failed — query: %s, error: %s".printf (
                                q.query, error_obj.get_string_member ("error")));
                    }
                    Services.Database.get_default ().remove_queue (q.uuid);
                }
            }
            if (node.has_member ("items")) {
                foreach (unowned Json.Node _node in node.get_array_member ("items").get_elements ()) {
                    process_item_node (_node);
                }
            }
        } catch (Error e) {
            debug (e.message);
        }

        _queue_running = false;
    }

    private string resolve_id (string id) {
        if (Services.Database.get_default ().curTempIds_exists (id)) {
            return Services.Database.get_default ().get_temp_id (id);
        }
        return id;
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

    public string get_queue_json (Gee.ArrayList<Objects.Queue ?> queue, string sync_token) {
        var builder = new Json.Builder ();
        builder.begin_object ();

        builder.set_member_name ("sync_token");
        builder.add_string_value (sync_token);
        builder.set_member_name ("resource_types");
        builder.begin_array ();
        builder.add_string_value ("items");
        builder.end_array ();

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
                builder.set_member_name ("project_id"); builder.add_string_value (resolve_id (Utils.JsonUtils.get_string (q.args, "project_id")));
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
            } else if (q.query == "project_move") {
                begin_command (builder, "project_move", q.uuid);
                builder.set_member_name ("id"); builder.add_string_value (Utils.JsonUtils.get_string (q.args, "id"));
                builder.set_member_name ("parent_id"); builder.add_string_value (Utils.JsonUtils.get_string (q.args, "parent_id"));
                end_command (builder);
            } else if (q.query == "item_add") {
                begin_command (builder, "item_add", q.uuid, q.temp_id);
                builder.set_member_name ("content"); builder.add_string_value (Utils.JsonUtils.get_string (q.args, "content"));
                builder.set_member_name ("description"); builder.add_string_value (Utils.JsonUtils.get_string (q.args, "description"));
                builder.set_member_name ("priority"); builder.add_int_value (Utils.JsonUtils.get_int (q.args, "priority"));
                string item_project_id = resolve_id (Utils.JsonUtils.get_string (q.args, "project_id"));
                builder.set_member_name ("project_id"); builder.add_string_value (item_project_id);
                var section_id = Utils.JsonUtils.get_string (q.args, "section_id");
                if (section_id != "") {
                    builder.set_member_name ("section_id"); builder.add_string_value (resolve_id (section_id));
                }
                var parent_id = Utils.JsonUtils.get_string (q.args, "parent_id");
                if (parent_id != "") {
                    builder.set_member_name ("parent_id"); builder.add_string_value (parent_id);
                }
                if (Utils.JsonUtils.is_null_member (q.args, "due")) {
                    builder.set_member_name ("due"); builder.add_null_value ();
                } else {
                    builder.set_member_name ("due");
                    builder.begin_object ();
                    builder.set_member_name ("date"); builder.add_string_value (Utils.JsonUtils.get_object_member (q.args, "due").get_string_member ("date"));
                    builder.set_member_name ("string"); builder.add_string_value (Utils.JsonUtils.get_object_member (q.args, "due").get_string_member ("string"));
                    builder.end_object ();
                }
                end_command (builder);
            } else if (q.query == "item_update") {
                begin_command (builder, "item_update", q.uuid);
                builder.set_member_name ("id"); builder.add_string_value (resolve_id (Utils.JsonUtils.get_string (q.args, "id")));
                builder.set_member_name ("content"); builder.add_string_value (Utils.JsonUtils.get_string (q.args, "content"));
                builder.set_member_name ("description"); builder.add_string_value (Utils.JsonUtils.get_string (q.args, "description"));
                builder.set_member_name ("priority"); builder.add_int_value (Utils.JsonUtils.get_int (q.args, "priority"));
                if (Utils.JsonUtils.is_null_member (q.args, "due")) {
                    builder.set_member_name ("due"); builder.add_null_value ();
                } else {
                    builder.set_member_name ("due");
                    builder.begin_object ();
                    builder.set_member_name ("date"); builder.add_string_value (Utils.JsonUtils.get_object_member (q.args, "due").get_string_member ("date"));
                    builder.set_member_name ("string"); builder.add_string_value (Utils.JsonUtils.get_object_member (q.args, "due").get_string_member ("string"));
                    builder.end_object ();
                }
                end_command (builder);
            } else if (q.query == "item_delete") {
                begin_command (builder, "item_delete", q.uuid);
                builder.set_member_name ("id"); builder.add_string_value (resolve_id (Utils.JsonUtils.get_string (q.args, "id")));
                end_command (builder);
            } else if (q.query == "item_move") {
                begin_command (builder, "item_move", q.uuid);
                builder.set_member_name ("id"); builder.add_string_value (resolve_id (Utils.JsonUtils.get_string (q.args, "id")));
                string move_type = Utils.JsonUtils.get_string (q.args, "type");
                builder.set_member_name (move_type); builder.add_string_value (resolve_id (Utils.JsonUtils.get_string (q.args, move_type)));
                end_command (builder);
            } else if (q.query == "item_complete" || q.query == "item_uncomplete" || q.query == "item_close") {
                begin_command (builder, q.query, q.uuid);
                builder.set_member_name ("id"); builder.add_string_value (resolve_id (Utils.JsonUtils.get_string (q.args, "id")));
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

    public async TodoistResponse add (Objects.BaseObject object) {
        return yield _items.add (object);
    }

    public async TodoistResponse update (Objects.BaseObject object) {
        return yield _items.update (object);
    }

    public async TodoistResponse delete (Objects.BaseObject object) {
        return yield _items.delete (object);
    }

    public async TodoistResponse complete_item (Objects.Item item) {
        return yield _items.complete_item (item);
    }
    
    public async TodoistResponse close_item (Objects.Item item) {
        return yield _items.close_item (item);
    }

    public async TodoistResponse move_item (Objects.Item item, string type, string id) {
        return yield _items.move_item (item, type, id);
    }

    public async void update_items (Gee.ArrayList<Objects.Item> objects) {
        yield _items.update_items (objects);
    }

    /*
     * Projects — delegated to TodoistProjects
     */

    public async TodoistResponse move_project_section (Objects.BaseObject base_object, string project_id) {
        return yield _projects.move_project_section (base_object, project_id);
    }

    public async TodoistResponse duplicate_project (Objects.Project project) {
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

public class TodoistResponse : HttpResponse {
    public void from_error_json (Json.Node node) {
        status = false;
        error_code = (int) node.get_object ().get_int_member ("error_code");
        error = node.get_object ().get_string_member ("error");
        http_code = (int) node.get_object ().get_int_member ("http_code");
    }
}
