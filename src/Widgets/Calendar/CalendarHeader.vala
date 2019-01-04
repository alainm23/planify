/*
* Copyright © 2019 Alain M. (https://github.com/alainm23/planner)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
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
* Authored by: Alain M. <alain23@protonmail.com>
*/

public class Widgets.Calendar.CalendarHeader : Gtk.Box {
    private Gtk.Button left_button;
    private Gtk.Button right_button;
    private Gtk.Button center_button;

    public signal void left_clicked ();
    public signal void right_clicked ();
    public signal void center_clicked ();

    public GLib.DateTime date {
        set {
            center_button.label = value.format (_("%OB %Y"));
        }
    }

    public CalendarHeader () {
        orientation = Gtk.Orientation.HORIZONTAL;
        margin_bottom = 4;
        get_style_context ().add_class ("linked");
        set_size_request (-1, 30);
    }

    construct {
        center_button = new Gtk.Button.with_label (new GLib.DateTime.now_local ().format (_("%OB %Y")));
        center_button.can_focus = false;

        left_button = new Gtk.Button.from_icon_name ("pan-start-symbolic", Gtk.IconSize.MENU);
        left_button.can_focus = false;

        right_button = new Gtk.Button.from_icon_name ("pan-end-symbolic", Gtk.IconSize.MENU);
        right_button.can_focus = false;

        add (left_button);
        pack_end (right_button, false, false, 0);
        pack_end (center_button, true, true, 0);

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
