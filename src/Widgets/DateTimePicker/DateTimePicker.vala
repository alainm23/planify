

/*
* Copyright © 2019 Alain M. (https://github.com/alainm23/planner)
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

public class Widgets.DateTimePicker.DateTimePicker : Gtk.Popover {
    private Widgets.ContextMenu.MenuItem no_date_item;
    private Widgets.DateTimePicker.TimePicker time_picker;

    private GLib.DateTime _datetime = null;
    public GLib.DateTime datetime {
        get {
            if (time_picker.has_time) {
                if (_datetime == null) {
                    _datetime = time_picker.time;
                } else {
                    _datetime = add_date_time (_datetime, time_picker.time);
                }
            } else {
                if (_datetime != null) {
                    _datetime = Util.get_default ().get_format_date (_datetime);
                }
            }

            return _datetime;
        }

        set {
            _datetime = value;

            if (Util.get_default ().has_time (_datetime)) {
                time_picker.time = _datetime;
                time_picker.has_time = true;
            }
        }
    }

    public bool visible_no_date {
        set {
            no_date_item.visible = value;
        }
    }

    public signal void date_changed ();

    public DateTimePicker () {
        Object (
            has_arrow: false,
            position: Gtk.PositionType.BOTTOM
        );
    }

    construct {
        var today_item = new Widgets.ContextMenu.MenuItem (_("Today"), "planner-today");
        today_item.secondary_text = new GLib.DateTime.now_local ().format ("%a");

        var tomorrow_item = new Widgets.ContextMenu.MenuItem (_("Tomorrow"), "planner-scheduled");
        tomorrow_item.secondary_text = new GLib.DateTime.now_local ().add_days (1).format ("%a");

        no_date_item = new Widgets.ContextMenu.MenuItem (_("No Date"), "planner-close-circle");

        var next_week_item = new Widgets.ContextMenu.MenuItem (_("Next week"), "planner-scheduled");
        next_week_item.secondary_text = Util.get_default ().get_relative_date_from_date (
            Util.get_default ().get_format_date (new GLib.DateTime.now_local ().add_days (7))
        );

        var calendar_item = new Widgets.Calendar.Calendar (true);

        var left_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            hexpand = true,
            margin_top = 6,
            margin_end = 9
        };

        left_box.append (today_item);
        left_box.append (tomorrow_item);
        left_box.append (next_week_item);
        left_box.append (no_date_item);

        var time_icon = new Widgets.DynamicIcon () {
            margin_start = 3
        };

        time_icon.size = 21;
        time_icon.update_icon_name ("planner-clock");

        var time_label = new Gtk.Label (_("Time")) {
            margin_start = 6
        };
        time_label.get_style_context ().add_class ("font-weight-500");

        time_picker = new Widgets.DateTimePicker.TimePicker () {
            hexpand = true,
            halign = Gtk.Align.END
        };

        var time_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            hexpand = true,
            margin_start = 7,
            margin_end = 6,
            margin_top = 3
        };

        time_box.append (time_icon);
        time_box.append (time_label);
        time_box.append (time_picker);

        var right_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            hexpand = true,
            margin_start = 6
        };

        right_box.append (calendar_item);
        right_box.append (time_box);

        var content_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            width_request = 225
        };
        
        content_box.append (left_box);
        content_box.append (new Gtk.Separator (Gtk.Orientation.VERTICAL) {
            margin_top = 6,
            margin_bottom = 6
        });
        content_box.append (right_box);

        child = content_box;

        today_item.activate_item.connect (() => {
            set_date (new DateTime.now_local ());
            popdown ();
        });

        tomorrow_item.activate_item.connect (() => {
            set_date (new DateTime.now_local ().add_days (1));
            popdown ();
        });

        next_week_item.activate_item.connect (() => {
            set_date (new DateTime.now_local ().add_days (7));
            popdown ();
        });

        no_date_item.activate_item.connect (() => {
            _datetime = null;
            popdown ();
        });

        calendar_item.selection_changed.connect ((date) => {
            _datetime = Util.get_default ().get_format_date (date);
        });

        time_picker.time_changed.connect (() => {
            _datetime = Util.get_default ().get_format_date (datetime);
        });

        closed.connect (() => {
            date_changed ();
        });
    }

    private void set_date (DateTime date) {
        _datetime = Util.get_default ().get_format_date (date);
    }

    private GLib.DateTime add_date_time (GLib.DateTime date, GLib.DateTime time) {
        return new GLib.DateTime.local (
            date.get_year (),
            date.get_month (),
            date.get_day_of_month (),
            time.get_hour (),
            time.get_minute (),
            time.get_second ()
        );
    }
}