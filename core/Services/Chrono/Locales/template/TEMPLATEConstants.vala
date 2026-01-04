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
    /**
     * Constants for [LANGUAGE_NAME] language support
     * 
     * TODO: Replace with actual translations for your language
     */
    public class TEMPLATEConstants : Object {
        private static Gee.HashMap<string, int>? _month_names = null;
        private static Gee.HashMap<string, TimeUnit>? _time_units = null;
        
        private static Gee.HashMap<string, int> get_month_names () {
            if (_month_names == null) {
                _month_names = new Gee.HashMap<string, int> ();
                
                // TODO: Add full month names in your language
                _month_names["month1"] = 1;  // January
                _month_names["month2"] = 2;  // February
                _month_names["month3"] = 3;  // March
                _month_names["month4"] = 4;  // April
                _month_names["month5"] = 5;  // May
                _month_names["month6"] = 6;  // June
                _month_names["month7"] = 7;  // July
                _month_names["month8"] = 8;  // August
                _month_names["month9"] = 9;  // September
                _month_names["month10"] = 10; // October
                _month_names["month11"] = 11; // November
                _month_names["month12"] = 12; // December
                
                // TODO: Add month abbreviations in your language
                _month_names["m1"] = 1;   // Jan
                _month_names["m2"] = 2;   // Feb
                _month_names["m3"] = 3;   // Mar
                // ... continue for all months
            }
            return _month_names;
        }
        
        public static int? get_month (string name) {
            string key = name.down ();
            var months = get_month_names ();
            if (months.has_key (key)) {
                return months[key];
            }
            return null;
        }
        
        private static Gee.HashMap<string, TimeUnit> get_time_units () {
            if (_time_units == null) {
                _time_units = new Gee.HashMap<string, TimeUnit> ();
                
                // TODO: Add time unit names in your language
                _time_units["second"] = TimeUnit.SECOND;
                _time_units["seconds"] = TimeUnit.SECOND;
                _time_units["minute"] = TimeUnit.MINUTE;
                _time_units["minutes"] = TimeUnit.MINUTE;
                _time_units["hour"] = TimeUnit.HOUR;
                _time_units["hours"] = TimeUnit.HOUR;
                _time_units["day"] = TimeUnit.DAY;
                _time_units["days"] = TimeUnit.DAY;
                _time_units["week"] = TimeUnit.WEEK;
                _time_units["weeks"] = TimeUnit.WEEK;
                _time_units["month"] = TimeUnit.MONTH;
                _time_units["months"] = TimeUnit.MONTH;
                _time_units["quarter"] = TimeUnit.QUARTER;
                _time_units["quarters"] = TimeUnit.QUARTER;
                _time_units["year"] = TimeUnit.YEAR;
                _time_units["years"] = TimeUnit.YEAR;
                
                // TODO: Add abbreviations in your language
                _time_units["s"] = TimeUnit.SECOND;
                _time_units["m"] = TimeUnit.MINUTE;
                _time_units["h"] = TimeUnit.HOUR;
                _time_units["d"] = TimeUnit.DAY;
                _time_units["w"] = TimeUnit.WEEK;
                _time_units["mo"] = TimeUnit.MONTH;
                _time_units["y"] = TimeUnit.YEAR;
            }
            return _time_units;
        }
        
        public static TimeUnit? get_time_unit (string name) {
            string key = name.down ();
            var units = get_time_units ();
            if (units.has_key (key)) {
                return units[key];
            }
            return null;
        }
    }
}