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
 * TaskValidator Tests
 * 
 * Tests for input validation logic including:
 * - Content validation (required field)
 * - Priority validation (1-4 range)
 * - Date format validation (YYYY-MM-DD)
 */

namespace PlanifyCLI.Tests.TaskValidator {
    void test_content_required () {
        print ("Testing: Content validation - null\n");
        string? error_message;
        
        bool result = PlanifyCLI.TaskValidator.validate_content (null, out error_message);
        
        assert (result == false);
        assert (error_message != null);
        print ("  ✓ Rejects null content\n---\n");
    }

    void test_content_empty () {
        print ("Testing: Content validation - empty string\n");
        string? error_message;
        
        bool result = PlanifyCLI.TaskValidator.validate_content ("   ", out error_message);
        
        assert (result == false);
        assert (error_message != null);
        print ("  ✓ Rejects empty/whitespace content\n---\n");
    }

    void test_content_valid () {
        print ("Testing: Content validation - valid\n");
        string? error_message;
        
        bool result = PlanifyCLI.TaskValidator.validate_content ("Valid task content", out error_message);
        
        assert (result == true);
        assert (error_message == null);
        print ("  ✓ Accepts valid content\n---\n");
    }

    void test_priority_range () {
        print ("Testing: Priority validation - range checks\n");
        string? error_message;
        
        // Test invalid priorities
        assert (PlanifyCLI.TaskValidator.validate_priority (0, out error_message) == false);
        print ("  ✓ Rejects priority 0\n");
        
        assert (PlanifyCLI.TaskValidator.validate_priority (5, out error_message) == false);
        print ("  ✓ Rejects priority 5\n");
        
        assert (PlanifyCLI.TaskValidator.validate_priority (-1, out error_message) == false);
        print ("  ✓ Rejects priority -1\n");
        
        // Test valid priorities
        assert (PlanifyCLI.TaskValidator.validate_priority (1, out error_message) == true);
        assert (PlanifyCLI.TaskValidator.validate_priority (2, out error_message) == true);
        assert (PlanifyCLI.TaskValidator.validate_priority (3, out error_message) == true);
        assert (PlanifyCLI.TaskValidator.validate_priority (4, out error_message) == true);
        print ("  ✓ Accepts priorities 1-4\n---\n");
    }

    void test_date_format_valid () {
        print ("Testing: Date validation - valid formats\n");
        string? error_message;
        GLib.DateTime? datetime;
        
        bool result = PlanifyCLI.TaskValidator.validate_and_parse_date ("2024-12-31", out datetime, out error_message);
        
        assert (result == true);
        assert (datetime != null);
        assert (datetime.get_year () == 2024);
        assert (datetime.get_month () == 12);
        assert (datetime.get_day_of_month () == 31);
        assert (error_message == null);
        print ("  ✓ Parses valid YYYY-MM-DD format\n---\n");
    }

    void test_date_format_invalid () {
        print ("Testing: Date validation - invalid formats\n");
        string? error_message;
        GLib.DateTime? datetime;
        
        // Invalid format
        bool result = PlanifyCLI.TaskValidator.validate_and_parse_date ("12/31/2024", out datetime, out error_message);
        assert (result == false);
        assert (error_message != null);
        print ("  ✓ Rejects invalid date format\n");
        
        // Invalid values
        result = PlanifyCLI.TaskValidator.validate_and_parse_date ("2024-13-01", out datetime, out error_message);
        assert (result == false);
        print ("  ✓ Rejects invalid month\n");
        
        result = PlanifyCLI.TaskValidator.validate_and_parse_date ("2024-01-32", out datetime, out error_message);
        assert (result == false);
        print ("  ✓ Rejects invalid day\n---\n");
    }

    void test_date_null_or_empty () {
        print ("Testing: Date validation - null/empty (optional)\n");
        string? error_message;
        GLib.DateTime? datetime;
        
        // Null is valid (optional field)
        bool result = PlanifyCLI.TaskValidator.validate_and_parse_date (null, out datetime, out error_message);
        assert (result == true);
        assert (datetime == null);
        print ("  ✓ Accepts null date (optional)\n");
        
        // Empty string is valid (optional field)
        result = PlanifyCLI.TaskValidator.validate_and_parse_date ("", out datetime, out error_message);
        assert (result == true);
        assert (datetime == null);
        print ("  ✓ Accepts empty date (optional)\n---\n");
    }

