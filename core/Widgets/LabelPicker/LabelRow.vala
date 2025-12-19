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

public class Widgets.LabelPicker.LabelRow : Gtk.ListBoxRow {
    public Objects.Label label { get; construct; }

    private Gtk.Box content_box;
    
    private bool _hide_check_button = false;
    public bool hide_check_button {
        get { return _hide_check_button; }
        set {
            _hide_check_button = value;
            checked_button.visible = !value;
        }
    }

    public bool active {
        set {
            checked_button.active = value;
        }
    }

    public int margin {
        set {
            content_box.margin_start = value;
            content_box.margin_top = value;
            content_box.margin_end = value;
            content_box.margin_bottom = value;
        }
    }

    private Gtk.CheckButton checked_button;
    private Gtk.Revealer loading_revealer;
    public signal void checked_toggled (Objects.Label label, bool active);
    private Gee.HashMap<ulong, weak GLib.Object> signals_map = new Gee.HashMap<ulong, weak GLib.Object> ();

    public LabelRow (Objects.Label label) {
        Object (
            label: label
        );
    }

    ~LabelRow () {
        debug ("Destroying - Widgets.LabelPicker.LabelRow\n");
    }

    construct {
        add_css_class ("border-radius-6");
        add_css_class ("no-padding");

        checked_button = new Gtk.CheckButton () {
            valign = Gtk.Align.CENTER,
            css_classes = { "checkbutton-label" }
        };

        var color_grid = new Gtk.Grid () {
            width_request = 3,
            height_request = 16,
            valign = Gtk.Align.CENTER,
            css_classes = { "event-bar" }
        };
        Util.get_default ().set_widget_color (Util.get_default ().get_color (label.color), color_grid);

        var name_label = new Gtk.Label (label.name) {
            valign = Gtk.Align.CENTER,
        };

        loading_revealer = new Gtk.Revealer () {
            child = new Adw.Spinner (),
            hexpand = true,
            halign = END
        };

        content_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        content_box.append (checked_button);
        content_box.append (color_grid);
        content_box.append (name_label);
        content_box.append (loading_revealer);

        child = content_box;

        var checked_button_gesture = new Gtk.GestureClick ();
        content_box.add_controller (checked_button_gesture);
        signals_map[checked_button_gesture.pressed.connect (() => {
            checked_button_gesture.set_state (Gtk.EventSequenceState.CLAIMED);
            update_checked_toggled ();
        })] = checked_button_gesture;

        signals_map[activate.connect (() => {
            update_checked_toggled ();
        })] = this;

        signals_map[label.updated.connect (() => {
            Util.get_default ().set_widget_color (Util.get_default ().get_color (label.color), color_grid);
            name_label.label = label.name;
        })] = label;
    }

    public void update_checked_toggled () {
        checked_button.active = !checked_button.active;
        checked_toggled (label, checked_button.active);
    }

    public void show_loading (bool show) {
        loading_revealer.reveal_child = show;
    }

    public void clean_up () {
        foreach (var entry in signals_map.entries) {
            entry.value.disconnect (entry.key);
        }

        signals_map.clear ();
    }
}
