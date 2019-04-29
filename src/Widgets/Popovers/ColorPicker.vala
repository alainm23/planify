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

public class Widgets.Popovers.ColorPicker : Gtk.Popover {
    public signal void color_selected (int color);

    public const string COLOR_CSS = """
        .color-%s radio {
            background: %s;
            border-color: @bg_color;
            color: %s;
        }
    """;
    public ColorPicker (Gtk.Widget relative) {
        Object (
            relative_to: relative,
            modal: true,
            position: Gtk.PositionType.BOTTOM
        );
    }

    construct {
        var title_label = new Gtk.Label ("<small>%s</small>".printf (_("Select an color")));
        title_label.use_markup = true;
        title_label.expand = true;
        title_label.halign = Gtk.Align.CENTER;
        title_label.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);

        var color_30 = new Gtk.RadioButton (null);
        color_30.valign = Gtk.Align.CENTER;
        color_30.halign = Gtk.Align.CENTER;
        apply_styles ("30", "#b8255f", color_30);

        var color_31 = new Gtk.RadioButton.from_widget (color_30);
        color_31.valign = Gtk.Align.CENTER;
        color_31.halign = Gtk.Align.CENTER;
        apply_styles ("31", "#db4035", color_31);

        var color_32 = new Gtk.RadioButton.from_widget (color_30);
        color_32.valign = Gtk.Align.CENTER;
        color_32.halign = Gtk.Align.CENTER;
        apply_styles ("32", "#ff9933", color_32);

        var color_33 = new Gtk.RadioButton.from_widget (color_30);
        color_33.valign = Gtk.Align.CENTER;
        color_33.halign = Gtk.Align.CENTER;
        apply_styles ("33", "#fad000", color_33);

        var color_34 = new Gtk.RadioButton.from_widget (color_30);
        color_34.valign = Gtk.Align.CENTER;
        color_34.halign = Gtk.Align.CENTER;
        apply_styles ("34", "#afb83b", color_34);

        var color_35 = new Gtk.RadioButton.from_widget (color_30);
        color_35.valign = Gtk.Align.CENTER;
        color_35.halign = Gtk.Align.CENTER;
        apply_styles ("35", "#7ecc49", color_35);

        var color_36 = new Gtk.RadioButton.from_widget (color_30);
        color_36.valign = Gtk.Align.CENTER;
        color_36.halign = Gtk.Align.CENTER;
        apply_styles ("36", "#299438", color_36);

        var color_37 = new Gtk.RadioButton.from_widget (color_30);
        color_37.valign = Gtk.Align.CENTER;
        color_37.halign = Gtk.Align.CENTER;
        apply_styles ("37", "#6accbc", color_37);

        var color_38 = new Gtk.RadioButton.from_widget (color_30);
        color_38.valign = Gtk.Align.CENTER;
        color_38.halign = Gtk.Align.CENTER;
        apply_styles ("38", "#158fad", color_38);

        var color_39 = new Gtk.RadioButton.from_widget (color_30);
        color_39.valign = Gtk.Align.CENTER;
        color_39.halign = Gtk.Align.CENTER;
        apply_styles ("39", "#14aaf5", color_39);

        var color_40 = new Gtk.RadioButton.from_widget (color_30);
        color_40.valign = Gtk.Align.CENTER;
        color_40.halign = Gtk.Align.CENTER;
        apply_styles ("40", "#96c3eb", color_40);

        var color_41 = new Gtk.RadioButton.from_widget (color_30);
        color_41.valign = Gtk.Align.CENTER;
        color_41.halign = Gtk.Align.CENTER;
        apply_styles ("41", "#4073ff", color_41);

        var color_42 = new Gtk.RadioButton.from_widget (color_30);
        color_42.valign = Gtk.Align.CENTER;
        color_42.halign = Gtk.Align.CENTER;
        apply_styles ("42", "#884dff", color_42);

        var color_43 = new Gtk.RadioButton.from_widget (color_30);
        color_43.valign = Gtk.Align.CENTER;
        color_43.halign = Gtk.Align.CENTER;
        apply_styles ("43", "#af38eb", color_43);

        var color_44 = new Gtk.RadioButton.from_widget (color_30);
        color_44.valign = Gtk.Align.CENTER;
        color_44.halign = Gtk.Align.CENTER;
        apply_styles ("44", "#eb96eb", color_44);

        var color_45 = new Gtk.RadioButton.from_widget (color_30);
        color_45.valign = Gtk.Align.CENTER;
        color_45.halign = Gtk.Align.CENTER;
        apply_styles ("45", "#e05194", color_45);
        
