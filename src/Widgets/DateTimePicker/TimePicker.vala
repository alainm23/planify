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

public class Widgets.DateTimePicker.TimePicker : Gtk.Grid {
    private Gtk.Button time_button;
    private Gtk.ToggleButton am_togglebutton;
    private Gtk.ToggleButton pm_togglebutton;
    private Gtk.Box am_pm_box;
    private Gtk.SpinButton hours_spinbutton;
    private Gtk.SpinButton minutes_spinbutton;
    private Gtk.Stack time_stack;
    private Gtk.Revealer no_time_revealer;
    private Gtk.Popover popover;

    public string format_12 { get; construct; }
    public string format_24 { get; construct; }

    private GLib.DateTime _time = null;
    public GLib.DateTime time {
        get {
            if (_time == null) {
                time = new GLib.DateTime.now_local ();
            }

            return _time;
        }

        set {
            _time = value;
            changing_time = true;

            if (_time.get_hour () >= 12) {
                pm_togglebutton.active = true;
            } else {
                am_togglebutton.active = true;
            }

            update_text (true);
            changing_time = false;
        }
    }

    public bool has_time {
        get {
            return time_stack.visible_child_name == "time-box";
        }

        set {
            time_stack.visible_child_name = value ? "time-box" : "add-time";
        }
    }

    public bool no_time_visible {
        set {
            no_time_revealer.reveal_child = value;
        }
    }

    private string old_string = "";
    private bool changing_time = false;

    public signal void time_changed ();

    construct {  
        time_button = new Gtk.Button.with_label ("") {
            valign = Gtk.Align.CENTER,
            can_focus = false
        };

        time_button.add_css_class ("time-button-picker");
        time_button.add_css_class (Granite.STYLE_CLASS_FLAT);

        var close_circle_icon = new Widgets.DynamicIcon ();
        close_circle_icon.size = 19;
        close_circle_icon.update_icon_name ("planner-close-circle");
        
        var no_time_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER,
            can_focus = false
        };

        no_time_button.child = close_circle_icon;
        no_time_button.add_css_class (Granite.STYLE_CLASS_FLAT);
        no_time_button.add_css_class ("p3");

