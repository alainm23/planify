/*
* Copyright © 2019 Alain M. (https://github.com/alainm23/planner)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
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
* Authored by: Alain M. <alain23@protonmail.com>
*/

public class Widgets.TimePicker : Gtk.EventBox {
    public signal void time_changed ();
    
    private Gtk.SpinButton hours_spinbutton;
    private Gtk.SpinButton minutes_spinbutton;

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

    private bool changing_time = false;
    private string old_string = "";
    private Granite.Widgets.ModeButton am_pm_modebutton;
    public Gtk.Entry time_entry;
    public TimePicker () {
        Object ();
    }

    construct {
        time_entry = new Gtk.Entry ();
        time_entry.max_length = 8;

        am_pm_modebutton = new Granite.Widgets.ModeButton ();
        am_pm_modebutton.orientation = Gtk.Orientation.VERTICAL;
        am_pm_modebutton.append_text (_("AM"));
        am_pm_modebutton.append_text (_("PM"));
        am_pm_modebutton.mode_changed.connect (mode => {
            if (changing_time) {
                return;
            }

            if (am_pm_modebutton.selected == 0) {
                time = _time.add_hours (-12);
            } else if (am_pm_modebutton.selected == 1) {
                time = _time.add_hours (12);
            } else {
                assert_not_reached ();
            }

            update_text (true);
        });

        am_pm_modebutton.hexpand = true;

        /// TRANSLATORS: separates hours from minutes.
        var separation_label = new Gtk.Label (":");

        hours_spinbutton = new Gtk.SpinButton.with_range (1, 12, 1);
        hours_spinbutton.orientation = Gtk.Orientation.VERTICAL;
        hours_spinbutton.wrap = true;
        hours_spinbutton.value_changed.connect (() => update_time (true));

        minutes_spinbutton = new Gtk.SpinButton.with_range (0, 59, 1);
        minutes_spinbutton.orientation = Gtk.Orientation.VERTICAL;
        minutes_spinbutton.wrap = true;
        minutes_spinbutton.value_changed.connect (() => update_time (false));

        minutes_spinbutton.output.connect (() => {
            var val = minutes_spinbutton.get_value ();
            if (val < 10) {
                minutes_spinbutton.set_text ("0" + val.to_string ());
                return true;
            }

            return false;
        });

        var grid = new Gtk.Grid ();
        grid.column_spacing = 6;
        grid.row_spacing = 6;
        grid.attach (hours_spinbutton,   0, 0, 1, 1);
        grid.attach (separation_label,   1, 0, 1, 1);
        grid.attach (minutes_spinbutton, 2, 0, 1, 1);
        grid.attach (am_pm_modebutton,   3, 0, 1, 1);
        grid.margin = 6;

        var main_grid = new Gtk.Grid ();
        main_grid.margin_top = 12;
        main_grid.halign = Gtk.Align.CENTER;
        main_grid.orientation = Gtk.Orientation.VERTICAL;

        main_grid.add (grid);
        //main_grid.add (time_entry);

        add (main_grid);
        update_text ();

        time_entry.focus_out_event.connect (() => {
            is_unfocused ();
            return false;
        });

        time_entry.activate.connect (is_unfocused);
    }

    private void update_text (bool no_signal = false) {
        time_entry.set_text (time.format (Granite.DateTime.get_default_time_format (true, false)));

        old_string = time_entry.text;

        if (no_signal == false) {
            time_changed ();
        }
    }

    private void is_unfocused () {
        old_string = time_entry.text;
        parse_time (time_entry.text.dup ());
    }

    private void update_time (bool is_hour) {
        if (changing_time == true) {
            return;
        }

        if (is_hour == true) {
            var new_hour = hours_spinbutton.get_value_as_int () - time.get_hour ();

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
            _time = time.add_minutes (minutes_spinbutton.get_value_as_int () - time.get_minute ());
        }

        update_text ();
    }

    private void parse_time (string timestr) {
        string current = "";
        bool is_hours = true;
        bool is_suffix = false;
        bool has_suffix = false;

        int? hour = null;
        int? minute = null;
        foreach (var c in timestr.down ().to_utf8 ()) {
            if (c.isdigit ()) {
                current = "%s%c".printf (current, c);
            } else {
                if (is_hours == true && is_suffix == false && current != "") {
                    is_hours = false;
                    hour = int.parse (current);
                    current = "";
                } else if (is_hours == false && is_suffix == false && current != "") {
                    minute = int.parse (current);
                    current = "";
                }

                if ((c.to_string ().contains ("a") || c.to_string ().contains ("p")) && is_suffix == false) {
                    is_suffix = true;
                    current = "%s%c".printf (current, c);
                }

                if (c.to_string ().contains ("m") && is_suffix == true) {
                    if (hour == null) {
                        return;
                    } else if (minute == null) {
                        minute = 0;
                    }

                    // We can imagine that some will try to set it to "19:00 am"
                    if (current.contains ("a") || hour >= 12) {
                        time = time.add_hours (hour - time.get_hour ());
                    } else {
                        time = time.add_hours (hour + 12 - time.get_hour ());
                    }

                    if (current.contains ("a") && hour == 12) {
                        time = time.add_hours (-12);
                    }

                    time = time.add_minutes (minute - time.get_minute ());
                    has_suffix = true;
                }
            }
        }

        if (is_hours == false && is_suffix == false && current != "") {
            minute = int.parse (current);
        }

        if (hour == null) {
            if (current.length < 3) {
                hour = int.parse (current);
                minute = 0;
            } else if (current.length == 4) {
                hour = int.parse (current.slice (0, 2));
                minute = int.parse (current.slice (2,4));
                if (hour > 23 || minute > 59) {
                    hour = null;
                    minute = null;
                }
            }
        }

        if (hour == null || minute == null) {
            update_text ();
            return;
        }

        if (has_suffix == false) {
            time = time.add_hours (hour - time.get_hour ());
            time = time.add_minutes (minute - time.get_minute ());
        }

        update_text ();
    }
}
