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
    public int selected { get; set; }
    public signal void color_changed (int color);

    construct {
        var color_30 = new Gtk.RadioButton (null);
        color_30.valign = Gtk.Align.START;
        color_30.halign = Gtk.Align.START;
        color_30.tooltip_text = Planner.utils.get_color_name (30);
        color_30.get_style_context ().add_class ("color-30");
        color_30.get_style_context ().add_class ("color-radio");

        var color_31 = new Gtk.RadioButton.from_widget (color_30);
        color_31.valign = Gtk.Align.START;
        color_31.halign = Gtk.Align.START;
        color_31.tooltip_text = Planner.utils.get_color_name (31);
        color_31.get_style_context ().add_class ("color-31");
        color_31.get_style_context ().add_class ("color-radio");

        var color_32 = new Gtk.RadioButton.from_widget (color_30);
        color_32.valign = Gtk.Align.START;
        color_32.halign = Gtk.Align.START;
        color_32.tooltip_text = Planner.utils.get_color_name (32);
        color_32.get_style_context ().add_class ("color-32");
        color_32.get_style_context ().add_class ("color-radio");

        var color_33 = new Gtk.RadioButton.from_widget (color_30);
        color_33.valign = Gtk.Align.START;
        color_33.halign = Gtk.Align.START;
        color_33.tooltip_text = Planner.utils.get_color_name (33);
        color_33.get_style_context ().add_class ("color-33");
        color_33.get_style_context ().add_class ("color-radio");

        var color_34 = new Gtk.RadioButton.from_widget (color_30);
        color_34.valign = Gtk.Align.START;
        color_34.halign = Gtk.Align.START;
        color_34.tooltip_text = Planner.utils.get_color_name (34);
        color_34.get_style_context ().add_class ("color-34");
        color_34.get_style_context ().add_class ("color-radio");

        var color_35 = new Gtk.RadioButton.from_widget (color_30);
        color_35.valign = Gtk.Align.START;
        color_35.halign = Gtk.Align.START;
        color_35.tooltip_text = Planner.utils.get_color_name (35);
        color_35.get_style_context ().add_class ("color-35");
        color_35.get_style_context ().add_class ("color-radio");

        var color_36 = new Gtk.RadioButton.from_widget (color_30);
        color_36.valign = Gtk.Align.START;
        color_36.halign = Gtk.Align.START;
        color_36.tooltip_text = Planner.utils.get_color_name (36);
        color_36.get_style_context ().add_class ("color-36");
        color_36.get_style_context ().add_class ("color-radio");

        var color_37 = new Gtk.RadioButton.from_widget (color_30);
        color_37.valign = Gtk.Align.START;
        color_37.halign = Gtk.Align.START;
        color_37.tooltip_text = Planner.utils.get_color_name (37);
        color_37.get_style_context ().add_class ("color-37");
        color_37.get_style_context ().add_class ("color-radio");

        var color_38 = new Gtk.RadioButton.from_widget (color_30);
        color_38.valign = Gtk.Align.START;
        color_38.halign = Gtk.Align.START;
        color_38.tooltip_text = Planner.utils.get_color_name (38);
        color_38.get_style_context ().add_class ("color-38");
        color_38.get_style_context ().add_class ("color-radio");

        var color_39 = new Gtk.RadioButton.from_widget (color_30);
        color_39.valign = Gtk.Align.START;
        color_39.halign = Gtk.Align.START;
        color_39.tooltip_text = Planner.utils.get_color_name (39);
        color_39.get_style_context ().add_class ("color-39");
        color_39.get_style_context ().add_class ("color-radio");

        var color_40 = new Gtk.RadioButton.from_widget (color_30);
        color_40.valign = Gtk.Align.START;
        color_40.halign = Gtk.Align.START;
        color_40.tooltip_text = Planner.utils.get_color_name (40);
        color_40.get_style_context ().add_class ("color-40");
        color_40.get_style_context ().add_class ("color-radio");

        var color_41 = new Gtk.RadioButton.from_widget (color_30);
        color_41.valign = Gtk.Align.START;
        color_41.halign = Gtk.Align.START;
        color_41.tooltip_text = Planner.utils.get_color_name (41);
        color_41.get_style_context ().add_class ("color-41");
        color_41.get_style_context ().add_class ("color-radio");

        var color_42 = new Gtk.RadioButton.from_widget (color_30);
        color_42.valign = Gtk.Align.START;
        color_42.halign = Gtk.Align.START;
        color_42.tooltip_text = Planner.utils.get_color_name (42);
        color_42.get_style_context ().add_class ("color-42");
        color_42.get_style_context ().add_class ("color-radio");

        var color_43 = new Gtk.RadioButton.from_widget (color_30);
        color_43.valign = Gtk.Align.START;
        color_43.halign = Gtk.Align.START;
        color_43.tooltip_text = Planner.utils.get_color_name (43);
        color_43.get_style_context ().add_class ("color-43");
        color_43.get_style_context ().add_class ("color-radio");

        var color_44 = new Gtk.RadioButton.from_widget (color_30);
        color_44.valign = Gtk.Align.START;
        color_44.halign = Gtk.Align.START;
        color_44.tooltip_text = Planner.utils.get_color_name (44);
        color_44.get_style_context ().add_class ("color-44");
        color_44.get_style_context ().add_class ("color-radio");

        var color_45 = new Gtk.RadioButton.from_widget (color_30);
        color_45.valign = Gtk.Align.START;
        color_45.halign = Gtk.Align.START;
        color_45.tooltip_text = Planner.utils.get_color_name (45);
        color_45.get_style_context ().add_class ("color-45");
        color_45.get_style_context ().add_class ("color-radio");

        var color_46 = new Gtk.RadioButton.from_widget (color_30);
        color_46.valign = Gtk.Align.START;
        color_46.halign = Gtk.Align.START;
        color_46.tooltip_text = Planner.utils.get_color_name (46);
        color_46.get_style_context ().add_class ("color-46");
        color_46.get_style_context ().add_class ("color-radio");

        var color_47 = new Gtk.RadioButton.from_widget (color_30);
        color_47.valign = Gtk.Align.START;
        color_47.halign = Gtk.Align.START;
        color_47.tooltip_text = Planner.utils.get_color_name (47);
        color_47.get_style_context ().add_class ("color-47");
        color_47.get_style_context ().add_class ("color-radio");

        var color_48 = new Gtk.RadioButton.from_widget (color_30);
        color_48.valign = Gtk.Align.START;
        color_48.halign = Gtk.Align.START;
        color_48.tooltip_text = Planner.utils.get_color_name (48);
        color_48.get_style_context ().add_class ("color-48");
        color_48.get_style_context ().add_class ("color-radio");

        var color_49 = new Gtk.RadioButton.from_widget (color_30);
        color_49.valign = Gtk.Align.START;
        color_49.halign = Gtk.Align.START;
        color_49.tooltip_text = Planner.utils.get_color_name (49);
        color_49.get_style_context ().add_class ("color-49");
        color_49.get_style_context ().add_class ("color-radio");

        var color_box = new Gtk.Grid ();
        color_box.hexpand = true;
        color_box.margin_start = 6;
        color_box.margin_end = 6;
        color_box.column_homogeneous = true;
        color_box.row_homogeneous = true;
        color_box.row_spacing = 9;
        color_box.column_spacing = 12;

        color_box.attach (color_30, 0, 0, 1, 1);
        color_box.attach (color_31, 1, 0, 1, 1);
        color_box.attach (color_32, 2, 0, 1, 1);
        color_box.attach (color_33, 3, 0, 1, 1);
        color_box.attach (color_34, 4, 0, 1, 1);
        color_box.attach (color_35, 5, 0, 1, 1);
        color_box.attach (color_36, 6, 0, 1, 1);
        color_box.attach (color_37, 0, 1, 1, 1);
        color_box.attach (color_38, 1, 1, 1, 1);
        color_box.attach (color_39, 2, 1, 1, 1);
        color_box.attach (color_40, 3, 1, 1, 1);
        color_box.attach (color_41, 4, 1, 1, 1);
        color_box.attach (color_42, 5, 1, 1, 1);
        color_box.attach (color_43, 6, 1, 1, 1);
        color_box.attach (color_44, 0, 2, 1, 1);
        color_box.attach (color_45, 1, 2, 1, 1);
        color_box.attach (color_46, 2, 2, 1, 1);
        color_box.attach (color_47, 3, 2, 1, 1);
        color_box.attach (color_48, 4, 2, 1, 1);
        color_box.attach (color_49, 5, 2, 1, 1);

        var popover_grid = new Gtk.Grid ();
        popover_grid.width_request = 235;
        popover_grid.orientation = Gtk.Orientation.VERTICAL;
        popover_grid.margin_top = 6;
        popover_grid.margin_bottom = 6;
        popover_grid.add (color_box);
        popover_grid.show_all ();

        add (popover_grid);

        notify["selected"].connect (() => {
            switch (selected) {
                case 30:
                    color_30.active = true;
                    break;
                case 31:
                    color_31.active = true;
                    break;
                case 32:
                    color_32.active = true;
                    break;
                case 33:
                    color_33.active = true;
                    break;
                case 34:
                    color_34.active = true;
                    break;
                case 35:
                    color_35.active = true;
                    break;
                case 36:
                    color_36.active = true;
                    break;
                case 37:
                    color_37.active = true;
                    break;
                case 38:
                    color_38.active = true;
                    break;
                case 39:
                    color_39.active = true;
                    break;
                case 40:
                    color_40.active = true;
                    break;
                case 41:
                    color_41.active = true;
                    break;
                case 42:
                    color_42.active = true;
                    break;
                case 43:
                    color_43.active = true;
                    break;
                case 44:
                    color_44.active = true;
                    break;
                case 45:
                    color_45.active = true;
                    break;
                case 46:
                    color_46.active = true;
                    break;
                case 47:
                    color_47.active = true;
                    break;
                case 48:
                    color_48.active = true;
                    break;
                case 49:
                    color_49.active = true;
                    break;
                default:
                    break;
            }
        });

        color_30.toggled.connect (() => {
            selected = 30;
            color_changed (selected);
        });

        color_31.toggled.connect (() => {
            selected = 31;
            color_changed (selected);
        });

        color_32.toggled.connect (() => {
            selected = 32;
            color_changed (selected);
        });

        color_33.toggled.connect (() => {
            selected = 33;
            color_changed (selected);
        });

        color_34.toggled.connect (() => {
            selected = 34;
            color_changed (selected);
        });

        color_35.toggled.connect (() => {
            selected = 35;
            color_changed (selected);
        });

        color_36.toggled.connect (() => {
            selected = 36;
            color_changed (selected);
        });

        color_37.toggled.connect (() => {
            selected = 37;
            color_changed (selected);
        });

        color_38.toggled.connect (() => {
            selected = 38;
            color_changed (selected);
        });

        color_39.toggled.connect (() => {
            selected = 39;
            color_changed (selected);
        });

        color_40.toggled.connect (() => {
            selected = 40;
            color_changed (selected);
        });

        color_41.toggled.connect (() => {
            selected = 41;
            color_changed (selected);
        });

        color_42.toggled.connect (() => {
            selected = 42;
            color_changed (selected);
        });

        color_43.toggled.connect (() => {
            selected = 43;
            color_changed (selected);
        });

        color_44.toggled.connect (() => {
            selected = 44;
            color_changed (selected);
        });

        color_45.toggled.connect (() => {
            selected = 45;
            color_changed (selected);
        });

        color_46.toggled.connect (() => {
            selected = 46;
        });

        color_47.toggled.connect (() => {
            selected = 47;
            color_changed (selected);
        });

        color_48.toggled.connect (() => {
            selected = 48;
            color_changed (selected);
        });

        color_49.toggled.connect (() => {
            selected = 49;
            color_changed (selected);
        });
    }
}