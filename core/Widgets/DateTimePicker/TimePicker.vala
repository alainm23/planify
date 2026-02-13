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

public class Widgets.DateTimePicker.TimePicker : Adw.Bin {
    private Gtk.Entry time_entry;

    public string format_12 { get; construct; }
    public string format_24 { get; construct; }

    private GLib.DateTime _time = null;
    public GLib.DateTime time {
        get {
            if (_time == null) {
                time = new GLib.DateTime.now_local ().add_minutes (10);
            }

            return _time;
        }

        set {
            _time = value;
            update_text (true);
        }
    }

    private string old_string = "";

    public signal void time_changed ();
    public signal void activated ();

    private Gee.HashMap<ulong, weak GLib.Object> signal_map = new Gee.HashMap<ulong, weak GLib.Object> ();
    
    ~TimePicker () {
        debug ("Destroying - Widgets.DateTimePicker.TimePicker\n");
    }

    construct {
        if (format_12 == null) {
            format_12 = Utils.Datetime.get_default_time_format (true);
        }

        if (format_24 == null) {
            format_24 = Utils.Datetime.get_default_time_format (false);
        }

        time_entry = new Gtk.Entry () {
            max_width_chars = 9,
            hexpand = true
        };

        child = time_entry;
        update_text ();

        // Connecting to events allowing manual changes
        var focus_controller = new Gtk.EventControllerFocus ();
        var scroll_controller = new Gtk.EventControllerScroll (
            Gtk.EventControllerScrollFlags.BOTH_AXES |
            Gtk.EventControllerScrollFlags.DISCRETE
        );

        time_entry.add_controller (focus_controller);
        time_entry.add_controller (scroll_controller);

        signal_map[focus_controller.leave.connect (() => {
            is_unfocused ();
        })] = focus_controller;

        signal_map[scroll_controller.scroll.connect ((dx, dy) => {
            double largest = dx.abs () > dy.abs () ? dx : dy;
            if (largest < 0) {
                _time = _time.add_minutes (1);
            } else {
                _time = _time.add_minutes (-1);
            }

            update_text ();
            return false;
        })] = scroll_controller;

        signal_map[time_entry.activate.connect (() => {
            is_unfocused ();
            activated ();
        })] = time_entry;
    }

    private void is_unfocused () {
        if (old_string.collate (time_entry.text) != 0) {
            old_string = time_entry.text;
            parse_time (time_entry.text.dup ());
        }
    }

    private void parse_time (string timestr) {
        string current = "";
        bool is_hours = true;
        bool is_suffix = false;
        bool has_suffix = false;

        int ? hour = null;
        int ? minute = null;
        foreach (var c in timestr.down ().to_utf8 ()) {
            if (c.isdigit ()) {
                current = "%s%c".printf (current, c);
            } else {
                if (!is_suffix) {
                    if (current != "") {
                        if (is_hours) {
                            is_hours = false;
                            hour = int.parse (current);
                            current = "";
                        } else {
                            minute = int.parse (current);
                            current = "";
                        }
                    }

                    if (c.to_string ().contains ("a") || c.to_string ().contains ("p")) {
                        is_suffix = true;
                        current = "%s%c".printf (current, c);
                    }
                }

                if (c.to_string ().contains ("m") && is_suffix) {
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
                minute = int.parse (current.slice (2, 4));
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

    private void update_text (bool no_signal = false) {
        if (Utils.Datetime.is_clock_format_12h ()) {
            time_entry.set_text (time.format (format_12));
        } else {
            time_entry.set_text (time.format (format_24));
        }

        old_string = time_entry.text;

        if (no_signal == false) {
            time_changed ();
        }
    }

    public void reset () {
        _time = null;
        update_text ();
    }

    public void clean_up () {
        foreach (var entry in signal_map.entries) {
            entry.value.disconnect (entry.key);
        }

        signal_map.clear ();
    }

    public void grab_entry_focus () {
        time_entry.grab_focus ();
    }
}
