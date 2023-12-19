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
    private Gtk.Revealer main_revealer;

    public SectionPickerRow (Objects.Section section, string widget_type = "picker") {
        Object (
            section: section,
            widget_type: widget_type
        );
    }

    construct {
        add_css_class ("selectable-item");
        add_css_class ("transition");

        name_label = new Gtk.Label (null);
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
            transition_type = Gtk.RevealerTransitionType.CROSSFADE
        };

        selected_revealer.child = selected_icon;

        var order_icon = new Widgets.DynamicIcon () {
            hexpand = true,
            halign = Gtk.Align.END
        };
        order_icon.size = 21;
        order_icon.update_icon_name ("menu");

        var content_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            margin_top = 6,
            margin_start = 6,
            margin_end = 6,
            margin_bottom = 6
        };

        content_box.append (name_label);

        if (widget_type == "order") {
            content_box.append (order_icon);
        }

        if (widget_type == "picker") {
            content_box.append (selected_revealer);
        }

        handle_grid = new Gtk.Grid ();
        handle_grid.attach (content_box, 0, 0);

        main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };

        main_revealer.child = handle_grid;

        child = main_revealer;
        update_request ();

        Timeout.add (main_revealer.transition_duration, () => {
            main_revealer.reveal_child = true;
            return GLib.Source.REMOVE;
        });

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
            build_drag_and_drop ();
        }
    }

    public void update_request () {
        name_label.label = section.name;
    }

    private void build_drag_and_drop () {
        var drag_source = new Gtk.DragSource ();
        drag_source.set_actions (Gdk.DragAction.MOVE);
        
        drag_source.prepare.connect ((source, x, y) => {
            return new Gdk.ContentProvider.for_value (this);
        });

        drag_source.drag_begin.connect ((source, drag) => {
            var paintable = new Gtk.WidgetPaintable (handle_grid);
            source.set_icon (paintable, 0, 0);
            drag_begin ();
        });
        
        drag_source.drag_end.connect ((source, drag, delete_data) => {
            drag_end ();
        });

        drag_source.drag_cancel.connect ((source, drag, reason) => {
            drag_end ();
            return false;
        });

        add_controller (drag_source);

        var drop_target = new Gtk.DropTarget (typeof (Dialogs.ProjectPicker.SectionPickerRow), Gdk.DragAction.MOVE);
        drop_target.preload = true;

        drop_target.drop.connect ((value, x, y) => {
            var picked_widget = (Dialogs.ProjectPicker.SectionPickerRow) value;
            var target_widget = this;

            picked_widget.drag_end ();
            target_widget.drag_end ();

            if (picked_widget == target_widget || target_widget == null) {
                return false;
            }

            var source_list = (Gtk.ListBox) picked_widget.parent;
            var target_list = (Gtk.ListBox) target_widget.parent;
            var position = 0;

            source_list.remove (picked_widget);
            
            if (target_widget.get_index () == 0) {
                if (y > (target_widget.get_height () / 2)) {
                    position = target_widget.get_index () + 1;
                }
            } else {
                position = target_widget.get_index () + 1;
            }

            target_list.insert (picked_widget, position);

            return true;
        });

        add_controller (drop_target);
    }

    public void drag_begin () {
        handle_grid.add_css_class ("card");
        opacity = 0.3;        
    }

    public void drag_end () {
        handle_grid.remove_css_class ("card");
        opacity = 1;
    }
}