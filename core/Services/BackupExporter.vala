/*
 * Copyright © 2026 Alain M. (https://github.com/alainm23/planify)
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

public class Services.BackupExporter : Object {

    private static BackupExporter? _instance;
    public static BackupExporter get_default () {
        if (_instance == null) {
            _instance = new BackupExporter ();
        }
        return _instance;
    }

    private string safe (string? val) {
        return val ?? "";
    }

    public string export_to_json () {
        var builder = new Json.Builder ();

        builder.begin_object ();

        builder.set_member_name ("version");
        builder.add_string_value (Constants.BACKUP_VERSION);

        builder.set_member_name ("date");
        builder.add_string_value (new GLib.DateTime.now_local ().to_string ());

        builder.set_member_name ("settings");
        builder.begin_object ();
        builder.set_member_name ("local-inbox-project-id");
        builder.add_string_value (Services.Settings.get_default ().settings.get_string ("local-inbox-project-id"));
        builder.end_object ();

        // Sources
        builder.set_member_name ("sources");
        builder.begin_array ();
        foreach (Objects.Source source in Services.Database.get_default ().get_sources_collection ()) {
            builder.begin_object ();
            builder.set_member_name ("id"); builder.add_string_value (safe (source.id));
            builder.set_member_name ("display_name"); builder.add_string_value (safe (source.display_name));
            builder.set_member_name ("source_type"); builder.add_string_value (source.source_type.to_string ());
            builder.set_member_name ("added_at"); builder.add_string_value (safe (source.added_at));
            builder.set_member_name ("updated_at"); builder.add_string_value (safe (source.updated_at));
            builder.set_member_name ("is_visible"); builder.add_boolean_value (source.is_visible);
            builder.set_member_name ("child_order"); builder.add_int_value (source.child_order);
            if (source.data != null) {
                builder.set_member_name ("data"); builder.add_string_value (safe (source.data.to_json ()));
            }
            builder.end_object ();
        }
        builder.end_array ();

        // Labels
        builder.set_member_name ("labels");
        builder.begin_array ();
        foreach (Objects.Label label in Services.Database.get_default ().get_labels_collection ()) {
            builder.begin_object ();
            builder.set_member_name ("id"); builder.add_string_value (safe (label.id));
            builder.set_member_name ("name"); builder.add_string_value (safe (label.name));
            builder.set_member_name ("color"); builder.add_string_value (safe (label.color));
            builder.set_member_name ("backend_type"); builder.add_string_value (label.backend_type.to_string ());
            builder.set_member_name ("is_deleted"); builder.add_boolean_value (label.is_deleted);
            builder.set_member_name ("is_favorite"); builder.add_boolean_value (label.is_favorite);
            builder.set_member_name ("source_id"); builder.add_string_value (safe (label.source_id));
            builder.end_object ();
        }
        builder.end_array ();

        // Projects
        builder.set_member_name ("projects");
        builder.begin_array ();
        foreach (Objects.Project project in Services.Database.get_default ().get_projects_collection ()) {
            builder.begin_object ();
            builder.set_member_name ("id"); builder.add_string_value (safe (project.id));
            builder.set_member_name ("name"); builder.add_string_value (safe (project.name));
            builder.set_member_name ("color"); builder.add_string_value (safe (project.color));
            builder.set_member_name ("backend_type"); builder.add_string_value (project.backend_type.to_string ());
            builder.set_member_name ("inbox_project"); builder.add_boolean_value (project.inbox_project);
            builder.set_member_name ("team_inbox"); builder.add_boolean_value (project.team_inbox);
            builder.set_member_name ("child_order"); builder.add_int_value (project.child_order);
            builder.set_member_name ("is_deleted"); builder.add_boolean_value (project.is_deleted);
            builder.set_member_name ("is_archived"); builder.add_boolean_value (project.is_archived);
            builder.set_member_name ("is_favorite"); builder.add_boolean_value (project.is_favorite);
            builder.set_member_name ("shared"); builder.add_boolean_value (project.shared);
            builder.set_member_name ("view_style"); builder.add_string_value (project.view_style.to_string ());
            builder.set_member_name ("sort_order"); builder.add_int_value (project.sort_order);
            builder.set_member_name ("parent_id"); builder.add_string_value (safe (project.parent_id));
            builder.set_member_name ("collapsed"); builder.add_boolean_value (project.collapsed);
            builder.set_member_name ("icon_style"); builder.add_string_value (project.icon_style.to_string ());
            builder.set_member_name ("emoji"); builder.add_string_value (safe (project.emoji));
            builder.set_member_name ("show_completed"); builder.add_boolean_value (project.show_completed);
            builder.set_member_name ("description"); builder.add_string_value (safe (project.description));
            builder.set_member_name ("due_date"); builder.add_string_value (safe (project.due_date));
            builder.set_member_name ("sync_id"); builder.add_string_value (safe (project.sync_id));
            builder.set_member_name ("source_id"); builder.add_string_value (safe (project.source_id));
            builder.set_member_name ("calendar_url"); builder.add_string_value (safe (project.calendar_url));
            builder.set_member_name ("markdown_setting"); builder.add_string_value (project.markdown_setting.to_string ());
            builder.end_object ();
        }
        builder.end_array ();

        // Sections
        builder.set_member_name ("sections");
        builder.begin_array ();
        foreach (Objects.Section section in Services.Database.get_default ().get_sections_collection ()) {
            builder.begin_object ();
            builder.set_member_name ("id"); builder.add_string_value (safe (section.id));
            builder.set_member_name ("name"); builder.add_string_value (safe (section.name));
            builder.set_member_name ("archived_at"); builder.add_string_value (safe (section.archived_at));
            builder.set_member_name ("added_at"); builder.add_string_value (safe (section.added_at));
            builder.set_member_name ("project_id"); builder.add_string_value (safe (section.project_id));
            builder.set_member_name ("section_order"); builder.add_int_value (section.section_order);
            builder.set_member_name ("collapsed"); builder.add_boolean_value (section.collapsed);
            builder.set_member_name ("is_deleted"); builder.add_boolean_value (section.is_deleted);
            builder.set_member_name ("is_archived"); builder.add_boolean_value (section.is_archived);
            builder.end_object ();
        }
        builder.end_array ();

        // Items
        builder.set_member_name ("items");
        builder.begin_array ();
        foreach (Objects.Item item in Services.Database.get_default ().get_items_collection ()) {
            builder.begin_object ();
            builder.set_member_name ("id"); builder.add_string_value (safe (item.id));
            builder.set_member_name ("content"); builder.add_string_value (safe (item.content));
            builder.set_member_name ("description"); builder.add_string_value (safe (item.description));
            builder.set_member_name ("due"); builder.add_string_value (safe (item.due.to_string ()));
            builder.set_member_name ("added_at"); builder.add_string_value (safe (item.added_at));
            builder.set_member_name ("completed_at"); builder.add_string_value (safe (item.completed_at));
            builder.set_member_name ("updated_at"); builder.add_string_value (safe (item.updated_at));
            builder.set_member_name ("section_id"); builder.add_string_value (safe (item.section_id));
            builder.set_member_name ("project_id"); builder.add_string_value (safe (item.project_id));
            builder.set_member_name ("parent_id"); builder.add_string_value (safe (item.parent_id));
            builder.set_member_name ("priority"); builder.add_int_value (item.priority);
            builder.set_member_name ("child_order"); builder.add_int_value (item.child_order);
            builder.set_member_name ("checked"); builder.add_boolean_value (item.checked);
            builder.set_member_name ("is_deleted"); builder.add_boolean_value (item.is_deleted);
            builder.set_member_name ("day_order"); builder.add_int_value (item.day_order);
            builder.set_member_name ("collapsed"); builder.add_boolean_value (item.collapsed);
            builder.set_member_name ("pinned"); builder.add_boolean_value (item.pinned);
            builder.set_member_name ("labels");
            builder.begin_array ();
            foreach (Objects.Label label in item.labels) {
                builder.add_string_value (safe (label.name));
            }
            builder.end_array ();
            builder.set_member_name ("extra_data"); builder.add_string_value (safe (item.extra_data));
            builder.set_member_name ("deadline_date"); builder.add_string_value (safe (item.deadline_date));
            builder.set_member_name ("item_type"); builder.add_string_value (item.item_type.to_string ());
            builder.end_object ();
        }
        builder.end_array ();

        builder.end_object ();

        var generator = new Json.Generator () { pretty = true };
        generator.set_root (builder.get_root ());
        return generator.to_data (null);
    }
}
