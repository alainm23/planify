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

    public bool active {
        set {
            checked_button.active = value;
        }
    }

    private Gtk.CheckButton checked_button;
    public signal void checked_toggled (Objects.Label label, bool active);

    public LabelRow (Objects.Label label) {
        Object (
            label: label
        );
    }

    construct {
        add_css_class ("selectable-item");

        checked_button = new Gtk.CheckButton () {
            valign = Gtk.Align.CENTER,
            css_classes = { "checkbutton-label", "priority-color" }
        };
        Util.get_default ().set_widget_priority (Constants.PRIORITY_4, checked_button);

        var name_label = new Gtk.Label (label.name) {
            valign = Gtk.Align.CENTER,
        };
        
        var color_grid = new Gtk.Grid () {
			width_request = 3,
			height_request = 16,
            margin_top = 0,
			valign = Gtk.Align.CENTER,
			css_classes = { "event-bar" }
		};
        Util.get_default ().set_widget_color (Util.get_default ().get_color (label.color), color_grid);

        var content_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            margin_top = 3,
            margin_start = 6,
            margin_end = 6,
            margin_bottom = 3
        };

        content_box.append (checked_button);
        content_box.append (color_grid);
        content_box.append (name_label);

        child = content_box;

        var checked_button_gesture = new Gtk.GestureClick ();
        checked_button_gesture.set_button (1);
        checked_button.add_controller (checked_button_gesture);

        checked_button_gesture.pressed.connect (() => {
            checked_button_gesture.set_state (Gtk.EventSequenceState.CLAIMED);
            update_checked_toggled ();
        });
    }

    public void update_checked_toggled () {
        checked_button.active = !checked_button.active;
        checked_toggled (label, checked_button.active);
    }
}