        var color_46 = new Gtk.RadioButton.from_widget (color_30);
        color_46.valign = Gtk.Align.CENTER;
        color_46.halign = Gtk.Align.CENTER;
        apply_styles ("46", "#ff8d85", color_46);

        var color_47 = new Gtk.RadioButton.from_widget (color_30);
        color_47.valign = Gtk.Align.CENTER;
        color_47.halign = Gtk.Align.CENTER;
        apply_styles ("47", "#808080", color_47);

        var color_48 = new Gtk.RadioButton.from_widget (color_30);
        color_48.valign = Gtk.Align.CENTER;
        color_48.halign = Gtk.Align.CENTER;
        apply_styles ("48", "#b8b8b8", color_48);

        var color_49 = new Gtk.RadioButton.from_widget (color_30);
        color_49.valign = Gtk.Align.CENTER;
        color_49.halign = Gtk.Align.CENTER;
        apply_styles ("49", "#ccac93", color_49);

        var color_box = new Gtk.Grid ();
        color_box.margin_top = color_box.margin_bottom = 6;
        color_box.column_homogeneous = true;
        color_box.column_spacing = 3;
        color_box.row_spacing = 6;

        color_box.attach (color_30, 0, 0, 1, 1);
        color_box.attach (color_31, 1, 0, 1, 1);
        color_box.attach (color_32, 2, 0, 1, 1);
        color_box.attach (color_33, 3, 0, 1, 1);
        color_box.attach (color_34, 4, 0, 1, 1);
        color_box.attach (color_35, 0, 1, 1, 1);
        color_box.attach (color_36, 1, 1, 1, 1);
        color_box.attach (color_37, 2, 1, 1, 1);
        color_box.attach (color_38, 3, 1, 1, 1);
        color_box.attach (color_39, 4, 1, 1, 1);
        color_box.attach (color_40, 0, 2, 1, 1);
        color_box.attach (color_41, 1, 2, 1, 1);
        color_box.attach (color_42, 2, 2, 1, 1);
        color_box.attach (color_43, 3, 2, 1, 1);
        color_box.attach (color_44, 4, 2, 1, 1);
        color_box.attach (color_45, 0, 3, 1, 1);
        color_box.attach (color_46, 1, 3, 1, 1);
        color_box.attach (color_47, 2, 3, 1, 1);
        color_box.attach (color_48, 3, 3, 1, 1);
        color_box.attach (color_49, 4, 3, 1, 1);

        var main_grid = new Gtk.Grid ();
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.expand = true;
        main_grid.margin = 6;
        main_grid.margin_top = 0;
        main_grid.width_request = 200;

        main_grid.add (title_label);
        main_grid.add (color_box);

        add (main_grid);

        color_30.toggled.connect (() => {
            color_selected (30);
        });

        color_31.toggled.connect (() => {
            color_selected (31);
        });

        color_32.toggled.connect (() => {
            color_selected (32);
        });

        color_33.toggled.connect (() => {
            color_selected (33);
        });

        color_34.toggled.connect (() => {
            color_selected (34);
        });

        color_35.toggled.connect (() => {
            color_selected (35);
        });

        color_36.toggled.connect (() => {
            color_selected (36);
        });

        color_37.toggled.connect (() => {
            color_selected (37);
        });

        color_38.toggled.connect (() => {
            color_selected (38);
        });

        color_39.toggled.connect (() => {
            color_selected (39);
        });

        color_40.toggled.connect (() => {
            color_selected (40);
        });

        color_41.toggled.connect (() => {
            color_selected (41);
        });

        color_42.toggled.connect (() => {
            color_selected (42);
        });

        color_43.toggled.connect (() => {
            color_selected (43);
        });

        color_44.toggled.connect (() => {
            color_selected (44);
        });

        color_45.toggled.connect (() => {
            color_selected (45);
        });

        color_46.toggled.connect (() => {
            color_selected (46);
        });

        color_47.toggled.connect (() => {
            color_selected (47);
        });

        color_48.toggled.connect (() => {
            color_selected (48);
        });

        color_49.toggled.connect (() => {
            color_selected (49);
        });
    }

    private void apply_styles (string id, string color, Gtk.RadioButton radio) {
        var provider = new Gtk.CssProvider ();
        radio.get_style_context ().add_class ("color-%s".printf (id));
        radio.get_style_context ().add_class ("color_radio");

        try {
            var colored_css = COLOR_CSS.printf (
                id,
                color,
                Application.utils.convert_invert (color)
            );

            provider.load_from_data (colored_css, colored_css.length);

            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (GLib.Error e) {
            return;
        }
    }
}