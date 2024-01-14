/*
* Copyright © 2024 Alain M. (https://github.com/alainm23/planify)
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

public class Services.VTodo : GLib.Object {
    public static Objects.Item to_item (Objects.Project project, GXml.DomElement element) {
        var item = new Objects.Item ();
        item.project_id = project.id;

        GXml.DomElement propstat = element.get_elements_by_tag_name ("d:propstat").get_element (0);
        GXml.DomElement prop = propstat.get_elements_by_tag_name ("d:prop").get_element (0);
        string data = prop.get_elements_by_tag_name ("cal:calendar-data").get_element (0).text_content;

        ICal.Component ical = new ICal.Component.from_string (data);
        ECal.Component ecal = new ECal.Component.from_icalcomponent (ical);

        item.id = ical.get_uid ();;
        item.content = ical.get_summary ();

        if (ical.get_description () != null) {
            item.description = ical.get_description ();
        }

        if (find_string_value ("PRIORITY", data) != "") {
            int _priority = int.parse (find_string_value ("PRIORITY", data));
            if (_priority <= 0) {
                item.priority = Constants.PRIORITY_4;
            } else if (_priority >= 1 && _priority <= 4) {
                item.priority = Constants.PRIORITY_1;
            } else if (_priority == 5) {
                item.priority = Constants.PRIORITY_2;
            } else if (_priority > 5 && _priority <= 9) {
                item.priority = Constants.PRIORITY_3;
            } else {
                item.priority = Constants.PRIORITY_4;
            }
        }

        if (!ical.get_due ().is_null_time ()) {
            item.due.date = ical_to_date_time_local (ical.get_due ()).to_string ();
        }

        item.pinned = find_boolean_value ("X-PINNED", data);

        return item;
    }

    public static string to_v_string (Objects.Item item) {
        ICal.Component ical = new ICal.Component.vtodo ();
        
        ical.set_uid (item.id);
        ical.set_summary (item.content);
        ical.set_description (item.description);

        var _priority = 0;
        if (item.priority == Constants.PRIORITY_4) {
            _priority = 0;
        } else if (item.priority == Constants.PRIORITY_1) {
            _priority = 1;
        } else if (item.priority == Constants.PRIORITY_2) {
            _priority = 5;
        } else if (item.priority == Constants.PRIORITY_3) {
            _priority = 9;
        } else {
            _priority = 0;
        }

        ical.add_property (new ICal.Property.priority (_priority));

        if (item.pinned) {
            var pinned_property = new ICal.Property (ICal.PropertyKind.X_PROPERTY);
            pinned_property.set_x_name ("X-PINNED");
            pinned_property.set_x (item.pinned.to_string ());
            ical.add_property (pinned_property);
        }
        

        if (item.has_due) {
            var task_tz = ical.get_due ().get_timezone ();
            ICal.Time new_icaltime = datetimes_to_icaltime (item.due.datetime, item.due.datetime, null);
            ical.set_due (new_icaltime);
        }

        var finalVTODO = "";
        finalVTODO += "BEGIN:VCALENDAR\nVERSION:2.0\nPRODID:-//Planify App (https://github.com/alainm23/planify)\n";
        finalVTODO += ical.as_ical_string ();
        finalVTODO += "END:VCALENDAR\n";

        return finalVTODO;
    }

    private static string find_string_value (string key, string data) {
        GLib.Regex? regex = null;
        GLib.MatchInfo match;

        try {
            regex = new GLib.Regex ("%s:(.*?)\n".printf (key));
        } catch (GLib.RegexError e) {
            critical (e.message);
        }

        if (regex == null) {
            return "";
        }

        if (!regex.match (data, 0, out match)) {
            return "";
        }

        return match.fetch_all () [1];
    }

    private static bool find_boolean_value (string key, string data) {
        GLib.Regex? regex = null;
        GLib.MatchInfo match;

        try {
            regex = new GLib.Regex ("%s:(.*?)\n".printf (key));
        } catch (GLib.RegexError e) {
            critical (e.message);
        }

        if (regex == null) {
            return false;
        }

        if (!regex.match (data, 0, out match)) {
            return false;
        }

        return bool.parse (match.fetch_all () [1]);
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
        var system_tz = ECal.util_get_system_timezone ();
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
     
     public static ICal.Time datetimes_to_icaltime (GLib.DateTime date, GLib.DateTime? time_local,
        ICal.Timezone? timezone = ECal.util_get_system_timezone ().copy ()) {

        var result = new ICal.Time.from_day_of_year (date.get_day_of_year (), date.get_year ());

        // Check if it's a date. If so, set is_date to true and fix the time to be sure.
        // If it's not a date, first thing set is_date to false.
        // Then, set the timezone.
        // Then, set the time.
        if (time_local == null) {
            // Date type: ensure that everything corresponds to a date
            result.set_is_date (true);
            result.set_time (0, 0, 0);
        } else {
            // Includes time
            // Set is_date first (otherwise timezone won't change)
            result.set_is_date (false);

            // Set timezone for the time to be relative to
            // (doesn't affect DATE-type times)
            result.set_timezone (timezone);

            // Set the time with the updated time zone
            result.set_time (time_local.get_hour (), time_local.get_minute (), time_local.get_second ());
            debug (result.get_tzid ());
            debug (result.as_ical_string ());
        }

        return result;
    }
}
