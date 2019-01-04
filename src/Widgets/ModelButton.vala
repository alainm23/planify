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

public class Widgets.ModelButton : Gtk.Button {
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
