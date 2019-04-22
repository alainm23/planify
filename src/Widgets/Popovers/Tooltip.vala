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

public class Widgets.Popovers.Tooltip : Gtk.Popover {
    private Gtk.Label message_label;
    private Gtk.Image icon;

    public string message {
        set {
            message_label.label = "<i>%s</i>".printf (value);
        }
        get {
            return message_label.label;
        }
    }

    public string icon_name {
        set {
            icon.gicon = new ThemedIcon (value);
        }
    }

    public Tooltip (Gtk.Widget relative, string _message, string _icon) {
        Object (
            relative_to: relative,
            message: _message,
            icon_name: _icon,
            position: Gtk.PositionType.BOTTOM
        );
    }

    construct {
        message_label = new Gtk.Label (null);
        message_label.use_markup = true;
        message_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        icon = new Gtk.Image ();
        icon.pixel_size = 13;

        var main_grid = new Gtk.Grid ();
        main_grid.column_spacing = 6;
        main_grid.margin = 6;
        /*
        main_grid.margin_start = 6;
        main_grid.margin_end = 6;
        main_grid.margin_top = 3;
        main_grid.margin_bottom = 3;
        */
        main_grid.add (icon);
        main_grid.add (message_label);

        add (main_grid);
    }

    public void show_tooltip () {
        Timeout.add (250, () => {
            show_all ();
            return false;
        });

        Timeout.add (2500, () => {
            popdown ();
            return false;
        });
    }
}