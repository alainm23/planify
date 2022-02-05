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

public class Widgets.Calendar.CalendarHeader : Gtk.Box {
    private Gtk.Label month_label;
    private Gtk.Label year_label;
    private Gtk.Button left_button;
    private Gtk.Button right_button;
    private Gtk.Button center_button;

    public signal void left_clicked ();
    public signal void right_clicked ();
    public signal void center_clicked ();

    public GLib.DateTime date {
        set {
            month_label.label = value.format (_("%OB"));
            year_label.label = value.format (_("%Y"));
        }
    }

    construct {
        orientation = Gtk.Orientation.HORIZONTAL;
        valign = Gtk.Align.CENTER;
        
        month_label = new Gtk.Label (new GLib.DateTime.now_local ().format (_("%OB")));
        month_label.get_style_context ().add_class ("font-bold");
        
        year_label = new Gtk.Label (new GLib.DateTime.now_local ().format (_("%Y")));
        year_label.get_style_context ().add_class ("font-bold");
        year_label.get_style_context ().add_class ("primary-color");

        var chevron_left_image = new Widgets.DynamicIcon ();
        chevron_left_image.size = 19;
        chevron_left_image.update_icon_name ("chevron-left");
        
        left_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            can_focus = false
        };

        left_button.add (chevron_left_image);
        left_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        left_button.get_style_context ().add_class ("no-padding");

        var chevron_right_image = new Widgets.DynamicIcon ();
        chevron_right_image.size = 19;
        chevron_right_image.update_icon_name ("chevron-right");

        right_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            can_focus = false
        };

        right_button.add (chevron_right_image);
        right_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        right_button.get_style_context ().add_class ("no-padding");

        var date_grid = new Gtk.Grid () {
            column_spacing = 6
        };
        date_grid.add (month_label);
        date_grid.add (year_label);

        center_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER
        };
        center_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        center_button.can_focus = false;
        center_button.add (date_grid);

        pack_start (center_button, false, false, 0);
        pack_end (right_button, false, false, 6);
        pack_end (left_button, false, false, 0);
        
        left_button.clicked.connect (() => {
            left_clicked ();
        });

        right_button.clicked.connect (() => {
            right_clicked ();
        });

        center_button.clicked.connect (() => {
            center_clicked ();
        });
    }
}
