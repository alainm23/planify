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
    private Widgets.ContextMenu.MenuItem today_item;
    private Widgets.ContextMenu.MenuItem tomorrow_item;
    private Widgets.ContextMenu.MenuItem date_item;
    private Widgets.ContextMenu.MenuItem next_week_item;
    private Widgets.DateTimePicker.TimePicker time_picker;
    private Widgets.Calendar.Calendar calendar_view;
    private Gtk.Revealer action_revealer;

    private GLib.DateTime _datetime = null;
    public GLib.DateTime datetime {
        set {
            _datetime = value;
            if (_datetime != null) {
                calendar_view.date = _datetime;
            }

            check_items (_datetime);

            if (Utils.Datetime.has_time (_datetime)) {
                time_picker.time = _datetime;
                time_picker.has_time = true;
            }
        }
        
        get {
            if (time_picker.has_time) {
                if (_datetime == null) {
                    _datetime = time_picker.time;
                } else {
                    _datetime = add_date_time (_datetime, time_picker.time);
                }
            } else {
                if (_datetime != null) {
                    _datetime = Utils.Datetime.get_format_date (_datetime);
                }
            }

            return _datetime;
        }
    }

    public bool visible_no_date {
        set {
            action_revealer.reveal_child = value;
        }
    }

    public signal void date_changed ();

    public DateTimePicker () {
        Object (
            has_arrow: false,
            position: Gtk.PositionType.RIGHT,
            width_request: 275
        );
    }

    construct {
        today_item = new Widgets.ContextMenu.MenuItem (_("Today"), "star-outline-thick-symbolic");
        tomorrow_item = new Widgets.ContextMenu.MenuItem (_("Tomorrow"), "today-calendar-symbolic");
        next_week_item = new Widgets.ContextMenu.MenuItem (_("Next week"), "work-week-symbolic");
        date_item = new Widgets.ContextMenu.MenuItem (_("Choose a date"), "month-symbolic");
        date_item.arrow = true;

        var time_icon = new Gtk.Image.from_icon_name ("clock-symbolic") {
            margin_start = 12
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
            margin_top = 6
        };

        time_box.append (time_icon);
        time_box.append (time_label);
        time_box.append (time_picker);

        var submit_button = new Widgets.LoadingButton.with_label (_("Done")) {
            css_classes = { "suggested-action" }
        };

        var clear_button = new Widgets.LoadingButton.with_label (_("Clear")) {
            css_classes = { "destructive-action" }
        };

        var action_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            margin_top = 12,
            homogeneous = true
        };
        action_box.append (clear_button);
        action_box.append (submit_button);

        action_revealer = new Gtk.Revealer () {
			transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
			child = action_box
		};

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            width_request = 225
        };  

        content_box.append (today_item);
        content_box.append (tomorrow_item);
        content_box.append (next_week_item);
        content_box.append (date_item);
        content_box.append (new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
            margin_start = 6,
            margin_top = 6
        });
        content_box.append (time_box);
        content_box.append (action_revealer);

        var back_item = new Widgets.ContextMenu.MenuItem (_("Back"), "go-previous-symbolic");
        calendar_view = new Widgets.Calendar.Calendar (false);

        var calendar_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            hexpand = true
        };

        calendar_box.append (back_item);
        calendar_box.append (new Widgets.ContextMenu.MenuSeparator ());
        calendar_box.append (calendar_view);

        var content_stack = new Gtk.Stack () {
            hexpand = true,
            vexpand = true,
            transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT,
            vhomogeneous = false,
            hhomogeneous = true
        };

        content_stack.add_named (content_box, "items");
        content_stack.add_named (calendar_box, "calendar");

        child = content_stack;

        today_item.activate_item.connect (() => {
            set_date (new DateTime.now_local ());
        });

        tomorrow_item.activate_item.connect (() => {
            set_date (new DateTime.now_local ().add_days (1));
        });

        next_week_item.activate_item.connect (() => {
            set_date (new DateTime.now_local ().add_days (7));
        });

        calendar_view.day_selected.connect (() => {
            datetime = Utils.Datetime.get_format_date (calendar_view.date);
            visible_no_date = true;
            content_stack.visible_child_name = "items";
        });

        back_item.clicked.connect (() => {
            content_stack.visible_child_name = "items";
        });

        time_picker.time_changed.connect (() => {
            datetime = Utils.Datetime.get_format_date (datetime);
        });

        time_picker.time_added.connect (() => {
            visible_no_date = true;

            if (datetime == null) {
                datetime = time_picker.time;
            }
        });

        submit_button.clicked.connect (() => {
            date_changed ();
            popdown ();
        });

        clear_button.clicked.connect (() => {
            time_picker.has_time = false;
            _datetime = null;
            popdown ();
            date_changed ();
            check_items (null);
        });

        date_item.clicked.connect (() => {
            content_stack.visible_child_name = "calendar";
        });

        closed.connect (() => {
            content_stack.visible_child_name = "items";
        });
    }

    private void set_date (DateTime date) {
        datetime = Utils.Datetime.get_format_date (date);
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

    public void reset () {
        time_picker.reset ();
        visible_no_date = false;
        calendar_view.reset ();
        check_items (null);
    }

    private void check_items (GLib.DateTime? datetime) {
        today_item.selected = false;
        tomorrow_item.selected = false;
        next_week_item.selected = false;
        date_item.selected = false;
        date_item.secondary_text = "";

        if (datetime == null) {
            return;
        }

        if (Utils.Datetime.is_today (datetime)) {
            today_item.selected = true;
        } else if (Utils.Datetime.is_tomorrow (datetime)) {
            tomorrow_item.selected = true;
        } else if (Utils.Datetime.is_next_week (datetime)) {
            next_week_item.selected = true;
        } else {
            date_item.secondary_text = Utils.Datetime.get_relative_date_from_date (
                Utils.Datetime.get_format_date (datetime)
            );
        }
    }
}
