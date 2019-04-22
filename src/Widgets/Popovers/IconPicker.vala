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

public class Widgets.Popovers.IconPicker : Gtk.Popover {
    public signal void on_selected (string icon_name, string color);
    private string icon_selected = "planner-startup-symbolic";
    public IconPicker (Gtk.Widget relative) {
        Object (
            relative_to: relative,
            modal: true,
            position: Gtk.PositionType.BOTTOM
        );
    }

    construct {
        var title_label = new Gtk.Label ("<small>%s</small>".printf (_("Select an icon y color")));
        title_label.use_markup = true;
        title_label.expand = true;
        title_label.halign = Gtk.Align.CENTER;
        title_label.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);
        
        var flow_box = new Gtk.FlowBox ();
        flow_box.column_spacing = 6;
        flow_box.row_spacing = 6;
        flow_box.homogeneous = true;
        flow_box.activate_on_single_click = true;

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.height_request = 100;
        scrolled.expand = true;
        scrolled.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        scrolled.add (flow_box);

        foreach (var item in Application.utils.get_icons_list ()) {
            var icon = new Gtk.Image.from_icon_name (item, Gtk.IconSize.MENU);
            flow_box.add (icon);
        }

        var color_1 = new Gtk.RadioButton (null);
        color_1.valign = Gtk.Align.CENTER;
        color_1.halign = Gtk.Align.CENTER;
        color_1.height_request = 24;
        color_1.width_request = 24;
        color_1.get_style_context ().add_class ("color_radio");
        color_1.get_style_context ().add_class ("color-1");

        var color_2 = new Gtk.RadioButton.from_widget (color_1);
        color_2.valign = Gtk.Align.CENTER;
        color_2.halign = Gtk.Align.CENTER;
        color_2.height_request = 24;
        color_2.width_request = 24;
        color_2.get_style_context ().add_class ("color_radio");
        color_2.get_style_context ().add_class ("color-2");

        var color_3 = new Gtk.RadioButton.from_widget (color_1);
        color_3.valign = Gtk.Align.CENTER;
        color_3.halign = Gtk.Align.CENTER;
        color_3.height_request = 24;
        color_3.width_request = 24;
        color_3.get_style_context ().add_class ("color_radio");
        color_3.get_style_context ().add_class ("color-3");

        var color_4 = new Gtk.RadioButton.from_widget (color_1);
        color_4.valign = Gtk.Align.CENTER;
        color_4.halign = Gtk.Align.CENTER;
        color_4.height_request = 24;
        color_4.width_request = 24;
        color_4.get_style_context ().add_class ("color_radio");
        color_4.get_style_context ().add_class ("color-4");

        var color_5 = new Gtk.RadioButton.from_widget (color_1);
        color_5.valign = Gtk.Align.CENTER;
        color_5.halign = Gtk.Align.CENTER;
        color_5.height_request = 24;
        color_5.width_request = 24;
        color_5.get_style_context ().add_class ("color_radio");
        color_5.get_style_context ().add_class ("color-5");

        var color_6 = new Gtk.RadioButton.from_widget (color_1);
        color_6.valign = Gtk.Align.CENTER;
        color_6.halign = Gtk.Align.CENTER;
        color_6.height_request = 24;
        color_6.width_request = 24;
        color_6.get_style_context ().add_class ("color_radio");
        color_6.get_style_context ().add_class ("color-6");

        var color_7 = new Gtk.RadioButton.from_widget (color_1);
        color_7.valign = Gtk.Align.CENTER;
        color_7.halign = Gtk.Align.CENTER;
        color_7.height_request = 24;
        color_7.width_request = 24;
        color_7.get_style_context ().add_class ("color_radio");
        color_7.get_style_context ().add_class ("color-7");

        var color_n = new Gtk.ToggleButton ();
        color_n.can_focus = false;
        color_n.valign = Gtk.Align.CENTER;
        color_n.halign = Gtk.Align.CENTER;
        color_n.height_request = 24;
        color_n.width_request = 24;

