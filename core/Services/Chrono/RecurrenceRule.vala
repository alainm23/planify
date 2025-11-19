/*
 * Copyright © 2025 Alain M. (https://github.com/alainm23/planify)
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
 *
 * Authored by: Alain M. <alainmh23@gmail.com>
 */
 
namespace Chrono {
    public enum RecurrenceType {
        DAILY,
        WEEKLY,
        MONTHLY,
        YEARLY
    }
    
    public class RecurrenceRule : Object {
        public RecurrenceType recurrence_type { get; set; }
        public int interval { get; set; default = 1; }
        public Gee.ArrayList<int>? days_of_week { get; set; }
        public int? day_of_month { get; set; }
        public int? month_of_year { get; set; }
        public int? hour { get; set; }
        public bool? last_day { get; set; }
        
        public RecurrenceRule (RecurrenceType recurrence_type) {
            this.recurrence_type = recurrence_type;
        }
    }
}
