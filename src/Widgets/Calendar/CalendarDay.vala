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

public class Widgets.Calendar.CalendarDay : Gtk.EventBox {
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

    construct {
        label = new Gtk.Label (null);
        label.height_request = 16;
        label.width_request = 16;

        var image = new Gtk.Image ();
        image.gicon = new ThemedIcon ("mail-unread-symbolic");
        image.pixel_size = 6;

        var main_grid = new Gtk.Grid ();
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.margin = 3;
        main_grid.halign = Gtk.Align.CENTER;
        main_grid.valign = Gtk.Align.CENTER;
        main_grid.add (label);

        add (main_grid);

        event.connect ((event) => {
            if (event.type == Gdk.EventType.BUTTON_PRESS) {
                day_selected (int.parse (label.label));
                get_style_context ().add_class ("calendar-day-selected");
            }

            return false;
        });
    }
}
