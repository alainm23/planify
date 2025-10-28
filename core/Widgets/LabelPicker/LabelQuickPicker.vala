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

public class Widgets.LabelPicker.LabelQuickPicker : Gtk.Popover {
    private Gtk.ListBox listbox;
    private Gtk.ScrolledWindow listbox_scrolled;
    private Gtk.EventControllerKey key_controller;
    
    public signal void label_selected (Objects.Label label);

    Objects.Source _source;
    public Objects.Source source {
        set {
            _source = value;
            add_labels (_source);
        }

        get {
            return _source;
        }
    }

    private string _filter_text = "";
    public string filter_text {
        get { return _filter_text; }
        set {
            _filter_text = value;
            apply_filter ();
        }
    }

    public Gee.HashMap<string, Widgets.LabelPicker.LabelRow> labels_widgets_map = new Gee.HashMap<string, Widgets.LabelPicker.LabelRow> ();
    
    public LabelQuickPicker () {
        Object (
            has_arrow: false,
            autohide: false,
            position: Gtk.PositionType.BOTTOM,
            width_request: 275
        );
    }

    ~LabelQuickPicker () {
        debug ("Destroying - Widgets.LabelPicker.LabelQuickPicker\n");
    }

    construct {
        listbox = new Gtk.ListBox () {
            hexpand = true,
            valign = Gtk.Align.START,
            css_classes = { "listbox-background" }
        };

        listbox.set_sort_func ((row1, row2) => {
            Objects.Label item1 = ((Widgets.LabelPicker.LabelRow) row1).label;
            Objects.Label item2 = ((Widgets.LabelPicker.LabelRow) row2).label;
            return item1.item_order - item2.item_order;
        });
        
        listbox.row_activated.connect ((row) => {
            var label_row = (Widgets.LabelPicker.LabelRow) row;
            label_selected (label_row.label);
        });

        var listbox_content = new Adw.Bin () {
            child = listbox,
            margin_start = 6,
            margin_end = 6,
            margin_top = 6,
            margin_bottom = 6
        };

        listbox_scrolled = new Gtk.ScrolledWindow () {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            hexpand = true,
            vexpand = true,
            child = listbox_content,
            max_content_height = 175,
            propagate_natural_height = true
        };

        child = listbox_scrolled;
        add_css_class ("popover-contents");
        
        key_controller = new Gtk.EventControllerKey ();
        key_controller.key_pressed.connect ((keyval, keycode, state) => {
            if (keyval == Gdk.Key.Tab || keyval == Gdk.Key.ISO_Left_Tab) {
                popdown ();
                return true;
            }
            return false;
        });
        ((Gtk.Widget) this).add_controller (key_controller);
        
        notify["visible"].connect (() => {
            if (visible) {
                setup_focus_monitoring ();
            }
        });
    }
    
    private void setup_focus_monitoring () {
        var parent_widget = get_parent ();
        if (parent_widget == null) return;
        
        var focus_controller = new Gtk.EventControllerFocus ();
        focus_controller.leave.connect (() => {
            Timeout.add (50, () => {
                if (visible && !parent_widget.has_focus) {
                    popdown ();
                }
                return GLib.Source.REMOVE;
            });
        });
        parent_widget.add_controller (focus_controller);
    }

    private void add_labels (Objects.Source source) {
        labels_widgets_map.clear ();

        foreach (unowned Gtk.Widget child in Util.get_default ().get_children (listbox)) {
            listbox.remove (child);
        }

        foreach (Objects.Label label in Services.Store.instance ().get_labels_by_source (source.id)) {
            add_label (label);
        }
    }

    private void add_label (Objects.Label label) {
        labels_widgets_map[label.id] = new Widgets.LabelPicker.LabelRow (label) {
            hide_check_button = true
        };
        listbox.append (labels_widgets_map[label.id]);
    }

    private void apply_filter () {
        listbox.set_filter_func ((row) => {
            var label_row = (Widgets.LabelPicker.LabelRow) row;
            if (_filter_text == "") {
                return true;
            }
            
            return label_row.label.name.down ().contains (_filter_text.down ());
        });
    }
    
    public void navigate_listbox (bool down) {
        var selected_row = listbox.get_selected_row ();
        
        if (selected_row == null) {
            var first_row = listbox.get_row_at_index (0);
            if (first_row != null && first_row.visible) {
                listbox.select_row (first_row);
                scroll_to_selected ();
            }
            return;
        }
        
        int current_index = selected_row.get_index ();
        int new_index = down ? current_index + 1 : current_index - 1;
        
        var new_row = listbox.get_row_at_index (new_index);
        if (new_row != null && new_row.visible) {
            listbox.select_row (new_row);
            scroll_to_selected ();
        }
    }
    
    public void activate_selected () {
        var selected_row = listbox.get_selected_row ();
        if (selected_row != null) {
            var label_row = (Widgets.LabelPicker.LabelRow) selected_row;
            label_selected (label_row.label);
        }
    }
    
    public void select_first_item () {
        var first_row = listbox.get_row_at_index (0);
        if (first_row != null && first_row.visible) {
            listbox.select_row (first_row);
            scroll_to_selected ();
        }
    }
    
    private void scroll_to_selected () {
        var selected_row = listbox.get_selected_row ();
        if (selected_row == null) return;
        
        Gtk.Allocation allocation;
        selected_row.get_allocation (out allocation);
        
        var vadjustment = listbox_scrolled.get_vadjustment ();
        
        int margin_top = 6;
        int margin_bottom = 6;
        int padding = 3;
        
        double row_top = allocation.y + margin_top;
        double row_bottom = allocation.y + allocation.height + margin_top;
        double visible_top = vadjustment.get_value ();
        double visible_bottom = visible_top + vadjustment.get_page_size ();
        
        if (row_top < visible_top + padding) {
            vadjustment.set_value (Math.fmax (0, row_top - padding));
        } else if (row_bottom > visible_bottom - padding) {
            double new_value = row_bottom - vadjustment.get_page_size () + margin_bottom + padding;
            vadjustment.set_value (Math.fmin (new_value, vadjustment.get_upper () - vadjustment.get_page_size ()));
        }
    }
}
