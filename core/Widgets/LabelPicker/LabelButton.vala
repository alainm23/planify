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

public class Widgets.LabelPicker.LabelButton : Adw.Bin {
    public bool is_board { get; construct; }

    private Gtk.MenuButton button; 
    private Widgets.LabelPicker.LabelPicker labels_picker;
    private Gtk.Label labels_label;

    public Gee.ArrayList<Objects.Label> labels {
        set {
            labels_picker.labels = value;
        }
    }

    Objects.Source _source;
    public Objects.Source source {
        set {
            _source = value;
            labels_picker.source = _source;
        }

        get {
            return _source;
        }
    }

    public signal void labels_changed (Gee.HashMap<string, Objects.Label> labels);

    public LabelButton () {
        Object (
            is_board: false,
            valign: Gtk.Align.CENTER,
            halign: Gtk.Align.CENTER,
            tooltip_text: _("Add Labels")
        );
    }

    public LabelButton.for_board () {
        Object (
            is_board: true,
            tooltip_text: _("Add Labels")
        );
    }

    ~LabelButton() {
        print ("Destroying Widgets.LabelPicker.LabelButton\n");
    }

    construct {
        labels_picker = new Widgets.LabelPicker.LabelPicker ();

        if (is_board) {
            var title_label = new Gtk.Label (_("Labels")) {
                halign = START,
                css_classes = { "title-4", "caption" }
            };

            labels_label = new Gtk.Label (_("Select Labels")) {
                xalign = 0,
                use_markup = true,
                halign = START,
                ellipsize = Pango.EllipsizeMode.END,
                css_classes = { "caption" }
            };

            var card_grid = new Gtk.Grid () {
                column_spacing = 12,
                margin_start = 12,
                margin_end = 6,
                margin_top = 6,
                margin_bottom = 6,
                vexpand = true,
                hexpand = true
            };
            card_grid.attach (new Gtk.Image.from_icon_name ("tag-outline-symbolic"), 0, 0, 1, 2);
            card_grid.attach (title_label, 1, 0, 1, 1);
            card_grid.attach (labels_label, 1, 1, 1, 1);

            labels_picker.set_parent (card_grid);
            labels_picker.position = Gtk.PositionType.BOTTOM;
            labels_picker.has_arrow = true;

            css_classes = { "card", "activatable" };
            child = card_grid;
            hexpand = true;
            vexpand = true;
    
            var click_gesture = new Gtk.GestureClick ();
            card_grid.add_controller (click_gesture);
            click_gesture.pressed.connect ((n_press, x, y) => {
                labels_picker.show ();
            });
        } else {
            button = new Gtk.MenuButton () {
                icon_name = "tag-outline-symbolic",
                popover = labels_picker,
                css_classes = { "flat" }
            };
            
            child = button;
        }

        labels_picker.closed.connect (() => {
            labels_changed (labels_picker.picked);
        });
    }

    public void reset () {
        labels_picker.reset ();
    }

    public void update_from_item (Objects.Item item) {
        labels_label.label = _("Select Labels");
        labels_label.tooltip_text = null;

        if (item.labels.size > 0) {
            labels_label.label = "";        
            for (int index = 0; index < item.labels.size; index++) {
                if (index < item.labels.size - 1) {
                    labels_label.label += item.labels[index].name + ", ";
                } else {
                    labels_label.label += item.labels[index].name;
                }
            }

            labels_label.tooltip_text = labels_label.label;
        }
    }
}
