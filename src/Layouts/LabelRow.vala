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

public class Layouts.LabelRow : Gtk.ListBoxRow {
    public Objects.Label label { get; construct; }

    private Gtk.Label name_label;
    private Gtk.Label count_label;
    private Gtk.Revealer count_revealer;
    private Gtk.Revealer main_revealer;
    private Gtk.Grid widget_color;
    private Gtk.Box handle_grid;

    public LabelRow (Objects.Label label) {
        Object (
            label: label
        );
    }

    construct {        
        add_css_class ("selectable-item");
        add_css_class ("transition");

        widget_color = new Gtk.Grid () {
            valign = Gtk.Align.CENTER,
            height_request = 12,
            width_request = 12,
            margin_start = 6
        };

        widget_color.add_css_class ("label-color");

        name_label = new Gtk.Label (label.name);
        name_label.valign = Gtk.Align.CENTER;
        name_label.ellipsize = Pango.EllipsizeMode.END;

        count_label = new Gtk.Label (label.label_count.to_string ()) {
            hexpand = true,
            halign = Gtk.Align.END
        };

        count_label.add_css_class ("dim-label");
        count_label.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);

        count_revealer = new Gtk.Revealer () {
            reveal_child = int.parse (count_label.label) > 0
        };

        count_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        count_revealer.child = count_label;

        var edit_image = new Widgets.DynamicIcon ();
        edit_image.size = 16;
        edit_image.update_icon_name ("planner-edit");

        var edit_button = new Gtk.Button ();
        edit_button.child = edit_image;
        edit_button.add_css_class (Granite.STYLE_CLASS_FLAT);
        edit_button.add_css_class ("padding-3");

        var trash_image = new Widgets.DynamicIcon ();
        trash_image.size = 16;
        trash_image.update_icon_name ("planner-trash");

        var trash_button = new Gtk.Button ();
        trash_button.child = trash_image;
        trash_button.add_css_class (Granite.STYLE_CLASS_FLAT);
        trash_button.add_css_class ("padding-3");

        var buttons_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        buttons_box.append (edit_button);
        buttons_box.append (trash_button);

        var buttons_box_revealer = new Gtk.Revealer ();
        buttons_box_revealer.transition_type = Gtk.RevealerTransitionType.SWING_RIGHT;
        buttons_box_revealer.child = buttons_box;
        
        handle_grid = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        handle_grid.append (widget_color);
        handle_grid.append (name_label);
        handle_grid.append (count_revealer);
        handle_grid.append (buttons_box_revealer);

        main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };
        main_revealer.child = handle_grid;

        child = main_revealer;
        update_request ();
        build_drag_and_drop ();
        
        Timeout.add (main_revealer.transition_duration, () => {
            main_revealer.reveal_child = true;
            return GLib.Source.REMOVE;
        });

        label.updated.connect (() => {
            update_request ();
        });

        label.label_count_updated.connect (() => {
            count_label.label = label.label_count.to_string ();
            count_revealer.reveal_child = int.parse (count_label.label) > 0;
        });

        var motion_gesture = new Gtk.EventControllerMotion ();
        add_controller (motion_gesture);

        motion_gesture.enter.connect (() => {
            buttons_box_revealer.reveal_child = true;
            count_revealer.reveal_child = false;
        });

        motion_gesture.leave.connect (() => {
            buttons_box_revealer.reveal_child = false;
            count_revealer.reveal_child = int.parse (count_label.label) > 0;
        });

        trash_button.clicked.connect (() => {
            Services.EventBus.get_default ().close_labels ();
            
            var dialog = new Adw.MessageDialog ((Gtk.Window) Planify.instance.main_window, 
            _("Delete label"), _("Are you sure you want to delete <b>%s</b>?".printf (Util.get_default ().get_dialog_text (label.short_name))));

            dialog.body_use_markup = true;
            dialog.add_response ("cancel", _("Cancel"));
            dialog.add_response ("delete", _("Delete"));
            dialog.set_response_appearance ("delete", Adw.ResponseAppearance.DESTRUCTIVE);
            dialog.show ();

            dialog.response.connect ((response) => {
                if (response == "delete") {
                    if (label.backend_type == BackendType.TODOIST) {
                        Services.Todoist.get_default ().delete.begin (label, (obj, res) => {
                            Services.Todoist.get_default ().delete.end (res);
                            Services.Database.get_default ().delete_label (label);
                        });
                    } else if (label.backend_type == BackendType.LOCAL) {
                        Services.Database.get_default ().delete_label (label);
                    }
                }
            });
        });

        edit_button.clicked.connect (() => {
            Services.EventBus.get_default ().close_labels ();
            var dialog = new Dialogs.Label (label);
            dialog.show ();
        });
    }

    public void update_request () {
        name_label.label = label.name;
        Util.get_default ().set_widget_color (Util.get_default ().get_color (label.color), widget_color);
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

        var drop_target = new Gtk.DropTarget (typeof (Layouts.LabelRow), Gdk.DragAction.MOVE);
        drop_target.preload = true;

        drop_target.drop.connect ((target, value, x, y) => {
            var picked_widget = (Layouts.LabelRow) value;
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
            update_labels_item_order (target_list);
            
            return true;
        });

        add_controller (drop_target);
    }

    private void update_labels_item_order (Gtk.ListBox listbox) {
        unowned Layouts.LabelRow? label_row = null;
        var row_index = 0;

        do {
            label_row = (Layouts.LabelRow) listbox.get_row_at_index (row_index);

            if (label_row != null) {
                label_row.label.item_order = row_index;
                Services.Database.get_default ().update_label (label_row.label);
            }

            row_index++;
        } while (label_row != null);
    }

    public void drag_begin () {
        handle_grid.add_css_class ("card");
        opacity = 0.3;
        // on_drag = true;
        // bottom_revealer.reveal_child = false;
    }

    public void drag_end () {
        handle_grid.remove_css_class ("card");
        opacity = 1;
        // on_drag = false;
    }

    public void hide_destroy () {
        main_revealer.reveal_child = false;
        Timeout.add (main_revealer.transition_duration, () => {
            ((Gtk.ListBox) parent).remove (this);
            return GLib.Source.REMOVE;
        });
    }
}
