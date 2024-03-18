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
    public Objects.Item item { get; construct; }

    private bool has_items {
        get {
            return item_labels_map.size > 0;
        }
    }

    private Gtk.FlowBox flowbox;
    private Gtk.Revealer main_revealer;

    private Gee.HashMap<string, Widgets.ItemLabelChild> item_labels_map = new Gee.HashMap<string, Widgets.ItemLabelChild> ();

    public ItemLabels (Objects.Item item) {
        Object (
            item: item
        );
    }

    public int top_margin {
        set {
            flowbox.margin_top = value;
        }
    }

    construct {
        flowbox = new Gtk.FlowBox () {
            column_spacing = 6,
            row_spacing = 6,
            homogeneous = false,
            hexpand = true,
            halign = Gtk.Align.START,
            min_children_per_line = 3,
            max_children_per_line = 20
        };

        main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            child = flowbox
        };
        
        child = main_revealer;
        add_labels ();

        item.item_label_deleted.connect ((label) => {
            remove_item_label (label);
        });

        item.item_label_added.connect ((label) => {
            add_item_label (label);
        });
    }

    public void add_labels () {
        foreach (Objects.Label label in item._get_labels ()) {
            add_item_label (label);
        }

        main_revealer.reveal_child = has_items;
    }

    public void add_item_label (Objects.Label label) {
        if (!item_labels_map.has_key (label.id)) {
            item_labels_map[label.id] = new Widgets.ItemLabelChild (label);
            flowbox.append (item_labels_map[label.id]);
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
            flowbox.remove (item_label_row);
        }

        item_labels_map.clear ();
    }
}
