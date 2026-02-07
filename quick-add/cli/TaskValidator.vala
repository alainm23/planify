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
    public class TaskValidator : Object {
        public static bool validate_content (string? content, out string? error_message) {
            error_message = null;
            
            if (content == null || content.strip () == "") {
                error_message = "Error: --content is required";
                return false;
            }
            
            return true;
        }

        public static bool validate_priority (int priority, out string? error_message) {
            error_message = null;
            
            if (priority < 1 || priority > 4) {
                error_message = "Error: --priority must be between 1 and 4";
                return false;
            }
            
            return true;
        }

        public static bool validate_and_parse_date (string? due_date, out GLib.DateTime? datetime, out string? error_message) {
            datetime = null;
            error_message = null;

            if (due_date == null || due_date.strip () == "") {
                return true; // No date provided is valid
            }

            // Parse YYYY-MM-DD format
            string[] parts = due_date.strip ().split ("-");
            if (parts.length != 3) {
                error_message = "Error: Invalid date format. Use YYYY-MM-DD";
                return false;
            }

            int year = int.parse (parts[0]);
            int month = int.parse (parts[1]);
            int day = int.parse (parts[2]);

            if (year < 1900 || year > 3000 || month < 1 || month > 12 || day < 1 || day > 31) {
                error_message = "Error: Invalid date values";
                return false;
            }

            datetime = new GLib.DateTime.local (year, month, day, 0, 0, 0);
            return true;
        }
    }
}