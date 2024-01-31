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
            position: Gtk.PositionType.RIGHT
        );
    }

    construct {
        var search_entry = new Gtk.SearchEntry () {
            css_classes = { "border-radius-9" }
        };

        var today_item = new Widgets.ContextMenu.MenuItem (_("Today"), "planner-today");
        today_item.secondary_text = new GLib.DateTime.now_local ().format ("%a");

        var tomorrow_item = new Widgets.ContextMenu.MenuItem (_("Tomorrow"), "planner-scheduled");
        tomorrow_item.secondary_text = new GLib.DateTime.now_local ().add_days (1).format ("%a");

        no_date_item = new Widgets.ContextMenu.MenuItem (_("No Date"), "planner-close-circle") {
            visible = false
        };

        var next_week_item = new Widgets.ContextMenu.MenuItem (_("Next week"), "planner-scheduled");
        next_week_item.secondary_text = Util.get_default ().get_relative_date_from_date (
            Util.get_default ().get_format_date (new GLib.DateTime.now_local ().add_days (7))
        );

        var date_item = new Widgets.ContextMenu.MenuItem (_("Choose a date"), "planner-scheduled");

        var items_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            hexpand = true,
            css_classes = { "card" }
        };
    
        items_box.append (today_item);
        items_box.append (tomorrow_item);
        items_box.append (next_week_item);
        items_box.append (no_date_item);
        items_box.append (date_item);
        
        var menu_items_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            hexpand = true
        };

        //  menu_items_box.append (search_entry);
        menu_items_box.append (items_box);

        var calendar_view = new Widgets.Calendar.Calendar (false);

        var calendar_grid = new Gtk.Grid ();
        calendar_grid.attach (calendar_view, 0, 0);
        calendar_grid.add_css_class (Granite.STYLE_CLASS_CARD);

        var time_icon = new Widgets.DynamicIcon.from_icon_name ("planner-clock") {
            margin_start = 9
        };

        var time_label = new Gtk.Label (_("Time")) {
            margin_start = 6,
            css_classes = { "font-weight-500" }
        };

        time_picker = new Widgets.DateTimePicker.TimePicker () {
            hexpand = true,
            halign = Gtk.Align.END
        };

        var time_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            hexpand = true,
            margin_top = 6,
            css_classes = { "card" }
        };

        time_box.append (time_icon);
        time_box.append (time_label);
        time_box.append (time_picker);

        var submit_button = new Widgets.LoadingButton.with_label (_("Done")) {
            margin_top = 12,
            margin_bottom = 3,
            css_classes = { Granite.STYLE_CLASS_SUGGESTED_ACTION }
        };

        var calendar_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            hexpand = true
        };

        calendar_box.append (calendar_grid);
        calendar_box.append (time_box);
        calendar_box.append (submit_button);

        var content_stack = new Gtk.Stack () {
            hexpand = true,
            vexpand = true,
            transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT,
            vhomogeneous = false,
            hhomogeneous = true
        };

        content_stack.add_named (menu_items_box, "items");
        content_stack.add_named (calendar_box, "calendar");

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            width_request = 225
        };
        
        content_box.append (content_stack);

        child = content_box;

        today_item.activate_item.connect (() => {
            set_date (new DateTime.now_local ());
        });

        tomorrow_item.activate_item.connect (() => {
            set_date (new DateTime.now_local ().add_days (1));
        });

        next_week_item.activate_item.connect (() => {
            set_date (new DateTime.now_local ().add_days (7));
        });

        no_date_item.activate_item.connect (() => {
            time_picker.has_time = false;
            _datetime = null;
            popdown ();
            date_changed ();
        });

        calendar_view.selection_changed.connect ((date) => {
            _datetime = Util.get_default ().get_format_date (date);
        });

        time_picker.time_changed.connect (() => {
            _datetime = Util.get_default ().get_format_date (datetime);
        });

        date_item.clicked.connect (() => {
            content_stack.visible_child_name = "calendar";
        });

        submit_button.clicked.connect (() => {
            date_changed ();
            popdown ();
        });

        closed.connect (() => {
            content_stack.visible_child_name = "items";
        });
    }

    private void set_date (DateTime date) {
        _datetime = Util.get_default ().get_format_date (date);
        popdown ();
        date_changed ();
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
