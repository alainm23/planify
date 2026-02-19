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
 */

namespace PlanifyCLI {
    private static int list_projects () {
        // Initialize database
        Services.Database.get_default ().init_database ();

        // Get all projects from store
        var projects = Services.Store.instance ().projects;

        // Output as JSON
        OutputFormatter.print_projects_list (projects);

        return 0;
    }

    private static int list_tasks (ListArguments args) {
        // Initialize database
        Services.Database.get_default ().init_database ();

        // Find target project
        string? error_message;
        Objects.Project? target_project = TaskCreator.find_project (
            args.project_id,
            args.project_name,
            out error_message
        );

        if (target_project == null) {
            stderr.printf ("%s\n", error_message);
            return 1;
        }

        // Get all items for the project
        var items = Services.Store.instance ().get_items_by_project (target_project);

        // Output result
        OutputFormatter.print_tasks_list (items);

        return 0;
    }

    private static int update_task (UpdateArguments args) {
        // Validate task_id
        if (args.task_id == null || args.task_id.strip () == "") {
            stderr.printf ("Error: --task-id is required\n");
            return 1;
        }

        // Initialize database
        Services.Database.get_default ().init_database ();

        // Get existing item
        Objects.Item? item = Services.Store.instance ().get_item (args.task_id.strip ());
        if (item == null) {
            stderr.printf ("Error: Task ID '%s' not found\n", args.task_id);
            return 1;
        }

        string? error_message;

        // Update content if provided
        if (args.content != null && args.content.strip () != "") {
            item.content = args.content.strip ();
        }

        // Update description if provided
        if (args.description != null) {
            item.description = args.description.strip ();
        }

        // Update priority if provided
        if (args.priority != -1) {
            if (!TaskValidator.validate_priority (args.priority, out error_message)) {
                stderr.printf ("%s\n", error_message);
                return 1;
            }
            // Convert user-friendly priority (1=high, 4=none) to internal format (4=high, 1=none)
            item.priority = 5 - args.priority;
        }

        // Update due date if provided
        if (args.due_date != null) {
            GLib.DateTime? due_datetime;
            if (!TaskValidator.validate_and_parse_date (args.due_date, out due_datetime, out error_message)) {
                stderr.printf ("%s\n", error_message);
                return 1;
            }
            if (due_datetime != null) {
                item.due.date = Utils.Datetime.get_todoist_datetime_format (due_datetime);
            }
        }

        // Handle project change if provided
        bool project_changed = false;
        string old_project_id = item.project_id;
        string old_section_id = item.section_id;
        string old_parent_id = item.parent_id;

        if (args.project_id != null || args.project_name != null) {
            Objects.Project? target_project = TaskCreator.find_project (
                args.project_id,
                args.project_name,
                out error_message
            );

            if (target_project == null) {
                stderr.printf ("%s\n", error_message);
                return 1;
            }

            if (item.project_id != target_project.id) {
                item.project_id = target_project.id;
                item.section_id = "";  // Reset section when moving to new project
                project_changed = true;
            }
        }

        // Update parent_id if provided
        if (args.parent_id != null) {
            if (!TaskValidator.validate_parent_id (args.parent_id, out error_message)) {
                stderr.printf ("%s\n", error_message);
                return 1;
            }
            item.parent_id = args.parent_id.strip ();
        }

        // Update labels if provided
        if (args.labels != null) {
            var new_labels = new Gee.HashMap<string, Objects.Label> ();
            string[] label_names = args.labels.split (",");
            foreach (string label_name in label_names) {
                string trimmed = label_name.strip ();
                if (trimmed != "") {
                    Objects.Label? label = Services.Store.instance ().get_label_by_name (trimmed, true, item.project.source_id);
                    if (label == null) {
                        // Create new label if it doesn't exist
                        label = new Objects.Label ();
                        label.id = Util.get_default ().generate_id (label);
                        label.name = trimmed;
                        label.color = Util.get_default ().get_random_color ();
                        label.source_id = item.project.source_id;
                        Services.Store.instance ().insert_label (label);
                    }
                    new_labels[label.id] = label;
                }
            }
            item.check_labels (new_labels);
        }

        // Handle completion status change if provided
        if (args.checked != -1) {
            bool old_checked = item.checked;
            bool new_checked = args.checked == 1;
            
            if (old_checked != new_checked) {
                item.checked = new_checked;
                if (new_checked) {
                    item.completed_at = new GLib.DateTime.now_local ().to_string ();
                } else {
                    item.completed_at = "";
                }
                
                // Use async completion handler
                var loop = new MainLoop ();
                item.complete_item.begin (old_checked, (obj, res) => {
                    var response = item.complete_item.end (res);
                    if (!response.status) {
                        stderr.printf ("Error: Failed to update task completion status\n");
                    }
                    loop.quit ();
                });
                loop.run ();
            }
        }

        // Update pinned if provided
        if (args.pinned != -1) {
            item.pinned = args.pinned == 1;
        }

        // Save changes
        if (project_changed) {
            Services.Store.instance ().move_item (item, old_project_id, old_section_id, old_parent_id);
        } else {
            Services.Store.instance ().update_item (item);
        }

        // Notify main app via DBus
        bool dbus_notified = false;
        try {
            DBusClient.get_default ().interface.update_item (item.id);
            dbus_notified = true;
        } catch (Error e) {
            // Not a critical error - main app might not be running
            debug ("DBus notification failed: %s", e.message);
        }

        // Ensure DBus message is flushed before exit
        if (dbus_notified) {
            var main_context = MainContext.default ();
            while (main_context.pending ()) {
                main_context.iteration (false);
            }
        }

        // Get the current project for output
        Objects.Project? current_project = Services.Store.instance ().get_project (item.project_id);
        if (current_project == null) {
            current_project = Services.Store.instance ().get_inbox_project ();
        }

        // Output result
        OutputFormatter.print_task_result (item, current_project);

        return 0;
    }

