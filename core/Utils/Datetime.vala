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
    public static GLib.DateTime ? get_todoist_datetime (string? date) {
        if (date == "" || date == null) {
            return null;
        }

        GLib.DateTime datetime = null;

        // YYYY-MM-DD
        if (date.length == 10) {
            var _date = date.split ("-");

            datetime = new GLib.DateTime.local (
                int.parse (_date[0]),
                int.parse (_date[1]),
                int.parse (_date[2]),
                0,
                0,
                0
            );
            // YYYY-MM-DDTHH:MM:SS
        } else {
            var _date = date.split ("T")[0].split ("-");
            var _time = date.split ("T")[1].split (":");

            datetime = new GLib.DateTime.local (
                int.parse (_date[0]),
                int.parse (_date[1]),
                int.parse (_date[2]),
                int.parse (_time[0]),
                int.parse (_time[1]),
                int.parse (_time[2])
            );
        }

        return datetime;
    }

    public static string get_relative_date_from_date (GLib.DateTime ? datetime) {
        if (datetime == null) {
            return "";
        }

        string returned = "";

        if (is_today (datetime)) {
            returned = _("Today");
        } else if (is_tomorrow (datetime)) {
            returned = _("Tomorrow");
        } else if (is_yesterday (datetime)) {
            returned = _("Yesterday");
        } else {
            returned = get_default_date_format_from_date (datetime);
        }

        if (has_time (datetime)) {
            returned = "%s %s".printf (returned, datetime.format (get_default_time_format ()));
        }

        return returned;
    }
    
    public static string days_left (GLib.DateTime datetime, bool show_today = false) {
        string return_value = "";
        var days = datetime.difference (new GLib.DateTime.now_local ()) / TimeSpan.DAY;

        if (is_today (datetime)) {
            return_value = show_today ? _("Today") : "";
        } else if (is_overdue (datetime)) {
            return_value = _("%s %s ago".printf ((days * -1).to_string (), days > 1 ? _("days") : _("day")));
        } else {
            return_value = _("%s %s left".printf ((days + 1).to_string (), days > 1 ? _("days") : _("day")));
        }

        return return_value;
    }

    public static string get_default_time_format (bool is_12h = is_clock_format_12h (), bool with_second = false) {
        if (is_12h == true) {
            if (with_second == true) {
                /// TRANSLATORS: a GLib.DateTime format showing the hour (12h format) with seconds
                return _("%-l:%M:%S %p");
            } else {
                /// TRANSLATORS: a GLib.DateTime format showing the hour (12h format)
                return _("%-l:%M %p");
            }
        } else {
            if (with_second == true) {
                /// TRANSLATORS: a GLib.DateTime format showing the hour (24h format) with seconds
                return _("%H:%M:%S");
            } else {
                /// TRANSLATORS: a GLib.DateTime format showing the hour (24h format)
                return _("%H:%M");
            }
        }
    }

    public static bool is_clock_format_12h () {
        return Services.Settings.get_default ().settings.get_string ("clock-format").contains ("12h");
    }

    public static bool is_yesterday (GLib.DateTime date) {
        return is_same_day (date, new GLib.DateTime.now_local ().add_days (-1));
    }

    public static bool is_same_day (GLib.DateTime day1, GLib.DateTime day2) {
        return day1.get_day_of_year () == day2.get_day_of_year () && day1.get_year () == day2.get_year ();
    }

    public static bool is_overdue (GLib.DateTime date) {
        if (get_date_only (date).compare (get_date_only (new DateTime.now_local ())) == -1) {
            return true;
        }

        return false;
    }

    public static string get_calendar_icon (GLib.DateTime date) {
        if (is_today (date)) {
            return "planner-today";
        } else {
            return "planner-scheduled";
        }
    }

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

        return is_same_day (date, new GLib.DateTime.now_local ());
    }

    public static bool is_tomorrow (GLib.DateTime date) {
        if (date == null) {
            return false;
        }

        return is_same_day (date, new GLib.DateTime.now_local ().add_days (1));
    }

    public static bool is_next_week (GLib.DateTime date) {
        if (date == null) {
            return false;
        }

        return is_same_day (date, new GLib.DateTime.now_local ().add_days (7));
    }

    public static GLib.DateTime get_date_from_string (string date) {
        return new GLib.DateTime.from_iso8601 (date, new GLib.TimeZone.local ());
    }

    public static void recurrence_to_due (ICal.Recurrence recurrence, Objects.DueDate due) {
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
            due.recurrency_end = ical_to_date_time_local (until).to_string ();
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

    public static GLib.DateTime format_date (GLib.DateTime date) {
        return new DateTime.local (
            date.get_year (),
            date.get_month (),
            date.get_day_of_month (),
            0,
            0,
            0
        );
    }

    public static bool is_this_week (GLib.DateTime date) {
        var current_date = new GLib.DateTime.now_local ();

        var start_of_week = current_date.add_days ((current_date.get_day_of_week () - 1) * -1);
        var end_of_week = current_date.add_days (6);

        if (date.compare (format_date (start_of_week)) >= 0 &&
            date.compare (format_date (end_of_week)) <= 0) {
            return true;
        }

        return false;
    }

    public static bool is_next_x_week (GLib.DateTime date, int days) {
        var current_date = new GLib.DateTime.now_local ();
        var end_date = current_date.add_days (days);

        if (date.compare (format_date (current_date)) >= 0 &&
            date.compare (format_date (end_date)) <= 0) {
            return true;
        }

        return false;
    }

    public static bool is_this_month (GLib.DateTime date) {
        var current_date = new GLib.DateTime.now_local ();
        return current_date.get_month () == date.get_month () && current_date.get_year () == date.get_year ();
    }

    public static GLib.DateTime next_recurrency (GLib.DateTime datetime, Objects.DueDate duedate) {
        GLib.DateTime returned = datetime;

        if (duedate.recurrency_type == RecurrencyType.MINUTELY) {
            returned = returned.add_minutes (duedate.recurrency_interval);
        } else if (duedate.recurrency_type == RecurrencyType.HOURLY) {
            returned = returned.add_hours (duedate.recurrency_interval);
        } else if (duedate.recurrency_type == RecurrencyType.EVERY_DAY) {
            returned = returned.add_days (duedate.recurrency_interval);
        } else if (duedate.recurrency_type == RecurrencyType.EVERY_WEEK) {
            if (duedate.recurrency_weeks == "") {
                returned = returned.add_days (duedate.recurrency_interval * 7);
            } else {
                returned = next_recurrency_week (datetime, duedate, true);
            }
        } else if (duedate.recurrency_type == RecurrencyType.EVERY_MONTH) {
            returned = returned.add_months (duedate.recurrency_interval);
        } else if (duedate.recurrency_type == RecurrencyType.EVERY_YEAR) {
            returned = returned.add_years (duedate.recurrency_interval);
        }

        return returned;
    }

    public static int get_next_day_of_week_from_recurrency_week (GLib.DateTime datetime, Objects.DueDate duedate) {
        string[] weeks = duedate.recurrency_weeks.split (",");
        int day_of_week = datetime.get_day_of_week ();
        int index = 0;

        for (int i = 0; i < weeks.length; i++) {
            if (day_of_week <= int.parse (weeks[i])) {
                index = i;
                break;
            }
        }

        if (index > weeks.length - 1) {
            index = 0;
        }

        return int.parse (weeks[index]);
    }

    public static GLib.DateTime next_recurrency_week (GLib.DateTime datetime, Objects.DueDate duedate, bool user = false) {
        string[] weeks = duedate.recurrency_weeks.split (","); // [1, 2, 3]
        int day_of_week = datetime.get_day_of_week (); // 2
        int days = 0;
        int next_day = 0;
        int index = 0;
        int recurrency_interval = 0;

        for (int i = 0; i < weeks.length; i++) {
            if (day_of_week < int.parse (weeks[i])) {
                index = i;
                break;
            }
        }

        next_day = int.parse (weeks[index]);

        if (day_of_week < next_day) {
            days = next_day - day_of_week;
        } else {
            days = 7 - (day_of_week - next_day);
        }

        if (user && index == 0) {
            recurrency_interval = (duedate.recurrency_interval - 1) * 7;
        }

        return datetime.add_days (days).add_days (recurrency_interval);
    }

    public static string get_recurrency_weeks (RecurrencyType recurrency_type, int recurrency_interval,
                                               string recurrency_weeks, string end = "") {
        string returned = recurrency_type.to_friendly_string (recurrency_interval);

        if (recurrency_type == RecurrencyType.EVERY_WEEK &&
            recurrency_weeks.split (",").length > 0) {
            string weeks = "";
            if (recurrency_weeks.contains ("1")) {
                weeks += _("Mo,");
            }

            if (recurrency_weeks.contains ("2")) {
                weeks += _("Tu,");
            }

            if (recurrency_weeks.contains ("3")) {
                weeks += _("We,");
            }

            if (recurrency_weeks.contains ("4")) {
                weeks += _("Th,");
            }

            if (recurrency_weeks.contains ("5")) {
                weeks += _("Fr,");
            }

            if (recurrency_weeks.contains ("6")) {
                weeks += _("Sa,");
            }

            if (recurrency_weeks.contains ("7")) {
                weeks += _("Su,");
            }

            weeks = weeks.slice (0, -1);
            returned = "%s (%s)".printf (returned, weeks);
        }

        return returned + " " + end;
    }

    public static GLib.DateTime get_today_format_date () {
        return get_date_only (new DateTime.now_local ());
    }

    public static GLib.DateTime get_date_only (GLib.DateTime date) {
        return new DateTime.local (
            date.get_year (),
            date.get_month (),
            date.get_day_of_month (),
            0,
            0,
            0
        );
    }

    public static string get_default_date_format_from_date (GLib.DateTime ? date) {
        if (date == null) {
            return "";
        }

        var format = date.format (get_default_date_format (
                                      false,
                                      true,
                                      date.get_year () != new GLib.DateTime.now_local ().get_year ()
        ));
        return format;
    }

    public static string get_todoist_datetime_format (GLib.DateTime date) {
        string returned = "";

        if (has_time (date)) {
            returned = date.format ("%F") + "T" + date.format ("%T");
        } else {
            returned = date.format ("%F");
        }

        return returned;
    }

    public static bool has_time_from_string (string date) {
        return has_time (new GLib.DateTime.from_iso8601 (date, new GLib.TimeZone.local ()));
    }

    public static int get_days_of_month (int index, int year_nav) {
        if ((index == 1) || (index == 3) || (index == 5) || (index == 7) || (index == 8) || (index == 10) || (index == 12)) { // vala-lint=line-length
            return 31;
        } else {
            if (index == 2) {
                if (year_nav % 4 == 0) {
                    return 29;
                } else {
                    return 28;
                }
            } else {
                return 30;
            }
        }
    }

    public static GLib.DateTime get_start_of_month (owned GLib.DateTime ? date = null) {
        if (date == null) {
            date = new GLib.DateTime.now_local ();
        }

        return new GLib.DateTime.local (date.get_year (), date.get_month (), 1, 0, 0, 0);
    }

    public static bool is_current_month (GLib.DateTime date) {
        var now = new GLib.DateTime.now_local ();

        if (date.get_year () == now.get_year ()) {
            if (date.get_month () == now.get_month ()) {
                return true;
            } else {
                return false;
            }
        } else {
            return false;
        }
    }

    /**
     * Converts the given ICal.Time to a GLib.DateTime, represented in the
     * system timezone.
     *
     * All timezone information in the original @date is lost. However, the
     * {@link GLib.TimeZone} contained in the resulting DateTime is correct,
     * since there is a well-defined local timezone between both libical and
     * GLib.
     */

    public static DateTime ical_to_date_time_local (ICal.Time date) {
        assert (!date.is_null_time ());
        var converted = ical_convert_to_local (date);
        int year, month, day, hour, minute, second;
        converted.get_date (out year, out month, out day);
        converted.get_time (out hour, out minute, out second);
        return new DateTime.local (year, month,
                                   day, hour, minute, second);
    }

    /** Converts the given ICal.Time to the local (or system) timezone */
    public static ICal.Time ical_convert_to_local (ICal.Time time) {
        var system_tz = get_system_timezone ();
        return time.convert_to_zone (system_tz);
    }

    /**
     * Converts two DateTimes representing a date and a time to one TimeType.
     *
     * The first contains the date; its time settings are ignored. The second
     * one contains the time itself; its date settings are ignored. If the time
     * is `null`, the resulting TimeType is of `DATE` type; if it is given, the
     * TimeType is of `DATE-TIME` type.
     *
     * This also accepts an optional `timezone` argument. If it is given a
     * timezone, the resulting TimeType will be relative to the given timezone.
     * If it is `null`, the resulting TimeType will be "floating" with no
     * timezone. If the argument is not given, it will default to the system
     * timezone.
     */

    public static ICal.Time datetimes_to_icaltime (GLib.DateTime date, GLib.DateTime ? time_local,
                                                   ICal.Timezone ? timezone = get_system_timezone ().copy ()) {
        var result = new ICal.Time.from_day_of_year (date.get_day_of_year (), date.get_year ());

        // Check if it's a date. If so, set is_date to true and fix the time to be sure.
        // If it's not a date, first thing set is_date to false.
        // Then, set the timezone.
        // Then, set the time.
        if (time_local == null) {
            // Date type: ensure that everything corresponds to a date
            result.set_is_date (true);
            // result.set_time (0, 0, 0);
        } else {
            // Includes time
            // Set is_date first (otherwise timezone won't change)
            result.set_is_date (false);

            // Set timezone for the time to be relative to
            // (doesn't affect DATE-type times)
            result.set_timezone (timezone);

            // Set the time with the updated time zone
            result.set_time (time_local.get_hour (), time_local.get_minute (), time_local.get_second ());
        }

        return result;
    }

    public static ICal.Timezone ? get_system_timezone () {
        #if WITH_EVOLUTION
        return ECal.util_get_system_timezone ();
        #else    
        string tzid = new GLib.TimeZone.local ().get_identifier ();
        return ICal.Timezone.get_builtin_timezone (tzid);
        #endif
    }


    public static string get_markdown_format_date (Objects.Item item) {
        if (!item.has_due) {
            return " ";
        }

        return " (" + get_relative_date_from_date (item.due.datetime) + ") ";
    }

    public static GLib.DateTime get_datetime_no_seconds (GLib.DateTime date, GLib.DateTime ? time = null) {
        return new DateTime.local (
            date.get_year (),
            date.get_month (),
            date.get_day_of_month (),
            time == null ? date.get_hour () : time.get_hour (),
            time == null ? date.get_minute () : time.get_minute (),
            0
        );
    }

    public static string get_default_date_format (bool with_weekday = false, bool with_day = true, bool with_year = false) {
        if (with_weekday == true && with_day == true && with_year == true) {
            /// TRANSLATORS: a GLib.DateTime format showing the weekday, date, and year
            return _("%a, %b %e, %Y");
        } else if (with_weekday == false && with_day == true && with_year == true) {
            /// TRANSLATORS: a GLib.DateTime format showing the date and year
            return _("%b %e %Y");
        } else if (with_weekday == false && with_day == false && with_year == true) {
            /// TRANSLATORS: a GLib.DateTime format showing the year
            return _("%Y");
        } else if (with_weekday == false && with_day == true && with_year == false) {
            /// TRANSLATORS: a GLib.DateTime format showing the date
            return _("%b %e");
        } else if (with_weekday == true && with_day == false && with_year == true) {
            /// TRANSLATORS: a GLib.DateTime format showing the weekday and year.
            return _("%a %Y");
        } else if (with_weekday == true && with_day == false && with_year == false) {
            /// TRANSLATORS: a GLib.DateTime format showing the weekday
            return _("%a");
        } else if (with_weekday == true && with_day == true && with_year == false) {
            /// TRANSLATORS: a GLib.DateTime format showing the weekday and date
            return _("%a, %b %e");
        } else if (with_weekday == false && with_day == false && with_year == false) {
            /// TRANSLATORS: a GLib.DateTime format showing the month.
            return _("%b");
        }

        return "";
    }
}
