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

public class Widgets.ItemLabels : Gtk.Grid {
    public Objects.Item item { get; construct; }

    private Gtk.FlowBox flowbox;
    private Gtk.Revealer main_revealer;

    public signal void labels_changed (Gee.HashMap <string, Objects.Label> labels);
    public signal void dialog_open (bool value);

    private bool has_items {
        get {
            return item_labels_map.size > 0;
        }
    }

    private Gee.HashMap<string, Widgets.ItemLabelChild> item_labels_map;

    public ItemLabels (Objects.Item item) {
        Object (
            item: item
        );
    }

    construct {
        item_labels_map = new Gee.HashMap<string, Widgets.ItemLabelChild> ();

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
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };

        main_revealer.child = flowbox;
        
        attach (main_revealer, 0, 0);
        add_labels ();

        //  button_press_event.connect ((sender, evt) => {
        //      if (evt.type == Gdk.EventType.BUTTON_PRESS && evt.button == 1) {
        //          var dialog = new Dialogs.LabelPicker.LabelPicker ();
        //          dialog.item = item;
                
        //          dialog.labels_changed.connect ((labels) => {
        //              labels_changed (labels);
        //          });
                
        //          dialog_open (true);
        //          dialog.popup ();

        //          dialog.destroy.connect (() => {
        //              dialog_open (false);
        //          });
        //      }

        //      return Gdk.EVENT_PROPAGATE;
        //  });

        item.item_label_added.connect ((item_label) => {
            add_item_label (item_label);
        });

        item.item_label_deleted.connect ((item_label) => {
            remove_item_label (item_label);
        });
    }

    public void add_labels () {
        foreach (Objects.ItemLabel item_label in item.labels.values) {
            add_item_label (item_label);
        }

        main_revealer.reveal_child = has_items;
    }

    public void add_item_label (Objects.ItemLabel item_label) {
        if (!item_labels_map.has_key (item_label.id_string)) {
            item_labels_map[item_label.id_string] = new Widgets.ItemLabelChild (item_label);
            flowbox.append (item_labels_map[item_label.id_string]);
        }

        main_revealer.reveal_child = has_items;
    }

    public void remove_item_label (Objects.ItemLabel item_label) {
        if (item_labels_map.has_key (item_label.id_string)) {
            flowbox.remove (item_labels_map[item_label.id_string]);
            item_labels_map.unset (item_label.id_string);
        }

        main_revealer.reveal_child = has_items;
    }

    public void update_labels () {
        foreach (Widgets.ItemLabelChild item_label_row in item_labels_map.values) {
            flowbox.remove (item_label_row);
        }

        item_labels_map.clear ();
        add_labels ();
    }
}