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

public class Widgets.ColorPopover : Gtk.Popover {
    public string selected { get; set; }

    public signal void color_changed (string color);

    private Gee.HashMap <string, Gtk.RadioButton> colors_hashmap;
    private Gtk.FlowBox flowbox;
    
    construct {
        var radio = new Gtk.RadioButton (null);
        colors_hashmap = new Gee.HashMap <string, Gtk.RadioButton> ();

        flowbox = new Gtk.FlowBox () {
            column_spacing = 9,
            row_spacing = 9,
            border_width = 9,
            max_children_per_line = 7,
            min_children_per_line = 7,
            expand = true
        };

        unowned Gtk.StyleContext flowbox_context = flowbox.get_style_context ();
        flowbox_context.add_class ("flowbox-color");

        foreach (var entry in Util.get_default ().get_colors ().entries) {
            if (!entry.key.has_prefix ("#")) {
                Gtk.RadioButton color_radio = new Gtk.RadioButton (radio.get_group ());
                color_radio.valign = Gtk.Align.START;
                color_radio.halign = Gtk.Align.START;
                color_radio.tooltip_text = Util.get_default ().get_color_name (entry.key);
                color_radio.get_style_context ().add_class ("color-radio");
                Util.get_default ().set_widget_color (Util.get_default ().get_color (entry.key), color_radio);
                colors_hashmap [entry.key] = color_radio;
                flowbox.add (colors_hashmap [entry.key]);
    
                color_radio.toggled.connect (() => {
                    selected = entry.key;
                    color_changed (selected);
                });
            }
        }

        var popover_grid = new Gtk.Grid ();
        popover_grid.add (flowbox);
        popover_grid.show_all ();

        add (popover_grid);

        notify["selected"].connect (() => {
            if (colors_hashmap.has_key (selected)) {
                colors_hashmap [selected].active = true;
            }
        });
    }
}