    void test_date_with_time () {
        print ("Testing: Date validation - full ISO timestamps with time components\n");
        string? error_message;
        GLib.DateTime? datetime;
        
        // Test parsing a full ISO 8601 string containing hours and minutes
        bool result = PlanifyCLI.TaskValidator.validate_and_parse_date ("2026-07-24T14:30:45", out datetime, out error_message);
        
        assert (result == true);
        assert (datetime != null);
        assert (datetime.get_year () == 2026);
        assert (datetime.get_month () == 7);
        assert (datetime.get_day_of_month () == 24);
        
        // CRITICAL EXTRA ASSERTIONS: Verify that hours and minutes survive!
        assert (datetime.get_hour () == 14);
        assert (datetime.get_minute () == 30);
        assert (datetime.get_second () == 45);
        assert (error_message == null);
        print ("  ✓ Correctly preserves time components (14:30:45)\n---\n");
    }

    void test_date_without_timezone () {
        print ("Testing: Input Case (i) - Naive timestamp with no timezone metadata\n");
        string? error_message;
        GLib.DateTime? datetime;
        
        // Act: Parse an ISO 8601 string completely lacking an explicit offset
        bool result = PlanifyCLI.TaskValidator.validate_and_parse_date ("2026-07-24T14:30:45", out datetime, out error_message);
        
        // Assert: Ensure it parses cleanly and falls back to an inoffensive system context
        assert (result == true);
        assert (datetime != null);
        assert (error_message == null);
        assert (datetime.get_hour () == 14);
        assert (datetime.get_minute () == 30);
        assert (datetime.get_second () == 45);
        
        print ("  ✓ Naive default input verified cleanly\n---\n");
    }

    void test_date_with_timezone () {
        print ("Testing: Input Case (ii) - Timestamp with explicit timezone offset (-06:00)\n");
        string? error_message;
        GLib.DateTime? datetime;

        // 1. Act: Pass an explicit timezone offset (-06:00) into the validation parser
        bool result = PlanifyCLI.TaskValidator.validate_and_parse_date ("2026-07-24T14:30:45-06:00", out datetime, out error_message);

        // 2. Base Asserts: Confirm structural parsing succeeded
        assert (result == true);
        assert (datetime != null);
        assert (error_message == null);

        /* ======================================================================
        * EXPLICIT TIMEZONE OFFSET & INSTANT ASSERTION
        * ----------------------------------------------------------------------
        * 2026-07-24T14:30:45-06:00 corresponds exactly to 2026-07-24T20:30:45 UTC.
        * We assert against the Unix timestamp to verify absolute data integrity.
        * ====================================================================== */
        var expected_utc = new GLib.DateTime.utc (2026, 7, 24, 20, 30, 45);
        assert (datetime.to_unix () == expected_utc.to_unix ());

        print ("  ✓ Explicit timezone offset (-06:00) verified directly on the parsed object\n---\n");
    }

    public void register_tests () {
        Test.add_func ("/cli/task_validator/content_required", test_content_required);
        Test.add_func ("/cli/task_validator/content_empty", test_content_empty);
        Test.add_func ("/cli/task_validator/content_valid", test_content_valid);
        Test.add_func ("/cli/task_validator/priority_range", test_priority_range);
        Test.add_func ("/cli/task_validator/date_format_valid", test_date_format_valid);
        Test.add_func ("/cli/task_validator/date_format_invalid", test_date_format_invalid);
        Test.add_func ("/cli/task_validator/date_null_or_empty", test_date_null_or_empty);
        Test.add_func ("/cli/task_validator/date_with_time", test_date_with_time);
        Test.add_func ("/cli/task_validator/date_with_timezone", test_date_with_timezone);
        Test.add_func ("/cli/task_validator/date_without_timezone", test_date_without_timezone);
    }
}
