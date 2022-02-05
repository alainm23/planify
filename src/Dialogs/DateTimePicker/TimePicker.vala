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

public class Dialogs.DateTimePicker.TimePicker : Gtk.EventBox {
    private Gtk.Button time_button;
    private Granite.Widgets.ModeButton am_pm_modebutton;
    private Gtk.SpinButton hours_spinbutton;
    private Gtk.SpinButton minutes_spinbutton;
    private Gtk.Stack time_stack;

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
                am_pm_modebutton.set_active (1);
            } else {
                am_pm_modebutton.set_active (0);
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

    private string old_string = "";
    private bool changing_time = false;

    public signal void time_changed ();

    construct {
        var time_icon = new Widgets.DynamicIcon ();
        time_icon.size = 19;
        time_icon.update_icon_name ("planner-clock");

        var title_label = new Gtk.Label (_("Time"));
        title_label.get_style_context ().add_class ("font-weight-500");
        
        time_button = new Gtk.Button.with_label ("") {
            valign = Gtk.Align.CENTER,
            can_focus = false
        };

        time_button.get_style_context ().add_class ("time-button-picker");
        time_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var close_circle_icon = new Widgets.DynamicIcon ();
        close_circle_icon.size = 19;
        close_circle_icon.update_icon_name ("planner-close-circle");
        
        var no_time_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER,
            can_focus = false
        };
        no_time_button.add (close_circle_icon);
        no_time_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var time_grid = new Gtk.Grid ();
        time_grid.add (time_button);
        time_grid.add (no_time_button);

        var add_circle_icon = new Widgets.DynamicIcon ();
        add_circle_icon.size = 19;
        add_circle_icon.update_icon_name ("planner-plus-circle");

        var add_time_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.END,
            can_focus = false
        };
        add_time_button.add (add_circle_icon);
        add_time_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        time_stack = new Gtk.Stack () {
            transition_type = Gtk.StackTransitionType.CROSSFADE,
            homogeneous = false
        };
        time_stack.add_named (add_time_button, "add-time");
        time_stack.add_named (time_grid, "time-box");

        var timepicker_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            margin_start = 3,
            hexpand = true
        };
        timepicker_box.pack_start (time_icon, false, false, 0);
        timepicker_box.pack_start (title_label, false, true, 6);
        timepicker_box.pack_end (time_stack, false, false, 0);

        /*
        *   Build Time Popover
        */

        if (format_12 == null) {
            format_12 = Granite.DateTime.get_default_time_format (true);
        }

        if (format_24 == null) {
            format_24 = Granite.DateTime.get_default_time_format (false);
        }

        am_pm_modebutton = new Granite.Widgets.ModeButton () {
            hexpand = true,
            orientation = Gtk.Orientation.VERTICAL,
            no_show_all = true
        };
        am_pm_modebutton.append_text (_("AM"));
        am_pm_modebutton.append_text (_("PM"));

        am_pm_modebutton.mode_changed.connect (mode => {
            if (changing_time) {
                return;
            }

            if (am_pm_modebutton.selected == 0) {
                time = _time.add_hours (-12);
                time_changed ();
            } else if (am_pm_modebutton.selected == 1) {
                time = _time.add_hours (12);
                time_changed ();
            } else {
                assert_not_reached ();
            }

            update_text (true);
        });

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

        var pop_grid = new Gtk.Grid ();
        pop_grid.column_spacing = 6;
        pop_grid.row_spacing = 6;
        pop_grid.attach (hours_spinbutton, 0, 0, 1, 1);
        pop_grid.attach (separation_label, 1, 0, 1, 1);
        pop_grid.attach (minutes_spinbutton, 2, 0, 1, 1);
        pop_grid.attach (am_pm_modebutton, 3, 0, 1, 1);
        pop_grid.margin = 6;

        var popover = new Gtk.Popover (time_button);
        popover.position = Gtk.PositionType.BOTTOM;
        popover.add (pop_grid);

        var main_grid = new Gtk.Grid () {
            hexpand = true,
            margin = 9,
            margin_top = 0,
            margin_bottom = 12
        };

        main_grid.add (timepicker_box);

        unowned Gtk.StyleContext main_grid_context = main_grid.get_style_context ();
        main_grid_context.add_class ("picker-content");

        add (main_grid);

        time_button.clicked.connect (() => {
            // If the mode is changed from 12h to 24h or visa versa, the entry updates on icon press
            update_text ();
            changing_time = true;

            if (Util.get_default ().is_clock_format_12h () && time.get_hour () > 12) {
                hours_spinbutton.set_value (time.get_hour () - 12);
            } else {
                hours_spinbutton.set_value (time.get_hour ());
            }

            if (Util.get_default ().is_clock_format_12h ()) {
                am_pm_modebutton.no_show_all = false;
                am_pm_modebutton.show_all ();

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
                am_pm_modebutton.no_show_all = true;
                am_pm_modebutton.hide ();
                hours_spinbutton.set_value (time.get_hour ());

                hours_spinbutton.set_range (0, 23);
            }

            minutes_spinbutton.set_value (time.get_minute ());
            changing_time = false;

            popover.show_all ();
        });

        add_time_button.clicked.connect (() => {
            time_stack.visible_child_name = "time-box";
            update_text ();
        });

        no_time_button.clicked.connect (() => {
            time_stack.visible_child_name = "add-time";
        });
    }

    private void update_time (bool is_hour) {
        if (changing_time) {
            return;
        }

        if (is_hour) {
            var new_hour = hours_spinbutton.get_value_as_int () - time.get_hour ();

            if (Util.get_default ().is_clock_format_12h ()) {
                if (hours_spinbutton.get_value_as_int () == 12 && am_pm_modebutton.selected == 0) {
                    _time = _time.add_hours (-_time.get_hour ());
                } else if (hours_spinbutton.get_value_as_int () < 12 && am_pm_modebutton.selected == 0) {
                    _time = _time.add_hours (new_hour);
                } else if (hours_spinbutton.get_value_as_int () == 12 && am_pm_modebutton.selected == 1) {
                    _time = _time.add_hours (-_time.get_hour () + 12);
                } else if (hours_spinbutton.get_value_as_int () < 12 && am_pm_modebutton.selected == 1) {
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