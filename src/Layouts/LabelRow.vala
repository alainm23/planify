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
        css_classes = { "selectable-item", "transition" };

        widget_color = new Gtk.Grid () {
            valign = Gtk.Align.CENTER,
            height_request = 12,
            width_request = 12,
            margin_start = 6,
            css_classes = { "label-color" }
        };

        name_label = new Gtk.Label (label.name) {
            valign = Gtk.Align.CENTER,
            ellipsize = Pango.EllipsizeMode.END
        };

        count_label = new Gtk.Label (label.label_count.to_string ()) {
            hexpand = true,
            halign = Gtk.Align.END,
            css_classes = { "dim-label", "small-label" }
        };

        count_revealer = new Gtk.Revealer () {
            reveal_child = int.parse (count_label.label) > 0,
            transition_type = Gtk.RevealerTransitionType.CROSSFADE,
            child = count_label

        };

        var edit_button = new Gtk.Button () {
            child = new Widgets.DynamicIcon.from_icon_name ("planner-edit"),
            css_classes = { "flat", "padding-3" }
        };

        var trash_button = new Gtk.Button () {
            child = new Widgets.DynamicIcon.from_icon_name ("planner-trash"),
            css_classes = { "flat", "padding-3" }
        };

        var buttons_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        buttons_box.append (edit_button);
        buttons_box.append (trash_button);

        var buttons_box_revealer = new Gtk.Revealer ();
        buttons_box_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
        buttons_box_revealer.child = buttons_box;
        
        handle_grid = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        handle_grid.append (widget_color);
        handle_grid.append (name_label);
        handle_grid.append (count_revealer);
        handle_grid.append (buttons_box_revealer);

        var reorder_child = new Widgets.ReorderChild (handle_grid, this);

        main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            child = reorder_child
        };

        child = main_revealer;
        update_request ();
        reorder_child.build_drag_and_drop ();
        
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
            _("Delete label"), _("Are you sure you want to delete %s?".printf (label.short_name)));

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

        reorder_child.on_drop_end.connect ((listbox) => {
            update_labels_item_order (listbox);
        });
    }

    public void update_request () {
        name_label.label = label.name;
        Util.get_default ().set_widget_color (Util.get_default ().get_color (label.color), widget_color);
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

    public void hide_destroy () {
        main_revealer.reveal_child = false;
        Timeout.add (main_revealer.transition_duration, () => {
            ((Gtk.ListBox) parent).remove (this);
            return GLib.Source.REMOVE;
        });
    }
}
