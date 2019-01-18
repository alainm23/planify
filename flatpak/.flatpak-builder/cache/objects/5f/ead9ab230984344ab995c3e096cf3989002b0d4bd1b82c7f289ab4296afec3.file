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

public class Widgets.Popovers.DeadlinePopover : Gtk.Popover {
    public signal void selection_changed (GLib.DateTime date);
    public signal void selection_double_changed (GLib.DateTime date);
    public signal void clear ();
    public DeadlinePopover (Gtk.Widget relative) {
        Object (
            relative_to: relative,
            modal: true,
            position: Gtk.PositionType.BOTTOM
        );
    }

    construct {
        var title_label = new Gtk.Label ("<small>%s</small>".printf (_("Deadline")));
        title_label.use_markup = true;
        title_label.hexpand = true;
        title_label.halign = Gtk.Align.CENTER;
        title_label.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);

        var calendar = new Widgets.Calendar.Calendar (true);

        var clear_button = new Gtk.Button.with_label (_("Clear"));
        clear_button.margin = 6;
        clear_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);

        var main_grid = new Gtk.Grid ();
        main_grid.expand = true;
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.width_request = 250;

        main_grid.add (title_label);
        main_grid.add (calendar);
        main_grid.add (clear_button);

        add (main_grid);

        calendar.selection_changed.connect ((date) => {
            selection_changed (date);
        });

        calendar.selection_double_changed.connect ((date) => {
            selection_double_changed (date);
            popdown ();
        });

        clear_button.clicked.connect (() => {
            clear ();
            popdown ();
        });
    }
}
