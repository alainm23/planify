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

namespace CalDAVUtil {
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
            return CalDAVUtil.line_break_to_space_regex.replace (str, str.length, 0, " ");
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
    public ICal.Time duedate_to_ical (Objects.Duedate duedate, string? timezone = null) {
        var result = new ICal.Time.from_day_of_year (duedate.datetime.get_day_of_year (), duedate.datetime.get_year ());

        if (!duedate.has_time ()) {
            if (timezone != null) {
                result.set_timezone (ICal.Timezone.get_builtin_timezone (timezone));
            } else {
                result.set_timezone (ECal.util_get_system_timezone ());
            }

            result.set_is_date (false);
            result.set_time (duedate.datetime.get_hour (), duedate.datetime.get_minute (), duedate.datetime.get_second ());
        } else {
            result.set_is_date (true);
            result.set_time (0, 0, 0);
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
    public Objects.Duedate ical_to_duedate (ICal.Time date) {
        int year, month, day, hour, minute, second;
        date.get_date (out year, out month, out day);
        date.get_time (out hour, out minute, out second);

        var duedate = new Objects.Duedate ();
        duedate.datetime = new DateTime (
            timezone_from_ical (date), year, month,
            day, hour, minute, second
        );

        return duedate;
    }

    public DateTime ical_to_date_time (ICal.Time date) {
        int year, month, day, hour, minute, second;
        date.get_date (out year, out month, out day);
        date.get_time (out hour, out minute, out second);
        return new DateTime (timezone_from_ical (date), year, month,
            day, hour, minute, second);
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

    public string get_esource_collection_display_name (E.Source source) {
        var task_store = Services.Tasks.Store.get_default ();
        var display_name = "";

        try {
            var registry = task_store.get_registry_sync ();
            var collection_source = registry.find_extension (source, E.SOURCE_EXTENSION_COLLECTION);

            if (collection_source != null) {
                display_name = collection_source.display_name;
            } else if (source.has_extension (E.SOURCE_EXTENSION_TASK_LIST)) {
                display_name = ((E.SourceTaskList) source.get_extension (E.SOURCE_EXTENSION_TASK_LIST)).backend_name;
            }

        } catch (Error e) {
            warning (e.message);
        }
        return display_name;
    }

    public uint esource_hash_func (E.Source source) {
        return source.hash ();
    }

    public bool esource_equal_func (E.Source a, E.Source b) {
        return a.equal (b);
    }
}
