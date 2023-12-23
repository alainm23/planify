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

public class Widgets.LabelsSummary : Adw.Bin {
    public Objects.Item item { get; construct; }

    private Gtk.FlowBox labels_flowbox;
    private Gtk.Revealer revealer;

    private Gtk.Label more_label;
    private Adw.Bin more_label_grid;
    private Gtk.Revealer more_label_revealer;

    Gee.HashMap<string, Widgets.ItemLabelChild> labels;

    public bool reveal_child {
        set {
            revealer.reveal_child = value;
        }
    }

    public LabelsSummary (Objects.Item item) {
        Object (item: item);
    }

    construct {
        labels = new Gee.HashMap<string, Widgets.ItemLabelChild> ();

        labels_flowbox = new Gtk.FlowBox () {
            column_spacing = 6,
            row_spacing = 6,
            homogeneous = false,
            hexpand = false,
            orientation = Gtk.Orientation.VERTICAL,
            halign = Gtk.Align.START,
            valign = Gtk.Align.START,
            min_children_per_line = 1,
            max_children_per_line = 20,
            margin_end = 6,
        };

        more_label = new Gtk.Label (null) {
            css_classes = { "small-label" }
        };
        
        more_label_grid = new Adw.Bin () {
            margin_end = 6,
            valign = Gtk.Align.START,
            css_classes = { "item-label-child" },
            child = more_label
        };

        more_label_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT,
            child = more_label_grid
        };

        var content_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            valign = Gtk.Align.START,
            margin_top = 3,
            margin_start = 24
        };

        content_box.append (labels_flowbox);
        content_box.append (more_label_revealer);

        revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_UP,
            child = content_box
        };

        child = revealer;
        update_request ();

        item.item_label_deleted.connect ((item_label) => {
            remove_item_label (item_label);
        });
    }

    public void update_request () {
        int more = 0;
        int count = 0;
        string tooltip_text = "";
        more_label_revealer.reveal_child = false;

        foreach (Objects.ItemLabel item_label in item.labels.values) {
            if (!labels.has_key (item_label.id_string)) {
                if (labels.size >= 3) {
                    more++;
                    more_label.label = "+%d".printf (more);
                    tooltip_text += "- %s%s".printf (
                        item_label.label.name,
                        more + 1 >= item.labels.values.size ? "" : "\n"
                    );
                    more_label_grid.tooltip_text = tooltip_text;
                    more_label_revealer.reveal_child = true;
                } else {
                    Util.get_default ().set_widget_color (
                        Util.get_default ().get_color (item_label.label.color),
                        more_label_grid
                    );

                    labels[item_label.id_string] = new Widgets.ItemLabelChild (item_label);
                    labels_flowbox.append (labels[item_label.id_string]);
                }

                count++;
            }
        }
    }

    public void remove_item_label (Objects.ItemLabel item_label) {
        if (labels.has_key (item_label.id_string)) {
            labels_flowbox.remove (labels[item_label.id_string]);
            labels.unset (item_label.id_string);
        }
    }

    public void check_revealer () {
        revealer.reveal_child = labels.size > 0;
    }
}