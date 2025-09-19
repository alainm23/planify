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
    public int max_items { get; construct; }
    public bool is_board { get; construct; }

    private Gtk.Box box_layout;
    private Gtk.Revealer revealer;
    public Gtk.Box content_box;
    private Gtk.Label more_label;
    private Adw.Bin more_label_grid;
    private Gtk.Revealer more_label_revealer;

    Gee.HashMap<string, Widgets.ItemLabelChild> labels = new Gee.HashMap<string, Widgets.ItemLabelChild> ();

    public bool reveal_child {
        set {
            revealer.reveal_child = value;
        }

        get {
            return revealer.reveal_child;
        }
    }
    
    public int start_margin {
        set {
            box_layout.margin_start = value;
        }
    }

    public int end_margin {
        set {
            box_layout.margin_end = value;
        }
    }

    public LabelsSummary (Objects.Item item, int max_items = 2, bool is_board = false) {
        Object (
            item: item,
            max_items: max_items,
            is_board: is_board
        );
    }

    ~LabelsSummary () {
        debug ("Destroying - Widgets.LabelsSummary\n");
    }

    construct {
        box_layout = new Gtk.Box (HORIZONTAL, 6) {
            halign = START
        };

        more_label = new Gtk.Label (null) {
            css_classes = { "caption" }
        };

        more_label_grid = new Adw.Bin () {
            valign = CENTER,
            css_classes = { "item-label-child" },
            child = more_label,
            margin_start = 6
        };

        more_label_revealer = new Gtk.Revealer () {
            transition_type = SLIDE_LEFT,
            child = more_label_grid
        };

        content_box = new Gtk.Box (HORIZONTAL, 0) {
            valign = Gtk.Align.CENTER
        };

        content_box.append (box_layout);
        content_box.append (more_label_revealer);

        revealer = new Gtk.Revealer () {
            transition_type = is_board ? Gtk.RevealerTransitionType.SLIDE_LEFT : Gtk.RevealerTransitionType.SLIDE_UP,
            child = content_box
        };

        child = revealer;
        update_request ();

        item.item_label_deleted.connect ((label) => {
            remove_item_label (label);
        });
    }

    public void update_request () {
        more_label_revealer.reveal_child = false;
        
        var item_labels = item._get_labels ();
        var overflow_labels = new Gee.ArrayList<Objects.Label> ();
        int current_visible = labels.size;
        
        foreach (Objects.Label label in item_labels) {
            if (!labels.has_key (label.id)) {
                if (current_visible >= max_items) {
                    overflow_labels.add (label);
                } else {
                    labels[label.id] = new Widgets.ItemLabelChild (label);
                    box_layout.append (labels[label.id]);
                    current_visible++;
                }
            }
        }
        
        if (overflow_labels.size > 0) {
            more_label.label = "+%d".printf (overflow_labels.size);
            more_label_grid.tooltip_text = create_overflow_tooltip (overflow_labels);
            
            Util.get_default ().set_widget_color (
                Util.get_default ().get_color (overflow_labels[0].color),
                more_label_grid
            );
            
            more_label_revealer.reveal_child = true;
        }
    }


    private string create_overflow_tooltip (Gee.ArrayList<Objects.Label> overflow_labels) {
        var tooltip_parts = new Gee.ArrayList<string> ();
        foreach (Objects.Label label in overflow_labels) {
            tooltip_parts.add ("- %s".printf (label.name));
        }
        return string.joinv ("\n", tooltip_parts.to_array ());
    }

    public void remove_item_label (Objects.Label label) {
        if (labels.has_key (label.id)) {
            labels[label.id].hide_destroy ();
            labels.unset (label.id);
        }
    }

    public void check_revealer () {
        revealer.reveal_child = labels.size > 0;
    }
}
