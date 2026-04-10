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

public class Widgets.ItemLabels : Adw.Bin {
    Objects.Item _item;
    public Objects.Item item {
        get {
            return _item;
        }

        set {
            disconnect_signals ();
            reset ();
            
            _item = value;
            
            signal_map[_item.item_label_deleted.connect ((label) => {
                remove_item_label (label);
            })] = _item;

            signal_map[_item.item_label_added.connect ((label) => {
                add_item_label (label);
            })] = _item;
            
            add_labels ();
        }
    }

    public signal void label_clicked (Objects.Label label);

    private bool has_items {
        get {
            return item_labels_map.size > 0;
        }
    }

    private Adw.WrapBox box_layout;
    private Gtk.Revealer main_revealer;

    private Gee.HashMap<string, Widgets.ItemLabelChild> item_labels_map = new Gee.HashMap<string, Widgets.ItemLabelChild> ();
    private Gee.HashMap<ulong, GLib.Object> signal_map = new Gee.HashMap<ulong, GLib.Object> ();

    public int top_margin {
        set {
            box_layout.margin_top = value;
        }
    }

    ~ItemLabels () {
        debug ("Destroying - Widgets.ItemLabels\n");
    }

    construct {
        box_layout = new Adw.WrapBox () {
            child_spacing = 6,
            line_spacing = 6,
            halign = START
        };

        main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            child = box_layout
        };

        child = main_revealer;
    }

    private void disconnect_signals () {
        foreach (var entry in signal_map.entries) {
            entry.value.disconnect (entry.key);
        }

        signal_map.clear ();
    }

    public void add_labels () {
        if (_item == null) {
            return;
        }
        
        foreach (Objects.Label label in _item.get_labels_list ()) {
            add_item_label (label);
        }

        main_revealer.reveal_child = has_items;
    }

    public void add_item_label (Objects.Label label) {
        if (!item_labels_map.has_key (label.id)) {
            item_labels_map[label.id] = new Widgets.ItemLabelChild (label);
            item_labels_map[label.id].clicked.connect (() => {
                label_clicked (label);
            });
            box_layout.append (item_labels_map[label.id]);
        }

        main_revealer.reveal_child = has_items;
    }

    public void remove_item_label (Objects.Label label) {
        if (item_labels_map.has_key (label.id)) {
            item_labels_map[label.id].hide_destroy ();
            item_labels_map.unset (label.id);
        }

        main_revealer.reveal_child = has_items;
    }

    public void update_labels () {
        reset ();
        add_labels ();
    }

    public void reset () {
        foreach (Widgets.ItemLabelChild item_label_row in item_labels_map.values) {
            box_layout.remove (item_label_row);
        }

        item_labels_map.clear ();
    }

    public void clean_up () {
        disconnect_signals ();

        foreach (Widgets.ItemLabelChild item_label_row in item_labels_map.values) {
            item_label_row.clean_up ();
        }
    }
}
