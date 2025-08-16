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

public class Widgets.SectionPicker.SectionPickerRow : Gtk.ListBoxRow {
    public Objects.Section section { get; construct; }

    private Gtk.Label name_label;

    public signal void update_section ();

    public SectionPickerRow (Objects.Section section) {
        Object (
            section: section
        );
    }

    construct {
        add_css_class ("border-radius-6");

        var color_grid = new Gtk.Grid () {
            width_request = 3,
            height_request = 16,
            margin_top = 0,
            valign = Gtk.Align.CENTER,
            css_classes = { "event-bar" }
        };

        Util.get_default ().set_widget_color (Util.get_default ().get_color (section.color), color_grid);

        name_label = new Gtk.Label (section.name);
        name_label.valign = Gtk.Align.CENTER;
        name_label.ellipsize = Pango.EllipsizeMode.END;

        var selected_icon = new Gtk.Image () {
            gicon = new ThemedIcon ("emblem-ok-symbolic"),
            pixel_size = 16,
            hexpand = true,
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.END,
            margin_end = 3
        };

        selected_icon.add_css_class ("color-primary");

        var selected_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.CROSSFADE,
            child = selected_icon
        };

        var hidded_switch = new Gtk.Switch () {
            css_classes = { "active-switch" },
            active = section.id == "" ? !section.project.inbox_section_hidded : !section.hidded
        };

        var order_icon = new Gtk.Image.from_icon_name ("list-drag-handle-symbolic") {
            css_classes = { "dimmed" },
            pixel_size = 12
        };

        var content_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            margin_top = 6,
            margin_start = 12,
            margin_end = 6,
            margin_bottom = 6
        };

        content_box.append (color_grid);
        content_box.append (name_label);
        content_box.append (selected_revealer);

        child = content_box;

        var select_gesture = new Gtk.GestureClick ();
        add_controller (select_gesture);

        select_gesture.pressed.connect (() => {
            Services.EventBus.get_default ().section_picker_changed (section.id);
        });

        Services.EventBus.get_default ().section_picker_changed.connect ((type, id) => {
            selected_revealer.reveal_child = section.id == id;
        });
    }
}
