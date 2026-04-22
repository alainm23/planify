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
    public class TaskCreator : Object {
        public static Objects.Section? find_section (string? section_id, string? section_name, Objects.Project project, out string? error_message) {
            error_message = null;
            Objects.Section? target_section = null;

            // Prefer section ID over name
            if (section_id != null && section_id.strip () != "") {
                // Search by section ID
                foreach (var section in Services.Store.instance ().get_sections_by_project (project)) {
                    if (section.id == section_id.strip ()) {
                        target_section = section;
                        break;
                    }
                }

                if (target_section == null) {
                    error_message = "Error: Section ID '%s' not found in project '%s'".printf (section_id, project.name);
                    return null;
                }
            } else if (section_name != null && section_name.strip () != "") {
                // Search for section by name (case-insensitive)
                string search_name = section_name.strip ().down ();
                foreach (var section in Services.Store.instance ().get_sections_by_project (project)) {
                    if (section.name.down () == search_name) {
                        target_section = section;
                        break;
                    }
                }

                if (target_section == null) {
                    error_message = "Error: Section '%s' not found in project '%s'".printf (section_name, project.name);
                    return null;
                }
            }

            return target_section;
        }

        public static Objects.Project? find_project (string? project_id, string? project_name, out string? error_message) {
            error_message = null;
            Objects.Project? target_project = null;

            // Prefer project ID over name
            if (project_id != null && project_id.strip () != "") {
                // Search by project ID
                foreach (var project in Services.Store.instance ().projects) {
                    if (project.id == project_id.strip () && !project.is_archived && !project.is_deleted) {
                        target_project = project;
                        break;
                    }
                }

                if (target_project == null) {
                    error_message = "Error: Project ID '%s' not found".printf (project_id);
                    return null;
                }
            } else if (project_name != null && project_name.strip () != "") {
                // Search for project by name (case-insensitive)
                string search_name = project_name.strip ().down ();
                foreach (var project in Services.Store.instance ().projects) {
                    if (project.name.down () == search_name && !project.is_archived && !project.is_deleted) {
                        target_project = project;
                        break;
                    }
                }

                if (target_project == null) {
                    error_message = "Error: Project '%s' not found".printf (project_name);
                    return null;
                }
            } else {
                // Default to inbox
                target_project = Services.Store.instance ().get_inbox_project ();
                if (target_project == null) {
                    error_message = "Error: No inbox project found";
                    return null;
                }
            }

            return target_project;
        }

        public static Objects.Item create_item (
            string content,
            string? description,
            int priority,
            GLib.DateTime? due_datetime,
            Objects.Project project,
            string? parent_id
        ) {
            var item = new Objects.Item ();
            item.id = Util.get_default ().generate_id (item);
            item.content = content.strip ();
            item.project_id = project.id;
            // Convert user-friendly priority (1=high, 4=none) to internal format (4=high, 1=none)
            item.priority = 5 - priority;
            item.added_at = new GLib.DateTime.now_local ().to_string ();

            // Set parent_id if provided
            if (parent_id != null && parent_id.strip () != "") {
                item.parent_id = parent_id.strip ();
            }

            // Set description if provided
            if (description != null && description.strip () != "") {
                item.description = description.strip ();
            }

            // Set due date if provided
            if (due_datetime != null) {
                item.due.date = Utils.Datetime.get_todoist_datetime_format (due_datetime);
            }

            return item;
        }

        public static bool save_and_notify (Objects.Item item) {
            // Insert item into database
            Services.Store.instance ().insert_item (item);

            // Notify main app via DBus
            bool dbus_notified = false;
            try {
                DBusClient.get_default ().interface.add_item (item.id);
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

            return true;
        }
    }
}