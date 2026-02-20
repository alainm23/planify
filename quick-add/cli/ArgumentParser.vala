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
    public enum CommandType {
        NONE,
        ADD,
        LIST_PROJECTS,
        LIST,
        UPDATE
    }

    public class TaskArguments : Object {
        public string? content { get; set; default = null; }
        public string? description { get; set; default = null; }
        public string? project_name { get; set; default = null; }
        public string? project_id { get; set; default = null; }
        public string? section_name { get; set; default = null; }
        public string? section_id { get; set; default = null; }
        public string? parent_id { get; set; default = null; }
        public int priority { get; set; default = 4; }
        public string? due_date { get; set; default = null; }
        public string? labels { get; set; default = null; }
        public int pinned { get; set; default = -1; } // -1 = not set, 0 = unpinned, 1 = pinned
    }

    public class ListArguments : Object {
        public string? project_name { get; set; default = null; }
        public string? project_id { get; set; default = null; }
    }

    public class UpdateArguments : Object {
        public string? task_id { get; set; default = null; }
        public string? content { get; set; default = null; }
        public string? description { get; set; default = null; }
        public string? project_name { get; set; default = null; }
        public string? project_id { get; set; default = null; }
        public string? section_name { get; set; default = null; }
        public string? section_id { get; set; default = null; }
        public string? parent_id { get; set; default = null; }
        public int priority { get; set; default = -1; }
        public string? due_date { get; set; default = null; }
        public string? labels { get; set; default = null; }
        public int checked { get; set; default = -1; } // -1 = not set, 0 = uncomplete, 1 = complete
        public int pinned { get; set; default = -1; } // -1 = not set, 0 = unpinned, 1 = pinned
    }

    public class ParsedCommand : Object {
        public CommandType command_type { get; set; default = CommandType.NONE; }
        public TaskArguments? task_args { get; set; default = null; }
        public ListArguments? list_args { get; set; default = null; }
        public UpdateArguments? update_args { get; set; default = null; }
    }

    public class ArgumentParser : Object {
        public static ParsedCommand? parse (string[] args, out int exit_code) {
            exit_code = 0;

            // Check for top-level help
            if (args.length >= 2 && (args[1] == "-h" || args[1] == "--help")) {
                print_general_help (args[0]);
                exit_code = 0;
                return null;
            }

            // Check for command
            if (args.length < 2) {
                stderr.printf ("Error: No command specified\n");
                stderr.printf ("Usage: %s <command> [OPTIONS]\n", args[0]);
                stderr.printf ("Commands: add, list, update, list-projects\n");
                stderr.printf ("Run '%s --help' for more information\n", args[0]);
                exit_code = 1;
                return null;
            }

            string command = args[1];
            var parsed = new ParsedCommand ();

            string[] command_args = new string[args.length - 1];
            command_args[0] = args[0] + " " + command;
            for (int i = 2; i < args.length; i++) {
                command_args[i - 1] = args[i];
            }

            try {
                switch (command) {
                    case "list-projects":
                        parsed.command_type = CommandType.LIST_PROJECTS;
                        return parsed;

                    case "list":
                        parsed.command_type = CommandType.LIST;
                        parsed.list_args = parse_list_command (command_args);
                        return parsed;

                    case "add":
                        parsed.command_type = CommandType.ADD;
                        parsed.task_args = parse_add_command (command_args);
                        return parsed;

                    case "update":
                        parsed.command_type = CommandType.UPDATE;
                        parsed.update_args = parse_update_command (command_args);
                        return parsed;

                    default:
                        stderr.printf ("Error: Unknown command '%s'\n", command);
                        stderr.printf ("Available commands: add, list, update, list-projects\n");
                        exit_code = 1;
                        return null;
                }
            } catch (OptionError e) {
                stderr.printf ("Error: %s\n", e.message);
                exit_code = 1;
                return null;
            }
        }

        private static ListArguments parse_list_command (string[] args) throws OptionError {
            string? project_name = null;
            string? project_id = null;

            var options = new OptionEntry[3];
            options[0] = { "project", 'p', 0, OptionArg.STRING, ref project_name,
                          "Project name (defaults to inbox)", "PROJECT" };
            options[1] = { "project-id", 'i', 0, OptionArg.STRING, ref project_id,
                          "Project ID (preferred over name)", "ID" };
            options[2] = { null };

            var context = new OptionContext ("- List tasks from a project");
            context.add_main_entries (options, null);
            context.set_help_enabled (true);

            unowned string[] tmp = args;
            context.parse (ref tmp);

            var list_args = new ListArguments ();
            list_args.project_name = project_name;
            list_args.project_id = project_id;

            return list_args;
        }

        private static TaskArguments parse_add_command (string[] args) throws OptionError {
            string? content = null;
            string? description = null;
            string? project_name = null;
            string? project_id = null;
            string? section_name = null;
            string? section_id = null;
            string? parent_id = null;
            int priority = 4;
            string? due_date = null;
            string? labels = null;
            string? pin_str = null;

            var options = new OptionEntry[12];
            options[0] = { "content", 'c', 0, OptionArg.STRING, ref content,
                          "Task content (required)", "CONTENT" };
            options[1] = { "description", 'd', 0, OptionArg.STRING, ref description,
                          "Task description", "DESC" };
            options[2] = { "project", 'p', 0, OptionArg.STRING, ref project_name,
                          "Project name (defaults to inbox)", "PROJECT" };
            options[3] = { "project-id", 'i', 0, OptionArg.STRING, ref project_id,
                          "Project ID (preferred over name)", "ID" };
            options[4] = { "section", 's', 0, OptionArg.STRING, ref section_name,
                          "Section name", "SECTION" };
            options[5] = { "section-id", 'S', 0, OptionArg.STRING, ref section_id,
                          "Section ID (preferred over name)", "ID" };
            options[6] = { "parent-id", 'a', 0, OptionArg.STRING, ref parent_id,
                          "Parent task ID (creates a subtask)", "ID" };
            options[7] = { "priority", 'P', 0, OptionArg.INT, ref priority,
                          "Priority: 1=high, 2=medium, 3=low, 4=none (default: 4)", "1-4" };
            options[8] = { "due", 'D', 0, OptionArg.STRING, ref due_date,
                          "Due date in YYYY-MM-DD format", "DATE" };
            options[9] = { "labels", 'l', 0, OptionArg.STRING, ref labels,
                          "Comma-separated list of label names", "LABELS" };
            options[10] = { "pin", 0, 0, OptionArg.STRING, ref pin_str,
                           "Pin or unpin the task", "true|false" };
            options[11] = { null };

            var context = new OptionContext ("- Add a new task to Planify");
            context.add_main_entries (options, null);
            context.set_help_enabled (true);

            unowned string[] tmp = args;
            context.parse (ref tmp);

            var task_args = new TaskArguments ();
            task_args.content = content;
            task_args.description = description;
            task_args.project_name = project_name;
            task_args.project_id = project_id;
            task_args.section_name = section_name;
            task_args.section_id = section_id;
            task_args.parent_id = parent_id;
            task_args.priority = priority;
            task_args.due_date = due_date;
            task_args.labels = labels;
            task_args.pinned = parse_boolean_option (pin_str);

            return task_args;
        }

        private static UpdateArguments parse_update_command (string[] args) throws OptionError {
            string? task_id = null;
            string? content = null;
            string? description = null;
            string? project_name = null;
            string? project_id = null;
            string? section_name = null;
            string? section_id = null;
            string? parent_id = null;
            int priority = -1;
            string? due_date = null;
            string? labels = null;
            string? complete_str = null;
            string? pin_str = null;

            var options = new OptionEntry[14];
            options[0] = { "task-id", 't', 0, OptionArg.STRING, ref task_id,
                          "Task ID to update (required)", "ID" };
            options[1] = { "content", 'c', 0, OptionArg.STRING, ref content,
                          "New task content", "CONTENT" };
            options[2] = { "description", 'd', 0, OptionArg.STRING, ref description,
                          "New task description", "DESC" };
            options[3] = { "project", 'p', 0, OptionArg.STRING, ref project_name,
                          "Move to project by name", "PROJECT" };
            options[4] = { "project-id", 'i', 0, OptionArg.STRING, ref project_id,
                          "Move to project by ID (preferred over name)", "ID" };
            options[5] = { "section", 's', 0, OptionArg.STRING, ref section_name,
                          "Section name", "SECTION" };
            options[6] = { "section-id", 'S', 0, OptionArg.STRING, ref section_id,
                          "Section ID (preferred over name)", "ID" };
            options[7] = { "parent-id", 'a', 0, OptionArg.STRING, ref parent_id,
                          "New parent task ID", "ID" };
            options[8] = { "priority", 'P', 0, OptionArg.INT, ref priority,
                          "Priority: 1=high, 2=medium, 3=low, 4=none", "1-4" };
            options[9] = { "due", 'D', 0, OptionArg.STRING, ref due_date,
                          "Due date in YYYY-MM-DD format", "DATE" };
            options[10] = { "labels", 'l', 0, OptionArg.STRING, ref labels,
                           "Comma-separated list of label names", "LABELS" };
            options[11] = { "complete", 0, 0, OptionArg.STRING, ref complete_str,
                           "Mark task as complete or incomplete", "true|false" };
            options[12] = { "pin", 0, 0, OptionArg.STRING, ref pin_str,
                           "Pin or unpin the task", "true|false" };
            options[13] = { null };

            var context = new OptionContext ("- Update an existing task. Only provided fields will be changed.");
            context.add_main_entries (options, null);
            context.set_help_enabled (true);

            unowned string[] tmp = args;
            context.parse (ref tmp);

            var update_args = new UpdateArguments ();
            update_args.task_id = task_id;
            update_args.content = content;
            update_args.description = description;
            update_args.project_name = project_name;
            update_args.project_id = project_id;
            update_args.section_name = section_name;
            update_args.section_id = section_id;
            update_args.parent_id = parent_id;
            update_args.priority = priority;
            update_args.due_date = due_date;
            update_args.labels = labels;
            update_args.checked = parse_boolean_option (complete_str);
            update_args.pinned = parse_boolean_option (pin_str);

            return update_args;
        }

        private static int parse_boolean_option (string? value) throws OptionError {
            if (value == null) {
                return -1;
            }

            string lower_value = value.down ();
            if (lower_value == "true") {
                return 1;
            } else if (lower_value == "false") {
                return 0;
            } else {
                throw new OptionError.BAD_VALUE ("Boolean option requires 'true' or 'false'");
            }
        }

        private static void print_general_help (string program_name) {
            stdout.printf ("Usage: %s <command> [OPTIONS]\n\n", program_name);
            stdout.printf ("Commands:\n");
            stdout.printf ("  add              Add a new task\n");
            stdout.printf ("  list             List tasks from a project\n");
            stdout.printf ("  update           Update an existing task\n");
            stdout.printf ("  list-projects    List all projects\n\n");
            stdout.printf ("Run '%s <command> --help' for command-specific options\n\n", program_name);
            stdout.printf ("Examples:\n");
            stdout.printf ("  %s add --help\n", program_name);
            stdout.printf ("  %s list --help\n", program_name);
            stdout.printf ("  %s update --help\n", program_name);
        }
    }
}