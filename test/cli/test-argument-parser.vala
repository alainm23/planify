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

/**
 * ArgumentParser Tests
 * 
 * Tests for command-line argument parsing including:
 * - Command recognition (add, list, update, list-projects)
 * - Option parsing (short and long forms)
 * - Error handling (missing args, invalid values)
 */

namespace PlanifyCLI.Tests.ArgumentParser {
    void test_no_command () {
        print ("Testing: No command provided\n");
        int exit_code;
        string[] args = {"planify-cli"};
        
        var parsed = PlanifyCLI.ArgumentParser.parse (args, out exit_code);
        
        assert (parsed == null);
        assert (exit_code == 1);
        print ("  ✓ Returns null with exit code 1\n---\n");
    }

    void test_unknown_command () {
        print ("Testing: Unknown command\n");
        int exit_code;
        string[] args = {"planify-cli", "invalid-command"};
        
        var parsed = PlanifyCLI.ArgumentParser.parse (args, out exit_code);
        
        assert (parsed == null);
        assert (exit_code == 1);
        print ("  ✓ Returns null with exit code 1\n---\n");
    }

    void test_list_projects () {
        print ("Testing: 'list-projects' command\n");
        int exit_code;
        string[] args = {"planify-cli", "list-projects"};
        
        var parsed = PlanifyCLI.ArgumentParser.parse (args, out exit_code);
        
        assert (parsed != null);
        assert (exit_code == 0);
        assert (parsed.command_type == PlanifyCLI.CommandType.LIST_PROJECTS);
        print ("  ✓ Parses list-projects command\n---\n");
    }

    void test_add_minimal () {
        print ("Testing: 'add' command with minimal args\n");
        int exit_code;
        string[] args = {"planify-cli", "add", "-c", "Test task"};
        
        var parsed = PlanifyCLI.ArgumentParser.parse (args, out exit_code);
        
        assert (parsed != null);
        assert (exit_code == 0);
        assert (parsed.command_type == PlanifyCLI.CommandType.ADD);
        assert (parsed.task_args != null);
        assert (parsed.task_args.content == "Test task");
        print ("  ✓ Parses add command with content\n---\n");
    }

    void test_add_full () {
        print ("Testing: 'add' command with all options\n");
        int exit_code;
        string[] args = {
            "planify-cli", "add",
            "-c", "Complete task",
            "-d", "Task description",
            "-p", "Work",
            "-s", "In Progress",
            "-P", "1",
            "-D", "2024-12-31",
            "-l", "urgent,important",
            "--pin", "true"
        };
        
        var parsed = PlanifyCLI.ArgumentParser.parse (args, out exit_code);
        
        assert (parsed != null);
        assert (exit_code == 0);
        assert (parsed.command_type == PlanifyCLI.CommandType.ADD);
        assert (parsed.task_args != null);
        assert (parsed.task_args.content == "Complete task");
        assert (parsed.task_args.description == "Task description");
        assert (parsed.task_args.project_name == "Work");
        assert (parsed.task_args.section_name == "In Progress");
        assert (parsed.task_args.priority == 1);
        assert (parsed.task_args.due_date == "2024-12-31");
        assert (parsed.task_args.labels == "urgent,important");
        assert (parsed.task_args.pinned == 1);
        print ("  ✓ Parses all add options correctly\n---\n");
    }

    void test_list_with_project () {
        print ("Testing: 'list' command with project\n");
        int exit_code;
        string[] args = {"planify-cli", "list", "-p", "Work"};
        
        var parsed = PlanifyCLI.ArgumentParser.parse (args, out exit_code);
        
        assert (parsed != null);
        assert (exit_code == 0);
        assert (parsed.command_type == PlanifyCLI.CommandType.LIST);
        assert (parsed.list_args != null);
        assert (parsed.list_args.project_name == "Work");
        print ("  ✓ Parses list command with project name\n---\n");
    }

    void test_list_with_project_id () {
        print ("Testing: 'list' command with project ID\n");
        int exit_code;
        string[] args = {"planify-cli", "list", "-i", "project-123"};
        
        var parsed = PlanifyCLI.ArgumentParser.parse (args, out exit_code);
        
        assert (parsed != null);
        assert (exit_code == 0);
        assert (parsed.command_type == PlanifyCLI.CommandType.LIST);
        assert (parsed.list_args != null);
        assert (parsed.list_args.project_id == "project-123");
        print ("  ✓ Parses list command with project ID\n---\n");
    }

