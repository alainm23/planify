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
        add_css_class ("row");

        checked_button = new Gtk.CheckButton () {
            can_focus = false,
            valign = Gtk.Align.CENTER,
            label = label.name,
            hexpand = true
        };

        checked_button.add_css_class ("priority-color");
        Util.get_default ().set_widget_priority (Constants.PRIORITY_4, checked_button);

        var main_grid = new Gtk.Grid () {
            column_spacing = 6,
            margin_top = 3,
            margin_start = 3,
            margin_end = 3,
            margin_bottom = 3
        };

        main_grid.attach (checked_button, 0, 0);

        child = main_grid;

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