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

public class Widgets.NoteChild : Gtk.FlowBoxChild {
    private Gtk.SourceView source_view;

    public NoteChild () {
        /*
        Object (
            label: _label
        );
        */
    }

    construct {
        can_focus = false;

        source_view = new Gtk.SourceView ();
        source_view.margin = 6;
        source_view.expand = true;

        var main_grid = new Gtk.Grid ();
        main_grid.get_style_context ().add_class (Granite.STYLE_CLASS_CARD);
        main_grid.expand = true;
        main_grid.add (source_view);

        add (main_grid);
    }
}
