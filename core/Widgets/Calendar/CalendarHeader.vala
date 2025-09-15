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

    public CalendarHeader () {
        Object (
            hexpand: true,
            orientation: Gtk.Orientation.HORIZONTAL,
            valign: Gtk.Align.CENTER
        );
    }

    ~CalendarHeader () {
        debug ("Destroying - Widgets.Calendar.CalendarHeader\n");
    }

    construct {
        month_label = new Gtk.Label (new GLib.DateTime.now_local ().format (_("%OB")));
        month_label.add_css_class ("font-bold");

        year_label = new Gtk.Label (new GLib.DateTime.now_local ().format (_("%Y")));
        year_label.add_css_class ("font-bold");
        year_label.add_css_class ("primary-color");

        left_button = new Gtk.Button.from_icon_name ("pan-start-symbolic") {
            valign = Gtk.Align.CENTER,
            css_classes = { "flat" },
            tooltip_text = _("Back")
        };

        right_button = new Gtk.Button.from_icon_name ("pan-end-symbolic") {
            valign = Gtk.Align.CENTER,
            css_classes = { "flat" },
            tooltip_text = _("Forward")
        };

        var date_grid = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        date_grid.append (month_label);
        date_grid.append (year_label);

        center_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            hexpand = true,
            tooltip_text = _("Today")
        };

        center_button.add_css_class ("flat");
        center_button.can_focus = false;
        center_button.child = date_grid;

        append (center_button);
        append (left_button);
        append (right_button);

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
