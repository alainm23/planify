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
            target_project
        );

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
            case CommandType.ADD:
                return add_task (parsed.task_args);
            default:
                stderr.printf ("Error: Unknown command\n");
                return 1;
        }
    }
}
