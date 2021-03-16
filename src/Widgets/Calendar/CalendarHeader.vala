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
        margin_start = 3;
        margin_end = 3;
        orientation = Gtk.Orientation.HORIZONTAL;
        valign = Gtk.Align.CENTER;
        
        month_label = new Gtk.Label (new GLib.DateTime.now_local ().format (_("%OB")));
        month_label.get_style_context ().add_class ("font-bold");
        
        year_label = new Gtk.Label (new GLib.DateTime.now_local ().format (_("%Y")));
        year_label.get_style_context ().add_class ("font-bold");
        year_label.get_style_context ().add_class ("inbox");

        left_button = new Gtk.Button.from_icon_name ("pan-start-symbolic", Gtk.IconSize.MENU);
        left_button.can_focus = false;
        left_button.get_style_context ().add_class ("flat");
        left_button.get_style_context ().add_class ("no-padding-left");
        
        right_button = new Gtk.Button.from_icon_name ("pan-end-symbolic", Gtk.IconSize.MENU);
        right_button.can_focus = false;
        right_button.get_style_context ().add_class ("flat");

        var date_grid = new Gtk.Grid ();
        date_grid.column_spacing = 6;
        date_grid.add (month_label);
        date_grid.add (year_label);

        center_button = new Gtk.Button ();
        center_button.get_style_context ().add_class ("flat");
        center_button.get_style_context ().add_class ("calendar-header");
        center_button.can_focus = false;
        center_button.add (date_grid);

        pack_start (left_button, false, false, 0);
        set_center_widget (center_button);
        pack_end (right_button, false, false, 0);
        
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
