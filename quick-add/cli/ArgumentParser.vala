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
        public string? parent_id { get; set; default = null; }
        public int priority { get; set; default = 4; }
        public string? due_date { get; set; default = null; }
        public string? labels { get; set; default = null; }
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
        public string? parent_id { get; set; default = null; }
        public int priority { get; set; default = -1; }
        public string? due_date { get; set; default = null; }
        public string? labels { get; set; default = null; }
        public int checked { get; set; default = -1; } // -1 = not set, 0 = uncomplete, 1 = complete
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

            if (command == "list-projects") {
                parsed.command_type = CommandType.LIST_PROJECTS;
                return parsed;
            } else if (command == "list") {
                parsed.command_type = CommandType.LIST;
                var list_args = new ListArguments ();

                // Parse options starting from index 2
                for (int i = 2; i < args.length; i++) {
                    string arg = args[i];
                    
                    if (arg == "-p" || arg == "--project") {
                        if (i + 1 < args.length) {
                            list_args.project_name = args[++i];
                        } else {
                            stderr.printf ("Error: %s requires an argument\n", arg);
                            exit_code = 1;
                            return null;
                        }
                    } else if (arg == "-i" || arg == "--project-id") {
                        if (i + 1 < args.length) {
                            list_args.project_id = args[++i];
                        } else {
                            stderr.printf ("Error: %s requires an argument\n", arg);
                            exit_code = 1;
                            return null;
                        }
                    } else if (arg == "-h" || arg == "--help") {
                        print_list_help (args[0]);
                        exit_code = 0;
                        return null;
                    } else {
                        stderr.printf ("Error: Unknown option '%s'\n", arg);
                        stderr.printf ("Run '%s list --help' for usage information\n", args[0]);
                        exit_code = 1;
                        return null;
                    }
                }

                parsed.list_args = list_args;
                return parsed;
            } else if (command == "update") {
                parsed.command_type = CommandType.UPDATE;
                var update_args = new UpdateArguments ();

                // Parse options starting from index 2
                for (int i = 2; i < args.length; i++) {
                    string arg = args[i];
                    
                    if (arg == "-t" || arg == "--task-id") {
                        if (i + 1 < args.length) {
                            update_args.task_id = args[++i];
                        } else {
                            stderr.printf ("Error: %s requires an argument\n", arg);
                            exit_code = 1;
                            return null;
                        }
                    } else if (arg == "-c" || arg == "--content") {
                        if (i + 1 < args.length) {
                            update_args.content = args[++i];
                        } else {
                            stderr.printf ("Error: %s requires an argument\n", arg);
                            exit_code = 1;
                            return null;
                        }
                    } else if (arg == "-d" || arg == "--description") {
                        if (i + 1 < args.length) {
                            update_args.description = args[++i];
                        } else {
                            stderr.printf ("Error: %s requires an argument\n", arg);
                            exit_code = 1;
                            return null;
                        }
                    } else if (arg == "-p" || arg == "--project") {
                        if (i + 1 < args.length) {
                            update_args.project_name = args[++i];
                        } else {
                            stderr.printf ("Error: %s requires an argument\n", arg);
                            exit_code = 1;
                            return null;
                        }
                    } else if (arg == "-i" || arg == "--project-id") {
                        if (i + 1 < args.length) {
                            update_args.project_id = args[++i];
                        } else {
                            stderr.printf ("Error: %s requires an argument\n", arg);
                            exit_code = 1;
                            return null;
                        }
                    } else if (arg == "-a" || arg == "--parent-id") {
                        if (i + 1 < args.length) {
                            update_args.parent_id = args[++i];
                        } else {
                            stderr.printf ("Error: %s requires an argument\n", arg);
                            exit_code = 1;
                            return null;
                        }
                    } else if (arg == "-P" || arg == "--priority") {
                        if (i + 1 < args.length) {
                            update_args.priority = int.parse (args[++i]);
                        } else {
                            stderr.printf ("Error: %s requires an argument\n", arg);
                            exit_code = 1;
                            return null;
                        }
                    } else if (arg == "-D" || arg == "--due") {
                        if (i + 1 < args.length) {
                            update_args.due_date = args[++i];
                        } else {
                            stderr.printf ("Error: %s requires an argument\n", arg);
                            exit_code = 1;
                            return null;
                        }
                    } else if (arg == "-l" || arg == "--labels") {
                        if (i + 1 < args.length) {
                            update_args.labels = args[++i];
                        } else {
                            stderr.printf ("Error: %s requires an argument\n", arg);
                            exit_code = 1;
                            return null;
                        }
                    } else if (arg == "--complete") {
                        update_args.checked = 1;
                    } else if (arg == "--uncomplete") {
                        update_args.checked = 0;
                    } else if (arg == "-h" || arg == "--help") {
                        print_update_help (args[0]);
                        exit_code = 0;
                        return null;
                    } else {
                        stderr.printf ("Error: Unknown option '%s'\n", arg);
                        stderr.printf ("Run '%s update --help' for usage information\n", args[0]);
                        exit_code = 1;
                        return null;
                    }
                }

                parsed.update_args = update_args;
                return parsed;
            } else if (command == "add") {
                parsed.command_type = CommandType.ADD;
                var task_args = new TaskArguments ();

            // Parse options starting from index 2
            for (int i = 2; i < args.length; i++) {
                string arg = args[i];
                
                if (arg == "-c" || arg == "--content") {
                    if (i + 1 < args.length) {
                        task_args.content = args[++i];
                    } else {
                        stderr.printf ("Error: %s requires an argument\n", arg);
                        exit_code = 1;
                        return null;
                    }
                } else if (arg == "-d" || arg == "--description") {
                    if (i + 1 < args.length) {
                        task_args.description = args[++i];
                    } else {
                        stderr.printf ("Error: %s requires an argument\n", arg);
                        exit_code = 1;
                        return null;
                    }
                } else if (arg == "-p" || arg == "--project") {
                    if (i + 1 < args.length) {
                        task_args.project_name = args[++i];
                    } else {
                        stderr.printf ("Error: %s requires an argument\n", arg);
                        exit_code = 1;
                        return null;
                    }
                } else if (arg == "-i" || arg == "--project-id") {
                    if (i + 1 < args.length) {
                        task_args.project_id = args[++i];
                    } else {
                        stderr.printf ("Error: %s requires an argument\n", arg);
                        exit_code = 1;
                        return null;
                    }
                } else if (arg == "-a" || arg == "--parent-id") {
                    if (i + 1 < args.length) {
                        task_args.parent_id = args[++i];
                    } else {
                        stderr.printf ("Error: %s requires an argument\n", arg);
                        exit_code = 1;
                        return null;
                    }
                } else if (arg == "-P" || arg == "--priority") {
                    if (i + 1 < args.length) {
                        task_args.priority = int.parse (args[++i]);
                    } else {
                        stderr.printf ("Error: %s requires an argument\n", arg);
                        exit_code = 1;
                        return null;
                    }
                } else if (arg == "-D" || arg == "--due") {
                    if (i + 1 < args.length) {
                        task_args.due_date = args[++i];
                    } else {
                        stderr.printf ("Error: %s requires an argument\n", arg);
                        exit_code = 1;
                        return null;
                    }
                } else if (arg == "-l" || arg == "--labels") {
                    if (i + 1 < args.length) {
                        task_args.labels = args[++i];
                    } else {
                        stderr.printf ("Error: %s requires an argument\n", arg);
                        exit_code = 1;
                        return null;
                    }
                } else if (arg == "-h" || arg == "--help") {
                    print_help (args[0]);
                    exit_code = 0;
                    return null;
                } else {
                    stderr.printf ("Error: Unknown option '%s'\n", arg);
                    stderr.printf ("Run '%s add --help' for usage information\n", args[0]);
                    exit_code = 1;
                    return null;
                }
            }

                parsed.task_args = task_args;
                return parsed;
            } else {
                stderr.printf ("Error: Unknown command '%s'\n", command);
                stderr.printf ("Available commands: add, list, update, list-projects\n");
                exit_code = 1;
                return null;
            }
        }

        private static void print_help (string program_name) {
            stdout.printf ("Usage: %s <command> [OPTIONS]\n\n", program_name);
            stdout.printf ("Commands:\n");
            stdout.printf ("  add              Add a new task\n");
            stdout.printf ("  list             List tasks from a project (JSON output)\n");
            stdout.printf ("  update           Update an existing task\n");
            stdout.printf ("  list-projects    List all projects (JSON output)\n\n");
            stdout.printf ("Add command options:\n");
            stdout.printf ("  -c, --content=CONTENT      Task content (required)\n");
            stdout.printf ("  -d, --description=DESC     Task description\n");
            stdout.printf ("  -p, --project=PROJECT      Project name (defaults to inbox)\n");
            stdout.printf ("  -i, --project-id=ID        Project ID (preferred over name)\n");
            stdout.printf ("  -a, --parent-id=ID         Parent task ID (creates a subtask)\n");
            stdout.printf ("  -P, --priority=1-4         Priority: 1=high, 2=medium, 3=low, 4=none (default: 4)\n");
            stdout.printf ("  -D, --due=DATE             Due date in YYYY-MM-DD format\n");
            stdout.printf ("  -l, --labels=LABELS        Comma-separated list of label names\n");
            stdout.printf ("  -h, --help                 Show this help message\n\n");
            stdout.printf ("List command options:\n");
            stdout.printf ("  -p, --project=PROJECT      Project name (defaults to inbox)\n");
            stdout.printf ("  -i, --project-id=ID        Project ID (preferred over name)\n");
            stdout.printf ("  -h, --help                 Show this help message\n\n");
            stdout.printf ("Update command options:\n");
            stdout.printf ("  -t, --task-id=ID           Task ID to update (required)\n");
            stdout.printf ("  -c, --content=CONTENT      New task content\n");
            stdout.printf ("  -d, --description=DESC     New task description\n");
            stdout.printf ("  -p, --project=PROJECT      Move to project by name\n");
            stdout.printf ("  -i, --project-id=ID        Move to project by ID (preferred over name)\n");
            stdout.printf ("  -a, --parent-id=ID         New parent task ID\n");
            stdout.printf ("  -P, --priority=1-4         Priority: 1=high, 2=medium, 3=low, 4=none\n");
            stdout.printf ("  -D, --due=DATE             Due date in YYYY-MM-DD format\n");
            stdout.printf ("  -l, --labels=LABELS        Comma-separated list of label names\n");
            stdout.printf ("  -h, --help                 Show this help message\n");
        }

        private static void print_list_help (string program_name) {
            stdout.printf ("Usage: %s list [OPTIONS]\n\n", program_name);
            stdout.printf ("List tasks from a project (JSON output)\n\n");
            stdout.printf ("Options:\n");
            stdout.printf ("  -p, --project=PROJECT      Project name (defaults to inbox)\n");
            stdout.printf ("  -i, --project-id=ID        Project ID (preferred over name)\n");
            stdout.printf ("  -h, --help                 Show this help message\n");
        }

        private static void print_update_help (string program_name) {
            stdout.printf ("Usage: %s update [OPTIONS]\n\n", program_name);
            stdout.printf ("Update an existing task. Only provided fields will be changed.\n\n");
            stdout.printf ("Options:\n");
            stdout.printf ("  -t, --task-id=ID           Task ID to update (required)\n");
            stdout.printf ("  -c, --content=CONTENT      New task content\n");
            stdout.printf ("  -d, --description=DESC     New task description\n");
            stdout.printf ("  -p, --project=PROJECT      Move to project by name\n");
            stdout.printf ("  -i, --project-id=ID        Move to project by ID (preferred over name)\n");
            stdout.printf ("  -a, --parent-id=ID         New parent task ID\n");
            stdout.printf ("  -P, --priority=1-4         Priority: 1=high, 2=medium, 3=low, 4=none\n");
            stdout.printf ("  -D, --due=DATE             Due date in YYYY-MM-DD format\n");
            stdout.printf ("  -l, --labels=LABELS        Comma-separated list of label names\n");
            stdout.printf ("  --complete                 Mark task as complete\n");
            stdout.printf ("  --uncomplete               Mark task as incomplete\n");
            stdout.printf ("  -h, --help                 Show this help message\n");
        }
    }
}
