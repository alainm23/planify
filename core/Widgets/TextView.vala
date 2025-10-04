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

public class Widgets.TextView : Gtk.TextView {
    private Gee.HashMap<ulong, GLib.Object> signal_map = new Gee.HashMap<ulong, GLib.Object> ();

    private bool showing_placeholder = false;

    public string placeholder_text { get; set; default = ""; }
    public signal void enter ();
    public signal void leave ();

    public bool event_focus { get; set; default = true; }

    construct {
        signal_map[realize.connect (() => {
            if (has_focus) {
                handle_focus_in ();
            }

            update_placeholder_visibility ();
        })] = this;

        signal_map[notify["has-focus"].connect (() => {
            if (has_focus) {
                handle_focus_in ();
            } else {
                update_on_leave ();
            }

            update_placeholder_visibility ();
        })] = this;

        var gesture = new Gtk.EventControllerFocus ();
        add_controller (gesture);
        signal_map[gesture.enter.connect (handle_focus_in)] = gesture;
        signal_map[gesture.leave.connect (() => {
            update_on_leave ();
            update_placeholder_visibility ();
        })] = gesture;

        destroy.connect (() => {
            foreach (var entry in signal_map.entries) {
                entry.value.disconnect (entry.key);
            }
            signal_map.clear ();
        });

        update_placeholder_visibility ();
    }

    private void handle_focus_in () {
        if (event_focus) {
            Services.EventBus.get_default ().disconnect_typing_accel ();
        }

        if (showing_placeholder) {
            buffer.text = "";
            opacity = 1;
            showing_placeholder = false;
        }
        enter ();
    }

    public void update_on_leave () {
        if (event_focus) {
            Services.EventBus.get_default ().connect_typing_accel ();
        }
        leave ();
    }

    private void update_placeholder_visibility () {
        if (!has_focus && buffer.text.strip () == "" && placeholder_text != "") {
            showing_placeholder = true;
            buffer.text = placeholder_text;
            opacity = 0.5;
        } else if (showing_placeholder && has_focus) {
            buffer.text = "";
            opacity = 1;
            showing_placeholder = false;
        }
    }

    public string get_text () {
        if (showing_placeholder) {
            return "";
        }

        Gtk.TextIter start;
        Gtk.TextIter end;
        buffer.get_start_iter (out start);
        buffer.get_end_iter (out end);
        return buffer.get_text (start, end, true).strip ();
    }

    public void set_text (string text) {
        buffer.text = text;
        showing_placeholder = false;
        opacity = 1;
        update_placeholder_visibility ();
    }
}


