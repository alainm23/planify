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
    private Gtk.Label date_label;
    private Gtk.Button left_button;
    private Gtk.Button right_button;
    private Gtk.Button center_button;

    public signal void left_clicked ();
    public signal void right_clicked ();
    public signal void center_clicked ();

    public GLib.DateTime date {
        set {
            date_label.label = value.format (_("%OB, %Y"));
        }
    }

    construct {
        margin_start = 3;
        margin_end = 3;
        orientation = Gtk.Orientation.HORIZONTAL;

        date_label = new Gtk.Label (new GLib.DateTime.now_local ().format (_("%OB %Y")));
        date_label.get_style_context ().add_class ("font-bold");

        center_button = new Gtk.Button.from_icon_name ("mail-unread-symbolic", Gtk.IconSize.MENU);
        center_button.get_style_context ().add_class ("flat");
        center_button.can_focus = false;

        left_button = new Gtk.Button.from_icon_name ("pan-start-symbolic", Gtk.IconSize.MENU);
        left_button.get_style_context ().add_class ("flat");
        left_button.can_focus = false;

        right_button = new Gtk.Button.from_icon_name ("pan-end-symbolic", Gtk.IconSize.MENU);
        right_button.get_style_context ().add_class ("flat");
        right_button.get_style_context ().add_class ("no-padding-right");
        right_button.can_focus = false;

        pack_start (date_label, false, false, 0);
        pack_end (right_button, false, false, 0);
        pack_end (center_button, false, false, 0);
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
