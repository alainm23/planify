/*
* Copyright © 2023 Alain M. (https://github.com/alainm23/planify)
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

public class Utils.Datetime {
    public static void parse_todoist_recurrency (Objects.DueDate duedate, Json.Object object) {
        if (object.has_member ("lang") && object.get_string_member ("lang") != "en") {
            duedate.recurrence_supported = false;
            return;
        }
    }

    public static bool has_time (GLib.DateTime datetime) {
        if (datetime == null) {
            return false;
        }

        bool returned = true;
        
        if (datetime.get_hour () == 0 && datetime.get_minute () == 0 && datetime.get_second () == 0) {
            returned = false;
        }

        return returned;
    }

    public static bool is_today (GLib.DateTime date) {
        if (date == null) {
            return false;
        }

        return Granite.DateTime.is_same_day (date, new GLib.DateTime.now_local ());
    }

    public static bool is_tomorrow (GLib.DateTime date) {
        if (date == null) {
            return false;
        }

        return Granite.DateTime.is_same_day (date, new GLib.DateTime.now_local ().add_days (1));
    }

    public static bool is_next_week (GLib.DateTime date) {
        if (date == null) {
            return false;
        }
        
        return Granite.DateTime.is_same_day (date, new GLib.DateTime.now_local ().add_days (7));
    }

    public static GLib.DateTime get_date_from_string (string date) {
        return new GLib.DateTime.from_iso8601 (date, new GLib.TimeZone.local ());
    }
}
