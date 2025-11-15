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
    private Widgets.LabelPicker.LabelRow create_label_row;
    
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
            
            if (label_row == create_label_row) {
                create_new_label (_filter_text);
            } else {
                label_selected (label_row.label);
            }
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
            height_request = 175
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
                reset_filter ();
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
        if (create_label_row != null) {
            listbox.remove (create_label_row);
            create_label_row = null;
        }
        
        int visible_count = 0;
        listbox.set_filter_func ((row) => {
            var label_row = (Widgets.LabelPicker.LabelRow) row;
            if (_filter_text == "") {
                return true;
            }
            
            bool matches = label_row.label.name.down ().contains (_filter_text.down ());
            if (matches) {
                visible_count++;
            }
            return matches;
        });
        
        if (visible_count == 0 && _filter_text.length > 0) {
            add_create_label_row ();
        } else {
            select_first_item ();
        }
    }
    
    private void add_create_label_row () {
        var create_label = new Objects.Label ();
        create_label.name = _("Label not found: Create '%s'").printf (_filter_text);
        create_label.color = "#a0a0a0";
        create_label.id = "create_new_label";
        
        create_label_row = new Widgets.LabelPicker.LabelRow (create_label) {
            hide_check_button = true
        };
        
        listbox.append (create_label_row);
        listbox.select_row (create_label_row);
    }
    
    private void create_new_label (string label_name) {
        if (create_label_row != null) {
            create_label_row.show_loading (true);
        }
        
        var label = new Objects.Label ();
        label.color = Util.get_default ().get_random_color ();
        label.name = label_name;
        label.source_id = _source.id;
        
        if (_source.source_type == SourceType.LOCAL || _source.source_type == SourceType.CALDAV) {
            label.id = Util.get_default ().generate_id (label);
            Services.Store.instance ().insert_label (label);
            label_selected (label);
        } else if (_source.source_type == SourceType.TODOIST) {
            Services.Todoist.get_default ().add.begin (label, (obj, res) => {
                HttpResponse response = Services.Todoist.get_default ().add.end (res);
                
                if (response.status) {
                    label.id = response.data;
                    Services.Store.instance ().insert_label (label);
                    label_selected (label);
                }
                
                if (create_label_row != null) {
                    create_label_row.show_loading (false);
                }
            });
        }
    }
    
    public void navigate_listbox (bool down) {
        var selected_row = listbox.get_selected_row ();
        
        if (selected_row == null) {
            int index = 0;
            while (true) {
                var row = listbox.get_row_at_index (index);
                if (row == null) break;
                if (row.get_child_visible ()) {
                    listbox.select_row (row);
                    scroll_to_selected ();
                    break;
                }
                index++;
            }
            return;
        }
        
        int current_index = selected_row.get_index ();
        int new_index = down ? current_index + 1 : current_index - 1;
        
        while (new_index >= 0) {
            var new_row = listbox.get_row_at_index (new_index);
            if (new_row == null) break;
            if (new_row.get_child_visible ()) {
                listbox.select_row (new_row);
                scroll_to_selected ();
                break;
            }
            new_index = down ? new_index + 1 : new_index - 1;
        }
    }
    
    public void activate_selected () {
        var selected_row = listbox.get_selected_row ();
        if (selected_row != null) {
            var label_row = (Widgets.LabelPicker.LabelRow) selected_row;
            
            if (label_row == create_label_row) {
                create_new_label (_filter_text);
            } else {
                label_selected (label_row.label);
            }
        }
    }
    
    public void select_first_item () {
        int index = 0;
        while (true) {
            var row = listbox.get_row_at_index (index);
            if (row == null) break;
            if (row.get_child_visible ()) {
                listbox.select_row (row);
                scroll_to_selected ();
                break;
            }
            index++;
        }
    }
    
    public void reset_filter () {
        if (create_label_row != null) {
            listbox.remove (create_label_row);
            create_label_row = null;
        }
        
        listbox.set_filter_func (null);
        listbox.unselect_all ();
    }
    
    private int count_visible_children () {
        int count = 0;
        int index = 0;
        while (true) {
            var row = listbox.get_row_at_index (index);
            if (row == null) break;
            if (row.get_child_visible ()) {
                count++;
            }
            index++;
        }
        return count;
    }
    
    private void scroll_to_selected () {
        var selected_row = listbox.get_selected_row ();
        if (selected_row == null) return;
        
        Gtk.Allocation allocation;
        selected_row.get_allocation (out allocation);
        
        var adjustment = listbox_scrolled.vadjustment;
        double row_start = allocation.y;
        double row_end = allocation.y + allocation.height;
        double visible_start = adjustment.value;
        double visible_end = adjustment.value + adjustment.page_size;
        
        if (row_start < visible_start) {
            adjustment.value = row_start - 10;
        } else if (row_end > visible_end) {
            adjustment.value = row_end - adjustment.page_size + 10;
        }
    }
}
