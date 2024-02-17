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

    public static void recurrence_to_due (string rrules, Objects.DueDate due) {
        ICal.Recurrence recurrence = new ICal.Recurrence.from_string (rrules);
        
        due.is_recurring = true;

        ICal.RecurrenceFrequency freq = recurrence.get_freq ();
        if (freq == ICal.RecurrenceFrequency.MINUTELY_RECURRENCE) {
            due.recurrency_type = RecurrencyType.MINUTELY;
        } else if (freq == ICal.RecurrenceFrequency.HOURLY_RECURRENCE) {
            due.recurrency_type = RecurrencyType.HOURLY;
        } else if (freq == ICal.RecurrenceFrequency.DAILY_RECURRENCE) {
            due.recurrency_type = RecurrencyType.EVERY_DAY;
        } else if (freq == ICal.RecurrenceFrequency.WEEKLY_RECURRENCE) {
            due.recurrency_type = RecurrencyType.EVERY_WEEK;
        } else if (freq == ICal.RecurrenceFrequency.MONTHLY_RECURRENCE) {
            due.recurrency_type = RecurrencyType.EVERY_MONTH;
        } else if (freq == ICal.RecurrenceFrequency.YEARLY_RECURRENCE) {
            due.recurrency_type = RecurrencyType.EVERY_YEAR;
        }

        short interval = recurrence.get_interval ();
        due.recurrency_interval = (int) interval;

        int count = recurrence.get_count ();
        due.recurrency_count = count;

        ICal.Time until = recurrence.get_until ();
        if (!until.is_null_time ()) {
            due.recurrency_end = Util.ical_to_date_time_local (until).to_string ();
        }
        
        if (due.recurrency_type == RecurrencyType.EVERY_WEEK) {
            string recurrency_weeks = "";
            GLib.Array<short> day_array = recurrence.get_by_day_array ();

            if (check_by_day ("1", day_array)) {
                recurrency_weeks += "7,";
            }
    
            if (check_by_day ("2", day_array)) {
                recurrency_weeks += "1,";
            }
    
    
            if (check_by_day ("3", day_array)) {
                recurrency_weeks += "2,";
            }
    
    
            if (check_by_day ("4", day_array)) {
                recurrency_weeks += "3,";
            }
    
    
            if (check_by_day ("5", day_array)) {
                recurrency_weeks += "4,";
            }
    
    
            if (check_by_day ("6", day_array)) {
                recurrency_weeks += "5,";
            }
    
    
            if (check_by_day ("7", day_array)) {
                recurrency_weeks += "6,";
            }
    
            if (recurrency_weeks.split (",").length > 0) {
                recurrency_weeks.slice (0, -1);
            }

            due.recurrency_weeks = recurrency_weeks;
        }
    }

    private static bool check_by_day (string day, GLib.Array<short> day_array) {
        foreach (var _day in day_array) {
            if (_day.to_string () == day) {
                return true;
            }
        }

        return false;
    }
}
