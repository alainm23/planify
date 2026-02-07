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
        public static void print_task_result (Objects.Item item, Objects.Project project) {
            stdout.printf ("{\n");
            stdout.printf ("  \"taskId\": \"%s\",\n", item.id);
            stdout.printf ("  \"projectId\": \"%s\",\n", project.id);
            stdout.printf ("  \"projectName\": \"%s\"\n", project.name);
            stdout.printf ("}\n");
        }
    }
}