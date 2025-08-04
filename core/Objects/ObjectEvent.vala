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

public class Objects.ObjectEvent : GLib.Object {
    public int64 id { get; set; default = 0; }
    public ObjectEventType event_type { get; set; }
    public string event_date { get; set; default = ""; }
    public string object_id { get; set; default = ""; }
    public string object_type { get; set; default = ""; }
    public ObjectEventKeyType object_key { get; set; }
    public string object_old_value { get; set; default = ""; }
    public string object_new_value { get; set; default = ""; }
    public string parent_item_id { get; set; default = ""; }
    public string parent_project_id { get; set; default = ""; }

    public string icon_name {
        get {
            if (event_type == ObjectEventType.INSERT) {
                return "plus-large-symbolic";
            } else if (event_type == ObjectEventType.UPDATE) {
                if (object_key == ObjectEventKeyType.CONTENT) {
                    return "edit-symbolic";
                } else if (object_key == ObjectEventKeyType.DESCRIPTION) {
                    return "paper-symbolic";
                } else if (object_key == ObjectEventKeyType.DUE) {
                    return "month-symbolic";
                } else if (object_key == ObjectEventKeyType.PRIORITY) {
                    return "flag-outline-thick-symbolic";
                } else if (object_key == ObjectEventKeyType.LABELS) {
                    return "tag-outline-symbolic";
                } else if (object_key == ObjectEventKeyType.PINNED) {
                    return "pin-symbolic";
                } else if (object_key == ObjectEventKeyType.CHECKED) {
                    return "check-round-outline-symbolic";
                } else if (object_key == ObjectEventKeyType.SECTION || object_key == ObjectEventKeyType.PROJECT) {
                    return "arrow3-right-symbolic";
                }
            }

            return "plus-large-symbolic";
        }
    }

    GLib.DateTime _datetime;
    public GLib.DateTime datetime {
        get {
            _datetime = Utils.Datetime.get_date_from_string (event_date);
            return _datetime;
        }
    }

    GLib.DateTime _date;
    public GLib.DateTime date {
        get {
            _date = Utils.Datetime.format_date (Utils.Datetime.get_date_from_string (event_date));
            return _date;
        }
    }

    string _time;
    public string time {
        get {
            if (Utils.Datetime.is_clock_format_12h ()) {
                _time = datetime.format (Granite.DateTime.get_default_time_format (true));
            } else {
                _time = datetime.format (Granite.DateTime.get_default_time_format (false));
            }

            return _time;
        }
    }

    public Objects.DueDate ? get_due_value (string value) {
        Json.Parser parser = new Json.Parser ();

        try {
            parser.load_from_data (value, value.length);
        } catch (Error e) {
            warning (e.message);
            return null;
        }

        var due = new Objects.DueDate ();
        due.update_from_json (parser.get_root ().get_object ());

        return due;
    }

    public string get_labels_value (string value) {
        string return_value = "";
        Gee.ArrayList<Objects.Label> labels = Services.Store.instance ().get_labels_by_item_labels (value);

        if (labels.size > 0) {
            for (int index = 0; index < labels.size; index++) {
                if (index < labels.size - 1) {
                    return_value += labels[index].name + ", ";
                } else {
                    return_value += labels[index].name;
                }
            }
        }

        return return_value;
    }
}
