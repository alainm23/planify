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

public class Widgets.Popovers.ProjectListMenu : Gtk.Popover {
    public ProjectListMenu (Gtk.Widget relative) {
        Object (
            relative_to: relative,
            modal: true,
            position: Gtk.PositionType.TOP
        );
    }

    construct {
        var import_menu = new Widgets.ModelButton (_("Import"), "document-import-symbolic", _("Import project"));
        
        var main_grid = new Gtk.Grid ();
        main_grid.margin_top = 6;
        main_grid.margin_bottom = 6;
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.width_request = 200;

        main_grid.add (import_menu);

        add (main_grid);

        import_menu.clicked.connect (() => {
            var chooser = new Gtk.FileChooserDialog (_("Export Project"), null, Gtk.FileChooserAction.OPEN);
            chooser.add_button ("_Cancel", Gtk.ResponseType.CANCEL);
            chooser.add_button ("_Open", Gtk.ResponseType.ACCEPT);
            chooser.set_do_overwrite_confirmation (true);

            var filter = new Gtk.FileFilter ();
            filter.set_filter_name (_("Planner files"));
            filter.add_pattern ("*.planner");
            chooser.add_filter (filter);

            if (chooser.run () == Gtk.ResponseType.ACCEPT) {
                popdown ();
                var file = chooser.get_file ();

                Application.share.import_project (file.get_path ());
            }

            chooser.destroy();
        });
    }
}
