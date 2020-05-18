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

public class Services.LabelsController : GLib.Object {
    construct {
        Planner.database.opened.connect (this.init);
    }

    private void init () {
        foreach (Objects.Label label in Planner.database.get_all_labels ()) {
            apply_styles (label.id, Planner.utils.get_color (label.color), label.color);
        }
    }

    private void apply_styles (int64 id, string color_hex, int color) {
        string color_css = """
            .label-preview-%s {
                background-color: alpha (%s, 0.25);
                color: @text_color;
                padding: 0px 3px 1px 3px;
                border-radius: 4px;
                font-size: 6pt;
                font-weight: 700;
                border: 1px solid shade (%s, 0.95)
            }

            .label-item-%s {
                color: %s;
            }

            .label-%s {
                color: %s
            }

            .label-color-%s {
                color: %s
            }
        """;

        var provider = new Gtk.CssProvider ();

        try {
            var colored_css = color_css.printf (
                // Label preview
                id.to_string (),
                color_hex,
                color_hex,
                // Label Item
                id.to_string (),
                color_hex,
                // Label Row
                id.to_string (),
                color_hex,
                // Label Color By Number
                color.to_string (),
                color_hex
            );

            provider.load_from_data (colored_css, colored_css.length);

            Gtk.StyleContext.add_provider_for_screen (
                Gdk.Screen.get_default (), provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            );
        } catch (GLib.Error e) {
            return;
        }
    }

    public void add_label (Objects.Label label) {
        apply_styles (label.id, Planner.utils.get_color (label.color), label.color);
    }

    public void update_label (Objects.Label label) {
        apply_styles (label.id, Planner.utils.get_color (label.color), label.color);
    }
}
