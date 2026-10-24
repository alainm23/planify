/*
 * Copyright © 2024 Alain M. (https://github.com/alainm23/planify)
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

public class Widgets.PinnedItemsBox : Adw.Bin {
    public Objects.Project project { get; construct; }

    private Adw.WrapBox box_layout;
    private Gee.HashMap<ulong, weak GLib.Object> signal_map = new Gee.HashMap<ulong, weak GLib.Object> ();
    private Gtk.Revealer main_revealer;
    public Gee.HashMap<string, Layouts.ItemBoard> items_map = new Gee.HashMap<string, Layouts.ItemBoard> ();

    public PinnedItemsBox (Objects.Project project) {
        Object (
            project: project
        );
    }

    ~PinnedItemsBox () {
        debug ("Destroying - Widgets.PinnedItemsBox\n");
    }

    construct {
        box_layout = new Adw.WrapBox () {
            margin_start = 20,
            margin_end = 24,
            margin_top = 12,
            child_spacing = 12,
            halign = START
        };

        main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            child = box_layout,
            reveal_child = false
        };

        child = main_revealer;
        add_items ();

        signal_map[project.item_added.connect ((item) => {
            add_item (item);
        })] = project;

        signal_map[project.item_deleted.connect ((item) => {
            update_pinboard (item);
        })] = project;

        signal_map[Services.EventBus.get_default ().item_moved.connect ((item) => {
            update_pinboard (item);
        })] = Services.EventBus.get_default ();

        signal_map[Services.Store.instance ().item_pin_change.connect ((item) => {
            if (item.project_id != project.id) {
                return;
            }

            if (items_map.has_key (item.id) && !item.pinned) {
                items_map[item.id].hide_widget ();
                items_map[item.id].clean_up ();
                box_layout.remove (items_map[item.id]);
                items_map.unset (item.id);
            }

            if (!items_map.has_key (item.id) && item.pinned) {
                add_item (item);
            }

            check_reveal_child ();
        })] = Services.Store.instance ();
    }

    public void clean_up () {
        foreach (var entry in signal_map.entries) {
            if (SignalHandler.is_connected (entry.value, entry.key)) entry.value.disconnect (entry.key);
        }
        signal_map.clear ();
        foreach (var row in items_map.values) {
            row.clean_up ();
            box_layout.remove (row);
        }
        items_map.clear ();
    }

    private void add_items () {
        foreach (Objects.Item item in project.items_pinned) {
            add_item (item);
        }
    }

    private void add_item (Objects.Item item) {
        if (items_map.has_key (item.id)) {
            return;
        }

        if (!item.pinned) {
            return;
        }

        items_map[item.id] = new Layouts.ItemBoard (item) {
            hexpand = true,
            pin_mode = true
        };

        box_layout.append (items_map[item.id]);
        check_reveal_child ();
    }

    private void update_pinboard (Objects.Item item) {
        if (!items_map.has_key (item.id)) {
            return;
        }

        items_map[item.id].hide_widget ();
        items_map[item.id].clean_up ();
        box_layout.remove (items_map[item.id]);
        items_map.unset (item.id);

        check_reveal_child ();
    }

    private void check_reveal_child () {
        main_revealer.reveal_child = items_map.size > 0;
    }
}
