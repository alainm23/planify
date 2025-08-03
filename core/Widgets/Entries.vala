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

public class Widgets.Entry : Gtk.Entry {
    private Gee.HashMap<ulong, GLib.Object> signal_map = new Gee.HashMap<ulong, GLib.Object> ();

    construct {
        signal_map[realize.connect (() => {
            if (has_focus) {
                handle_focus_in ();
            }
        })] = this;

        signal_map[notify["has-focus"].connect (() => {
            if (has_focus) {
                handle_focus_in ();
            } else {
                update_on_leave ();
            }
        })] = this;

        var gesture = new Gtk.EventControllerFocus ();
        add_controller (gesture);

        signal_map[gesture.enter.connect (handle_focus_in)] = gesture;
        signal_map[gesture.leave.connect (update_on_leave)] = gesture;
        signal_map[changed.connect (handle_focus_in)] = this;

        destroy.connect (() => {
            foreach (var entry in signal_map.entries) {
                entry.value.disconnect (entry.key);
            }

            signal_map.clear ();
        });
    }

    private void handle_focus_in () {
        Services.EventBus.get_default ().disconnect_typing_accel ();
    }

    public void update_on_leave () {
        Services.EventBus.get_default ().connect_typing_accel ();
    }
}

public class Widgets.TextView : Gtk.TextView {
    private Gee.HashMap<ulong, GLib.Object> signal_map = new Gee.HashMap<ulong, GLib.Object> ();

    private Gtk.Label placeholder_label;
    private Gtk.Overlay overlay;

    public string placeholder_text {
        get {
            return placeholder_label.label;
        }

        set {
            placeholder_label.label = value;
        }
    }

    public signal void enter ();
    public signal void leave ();

    public bool event_focus { get; set; default = true; }

    construct {
        overlay = new Gtk.Overlay ();
        overlay.child = this;

        placeholder_label = new Gtk.Label ("") {
            halign = Gtk.Align.START,
            valign = Gtk.Align.START,
            sensitive = false
        };

        overlay.add_overlay (placeholder_label);

        signal_map[realize.connect (() => {
            if (has_focus)handle_focus_in ();
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

        signal_map[buffer.changed.connect (update_placeholder_visibility)] = buffer;

        signal_map[notify["left-margin"].connect_after (() => {
            placeholder_label.margin_start = left_margin;
        })] = this;

        signal_map[notify["top-margin"].connect_after (() => {
            placeholder_label.margin_top = top_margin;
        })] = this;

        destroy.connect (() => {
            foreach (var entry in signal_map.entries) {
                entry.value.disconnect (entry.key);
            }
            signal_map.clear ();
        });
    }

    private void handle_focus_in () {
        if (event_focus) {
            Services.EventBus.get_default ().disconnect_typing_accel ();
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
        placeholder_label.visible = buffer.text.strip () == "";
    }

    public Gtk.Widget get_widget () {
        return overlay;
    }
}

public class Widgets.HyperTextView : Granite.HyperTextView {
    private Gtk.Label placeholder_label;
    private Gtk.Overlay overlay;

    private Gee.HashMap<ulong, GLib.Object> signal_map = new Gee.HashMap<ulong, GLib.Object> ();
    private uint changed_timeout_id { get; set; default = 0; }

    public string placeholder_text {
        get {
            return placeholder_label.label;
        }

        set {
            placeholder_label.label = value;
        }
    }

    public signal void changed ();
    public signal void enter ();
    public signal void leave ();

    public bool is_valid {
        get {
            return get_text () != "";
        }
    }

    public bool event_focus { get; set; default = true; }

    construct {
        overlay = new Gtk.Overlay ();
        overlay.child = this;

        placeholder_label = new Gtk.Label ("") {
            halign = Gtk.Align.START,
            valign = Gtk.Align.START,
            sensitive = false
        };

        overlay.add_overlay (placeholder_label);

        signal_map[buffer.changed.connect (() => {
            changed_timeout ();
            update_placeholder_visibility ();
        })] = buffer;

        var gesture = new Gtk.EventControllerFocus ();
        add_controller (gesture);

        signal_map[gesture.enter.connect (() => {
            handle_focus_in ();
            update_placeholder_visibility ();
        })] = gesture;

        signal_map[gesture.leave.connect (() => {
            update_on_leave ();
            update_placeholder_visibility ();
        })] = gesture;

        signal_map[notify["left-margin"].connect_after (() => {
            placeholder_label.margin_start = left_margin;
        })] = this;

        signal_map[notify["top-margin"].connect_after (() => {
            placeholder_label.margin_top = top_margin;
        })] = this;

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

        enter ();
    }

    public void update_on_leave () {
        if (event_focus) {
            Services.EventBus.get_default ().connect_typing_accel ();
        }

        leave ();
    }

    private string buffer_get_text () {
        Gtk.TextIter start;
        Gtk.TextIter end;

        buffer.get_start_iter (out start);
        buffer.get_end_iter (out end);

        return buffer.get_text (start, end, true);
    }

    private void update_placeholder_visibility () {
        placeholder_label.visible = buffer_get_text ().strip () == "" && !has_focus;
    }

    public void set_text (string text) {
        buffer.text = text;
        update_placeholder_visibility ();
    }

    public string get_text () {
        return buffer_get_text ().strip ();
    }

    private void changed_timeout () {
        handle_focus_in ();

        if (changed_timeout_id != 0) {
            GLib.Source.remove (changed_timeout_id);
            changed_timeout_id = 0;
        }

        changed_timeout_id = Timeout.add (Constants.UPDATE_TIMEOUT, () => {
            changed_timeout_id = 0;
            changed ();
            return GLib.Source.REMOVE;
        });
    }

    public Gtk.Widget get_widget () {
        return overlay;
    }
}

