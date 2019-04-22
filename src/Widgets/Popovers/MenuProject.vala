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

public class Widgets.Popovers.MenuProject : Gtk.Popover {
    public signal void on_selected_menu (string name);

    public MenuProject (Gtk.Widget relative) {
        Object (
            relative_to: relative,
            modal: true,
            position: Gtk.PositionType.RIGHT
        );
    }

    construct {
        var finalize_menu = new ModelButton (_("Mark as Completed"), "emblem-default-symbolic", _("Finalize project"));
        
        var edit_menu = new ModelButton (_("Edit"), "edit-symbolic", _("Change project name"));
        var favorite_menu = new ModelButton (_("Favorite"), "emblem-favorite-symbolic", _("Favorite"));

        var export_menu = new ModelButton (_("Export"), "document-export-symbolic", _("Export project"));
        var share_menu = new ModelButton (_("Share"), "emblem-shared-symbolic", _("Share project"));

        var remove_menu = new ModelButton (_("Delete"), "user-trash-symbolic", _("Delete project"));
        var archived_menu = new ModelButton (_("Archived"), "package-x-generic-symbolic", _("Delete project"));

        var separator_1 = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator_1.margin_top = 3;
        separator_1.margin_bottom = 3;
        separator_1.expand = true;

        var separator_2 = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator_2.margin_top = 3;
        separator_2.margin_bottom = 3;
        separator_2.expand = true;

        var separator_3 = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator_3.margin_top = 3;
        separator_3.margin_bottom = 3;
        separator_3.expand = true;

        var main_grid = new Gtk.Grid ();
        main_grid.margin_top = 6;
        main_grid.margin_bottom = 6;
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.width_request = 200;

        main_grid.add (finalize_menu);
        main_grid.add (separator_1);
        main_grid.add (edit_menu);
        main_grid.add (favorite_menu);
        main_grid.add (separator_2);
        main_grid.add (export_menu);
        main_grid.add (share_menu);
        main_grid.add (separator_3);
        main_grid.add (archived_menu);
        main_grid.add (remove_menu);
        
        add (main_grid);

        // Event
        finalize_menu.clicked.connect (() => {
            popdown ();
            on_selected_menu ("finalize");
        });

        edit_menu.clicked.connect (() => {
            popdown ();
            on_selected_menu ("edit");
        });

        favorite_menu.clicked.connect (() => {
            popdown ();
            on_selected_menu ("favorite");
        });

        share_menu.clicked.connect (() => {
            popdown ();
            on_selected_menu ("share");
        });

        remove_menu.clicked.connect (() => {
            popdown ();
            on_selected_menu ("remove");
        });

        export_menu.clicked.connect (() => {
            popdown ();
            on_selected_menu ("export");
        });

        archived_menu.clicked.connect (() => {
            popdown ();
            on_selected_menu ("archived");
        });
    }
}

public class ModelButton : Gtk.Button {
    public string icon { get; construct; }
    public string text { get; construct; }
    public string tooltip { get; construct; }

    public ModelButton (string _text, string _icon, string _tooltip) {
        Object (
            icon: _icon,
            text: _text,
            tooltip: _tooltip,
            expand: true
        );
    }

    construct {
        get_style_context ().remove_class ("button");
        get_style_context ().add_class ("menuitem");

        tooltip_text = tooltip;
        var label = new Gtk.Label (text);
        var image = new Gtk.Image.from_icon_name (icon, Gtk.IconSize.SMALL_TOOLBAR);

        var grid = new Gtk.Grid ();
        grid.column_spacing = 6;
        grid.add (image);
        grid.add (label);

        add (grid);
    }
}
