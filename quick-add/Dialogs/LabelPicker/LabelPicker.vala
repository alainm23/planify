/*
* Copyright © 2019 Alain M. (https://github.com/alainm23/planner)
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

public class Dialogs.LabelPicker.LabelPicker : Hdy.Window {
    public Objects.Item item { get; construct; }

    private Gtk.SearchEntry search_entry;
    private Gtk.ListBox listbox;
    
    private Gtk.Button cancel_clear_button;
    public Gee.HashMap <string, Objects.Label> labels_map;
    public Gee.HashMap <string, Dialogs.LabelPicker.LabelRow> labels_widgets_map;

    public signal void labels_changed (Gee.HashMap <string, Objects.Label> labels_map);

    public LabelPicker (Objects.Item item) {
        Object (
            item: item,
            transient_for: (Gtk.Window) PlannerQuickAdd.instance.main_window.get_toplevel (),
            destroy_with_parent: true,
            window_position: Gtk.WindowPosition.MOUSE,
            resizable: false
        );
    }

    construct {
        labels_map = new Gee.HashMap <string, Objects.Label> ();
        labels_widgets_map = new Gee.HashMap <string, Dialogs.LabelPicker.LabelRow> ();

        foreach (var entry in item.labels.entries) {
            labels_map [entry.key] = entry.value.label;
        }

        var headerbar = new Hdy.HeaderBar () {
            has_subtitle = false,
            show_close_button = false,
            hexpand = true
        };
        headerbar.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        headerbar.get_style_context ().add_class ("default-decoration");

        var done_button = new Gtk.Button.with_label (_("Done")) {
            halign = Gtk.Align.CENTER,
            valign = Gtk.Align.CENTER,
            can_focus = false
        };
        done_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        done_button.get_style_context ().add_class ("primary-color");
        done_button.get_style_context ().add_class (Granite.STYLE_CLASS_SMALL_LABEL);

        cancel_clear_button = new Gtk.Button.with_label (_("Clear")) {
            halign = Gtk.Align.CENTER,
            valign = Gtk.Align.CENTER,
            can_focus = false
        };
        cancel_clear_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        cancel_clear_button.get_style_context ().add_class (Granite.STYLE_CLASS_SMALL_LABEL);

        var title_label = new Gtk.Label (_("Labels"));
        title_label.get_style_context ().add_class ("h4");

        var header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            hexpand = true,
            margin_start = 3,
            margin_end = 3
        };
        header_box.pack_start (cancel_clear_button, false, false, 0);
        header_box.set_center_widget (title_label);
        header_box.pack_end (done_button, false, false, 0);

        headerbar.set_custom_title (header_box);

        search_entry = new Gtk.SearchEntry () {
            placeholder_text = _("Search or Create"),
            valign = Gtk.Align.CENTER,
            hexpand = true,
            margin_start = 9,
            margin_end = 9,
            margin_top = 3,
            margin_bottom = 12
        };

        search_entry.get_style_context ().add_class ("border-radius-6");
        search_entry.get_style_context ().add_class ("picker-background");

        listbox = new Gtk.ListBox () {
            hexpand = true
        };
        listbox.set_placeholder (get_placeholder ());
        listbox.set_filter_func (filter_func);

        unowned Gtk.StyleContext listbox_context = listbox.get_style_context ();
        listbox_context.add_class ("picker-background");
        listbox_context.add_class ("listbox-separator-3");
        
        var listbox_scrolled = new Gtk.ScrolledWindow (null, null) {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            vscrollbar_policy = Gtk.PolicyType.NEVER,
            expand = true,
            height_request = 64
        };
        listbox_scrolled.add (listbox);

        var content_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            hexpand = true,
            margin = 9,
            margin_top = 0,
            margin_bottom = 12
        };
        
        content_grid.add (listbox_scrolled);

        unowned Gtk.StyleContext content_grid_context = content_grid.get_style_context ();
        content_grid_context.add_class ("picker-content");

        var main_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            width_request = 225
        };
        main_grid.add (headerbar);
        main_grid.add (search_entry);
        main_grid.add (content_grid);

        unowned Gtk.StyleContext main_grid_context = main_grid.get_style_context ();
        main_grid_context.add_class ("picker");

        add (main_grid);
        add_all_labels ();

        key_press_event.connect ((event) => {
            var key = Gdk.keyval_name (event.keyval).replace ("KP_", "");

            if (key == "Up" || key == "Down") {
                return false;
            } else if (key == "Enter" || key == "Return" || key == "KP_Enter") {
                return false;
            } else {
                if (!search_entry.has_focus) {
                    search_entry.grab_focus ();
                    search_entry.move_cursor (Gtk.MovementStep.BUFFER_ENDS, 0, false);
                }

                return false;
            }

            return true;
        });

        focus_out_event.connect (() => {
            labels_changed (labels_map);
            hide_destroy ();
            return false;
        });

        key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                hide_destroy ();
            }

            return false;
        });

        done_button.clicked.connect (() => {
            labels_changed (labels_map);
            hide_destroy ();
        });

        cancel_clear_button.clicked.connect (() => {
            labels_map.clear ();
            labels_changed (labels_map);
            hide_destroy ();
        });

        search_entry.search_changed.connect (() => {
            listbox.invalidate_filter ();
        });

        search_entry.activate.connect (() => {
            if (QuickAddUtil.is_input_valid (search_entry)) {
                Objects.Label label = Services.Database.get_default ().get_label_by_name (search_entry.text, true);
                if (label != null) {
                    if (labels_widgets_map.has_key (label.id_string)) {
                        labels_widgets_map [label.id_string].update_checked_toggled ();
                    }
                } else {
                    add_assign_label ();
                }
            }
        });
    }

    private void add_assign_label () {
        //  BackendType backend_type = (BackendType) PlannerQuickAdd.settings.get_enum ("backend-type");

        //  var label = new Objects.Label ();
        //  label.color = QuickAddUtil.get_random_color ();
        //  label.name = search_entry.text;

        //  if (backend_type == BackendType.TODOIST) {
        //      label.todoist = true;
        //      Planner.todoist.add.begin (label, (obj, res) => {
        //          label.id = Planner.todoist.add.end (res);
        //          Planner.database.insert_label (label);
        //          checked_toggled (label, true);
        //          labels_changed (labels_map);
        //          hide_destroy ();
        //      });
        //  } else if (backend_type == BackendType.LOCAL) {
        //      label.id = QuickAddUtil.generate_id ();
        //      Planner.database.insert_label (label);
        //      checked_toggled (label, true);
        //      labels_changed (labels_map);
        //      hide_destroy ();
        //  }
    }

    private void add_all_labels () {
        foreach (Objects.Label label in Services.Database.get_default ().labels) {
            Dialogs.LabelPicker.LabelRow row = new Dialogs.LabelPicker.LabelRow (label, item.labels.has_key (label.id_string));
            row.checked_toggled.connect (checked_toggled);

            labels_widgets_map [label.id_string] = row;
            listbox.add (row);
        }

        listbox.show_all ();
    }
    
    private void hide_destroy () {
        hide ();

        Timeout.add (500, () => {
            destroy ();
            return GLib.Source.REMOVE;
        });
    }

    public void popup () {
        show_all ();

        // Gdk.Rectangle rect;
        // get_allocation (out rect);

        // int root_x, root_y;
        // get_position (out root_x, out root_y);

        // move (root_x + (rect.width / 3), root_y + (rect.height / 3) + 24);
    }

    private Gtk.Widget get_placeholder () {
        var message_label = new Gtk.Label ("Your list of filters will show up here. Create one by entering the name and pressing the Enter key") {
            wrap = true,
            justify = Gtk.Justification.CENTER
        };
        
        unowned Gtk.StyleContext message_label_context = message_label.get_style_context ();
        message_label_context.add_class ("dim-label");
        message_label_context.add_class (Granite.STYLE_CLASS_SMALL_LABEL);

        var grid = new Gtk.Grid () {
            margin = 6,
            valign = Gtk.Align.CENTER
        };
        grid.add (message_label);
        grid.show_all ();

        return grid;
    }

    private void checked_toggled (Objects.Label label, bool active) {
        if (active) {
            if (!labels_map.has_key (label.id_string)) {
                labels_map [label.id_string] = label;
            }
        } else {
            if (labels_map.has_key (label.id_string)) {
                labels_map.unset (label.id_string);
            }
        }
    }

    private bool filter_func (Gtk.ListBoxRow row) {
        var label = ((Dialogs.LabelPicker.LabelRow) row).label;
        return search_entry.text.down () in label.name.down ();
    }
}
