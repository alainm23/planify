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

public class Dialogs.QuickFind.QuickFind : Hdy.Window {
    private Gtk.SearchEntry search_entry;
    private Gtk.ListBox listbox;

    public QuickFind () {
        Object (
            transient_for: Planner.instance.main_window,
            deletable: false,
            destroy_with_parent: true,
            window_position: Gtk.WindowPosition.CENTER_ON_PARENT,
            title: _("Quick Find"),
            modal: true,
            width_request: 400,
            height_request: 300
        );
    }

    construct {
        unowned Gtk.StyleContext main_context = get_style_context ();
        main_context.add_class ("picker");
        transient_for = Planner.instance.main_window;

        var headerbar = new Hdy.HeaderBar ();
        headerbar.has_subtitle = false;
        headerbar.show_close_button = false;
        headerbar.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        search_entry = new Gtk.SearchEntry () {
            placeholder_text = _("Quick Find"),
            hexpand = true
        };

        search_entry.get_style_context ().add_class ("quick-find-entry");

        headerbar.custom_title = search_entry;

        listbox = new Gtk.ListBox ();
        listbox.hexpand = true;
        // listbox.set_placeholder (placeholder_grid);
        listbox.set_header_func (header_function);

        unowned Gtk.StyleContext listbox_context = listbox.get_style_context ();
        listbox_context.add_class ("listbox-background");
        listbox_context.add_class ("listbox-separator-3");

        var listbox_grid = new Gtk.Grid () {
            margin = 6,
            margin_top = 0,
            margin_bottom = 12
        };
        listbox_grid.add (listbox);

        var listbox_scrolled = new Gtk.ScrolledWindow (null, null) {
            expand = true,
            hscrollbar_policy = Gtk.PolicyType.NEVER
        };
        listbox_scrolled.expand = true;
        listbox_scrolled.add (listbox_grid);

        var content_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL
        };

        content_grid.add (headerbar);
        content_grid.add (listbox_scrolled);

        add (content_grid);

        search_entry.search_changed.connect (() => {
            if (search_entry.text.strip () != "") {
                clean_results ();

                foreach (Objects.Project project in Planner.database.get_all_projects_by_search (search_entry.text)) {
                    listbox.add (new Dialogs.QuickFind.QuickFindItem (project, search_entry.text));
                    listbox.show_all ();
                }
    
                foreach (Objects.Item item in Planner.database.get_all_items_by_search (search_entry.text)) {
                    listbox.add (new Dialogs.QuickFind.QuickFindItem (item, search_entry.text));
                    listbox.show_all ();
                }
            } else {
                clean_results ();
            }
        });

        focus_out_event.connect (() => {
            hide_destroy ();
            return false;
        });

         key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                hide_destroy ();
            }

            return false;
        });

        key_press_event.connect ((event) => {
            var key = Gdk.keyval_name (event.keyval).replace ("KP_", "");

            if (key == "Up" || key == "Down") {
                return false;
            } else if (key == "Enter" || key == "Return" || key == "KP_Enter") {
                row_activated (listbox.get_selected_row ());
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

        listbox.row_activated.connect ((row) => {
            row_activated (row);
        });
    }

    private void row_activated (Gtk.ListBoxRow row) {
        var base_object = ((Dialogs.QuickFind.QuickFindItem) row).base_object;

        if (base_object.object_type == ObjectType.PROJECT) {
            Planner.event_bus.pane_selected (PaneType.PROJECT, base_object.id_string);
        } else if (base_object.object_type == ObjectType.ITEM) {
            Planner.event_bus.pane_selected (PaneType.PROJECT,
                ((Objects.Item) base_object).project_id.to_string ()
            );
        }

        hide_destroy ();
    }

    private void hide_destroy () {
        hide ();

        Timeout.add (500, () => {
            destroy ();
            return GLib.Source.REMOVE;
        });
    }

    private void clean_results () {
        foreach (unowned Gtk.Widget child in listbox.get_children ()) {
            child.destroy ();
        }
    }

    private void header_function (Gtk.ListBoxRow lbrow, Gtk.ListBoxRow? lbbefore) {
        var row = (Dialogs.QuickFind.QuickFindItem) lbrow;

        if (lbbefore != null) {
            var before = (Dialogs.QuickFind.QuickFindItem) lbbefore;
            if (row.base_object.object_type == before.base_object.object_type) {
                return;
            }
        }

        var header_label = new Granite.HeaderLabel (row.base_object.object_type.get_header ());

        row.set_header (header_label);
    }
}
