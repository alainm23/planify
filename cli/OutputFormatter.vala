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
    public class OutputFormatter : Object {
        private delegate void FieldValueAdder (Json.Builder builder);

        private struct FieldDef {
            string name;
            FieldValueAdder add_value;
        }

        // Define fields to include in output
        private static FieldDef[] get_project_fields (Objects.Project project) {
            return {
                { "id", (builder) => builder.add_string_value (project.id) },
                { "name", (builder) => builder.add_string_value (project.name) },
                { "item-count", (builder) => builder.add_int_value (project.item_count) },
                { "description", (builder) => builder.add_string_value (project.description) }
            };
        }

        private static FieldDef[] get_item_fields (Objects.Item item) {
            return {
                { "id", (builder) => builder.add_string_value (item.id) },
                { "content", (builder) => builder.add_string_value (item.content) },
                { "description", (builder) => builder.add_string_value (item.description) },
                { "checked", (builder) => builder.add_boolean_value (item.checked) },
                { "pinned", (builder) => builder.add_boolean_value (item.pinned) },
                { "priority", (builder) => builder.add_int_value (5 - item.priority) },
                { "project-id", (builder) => builder.add_string_value (item.project_id) },
                { "section-id", (builder) => builder.add_string_value (item.section_id) },
                { "parent-id", (builder) => builder.add_string_value (item.parent_id) },
                { "added-at", (builder) => builder.add_string_value (item.added_at) },
                { "completed-at", (builder) => builder.add_string_value (item.completed_at) },
                { "updated-at", (builder) => builder.add_string_value (item.updated_at) },
                { "labels", (builder) => {
                    builder.begin_array ();
                    foreach (var label in item.labels) {
                        builder.add_string_value (label.name);
                    }
                    builder.end_array ();
                }}
            };
        }

        public static void print_task_result (Objects.Item item, Objects.Project project) {
            var builder = new Json.Builder ();
            builder.begin_object ();
            
            builder.set_member_name ("task");
            add_object (builder, get_item_fields (item));
            
            builder.set_member_name ("project");
            add_object (builder, get_project_fields (project));
            
            builder.end_object ();

            var generator = new Json.Generator ();
            generator.set_root (builder.get_root ());
            generator.pretty = true;
            stdout.printf ("%s\n", generator.to_data (null));
        }

        public static void print_projects_list (Gee.ArrayList<Objects.Project> projects) {
            var builder = new Json.Builder ();
            builder.begin_array ();

            foreach (var project in projects) {
                add_object (builder, get_project_fields (project));
            }

            builder.end_array ();

            var generator = new Json.Generator ();
            generator.set_root (builder.get_root ());
            generator.pretty = true;
            stdout.printf ("%s\n", generator.to_data (null));
        }

        public static void print_tasks_list (Gee.ArrayList<Objects.Item> items) {
            var builder = new Json.Builder ();
            builder.begin_array ();

            foreach (var item in items) {
                add_object (builder, get_item_fields (item));
            }

            builder.end_array ();

            var generator = new Json.Generator ();
            generator.set_root (builder.get_root ());
            generator.pretty = true;
            stdout.printf ("%s\n", generator.to_data (null));
        }

        private static void add_object (Json.Builder builder, FieldDef[] fields) {
            builder.begin_object ();

            foreach (var field in fields) {
                builder.set_member_name (field.name);
                field.add_value (builder);
            }

            builder.end_object ();
        }
    }
}
