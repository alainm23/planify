/*
* Copyright 2019 elementary, Inc. (https://elementary.io)
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
*/

namespace Tasks.Util {
    /**
    * Replaces all line breaks with a space and
    * replaces multiple spaces with a single one.
    */
    private GLib.Regex line_break_to_space_regex = null;

    public string line_break_to_space (string str) {
        if (line_break_to_space_regex == null) {
            try {
                line_break_to_space_regex = new GLib.Regex ("(^\\s+|\\s+$|\n|\\s\\s+)");
            } catch (GLib.RegexError e) {
                critical (e.message);
            }
        }

        try {
            return Tasks.Util.line_break_to_space_regex.replace (str, str.length, 0, " ");
        } catch (GLib.RegexError e) {
            warning (e.message);
        }

        return str;
    }

    /*
    * Gee Utility Functions
    */

    /* Returns true if 'a' and 'b' are the same ECal.Component */
    private bool calcomponent_equal_func (ECal.Component a, ECal.Component b) {
        return a.get_id ().equal (b.get_id ());
    }


    //--- Date and Time ---//


    /**
    * Converts two datetimes to one TimeType. The first contains the date,
    * its time settings are ignored. The second one contains the time itself.
    */
    public ICal.Time date_time_to_ical (DateTime date, DateTime? time_local, string? timezone = null) {
    #if E_CAL_2_0
        var result = new ICal.Time.from_day_of_year (date.get_day_of_year (), date.get_year ());
    #else
        var result = ICal.Time.from_day_of_year (date.get_day_of_year (), date.get_year ());
    #endif
        if (time_local != null) {
            if (timezone != null) {
    #if E_CAL_2_0
                result.set_timezone (ICal.Timezone.get_builtin_timezone (timezone));
    #else
                result.zone = ICal.Timezone.get_builtin_timezone (timezone);
    #endif
            } else {
    #if E_CAL_2_0
                result.set_timezone (ECal.util_get_system_timezone ());
    #else
                result.zone = ECal.Util.get_system_timezone ();
    #endif
            }

    #if E_CAL_2_0
            result.set_is_date (false);
            result.set_time (time_local.get_hour (), time_local.get_minute (), time_local.get_second ());
    #else
            result._is_date = 0;
            result.hour = time_local.get_hour ();
            result.minute = time_local.get_minute ();
            result.second = time_local.get_second ();
    #endif
        } else {
    #if E_CAL_2_0
            result.set_is_date (true);
            result.set_time (0, 0, 0);
    #else
            result._is_date = 1;
            result.hour = 0;
            result.minute = 0;
            result.second = 0;
    #endif
        }

        return result;
    }

    /**
    * Converts the given TimeType to a DateTime.
    */
    private TimeZone timezone_from_ical (ICal.Time date) {
        int is_daylight;
        var interval = date.get_timezone ().get_utc_offset (null, out is_daylight);
        bool is_positive = interval >= 0;
        interval = interval.abs ();
        var hours = (interval / 3600);
        var minutes = (interval % 3600) / 60;
        var hour_string = "%s%02d:%02d".printf (is_positive ? "+" : "-", hours, minutes);

        return new TimeZone (hour_string);
    }

    /**
    * Converts the given TimeType to a DateTime.
    * XXX : Track next versions of evolution in order to convert ICal.Timezone to GLib.TimeZone with a dedicated function…
    */
    public DateTime ical_to_date_time (ICal.Time date) {
    #if E_CAL_2_0
        int year, month, day, hour, minute, second;
        date.get_date (out year, out month, out day);
        date.get_time (out hour, out minute, out second);
        return new DateTime (timezone_from_ical (date), year, month,
            day, hour, minute, second);
    #else
        return new DateTime (timezone_from_ical (date), date.year, date.month,
            date.day, date.hour, date.minute, date.second);
    #endif
    }

    /**
    * Compares a {@link GLib.DateTime} to {@link GLib.DateTime.now_local} and returns a location, relative date string.
    * Results appear as natural-language strings like "Today", "Yesterday", "Fri, Apr 17", "Jan 15", "Sep 18 2019".
    *Util
    * @param date_time a {@link GLib.DateTime} to compare against {@link GLib.DateTime.now_local}
    *
    * @return a localized, relative date string
    */
    public static string get_relative_date (GLib.DateTime date_time) {
        var now = new GLib.DateTime.now_local ();
        var diff = now.difference (date_time);

        if (Granite.DateTime.is_same_day (date_time, now)) {
            return _("Today");
        } else if (Granite.DateTime.is_same_day (date_time.add_days (1), now)) {
            return _("Yesterday");
        } else if (Granite.DateTime.is_same_day (date_time.add_days (-1), now)) {
            return _("Tomorrow");
        } else if (diff < 6 * TimeSpan.DAY && diff > -6 * TimeSpan.DAY) {
            return date_time.format (Granite.DateTime.get_default_date_format (true, true, false));
        } else if (date_time.get_year () == now.get_year ()) {
            return date_time.format (Granite.DateTime.get_default_date_format (false, true, false));
        } else {
            return date_time.format (Granite.DateTime.get_default_date_format (false, true, true));
        }
    }
}