    private static int add_task (TaskArguments args) {
        // Validate content
        string? error_message;
        if (!TaskValidator.validate_content (args.content, out error_message)) {
            stderr.printf ("%s\n", error_message);
            return 1;
        }

        // Validate priority
        if (!TaskValidator.validate_priority (args.priority, out error_message)) {
            stderr.printf ("%s\n", error_message);
            return 1;
        }

        // Validate and parse due date
        GLib.DateTime? due_datetime;
        if (!TaskValidator.validate_and_parse_date (args.due_date, out due_datetime, out error_message)) {
            stderr.printf ("%s\n", error_message);
            return 1;
        }

        // Initialize database
        Services.Database.get_default ().init_database ();

        // Validate parent_id if provided
        if (!TaskValidator.validate_parent_id (args.parent_id, out error_message)) {
            stderr.printf ("%s\n", error_message);
            return 1;
        }

        // Find target project
        Objects.Project? target_project = TaskCreator.find_project (
            args.project_id,
            args.project_name,
            out error_message
        );

        if (target_project == null) {
            stderr.printf ("%s\n", error_message);
            return 1;
        }

        // Create item
        var item = TaskCreator.create_item (
            args.content,
            args.description,
            args.priority,
            due_datetime,
            target_project,
            args.parent_id
        );

        // Add labels if provided
        if (args.labels != null && args.labels.strip () != "") {
            string[] label_names = args.labels.split (",");
            foreach (string label_name in label_names) {
                string trimmed = label_name.strip ();
                if (trimmed != "") {
                    Objects.Label? label = Services.Store.instance ().get_label_by_name (trimmed, true, target_project.source_id);
                    if (label == null) {
                        // Create new label if it doesn't exist
                        label = new Objects.Label ();
                        label.id = Util.get_default ().generate_id (label);
                        label.name = trimmed;
                        label.color = Util.get_default ().get_random_color ();
                        label.source_id = target_project.source_id;
                        Services.Store.instance ().insert_label (label);
                    }
                    item.labels.add (label);
                }
            }
        }

        // Set pinned if provided
        if (args.pinned != -1) {
            item.pinned = args.pinned == 1;
        }

        // Save and notify
        TaskCreator.save_and_notify (item);

        // Output result
        OutputFormatter.print_task_result (item, target_project);

        return 0;
    }

    public static int main (string[] args) {
        // Initialize localization
        Intl.setlocale (LocaleCategory.ALL, "");
        string langpack_dir = Path.build_filename (Build.INSTALL_PREFIX, "share", "locale");
        Intl.bindtextdomain (Build.GETTEXT_PACKAGE, langpack_dir);
        Intl.bind_textdomain_codeset (Build.GETTEXT_PACKAGE, "UTF-8");
        Intl.textdomain (Build.GETTEXT_PACKAGE);

        // Parse arguments
        int exit_code;
        ParsedCommand? parsed = ArgumentParser.parse (args, out exit_code);

        if (parsed == null) {
            return exit_code;
        }

        // Route to appropriate command handler
        switch (parsed.command_type) {
            case CommandType.LIST_PROJECTS:
                return list_projects ();
            case CommandType.LIST:
                return list_tasks (parsed.list_args);
            case CommandType.UPDATE:
                return update_task (parsed.update_args);
            case CommandType.ADD:
                return add_task (parsed.task_args);
            default:
                stderr.printf ("Error: Unknown command\n");
                return 1;
        }
    }
}
