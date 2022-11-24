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

public class Widgets.Entry : Gtk.Entry {
    construct {
        var gesture = new Gtk.EventControllerFocus ();
        add_controller (gesture);

        gesture.enter.connect (handle_focus_in);
        gesture.leave.connect (update_on_leave);
    }

    private void handle_focus_in () {
        Planner.event_bus.disconnect_typing_accel ();
    }

    public void update_on_leave () {
        Planner.event_bus.connect_typing_accel ();
    }
}

public class Widgets.SourceView : Gtk.TextView/*GtkSource.View*/ {
    construct {
        var gesture = new Gtk.EventControllerFocus ();
        add_controller (gesture);

        gesture.enter.connect (handle_focus_in);
        gesture.leave.connect (update_on_leave);
    }

    private void handle_focus_in () {
        Planner.event_bus.disconnect_typing_accel ();
    }

    public void update_on_leave () {
        Planner.event_bus.connect_typing_accel ();
    }
}

public class Widgets.HyperTextView : Granite.HyperTextView {
    public string placeholder_text { get; construct; }

    private uint changed_timeout_id { get; set; default = 0; }

    public signal void updated ();

    public bool is_valid {
        get {
            return buffer_get_text () != "";
        }
    }

    public HyperTextView (string placeholder_text) {
        Object (
            placeholder_text: placeholder_text
        );
    }
 
    construct {
        var gesture = new Gtk.EventControllerFocus ();
        add_controller (gesture);

        gesture.enter.connect (handle_focus_in);
        gesture.leave.connect (update_on_leave);
    }

    private void handle_focus_in () {
        Planner.event_bus.disconnect_typing_accel ();
    }

    public void update_on_leave () {
        Planner.event_bus.connect_typing_accel ();
    }

    private string buffer_get_text () {
        Gtk.TextIter start;
        Gtk.TextIter end;

        buffer.get_start_iter (out start);
        buffer.get_end_iter (out end);

        return buffer.get_text (start, end, true);
    }

    public void set_text (string text) {
        buffer.text = text;
    }

    public string get_text () {
        return buffer_get_text ();
    }
}