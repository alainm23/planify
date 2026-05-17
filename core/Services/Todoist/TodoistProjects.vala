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

public class Services.TodoistProjects : GLib.Object {
    private Soup.Session session;

    private const string TODOIST_SYNC_URL = "https://api.todoist.com/api/v1/sync";
    private const string MIGRATE_MESSAGE = _ ("Todoist has updated their API. Please reconnect your account in Preferences to continue syncing.");

    public TodoistProjects (Soup.Session session) {
        this.session = session;
    }

    public async HttpResponse move_project_section (Objects.BaseObject base_object, string project_id) {
        HttpResponse response = new HttpResponse ();

        if (base_object.source.needs_migration ()) {
            response.status = false;
            response.error = MIGRATE_MESSAGE;
            response.error_code = 410;
            return response;
        }

        string uuid = Util.get_default ().generate_string ();
        string json = base_object.get_move_json (uuid, project_id);

        var message = new Soup.Message ("POST", TODOIST_SYNC_URL);
        message.request_headers.append ("Authorization", "Bearer %s".printf (base_object.source.todoist_data.access_token));
        message.set_request_body_from_bytes ("application/json", new Bytes (json.data));

        try {
            GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);
            var parser = new Json.Parser ();
            parser.load_from_data ((string) stream.get_data ());

            if (Services.Todoist.get_default ().is_todoist_error (message.status_code)) {
                response.from_error_json (parser.get_root ());
                debug ("Code: %s - %s".printf (message.status_code.to_string (), Services.Todoist.get_default ().get_todoist_error (message.status_code)));
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
                }
            }
        } catch (Error e) {
            if (Services.Todoist.get_default ().is_todoist_error (message.status_code)) {
                response.error = e.message;
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
        HttpResponse response = new HttpResponse ();

        if (project.source.needs_migration ()) {
            response.status = false;
            response.error = MIGRATE_MESSAGE;
            response.error_code = 410;
            return response;
        }

        string json = get_duplicate_project_json (project);

        var message = new Soup.Message ("POST", TODOIST_SYNC_URL);
        message.request_headers.append ("Authorization", "Bearer %s".printf (project.source.todoist_data.access_token));
        message.set_request_body_from_bytes ("application/json", new Bytes (json.data));

        try {
            GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);
            var parser = new Json.Parser ();
            parser.load_from_data ((string) stream.get_data ());

            if (Services.Todoist.get_default ().is_todoist_error (message.status_code)) {
                response.from_error_json (parser.get_root ());
                debug ("Code: %s - %s".printf (message.status_code.to_string (), Services.Todoist.get_default ().get_todoist_error (message.status_code)));
            } else {
                response.status = true;
            }
        } catch (Error e) {
            Services.LogService.get_default ().error ("Todoist", "Failed to duplicate project: %s".printf (e.message));
            response.error = e.message;
            response.error_code = e.code;
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
        builder.set_member_name ("type"); builder.add_string_value ("project_add");
        builder.set_member_name ("temp_id"); builder.add_string_value ("_" + project.id);
        builder.set_member_name ("uuid"); builder.add_string_value (Util.get_default ().generate_string ());
        builder.set_member_name ("args");
        builder.begin_object ();
        builder.set_member_name ("name"); builder.add_string_value (project.name);
        builder.set_member_name ("color"); builder.add_string_value (project.color);
        builder.end_object ();
        builder.end_object ();

        // Sections
        foreach (Objects.Section section in project.sections) {
            builder.begin_object ();
            builder.set_member_name ("type"); builder.add_string_value ("section_add");
            builder.set_member_name ("temp_id"); builder.add_string_value ("_" + section.id);
            builder.set_member_name ("uuid"); builder.add_string_value (Util.get_default ().generate_string ());
            builder.set_member_name ("args");
            builder.begin_object ();
            builder.set_member_name ("name"); builder.add_string_value (section.name);
            builder.set_member_name ("project_id"); builder.add_string_value ("_" + section.project_id);
            builder.end_object ();
            builder.end_object ();
        }

        // Items
        foreach (Objects.Item item in project.all_items) {
            builder.begin_object ();
            builder.set_member_name ("type"); builder.add_string_value ("item_add");
            builder.set_member_name ("temp_id"); builder.add_string_value ("_" + item.id);
            builder.set_member_name ("uuid"); builder.add_string_value (Util.get_default ().generate_string ());
            builder.set_member_name ("args");
            builder.begin_object ();
            builder.set_member_name ("content"); builder.add_string_value (item.content);
            builder.set_member_name ("description"); builder.add_string_value (item.description);
            builder.set_member_name ("project_id"); builder.add_string_value ("_" + item.project_id);

            if (item.parent_id != "") {
                builder.set_member_name ("parent_id"); builder.add_string_value ("_" + item.parent_id);
            }

            if (item.section_id != "") {
                builder.set_member_name ("section_id"); builder.add_string_value ("_" + item.section_id);
            }

            builder.set_member_name ("priority");
            builder.add_int_value (item.priority == 0 ? Constants.PRIORITY_4 : item.priority);

            if (item.has_due) {
                builder.set_member_name ("due");
                builder.begin_object ();
                builder.set_member_name ("date"); builder.add_string_value (item.due.date);
                builder.end_object ();
            }

            builder.set_member_name ("labels");
            builder.begin_array ();
            foreach (Objects.Label label in item.labels) {
                builder.add_string_value (label.name);
            }
            builder.end_array ();
            builder.end_object (); // close args
            builder.end_object (); // close command
        }

        builder.end_array ();
        builder.end_object ();

        var generator = new Json.Generator ();
        generator.set_root (builder.get_root ());
        return generator.to_data (null);
    }
}
