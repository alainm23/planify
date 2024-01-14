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

public class Widgets.Calendar.CalendarDay : Adw.Bin {
    public int day {
        set {
            label.label = value.to_string ();
        }
        get {
            return int.parse (label.label);
        }
    }

    private Gtk.Label label;
    public signal void day_selected (int day);

    public CalendarDay () {
        Object (
            halign: Gtk.Align.CENTER,
            valign: Gtk.Align.CENTER
        );
    }

    construct {
        label = new Gtk.Label (null) {
            height_request = 16,
            width_request = 16,
            margin_top = 3,
            margin_start = 3,
            margin_end = 3,
            margin_bottom = 3
        };

        var image = new Gtk.Image ();
        image.gicon = new ThemedIcon ("mail-unread-symbolic");
        image.pixel_size = 6;

        var main_grid = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            halign = Gtk.Align.CENTER,
            valign = Gtk.Align.CENTER
        };

        main_grid.append (label);

        child = main_grid;

        var gesture = new Gtk.GestureClick ();
        gesture.set_button (1);
        add_controller (gesture);

        gesture.pressed.connect (() => {
            day_selected (int.parse (label.label));
            add_css_class ("calendar-day-selected");
        });
    }
}