        var hex_label = new Gtk.Label ("<b>#</b>");
        hex_label.use_markup = true;
        color_n.add (hex_label);
        color_n.get_style_context ().add_class ("color-n");

        var color_box = new Gtk.Grid ();
        color_box.column_homogeneous = true;
        color_box.column_spacing = 3;

        color_box.add (color_1);
        color_box.add (color_2);
        color_box.add (color_3);
        color_box.add (color_4);
        color_box.add (color_5);
        color_box.add (color_6);
        color_box.add (color_7);
        color_box.add (color_n);

        var color_hex_entry = new Gtk.Entry ();
        color_hex_entry.hexpand = true;
        color_hex_entry.placeholder_text = "#7239b3";
        color_hex_entry.max_length = 7;

        var random_button = new Gtk.Button.from_icon_name ("system-reboot-symbolic", Gtk.IconSize.MENU);
        random_button.can_focus = false;

        var color_button  = new Gtk.ColorButton ();
        color_button.valign = Gtk.Align.START;

        var color_grid = new Gtk.Grid ();
        color_grid.get_style_context ().add_class (Gtk.STYLE_CLASS_LINKED);
        color_grid.add (color_hex_entry);
        color_grid.add (random_button);
        color_grid.add (color_button);

        var color_hex_revealer = new Gtk.Revealer ();
        color_hex_revealer.margin_top = 6;
        color_hex_revealer.margin_bottom = 12;
        color_hex_revealer.add (color_grid);
        color_hex_revealer.reveal_child = false;

        var main_grid = new Gtk.Grid ();
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.margin_end = 12;
        main_grid.margin_start = 12;
        main_grid.expand = true;
        main_grid.width_request = 200;

        main_grid.add (title_label);
        main_grid.add (new Granite.HeaderLabel (_("Icon")));
        main_grid.add (scrolled);
        main_grid.add (new Granite.HeaderLabel (_("Color")));
        main_grid.add (color_box);
        main_grid.add (color_hex_revealer);

        add (main_grid);

        color_n.clicked.connect (() => {
            if (color_hex_revealer.reveal_child) {
                color_hex_revealer.reveal_child = false;
            } else {
                color_hex_revealer.reveal_child = true;
            }
        });

        color_1.clicked.connect (() => {
            color_hex_entry.text = "#c6262e";
        });

        color_2.clicked.connect (() => {
            color_hex_entry.text = "#f37329";
        });

        color_3.clicked.connect (() => {
            color_hex_entry.text = "#f9c440";
        });

        color_4.clicked.connect (() => {
            color_hex_entry.text = "#68b723";
        });

        color_5.clicked.connect (() => {
            color_hex_entry.text = "#3689e6";
        });

        color_6.clicked.connect (() => {
            color_hex_entry.text = "#a56de2";
        });

        color_7.clicked.connect (() => {
            color_hex_entry.text = "#333333";
        });

        random_button.clicked.connect (() => {
            string random_color = "rgb(%i, %i, %i)".printf (GLib.Random.int_range (0, 255), GLib.Random.int_range (0, 255), GLib.Random.int_range (0, 255));
            var rgba = Gdk.RGBA ();
            rgba.parse (random_color);

            color_button.rgba = rgba;
            string hex = Application.utils.rgb_to_hex_string (color_button.rgba);

            color_hex_entry.text = hex;
        });

        color_button.color_set.connect (() => {
            string hex = Application.utils.rgb_to_hex_string (color_button.rgba);
            color_hex_entry.text = hex;
        });

        color_hex_entry.changed.connect (() => {
            var rgba = Gdk.RGBA ();
            if (rgba.parse (color_hex_entry.text)) {
                color_button.rgba = rgba;

                on_selected (icon_selected, color_hex_entry.text);
            } else {
                on_selected (icon_selected, "#333");
            }
        });

        flow_box.child_activated.connect ((child) => {
            icon_selected = Application.utils.get_icon_by_index (child.get_index ());
            on_selected (icon_selected, color_hex_entry.text);
        });
    }
}