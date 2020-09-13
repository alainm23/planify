/*/
*- Copyright © 2019 Alain M. (https://github.com/alainm23/planner)
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

public class Services.ExportImport : Object {
    private Json.Generator generator;
    private Json.Builder builder;

    construct {
        generator = new Json.Generator ();
        generator.pretty = true;

        builder = new Json.Builder ();
    }

    public void export_to_json (string path) {
        builder.begin_object ();

            builder.set_member_name ("version");
            builder.add_string_value (Constants.VERSION);

            // Preferences
            builder.set_member_name ("settings");
            builder.begin_object ();
                builder.set_member_name ("inbox-project");
                builder.add_int_value (Planner.settings.get_int64 ("inbox-project"));

                builder.set_member_name ("todoist-account");
                builder.add_boolean_value (Planner.settings.get_boolean ("todoist-account"));

                builder.set_member_name ("todoist-access-token");
                builder.add_string_value (Planner.settings.get_string ("todoist-access-token"));

                builder.set_member_name ("todoist-sync-token");
                builder.add_string_value (Planner.settings.get_string ("todoist-sync-token"));

                builder.set_member_name ("todoist-user-email");
                builder.add_string_value (Planner.settings.get_string ("todoist-user-email"));
            builder.end_object ();

            // Labels
            builder.set_member_name ("labels");
            builder.begin_array ();
                foreach (var label in Planner.database.get_all_labels ()) {
                    builder.begin_object ();
                    builder.set_member_name ("id");
                    builder.add_int_value (label.id);

                    builder.set_member_name ("name");
                    builder.add_string_value (label.name);

                    builder.set_member_name ("color");
                    builder.add_int_value (label.color);

                    builder.set_member_name ("item_order");
                    builder.add_int_value (label.item_order);

                    builder.set_member_name ("is_deleted");
                    builder.add_int_value (label.is_deleted);

                    builder.set_member_name ("is_favorite");
                    builder.add_int_value (label.is_favorite);

                    builder.set_member_name ("is_todoist");
                    builder.add_int_value (label.is_todoist);
                    builder.end_object ();
                }
            builder.end_array ();

            // Areas
            builder.set_member_name ("areas");
            builder.begin_array ();
                foreach (var area in Planner.database.get_all_areas ()) {
                    builder.begin_object ();
                    builder.set_member_name ("id");
                    builder.add_int_value (area.id);

                    builder.set_member_name ("name");
                    builder.add_string_value (area.name);

                    builder.set_member_name ("date_added");
                    builder.add_string_value (area.date_added);

                    builder.set_member_name ("collapsed");
                    builder.add_int_value (area.collapsed);

                    builder.set_member_name ("item_order");
                    builder.add_int_value (area.item_order);

                    builder.end_object ();
                }
            builder.end_array ();
            
            // Projects
            builder.set_member_name ("projects");
            builder.begin_array ();
                foreach (var project in Planner.database.get_all_projects ()) {
                    builder.begin_object ();
                    builder.set_member_name ("area_id");
                    builder.add_int_value (project.area_id);

                    builder.set_member_name ("id");
                    builder.add_int_value (project.id);

                    builder.set_member_name ("name");
                    builder.add_string_value (project.name);

                    builder.set_member_name ("note");
                    builder.add_string_value (project.note);

                    builder.set_member_name ("due_date");
                    builder.add_string_value (project.due_date);

                    builder.set_member_name ("color");
                    builder.add_int_value (project.color);

                    builder.set_member_name ("is_todoist");
                    builder.add_int_value (project.is_todoist);

                    builder.set_member_name ("inbox_project");
                    builder.add_int_value (project.inbox_project);

                    builder.set_member_name ("team_inbox");
                    builder.add_int_value (project.team_inbox);

                    builder.set_member_name ("item_order");
                    builder.add_int_value (project.item_order);

                    builder.set_member_name ("is_deleted");
                    builder.add_int_value (project.is_deleted);

                    builder.set_member_name ("is_archived");
                    builder.add_int_value (project.is_archived);

                    builder.set_member_name ("is_favorite");
                    builder.add_int_value (project.is_favorite);

                    builder.set_member_name ("is_sync");
                    builder.add_int_value (project.is_sync);

                    builder.set_member_name ("shared");
                    builder.add_int_value (project.shared);

                    builder.set_member_name ("is_kanban");
                    builder.add_int_value (project.is_kanban);

                    builder.set_member_name ("show_completed");
                    builder.add_int_value (project.show_completed);

                    builder.set_member_name ("sort_order");
                    builder.add_int_value (project.sort_order);
                    builder.end_object ();
                }
            builder.end_array ();

            // Sections
            builder.set_member_name ("sections");
            builder.begin_array ();
                foreach (var section in Planner.database.get_all_sections ()) {
                    builder.begin_object ();
                    builder.set_member_name ("id");
                    builder.add_int_value (section.id);

                    builder.set_member_name ("project_id");
                    builder.add_int_value (section.project_id);

                    builder.set_member_name ("sync_id");
                    builder.add_int_value (section.sync_id);

                    builder.set_member_name ("name");
                    builder.add_string_value (section.name);

                    builder.set_member_name ("note");
                    builder.add_string_value (section.note);

                    builder.set_member_name ("item_order");
                    builder.add_int_value (section.item_order);

                    builder.set_member_name ("collapsed");
                    builder.add_int_value (section.collapsed);

                    builder.set_member_name ("is_todoist");
                    builder.add_int_value (section.is_todoist);

                    builder.set_member_name ("is_deleted");
                    builder.add_int_value (section.is_deleted);

                    builder.set_member_name ("is_archived");
                    builder.add_int_value (section.is_archived);

                    builder.set_member_name ("date_archived");
                    builder.add_string_value (section.date_archived);

                    builder.set_member_name ("date_added");
                    builder.add_string_value (section.date_added);
                    builder.end_object ();
                }
            builder.end_array ();

            // Items
            builder.set_member_name ("items");
            builder.begin_array ();
                foreach (var item in Planner.database.get_all_items ()) {
                    builder.begin_object ();
                    builder.set_member_name ("id");
                    builder.add_int_value (item.id);

                    builder.set_member_name ("project_id");
                    builder.add_int_value (item.project_id);

                    builder.set_member_name ("section_id");
                    builder.add_int_value (item.section_id);

                    builder.set_member_name ("user_id");
                    builder.add_int_value (item.user_id);

                    builder.set_member_name ("assigned_by_uid");
                    builder.add_int_value (item.assigned_by_uid);

                    builder.set_member_name ("responsible_uid");
                    builder.add_int_value (item.responsible_uid);

                    builder.set_member_name ("sync_id");
                    builder.add_int_value (item.sync_id);

                    builder.set_member_name ("parent_id");
                    builder.add_int_value (item.parent_id);

                    builder.set_member_name ("priority");
                    builder.add_int_value (item.priority);

                    builder.set_member_name ("item_order");
                    builder.add_int_value (item.item_order);

                    builder.set_member_name ("day_order");
                    builder.add_int_value (item.day_order);

                    builder.set_member_name ("checked");
                    builder.add_int_value (item.checked);

                    builder.set_member_name ("is_deleted");
                    builder.add_int_value (item.is_deleted);

                    builder.set_member_name ("is_todoist");
                    builder.add_int_value (item.is_todoist);

                    builder.set_member_name ("content");
                    builder.add_string_value (item.content);
                    
                    builder.set_member_name ("note");
                    builder.add_string_value (item.note);

                    builder.set_member_name ("due_date");
                    builder.add_string_value (item.due_date);

                    builder.set_member_name ("due_timezone");
                    builder.add_string_value (item.due_timezone);

                    builder.set_member_name ("due_string");
                    builder.add_string_value (item.due_string);

                    builder.set_member_name ("due_lang");
                    builder.add_string_value (item.due_lang);

                    builder.set_member_name ("due_is_recurring");
                    builder.add_int_value (item.due_is_recurring);

                    builder.set_member_name ("date_added");
                    builder.add_string_value (item.date_added);

                    builder.set_member_name ("date_completed");
                    builder.add_string_value (item.date_completed);

                    builder.set_member_name ("date_updated");
                    builder.add_string_value (item.date_updated);

                    builder.set_member_name ("labels");
                    builder.begin_array ();
                        foreach (var label in Planner.database.get_labels_by_item (item.id)) {
                            builder.add_int_value (label.id);
                        }
                    builder.end_array ();
                    builder.end_object ();
                }
            builder.end_array ();

            // Reminders
            builder.set_member_name ("reminders");
            builder.begin_array ();
                foreach (var reminder in Planner.database.get_reminders ()) {
                    builder.begin_object ();
                    builder.set_member_name ("id");
                    builder.add_int_value (reminder.id);

                    builder.set_member_name ("notify_uid");
                    builder.add_int_value (reminder.notify_uid);

                    builder.set_member_name ("item_id");
                    builder.add_int_value (reminder.item_id);

                    builder.set_member_name ("project_id");
                    builder.add_int_value (reminder.project_id);

                    builder.set_member_name ("service");
                    builder.add_string_value (reminder.service);

                    builder.set_member_name ("due_date");
                    builder.add_string_value (reminder.due_date);

                    builder.set_member_name ("due_timezone");
                    builder.add_string_value (reminder.due_timezone);

                    builder.set_member_name ("due_string");
                    builder.add_string_value (reminder.due_string);

                    builder.set_member_name ("due_lang");
                    builder.add_string_value (reminder.due_lang);

                    builder.set_member_name ("content");
                    builder.add_string_value (reminder.content);

                    builder.set_member_name ("service");
                    builder.add_string_value (reminder.service);

                    builder.set_member_name ("due_is_recurring");
                    builder.add_int_value (reminder.due_is_recurring);

                    builder.set_member_name ("mm_offset");
                    builder.add_int_value (reminder.mm_offset);

                    builder.set_member_name ("is_deleted");
                    builder.add_int_value (reminder.is_deleted);

                    builder.set_member_name ("is_todoist");
                    builder.add_int_value (reminder.is_todoist);
                    builder.end_object ();
                }
            builder.end_array ();
        builder.end_object ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);

        try {
            generator.to_file (path);
        } catch (Error e) {
            print ("Error: %s\n", e.message);
        }
    }

    public void save_file_as () {
        var dialog = new Gtk.FileChooserNative (
            _("Save Planner file"), Planner.instance.main_window,
            Gtk.FileChooserAction.SAVE,
            _("Save"),
            _("Cancel"));

        dialog.set_do_overwrite_confirmation (true);
        add_filters (dialog);
        dialog.set_modal (true);
        
        if (dialog.run () == Gtk.ResponseType.ACCEPT) {
            var file = dialog.get_file ();

            if (!file.get_basename ().down ().has_suffix (".planner")) {
                try {
                    export_to_json (file.get_path () + ".planner");
                } catch (Error e) {
                    debug (e.message);
                }
            }
        }

        dialog.destroy ();
    }

    private void add_filters (Gtk.FileChooserNative chooser) {
        Gtk.FileFilter filter = new Gtk.FileFilter ();
        filter.add_pattern ("*.planner");
        filter.set_filter_name (_("Planner files"));
        chooser.add_filter (filter);

        filter = new Gtk.FileFilter ();
        filter.add_pattern ("*");
        filter.set_filter_name (_("All files"));
        chooser.add_filter (filter);
    }

    public void import_backup () {
        string file = choose_file ();
        if (file != null) {
            var parser = new Json.Parser ();
            
            try {
                parser.load_from_file (file);

                var node = parser.get_root ().get_object ();
                var version = node.get_string_member ("version");

                // Set Settings
                var settings = node.get_object_member ("settings");
                Planner.settings.set_int64 ("inbox-project", settings.get_int_member ("inbox-project"));
                Planner.settings.set_boolean ("todoist-account", settings.get_boolean_member ("todoist-account"));
                Planner.settings.set_string ("todoist-access-token", settings.get_string_member ("todoist-access-token"));
                Planner.settings.set_string ("todoist-sync-token", settings.get_string_member ("todoist-access-token"));

                // Create Labels
                unowned Json.Array labels = node.get_array_member ("labels");
                foreach (unowned Json.Node item in labels.get_elements ()) {
                    var object = item.get_object ();

                    var l = new Objects.Label ();
                    l.id = object.get_int_member ("id");
                    l.name = object.get_string_member ("name");
                    l.color = (int32) object.get_int_member ("color");
                    l.item_order = (int32) object.get_int_member ("item_order");
                    l.is_deleted = (int32) object.get_int_member ("is_deleted");
                    l.is_favorite = (int32) object.get_int_member ("is_favorite");
                    l.is_todoist = (int32) object.get_int_member ("is_todoist");

                    Planner.database.insert_label (l);
                }

                // Create Areas
                unowned Json.Array areas = node.get_array_member ("areas");
                foreach (unowned Json.Node item in areas.get_elements ()) {
                    var object = item.get_object ();

                    var a = new Objects.Area ();
                    a.id = object.get_int_member ("id");
                    a.name = object.get_string_member ("name");
                    a.date_added = object.get_string_member ("date_added");
                    a.collapsed = (int32) object.get_int_member ("collapsed");
                    a.item_order = (int32) object.get_int_member ("item_order");

                    Planner.database.insert_area (a);
                }

                // Create Projects
                unowned Json.Array projects = node.get_array_member ("projects");
                foreach (unowned Json.Node item in projects.get_elements ()) {
                    var object = item.get_object ();

                    var p = new Objects.Project ();

                    p.id = object.get_int_member ("id");
                    p.area_id = object.get_int_member ("area_id");
                    p.name = object.get_string_member ("name");
                    p.note = object.get_string_member ("note");
                    p.due_date = object.get_string_member ("due_date");
                    p.color = (int32) object.get_int_member ("color");
                    p.is_todoist = (int32) object.get_int_member ("is_todoist");
                    p.inbox_project = (int32) object.get_int_member ("inbox_project");
                    p.team_inbox = (int32) object.get_int_member ("team_inbox");
                    p.item_order = (int32) object.get_int_member ("item_order");
                    p.is_deleted = (int32) object.get_int_member ("is_deleted");
                    p.is_archived = (int32) object.get_int_member ("is_archived");
                    p.is_favorite = (int32) object.get_int_member ("is_favorite");
                    p.is_sync = (int32) object.get_int_member ("is_sync");
                    p.shared = (int32) object.get_int_member ("shared");
                    p.is_kanban = (int32) object.get_int_member ("is_kanban");
                    p.show_completed = (int32) object.get_int_member ("show_completed");
                    p.sort_order = (int32) object.get_int_member ("sort_order");

                    Planner.database.insert_project (p);
                }

                // Create sections
                unowned Json.Array sections = node.get_array_member ("sections");
                foreach (unowned Json.Node item in sections.get_elements ()) {
                    var object = item.get_object ();

                    var s = new Objects.Section ();

                    s.id = object.get_int_member ("id");
                    s.name = object.get_string_member ("name");
                    s.project_id = object.get_int_member ("project_id");
                    s.item_order = (int32) object.get_int_member ("item_order");
                    s.collapsed = (int32) object.get_int_member ("collapsed");
                    s.sync_id = object.get_int_member ("sync_id");
                    s.is_deleted = (int32) object.get_int_member ("is_deleted");
                    s.is_archived = (int32) object.get_int_member ("is_archived");
                    s.date_archived = object.get_string_member ("date_archived");
                    s.date_added = object.get_string_member ("date_added");
                    s.is_todoist = (int32) object.get_int_member ("is_todoist");
                    s.note = object.get_string_member ("note");

                    Planner.database.insert_section (s);
                }

                // Create Items
                unowned Json.Array items = node.get_array_member ("items");
                foreach (unowned Json.Node item in items.get_elements ()) {
                    var object = item.get_object ();

                    var i = new Objects.Item ();

                    i.id = object.get_int_member ("id");
                    i.project_id = object.get_int_member ("project_id");
                    i.section_id = object.get_int_member ("section_id");
                    i.user_id = object.get_int_member ("user_id");
                    i.assigned_by_uid = object.get_int_member ("assigned_by_uid");
                    i.responsible_uid = object.get_int_member ("responsible_uid");
                    i.sync_id = object.get_int_member ("sync_id");
                    i.priority = (int32) object.get_int_member ("priority");
                    i.item_order = (int32) object.get_int_member ("item_order");
                    i.checked = (int32) object.get_int_member ("checked");
                    i.is_deleted = (int32) object.get_int_member ("is_deleted");
                    i.content = object.get_string_member ("content");
                    i.note = object.get_string_member ("note");
                    i.due_date = object.get_string_member ("due_date");
                    i.due_timezone = object.get_string_member ("due_timezone");
                    i.due_string = object.get_string_member ("due_string");
                    i.due_lang = object.get_string_member ("due_lang");
                    i.due_is_recurring = (int32) object.get_int_member ("due_is_recurring");
                    i.date_added = object.get_string_member ("date_added");
                    i.date_completed = object.get_string_member ("date_completed");
                    i.date_updated = object.get_string_member ("date_updated");
                    i.is_todoist = (int32) object.get_int_member ("is_todoist");
                    i.day_order = (int32) object.get_int_member ("is_day_ordertodoist");
                    
                    Planner.database.insert_item (i);
                }

                // Create Reminders
                unowned Json.Array reminders = node.get_array_member ("reminders");
                foreach (unowned Json.Node item in reminders.get_elements ()) {
                    var object = item.get_object ();

                    var r = new Objects.Reminder ();

                    r.id = object.get_int_member ("id");
                    r.notify_uid = object.get_int_member ("notify_uid");
                    r.item_id = object.get_int_member ("item_id");
                    r.service = object.get_string_member ("service");
                    r.due_date = object.get_string_member ("due_date");
                    r.due_timezone = object.get_string_member ("due_timezone");
                    r.due_is_recurring = (int32) object.get_int_member ("due_is_recurring");
                    r.due_string = object.get_string_member ("due_string");
                    r.due_lang = object.get_string_member ("due_lang");
                    r.mm_offset = (int32) object.get_int_member ("mm_offset");
                    r.is_deleted = (int32) object.get_int_member ("is_deleted");
                    r.is_todoist = (int32) object.get_int_member ("is_todoist");

                    Planner.database.insert_reminder (r);
                }

                Planner.todoist.first_sync_finished ();
            } catch (Error e) {
                debug (e.message);
            }
        }
    }

    private string choose_file () {
        string? return_value = null;
        var dialog = new Gtk.FileChooserNative (
            _("Open Planner file"), Planner.instance.main_window,
            Gtk.FileChooserAction.OPEN,
            _("Open"),
            _("Cancel"));

        dialog.set_do_overwrite_confirmation (true);
        add_filters (dialog);
        dialog.set_modal (true);
        
        if (dialog.run () == Gtk.ResponseType.ACCEPT) {
            return_value = dialog.get_file ().get_path ();
        }

        dialog.destroy ();
        return return_value;
    }
}