        no_time_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT,
            reveal_child = true
        };

        no_time_revealer.child = no_time_button;

        var time_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        time_box.append (time_button);
        time_box.append (no_time_revealer);

        var add_circle_icon = new Widgets.DynamicIcon ();
        add_circle_icon.size = 19;
        add_circle_icon.update_icon_name ("planner-plus-circle");

        var add_time_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.END,
            can_focus = false
        };

        add_time_button.child = add_circle_icon;
        add_time_button.add_css_class (Granite.STYLE_CLASS_FLAT);
        add_time_button.add_css_class ("p3");

        time_stack = new Gtk.Stack () {
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };
        time_stack.add_named (add_time_button, "add-time");
        time_stack.add_named (time_box, "time-box");

        var timepicker_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            margin_start = 3,
            hexpand = true
        };
        
        timepicker_box.append (time_stack);

        /*
        *   Build Time Popover
        */

        if (format_12 == null) {
            format_12 = Granite.DateTime.get_default_time_format (true);
        }

        if (format_24 == null) {
            format_24 = Granite.DateTime.get_default_time_format (false);
        }

        /// TRANSLATORS: this will only show up when 12-hours clock is in use
        am_togglebutton = new Gtk.ToggleButton.with_label (_("AM")) {
            vexpand = true
        };

        /// TRANSLATORS: this will only show up when 12-hours clock is in use
        pm_togglebutton = new Gtk.ToggleButton.with_label (_("PM")) {
            group = am_togglebutton,
            vexpand = true
        };

        am_pm_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        am_pm_box.add_css_class (Granite.STYLE_CLASS_LINKED);
        am_pm_box.append (am_togglebutton);
        am_pm_box.append (pm_togglebutton);

        if (Util.get_default ().is_clock_format_12h ()) {
            hours_spinbutton = new Gtk.SpinButton.with_range (1, 12, 1);
        } else {
            hours_spinbutton = new Gtk.SpinButton.with_range (0, 23, 1);
        }

        hours_spinbutton.orientation = Gtk.Orientation.VERTICAL;
        hours_spinbutton.wrap = true;
        hours_spinbutton.value_changed.connect (() => {
            update_time (true);
        });

        minutes_spinbutton = new Gtk.SpinButton.with_range (0, 59, 1);
        minutes_spinbutton.orientation = Gtk.Orientation.VERTICAL;
        minutes_spinbutton.wrap = true;
        minutes_spinbutton.value_changed.connect (() => {
            update_time (false);
        });

        var separation_label = new Gtk.Label (_(":"));

        var pop_grid = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);

        pop_grid.append (hours_spinbutton);
        pop_grid.append (separation_label);
        pop_grid.append (minutes_spinbutton);
        pop_grid.append (am_pm_box);

        popover = new Gtk.Popover ();
        popover.position = Gtk.PositionType.BOTTOM;
        popover.set_parent (time_button);
        popover.child = pop_grid;

        var main_grid = new Gtk.Grid () {
            hexpand = true
        };

        main_grid.attach (timepicker_box, 0, 0);

        attach (main_grid, 0, 0);

        time_button.clicked.connect (() => {
            open_time_picker ();
        });

        add_time_button.clicked.connect (() => {
            time_stack.visible_child_name = "time-box";
            update_text ();
            open_time_picker ();
        });

        no_time_button.clicked.connect (() => {
            time_stack.visible_child_name = "add-time";
            update_text ();
        });

        am_togglebutton.clicked.connect (() => {
            update_am_pm (-12);
        });

        pm_togglebutton.clicked.connect (() => {
            update_am_pm (12);
        });
    }

    private void update_am_pm (int hours) {
        if (changing_time) {
            return;
        }

        time = _time.add_hours (hours);
        time_changed ();

        update_text (true);
    }

    private void open_time_picker () {
        // If the mode is changed from 12h to 24h or visa versa, the entry updates on icon press
        update_text ();
        changing_time = true;

        if (Util.get_default ().is_clock_format_12h () && time.get_hour () > 12) {
            hours_spinbutton.set_value (time.get_hour () - 12);
        } else {
            hours_spinbutton.set_value (time.get_hour ());
        }

        if (Util.get_default ().is_clock_format_12h ()) {
            am_pm_box.show ();

            if (time.get_hour () > 12) {
                hours_spinbutton.set_value (time.get_hour () - 12);
            } else if (time.get_hour () == 0) {
                hours_spinbutton.set_value (12);
            } else {
                hours_spinbutton.set_value (time.get_hour ());
            }

            // Make sure that bounds are set correctly
            hours_spinbutton.set_range (1, 12);
        } else {
            am_pm_box.hide ();
            hours_spinbutton.set_value (time.get_hour ());
            hours_spinbutton.set_range (0, 23);
        }

        minutes_spinbutton.set_value (time.get_minute ());
        changing_time = false;

        popover.popup ();
    }

    private void update_time (bool is_hour) {
        if (changing_time) {
            return;
        }

        if (is_hour) {
            var new_hour = hours_spinbutton.get_value_as_int () - time.get_hour ();

            if (Util.get_default ().is_clock_format_12h ()) {
                if (hours_spinbutton.get_value_as_int () == 12 && am_togglebutton.active = true) {
                    _time = _time.add_hours (-_time.get_hour ());
                } else if (hours_spinbutton.get_value_as_int () < 12 && am_togglebutton.active = true) {
                    _time = _time.add_hours (new_hour);
                } else if (hours_spinbutton.get_value_as_int () == 12 && pm_togglebutton.active = true) {
                    _time = _time.add_hours (-_time.get_hour () + 12);
                } else if (hours_spinbutton.get_value_as_int () < 12 && pm_togglebutton.active = true) {
                    _time = _time.add_hours (new_hour + 12);

                    if (time.get_hour () <= 12) {
                        _time = _time.add_hours (12);
                    }
                }
            } else {
                _time = _time.add_hours (new_hour);
            }
        } else {
            _time = time.add_minutes (minutes_spinbutton.get_value_as_int () - time.get_minute ());
        }

        update_text ();
    }

    private void update_text (bool no_signal = false) {
        if (Util.get_default ().is_clock_format_12h ()) {
            time_button.label = time.format (format_12);
        } else {
            time_button.label = time.format (format_24);
        }

        old_string = time_button.label;

        if (no_signal == false) {
            time_changed ();
        }
    }
}