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
    private Gtk.Image widget_color;
    private Gtk.Box handle_grid;
    private Widgets.ReorderChild reorder_child;

    private Gee.HashMap<ulong, weak GLib.Object> signal_map = new Gee.HashMap<ulong, weak GLib.Object> ();

    public LabelRow (Objects.Label label) {
        Object (
            label: label
        );
    }

    ~LabelRow () {
        print ("Destroying - Layouts.LabelRow\n");
    }

    construct {
        css_classes = { "row", "transition", "no-padding" };

        widget_color = new Gtk.Image.from_icon_name ("tag-outline-symbolic") {
            css_classes = { "icon-color" },
            valign = Gtk.Align.CENTER,
        };

        name_label = new Gtk.Label (label.name) {
            valign = Gtk.Align.CENTER,
            ellipsize = Pango.EllipsizeMode.END
        };

        count_label = new Gtk.Label (label.label_count.to_string ()) {
            hexpand = true,
            halign = Gtk.Align.END
        };

        count_revealer = new Gtk.Revealer () {
            reveal_child = int.parse (count_label.label) > 0,
            transition_type = Gtk.RevealerTransitionType.CROSSFADE,
            child = count_label
        };

        var menu_button = new Gtk.MenuButton () {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER,
            popover = build_context_menu (),
            icon_name = "view-more-symbolic",
            css_classes = { "flat", "header-item-button", "dimmed" }
        };

        var loading_button = new Widgets.LoadingButton.with_icon ("go-next-symbolic", 16) {
            valign = Gtk.Align.CENTER,
            css_classes = { "flat", "dimmed", "no-padding" }
        };

        var buttons_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        buttons_box.append (menu_button);
        buttons_box.append (loading_button);

        handle_grid = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            margin_start = 6,
            margin_end = 6,
            margin_top = 3,
            margin_bottom = 3
        };
        handle_grid.append (widget_color);
        handle_grid.append (name_label);
        handle_grid.append (count_revealer);
        handle_grid.append (buttons_box);

        reorder_child = new Widgets.ReorderChild (handle_grid, this);

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

        signal_map[label.updated.connect (() => {
            update_request ();
        })] = label;

        signal_map[label.label_count_updated.connect (() => {
            count_label.label = label.label_count.to_string ();
            count_revealer.reveal_child = int.parse (count_label.label) > 0;
        })] = label;

        signal_map[reorder_child.on_drop_end.connect ((listbox) => {
            update_labels_item_order (listbox);
        })] = reorder_child;

        signal_map[label.loading_change.connect (() => {
            loading_button.is_loading = label.loading;
        })] = label;

        signal_map[loading_button.clicked.connect (() => {
            Services.EventBus.get_default ().pane_selected (PaneType.LABEL, label.id);
        })] = loading_button;
    }

    public void update_request () {
        name_label.label = label.name;
        Util.get_default ().set_widget_color (Util.get_default ().get_color (label.color), widget_color);
    }

    private void update_labels_item_order (Gtk.ListBox listbox) {
        unowned Layouts.LabelRow ? label_row = null;
        var row_index = 0;

        do {
            label_row = (Layouts.LabelRow) listbox.get_row_at_index (row_index);

            if (label_row != null) {
                label_row.label.item_order = row_index;
                Services.Store.instance ().update_label (label_row.label);
            }

            row_index++;
        } while (label_row != null);
    }

    private Gtk.Popover build_context_menu () {
        var edit_item = new Widgets.ContextMenu.MenuItem (_("Edit Label"), "edit-symbolic");
        var delete_item = new Widgets.ContextMenu.MenuItem (_("Delete Label"), "user-trash-symbolic");
        delete_item.add_css_class ("menu-item-danger");

        var menu_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        menu_box.margin_top = menu_box.margin_bottom = 3;
        menu_box.append (edit_item);
        menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
        menu_box.append (delete_item);

        var menu_popover = new Gtk.Popover () {
            has_arrow = false,
            child = menu_box,
            position = Gtk.PositionType.BOTTOM,
            width_request = 250
        };

        signal_map[edit_item.clicked.connect (() => {
            var dialog = new Dialogs.Label (label);
            dialog.present (Planify._instance.main_window);
        })] = edit_item;

        signal_map[delete_item.clicked.connect (() => {
            label.delete_label.begin (Planify._instance.main_window);
        })] = delete_item;

        return menu_popover;
    }

    public void hide_destroy () {
        main_revealer.reveal_child = false;
        clean_up ();
        Timeout.add (main_revealer.transition_duration, () => {
            ((Gtk.ListBox) parent).remove (this);
            return GLib.Source.REMOVE;
        });
    }

    public void clean_up () {
        foreach (var entry in signal_map.entries) {
            entry.value.disconnect (entry.key);
        }

        signal_map.clear ();

        if (reorder_child != null) {
            reorder_child.clean_up ();
            reorder_child = null;
        }
    }
}
