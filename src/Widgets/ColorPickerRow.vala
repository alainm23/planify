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

public class Widgets.ColorPickerRow : Gtk.Grid {
    public string color { get; set; }

    public signal void color_changed (string color);

    private Gee.HashMap<string, Gtk.CheckButton> colors_hashmap;
    private Gee.HashMap<ulong, weak GLib.Object> signal_map = new Gee.HashMap<ulong, weak GLib.Object> ();

    public ColorPickerRow () {
        Object (

        );
    }

    ~ColorPickerRow () {
        debug ("Destroying - Widgets.ColorPickerRow\n");
    }

    construct {
        colors_hashmap = new Gee.HashMap<string, Gtk.CheckButton> ();

        var colors_flowbox = new Gtk.FlowBox () {
            column_spacing = 6,
            row_spacing = 6,
            max_children_per_line = 10,
            homogeneous = true,
            margin_top = 9,
            margin_bottom = 9,
            margin_start = 9,
            margin_end = 9,
            vexpand = true,
            hexpand = true,
            selection_mode = Gtk.SelectionMode.NONE
        };

        var colors_list = new Gee.ArrayList<Objects.Color> ();
        foreach (var entry in Util.get_default ().get_colors ().entries) {
            if (!entry.key.has_prefix ("#")) {
                colors_list.add (entry.value);
            }
        }
        
        colors_list.sort ((a, b) => {
            return a.id - b.id;
        });

        var radio = new Gtk.CheckButton ();
        foreach (Objects.Color color_obj in colors_list) {
            Gtk.CheckButton color_radio = new Gtk.CheckButton () {
                valign = Gtk.Align.CENTER,
                halign = Gtk.Align.CENTER,
                tooltip_text = color_obj.name,
                name = color_obj.name,
                css_classes = { "color-radio" },
                group = radio
            };

            Util.get_default ().set_widget_color (color_obj.hexadecimal, color_radio);
            colors_hashmap[color_obj.hexadecimal] = color_radio;
            colors_flowbox.append (colors_hashmap[color_obj.hexadecimal]);

            signal_map[color_radio.toggled.connect (() => {
                color = color_obj.hexadecimal;
                color_changed (color);
            })] = color_radio;
        }

        attach (colors_flowbox, 0, 0);

        signal_map[notify["color"].connect (() => {
            if (colors_hashmap.has_key (color)) {
                colors_hashmap[color].active = true;
            }
        })] = this;

        signal_map[colors_flowbox.child_activated.connect ((child) => {
            color = child.child.name;
            color_changed (color);
        })] = colors_flowbox;
    }

    public void clean_up () {
        foreach (var entry in signal_map.entries) {
            entry.value.disconnect (entry.key);
        }

        signal_map.clear ();
    }
}