    void test_update_minimal () {
        print ("Testing: 'update' command with minimal args\n");
        int exit_code;
        string[] args = {"planify-cli", "update", "-t", "task-456", "-c", "Updated content"};
        
        var parsed = PlanifyCLI.ArgumentParser.parse (args, out exit_code);
        
        assert (parsed != null);
        assert (exit_code == 0);
        assert (parsed.command_type == PlanifyCLI.CommandType.UPDATE);
        assert (parsed.update_args != null);
        assert (parsed.update_args.task_id == "task-456");
        assert (parsed.update_args.content == "Updated content");
        print ("  ✓ Parses update command with task ID and content\n---\n");
    }

    void test_update_completion () {
        print ("Testing: 'update' command with completion flags\n");
        int exit_code;
        
        // Test --complete=true
        string[] args_complete = {"planify-cli", "update", "-t", "task-123", "--complete", "true"};
        var parsed = PlanifyCLI.ArgumentParser.parse (args_complete, out exit_code);
        
        assert (parsed != null);
        assert (exit_code == 0);
        assert (parsed.update_args.checked == 1);
        print ("  ✓ Parses --complete=true\n");
        
        // Test --complete=false
        string[] args_uncomplete = {"planify-cli", "update", "-t", "task-123", "--complete", "false"};
        parsed = PlanifyCLI.ArgumentParser.parse (args_uncomplete, out exit_code);
        
        assert (parsed != null);
        assert (exit_code == 0);
        assert (parsed.update_args.checked == 0);
        print ("  ✓ Parses --complete=false\n---\n");
    }

    void test_missing_required_arg () {
        print ("Testing: Missing required argument value\n");
        int exit_code;
        string[] args = {"planify-cli", "add", "-c"}; // -c without value
        
        var parsed = PlanifyCLI.ArgumentParser.parse (args, out exit_code);
        
        assert (parsed == null);
        assert (exit_code == 1);
        print ("  ✓ Returns error for missing argument value\n---\n");
    }

    void test_invalid_pin_value () {
        print ("Testing: Invalid --pin value\n");
        int exit_code;
        string[] args = {"planify-cli", "add", "-c", "Task", "--pin", "invalid"};
        
        var parsed = PlanifyCLI.ArgumentParser.parse (args, out exit_code);
        
        assert (parsed == null);
        assert (exit_code == 1);
        print ("  ✓ Returns error for invalid pin value\n---\n");
    }

    void test_invalid_complete_value () {
        print ("Testing: Invalid --complete value\n");
        int exit_code;
        string[] args = {"planify-cli", "update", "-t", "task-123", "--complete", "invalid"};
        
        var parsed = PlanifyCLI.ArgumentParser.parse (args, out exit_code);
        
        assert (parsed == null);
        assert (exit_code == 1);
        print ("  ✓ Returns error for invalid complete value\n---\n");
    }

    void test_unknown_option () {
        print ("Testing: Unknown option\n");
        int exit_code;
        string[] args = {"planify-cli", "add", "-c", "Task", "--unknown-option"};
        
        var parsed = PlanifyCLI.ArgumentParser.parse (args, out exit_code);
        
        assert (parsed == null);
        assert (exit_code == 1);
        print ("  ✓ Returns error for unknown option\n---\n");
    }

    public void register_tests () {
        Test.add_func ("/cli/argument_parser/no_command", test_no_command);
        Test.add_func ("/cli/argument_parser/unknown_command", test_unknown_command);
        Test.add_func ("/cli/argument_parser/list_projects", test_list_projects);
        Test.add_func ("/cli/argument_parser/add_minimal", test_add_minimal);
        Test.add_func ("/cli/argument_parser/add_full", test_add_full);
        Test.add_func ("/cli/argument_parser/list_with_project", test_list_with_project);
        Test.add_func ("/cli/argument_parser/list_with_project_id", test_list_with_project_id);
        Test.add_func ("/cli/argument_parser/update_minimal", test_update_minimal);
        Test.add_func ("/cli/argument_parser/update_completion", test_update_completion);
        Test.add_func ("/cli/argument_parser/missing_required_arg", test_missing_required_arg);
        Test.add_func ("/cli/argument_parser/invalid_pin_value", test_invalid_pin_value);
        Test.add_func ("/cli/argument_parser/invalid_complete_value", test_invalid_complete_value);
        Test.add_func ("/cli/argument_parser/unknown_option", test_unknown_option);
    }
}