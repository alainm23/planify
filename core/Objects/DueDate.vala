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

public class Objects.DueDate : GLib.Object {
    public string date { get; set; default = ""; }
    public string time_zone { get; set; default = ""; }
    public string recurrency_weeks { get; set; default = ""; }
    public bool is_recurring { get; set; default = false; }
    public RecurrencyType recurrency_type { get; set; default = RecurrencyType.NONE; }
    public int recurrency_interval { get; set; default = 0; }
    public int recurrency_count { get; set; default = 0; }
    public string recurrency_end { get; set; default = ""; }
    public bool recurrence_supported { get; set; default = false; }

    GLib.DateTime ? _datetime = null;
    public GLib.DateTime ? datetime {
        get {
            if (_datetime == null) {
                _datetime = Utils.Datetime.get_todoist_datetime (date);
            }

            return _datetime;
        }

        set {
            date = Utils.Datetime.get_todoist_datetime_format (value);
        }
    }

    GLib.DateTime _end_datetime;
    public GLib.DateTime end_datetime {
        get {
            _end_datetime = Utils.Datetime.get_date_from_string (recurrency_end);
            return _end_datetime;
        }
    }

    public bool has_weeks {
        get {
            return recurrency_weeks != "";
        }
    }

    public RecurrencyEndType end_type {
        get {
            if (recurrency_end != "") {
                return RecurrencyEndType.ON_DATE;
            }

            if (recurrency_count > 0) {
                return RecurrencyEndType.AFTER;
            }

            return RecurrencyEndType.NEVER;
        }
    }

    public bool is_recurrency_end {
        get {
            if (end_type == RecurrencyEndType.ON_DATE) {
                var next_recurrency = Utils.Datetime.next_recurrency (datetime, this);
                return next_recurrency.compare (end_datetime) > -1;
            } else if (end_type == RecurrencyEndType.AFTER) {
                return recurrency_count - 1 <= 0;
            }

            return false;
        }
    }

    public DueDate.from_json (Json.Object object) {
        update_from_json (object);
    }

    construct {
        notify["date"].connect (() => {
            _datetime = null;
        });
    }

    public void update_from_todoist_json (Json.Object object) {
        if (object.has_member ("date")) {
            date = object.get_string_member ("date");
        }

        if (object.has_member ("timezone")) {
            time_zone = object.get_string_member ("timezone");
        }

        if (object.has_member ("is_recurring")) {
            is_recurring = object.get_boolean_member ("is_recurring");
            Utils.Datetime.parse_todoist_recurrency (this, object);
        }
    }

    public void update_from_json (Json.Object object) {
        if (object.has_member ("date")) {
            date = object.get_string_member ("date");
        }

        if (object.has_member ("timezone")) {
            time_zone = object.get_string_member ("timezone");
        }

        if (object.has_member ("is_recurring")) {
            is_recurring = object.get_boolean_member ("is_recurring");
        }

        if (object.has_member ("recurrency_type")) {
            recurrency_type = (RecurrencyType) int.parse (object.get_string_member ("recurrency_type"));
        }

        if (object.has_member ("recurrency_interval")) {
            recurrency_interval = int.parse (object.get_string_member ("recurrency_interval"));
        }

        if (object.has_member ("recurrency_weeks")) {
            recurrency_weeks = object.get_string_member ("recurrency_weeks");
        }

        if (object.has_member ("recurrency_count")) {
            recurrency_count = int.parse (object.get_string_member ("recurrency_count"));
        }

        if (object.has_member ("recurrency_end")) {
            recurrency_end = object.get_string_member ("recurrency_end");
        }
    }

    public void reset () {
        date = "";
        time_zone = "";
        recurrency_type = RecurrencyType.NONE;
        recurrency_interval = 0;
        is_recurring = false;
    }

    public string to_string () {
        var builder = new Json.Builder ();
        builder.begin_object ();

        builder.set_member_name ("date");
        builder.add_string_value (date);

        builder.set_member_name ("timezone");
        builder.add_string_value (time_zone);

        builder.set_member_name ("is_recurring");
        builder.add_boolean_value (is_recurring);

        builder.set_member_name ("recurrency_type");
        builder.add_string_value (((int) recurrency_type).to_string ());

        builder.set_member_name ("recurrency_interval");
        builder.add_string_value (recurrency_interval.to_string ());

        builder.set_member_name ("recurrency_weeks");
        builder.add_string_value (recurrency_weeks);

        builder.set_member_name ("recurrency_count");
        builder.add_string_value (recurrency_count.to_string ());

        builder.set_member_name ("recurrency_end");
        builder.add_string_value (recurrency_end);

        builder.end_object ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);

        return generator.to_data (null);
    }

    public bool is_recurrency_equal (Objects.DueDate duedate) {
        return ((int) recurrency_type == (int) duedate.recurrency_type &&
                recurrency_interval == duedate.recurrency_interval &&
                recurrency_weeks == duedate.recurrency_weeks &&
                recurrency_count == duedate.recurrency_count &&
                recurrency_end == duedate.recurrency_end &&
                is_recurring == duedate.is_recurring);
    }

    public string to_friendly_string () {
        return recurrency_type.to_friendly_string (recurrency_interval);
    }

    public Objects.DueDate duplicate () {
        var new_due = new Objects.DueDate ();
        new_due.date = date;
        new_due.time_zone = time_zone;
        new_due.recurrency_weeks = recurrency_weeks;
        new_due.is_recurring = is_recurring;
        new_due.recurrency_type = recurrency_type;
        new_due.recurrency_interval = recurrency_interval;
        new_due.recurrency_count = recurrency_count;
        new_due.recurrency_end = recurrency_end;
        new_due.recurrence_supported = recurrence_supported;
        return new_due;
    }
}
