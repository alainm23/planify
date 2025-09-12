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

public class Widgets.ProjectPicker.ProjectPickerPopover : Gtk.Popover {
    public signal void selected (Objects.Project project);

    private Gtk.ListBox listbox;
    private Gtk.Revealer search_entry_revealer;

    public bool search_visible {
        set {
            // search_entry_revealer.reveal_child = value;
        }
    }

    private Gee.HashMap<ulong, weak GLib.Object> signal_map = new Gee.HashMap<ulong, weak GLib.Object> ();

    public ProjectPickerPopover () {
        Object (
            height_request: 300,
            width_request: 275,
            has_arrow: false,
            position: Gtk.PositionType.BOTTOM
        );
    }

    ~ProjectPickerPopover () {
        print ("Destroying - Widgets.ProjectPicker.ProjectPickerPopover\n");
    }

    construct {
        css_classes = { "popover-contents" };

        var search_entry = new Gtk.SearchEntry () {
            margin_top = 9,
            margin_start = 9,
            margin_end = 9,
            margin_bottom = 9
        };

        search_entry_revealer = new Gtk.Revealer () {
            child = search_entry,
            reveal_child = true
        };

        listbox = new Gtk.ListBox () {
            hexpand = true,
            valign = Gtk.Align.START,
            css_classes = { "listbox-background" },
            margin_start = 9,
            margin_end = 9,
            margin_bottom = 9
        };

        listbox.set_sort_func (sort_source_function);
        listbox.set_header_func (header_project_function);
        listbox.set_filter_func ((row) => {
            var project = ((Widgets.ProjectPicker.ProjectPickerRow) row).project;
            return search_entry.text.down () in project.name.down ();
        });
        
        var scrolled_window = new Gtk.ScrolledWindow () {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            hexpand = true,
            vexpand = true,
            child = listbox
        };

        var toolbar_view = new Adw.ToolbarView ();
        toolbar_view.add_top_bar (search_entry_revealer);
        toolbar_view.content = scrolled_window;

        child = toolbar_view;
        add_projects ();

        signal_map[search_entry.search_changed.connect (() => {
            scrolled_window.vadjustment.value = 0;
            listbox.invalidate_filter ();
        })] = search_entry;

        signal_map[listbox.row_activated.connect ((row) => {
            selected (((Widgets.ProjectPicker.ProjectPickerRow) row).project);
            popdown ();
        })] = listbox;

        var listbox_controller_key = new Gtk.EventControllerKey ();
        listbox.add_controller (listbox_controller_key);
        signal_map[listbox_controller_key.key_pressed.connect ((keyval, keycode, state) => {
            var key = Gdk.keyval_name (keyval).replace ("KP_", "");

            if (key == "Up" || key == "Down") {
            } else if (key == "Enter" || key == "Return" || key == "KP_Enter") {
            } else {
                if (!search_entry.has_focus) {
                    search_entry.grab_focus ();
                    if (search_entry.cursor_position < search_entry.text.length) {
                        search_entry.set_position (search_entry.text.length);
                    }
                }
            }

            return false;
        })] = listbox_controller_key;

        var search_entry_ctrl_key = new Gtk.EventControllerKey ();
        search_entry.add_controller (search_entry_ctrl_key);
        signal_map[search_entry_ctrl_key.key_pressed.connect ((keyval, keycode, state) => {
            if (keyval == 65307) {
                popdown ();
            }

            return false;
        })] = search_entry_ctrl_key;
    }

    private void add_projects () {
        foreach (Objects.Project project in Services.Store.instance ().projects) {
            listbox.append (build_project_row (project));
        }
    }

    private Gtk.Widget build_project_row (Objects.Project project) {
        var row = new Widgets.ProjectPicker.ProjectPickerRow (project);

        signal_map[row.selected.connect (() => {
            selected (row.project);
            popdown ();
        })] = row;

        return row;
    }

    private int sort_source_function (Gtk.ListBoxRow row1, Gtk.ListBoxRow ? row2) {
        var project1 = ((Widgets.ProjectPicker.ProjectPickerRow) row1).project;
        var project2 = ((Widgets.ProjectPicker.ProjectPickerRow) row2).project;
        return project2.source.id.collate (project1.source.id);
    }

    private void header_project_function (Gtk.ListBoxRow lbrow, Gtk.ListBoxRow ? lbbefore) {
        if (!(lbrow is Widgets.ProjectPicker.ProjectPickerRow)) {
            return;
        }

        var row = (Widgets.ProjectPicker.ProjectPickerRow) lbrow;
        if (lbbefore != null && lbbefore is Widgets.ProjectPicker.ProjectPickerRow) {
            var before = (Widgets.ProjectPicker.ProjectPickerRow) lbbefore;

            if (row.project.source.id == before.project.source.id) {
                row.set_header (null);
                return;
            }
        }

        row.set_header (get_header_box (row.project.source.header_text));
    }

    private Gtk.Widget get_header_box (string title) {
        var header_label = new Gtk.Label (title) {
            css_classes = { "heading" },
            halign = START,
            margin_start = 3
        };

        var header_separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
            hexpand = true,
            margin_bottom = 6,
            margin_start = 3
        };

        var header_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
            margin_top = 12,
            margin_start = 3
        };

        header_box.append (header_label);
        header_box.append (header_separator);

        return header_box;
    }

    public void clean_up () {
        listbox.set_sort_func (null);
        listbox.set_header_func (null);
        listbox.set_filter_func (null);

        foreach (var entry in signal_map.entries) {
            entry.value.disconnect (entry.key);
        }

        signal_map.clear ();

        foreach (unowned Gtk.Widget child in Util.get_default ().get_children (listbox)) {
            ((Widgets.ProjectPicker.ProjectPickerRow) child).clean_up ();
        }
    }
}
