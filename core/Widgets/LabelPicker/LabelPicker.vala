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

public class Widgets.LabelPicker.LabelPicker : Gtk.Popover {
    public BackendType backend_type { get; construct; }

    private Gtk.SearchEntry search_entry;
    private Gtk.Stack placeholder_stack;
    private Gtk.ListBox listbox;
    
    public Gee.HashMap <string, Widgets.LabelPicker.LabelRow> labels_widgets_map;

    public Gee.HashMap<string, Objects.Label> picked = new Gee.HashMap<string, Objects.Label> ();
    public Gee.ArrayList<Objects.Label> labels {
        set {
            picked.clear ();

            foreach (Objects.Label label in value) {
                labels_widgets_map [label.id].active = true;
                picked[label.id] = label;
            }
        }
    }

    public bool is_loading {
        set {
            placeholder_stack.visible_child_name = value ? "spinner" : "message";
        }
    }

    public LabelPicker (BackendType backend_type = BackendType.ALL) {
        Object (
            backend_type: backend_type,
            has_arrow: false,
            position: Gtk.PositionType.TOP,
            width_request: 275,
            height_request: 300
        );
    }

    construct {
        css_classes = { "popover-contents" };

        labels_widgets_map = new Gee.HashMap <string, Widgets.LabelPicker.LabelRow> ();

        search_entry = new Gtk.SearchEntry () {
            placeholder_text = _("Search or Create"),
            valign = Gtk.Align.CENTER,
            hexpand = true,
            margin_top = 9,
            margin_start = 9,
            margin_end = 9,
            margin_bottom = 9
        };

        listbox = new Gtk.ListBox () {
            hexpand = true
        };

        listbox.set_placeholder (get_placeholder ());
        listbox.set_filter_func (filter_func);
        listbox.add_css_class ("listbox-separator-3");
        listbox.add_css_class ("listbox-background");

        var listbox_grid = new Adw.Bin () {
            margin_start = 3,
            margin_end = 3,
            margin_bottom = 9,
            child = listbox
        };

        var listbox_scrolled = new Gtk.ScrolledWindow () {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            hexpand = true,
            vexpand = true
        };

        listbox_scrolled.child = listbox_grid;

        var toolbar_view = new Adw.ToolbarView ();
		toolbar_view.add_top_bar (search_entry);
		toolbar_view.content = listbox_scrolled;

        child = toolbar_view;
        add_all_labels ();

        var controller_key = new Gtk.EventControllerKey ();
        toolbar_view.add_controller (controller_key);

        controller_key.key_pressed.connect ((keyval, keycode, state) => {
            var key = Gdk.keyval_name (keyval).replace ("KP_", "");
                        
            if (key == "Up" || key == "Down") {
                return false;
            } else if (key == "Enter" || key == "Return" || key == "KP_Enter") {
                return false;
            } else {
                if (!search_entry.has_focus) {
                    search_entry.grab_focus ();
                    if (search_entry.cursor_position < search_entry.text.length) {
                        search_entry.set_position (search_entry.text.length);
                    }
                }

                return false;
            }

            return true;
        });

        search_entry.search_changed.connect (() => {
            listbox.invalidate_filter ();
        });

        search_entry.activate.connect (() => {
            if (search_entry.text.length > 0) {
                Objects.Label label = Services.Database.get_default ().get_label_by_name (search_entry.text, true, backend_type);
                if (label != null) {
                    if (labels_widgets_map.has_key (label.id_string)) {
                        labels_widgets_map [label.id_string].update_checked_toggled ();
                    }
                } else {
                    add_assign_label ();
                }
            }
        });

        Services.Database.get_default ().label_added.connect ((label) => {
            add_label (label);
        });
    }

    private void add_assign_label () {
        var label = new Objects.Label ();
        label.color = Util.get_default ().get_random_color ();
        label.name = search_entry.text;

        if (backend_type == BackendType.TODOIST) {
            is_loading = true;
            label.backend_type = BackendType.TODOIST;
            Services.Todoist.get_default ().add.begin (label, (obj, res) => {
                TodoistResponse response = Services.Todoist.get_default ().add.end (res);

                if (response.status) {
                    label.id = response.data;
                    Services.Database.get_default ().insert_label (label);
                    checked_toggled (label, true);
                    
                    popdown ();
                    is_loading = false;
                    search_entry.text = "";
                } else {
                    
                }
            });
        } else if (backend_type == BackendType.LOCAL) {
            label.id = Util.get_default ().generate_id (label);
            label.backend_type = BackendType.LOCAL;
            Services.Database.get_default ().insert_label (label);

            popdown ();
            is_loading = false;
            search_entry.text = "";
        }
    }

    private void add_all_labels () {
        foreach (Objects.Label label in Services.Database.get_default ().get_labels_by_backend_type (backend_type)) {
            add_label (label);
        }
    }

    private void add_label (Objects.Label label) {
        labels_widgets_map [label.id] = new Widgets.LabelPicker.LabelRow (label);
        labels_widgets_map [label.id].checked_toggled.connect (checked_toggled);
        listbox.append (labels_widgets_map [label.id]);
    }

    private Gtk.Widget get_placeholder () {
        var message_label = new Gtk.Label (_("Your list of filters will show up here. Create one by entering the name and pressing the Enter key.")) {
            wrap = true,
            justify = Gtk.Justification.CENTER
        };
        
        message_label.add_css_class ("dim-label");
        message_label.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);
        
        var spinner = new Gtk.Spinner () {
            valign = Gtk.Align.CENTER,
            valign = Gtk.Align.CENTER,
            height_request = 32,
            width_request = 32
        };

        spinner.add_css_class ("text-color");
        spinner.start ();

        placeholder_stack = new Gtk.Stack () {
            vexpand = true,
            hexpand = true,
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };

        placeholder_stack.add_named (message_label, "message");
        placeholder_stack.add_named (spinner, "spinner");

        var grid = new Gtk.Grid () {
            margin_top = 6,
            margin_bottom = 6,
            margin_start = 6,
            margin_end = 6,
            valign = Gtk.Align.CENTER
        };

        grid.attach (placeholder_stack, 0, 0);

        return grid;
    }

    private void checked_toggled (Objects.Label label, bool active) {
        if (active) {
            if (!picked.has_key (label.id)) {
                picked [label.id] = label;
            }
        } else {
            if (picked.has_key (label.id)) {
                picked.unset (label.id);
            }
        }
    }

    private bool filter_func (Gtk.ListBoxRow row) {
        var label = ((Widgets.LabelPicker.LabelRow) row).label;
        return search_entry.text.down () in label.name.down ();
    }
}
