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

public class Widgets.Popovers.SearchPopover : Gtk.Popover {
    public signal void search_changed (string text);

    private Gtk.SearchEntry search_entry;
    public SearchPopover (Gtk.Widget relative) {
        Object (
            relative_to: relative,
            modal: true,
            position: Gtk.PositionType.BOTTOM
        );
    }

    construct {
        var search_label = new Gtk.Label (_("Search"));
        search_label.margin_start = 6;

        search_entry = new Gtk.SearchEntry ();
        search_entry.width_request = 220;

        var main_grid = new Gtk.Grid ();
        main_grid.column_spacing = 12;
        main_grid.margin = 6;

        main_grid.add (search_label);
        main_grid.add (search_entry);

        add (main_grid);

        search_entry.search_changed.connect (() => {
            search_changed (search_entry.text);
        });
    }
}
