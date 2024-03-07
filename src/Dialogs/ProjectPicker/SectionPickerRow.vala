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

public class Dialogs.ProjectPicker.SectionPickerRow : Gtk.ListBoxRow {
    public Objects.Section section { get; construct; }
    public string widget_type { get; construct; }
    
    private Gtk.Label name_label;
    private Gtk.Grid handle_grid;

    public SectionPickerRow (Objects.Section section, string widget_type = "picker") {
        Object (
            section: section,
            widget_type: widget_type
        );
    }

    construct {
        add_css_class ("selectable-item");
        add_css_class ("transition");

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

        var order_icon = new Gtk.Image.from_icon_name ("list-drag-handle-symbolic");

        var content_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            margin_top = 9,
            margin_start = 12,
            margin_end = 9,
            margin_bottom = 9
        };

        content_box.append (name_label);

        if (widget_type == "order") {
            var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12) {
                hexpand = true,
                halign = Gtk.Align.END
            };
            box.append (hidded_switch);
            box.append (order_icon);

            content_box.append (box);
        }

        if (widget_type == "picker") {
            content_box.append (selected_revealer);
        }

        handle_grid = new Gtk.Grid ();
        handle_grid.attach (content_box, 0, 0);

        var reorder_child = new Widgets.ReorderChild (handle_grid, this);

        child = reorder_child;

        if (widget_type == "picker") {
            var select_gesture = new Gtk.GestureClick ();
            add_controller (select_gesture);

            select_gesture.pressed.connect (() => {
                Services.EventBus.get_default ().section_picker_changed (section.id);
            });
    
            Services.EventBus.get_default ().section_picker_changed.connect ((type, id) => {
                selected_revealer.reveal_child = section.id == id;
            });
        }

        if (widget_type == "order") {
            reorder_child.build_drag_and_drop ();

            hidded_switch.notify["active"].connect (() => {
                if (section.id == "") {
                    section.project.inbox_section_hidded = !hidded_switch.active;
                    section.project.update_local ();
                } else {
                    section.hidded = !hidded_switch.active;
                    Services.Database.get_default ().update_section (section);
                }
            });
        }
    }
}
