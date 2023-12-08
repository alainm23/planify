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

public class Dialogs.QuickFind.QuickFind : Adw.Window {
    private Gtk.SearchEntry search_entry;
    private Gtk.ListBox listbox;
    private Gee.ArrayList<Dialogs.QuickFind.QuickFindItem> items;
    public QuickFind () {
        Object (
            transient_for: Planify.instance.main_window,
            deletable: false,
            modal: true,
            margin_bottom: 128,
            width_request: 400,
            height_request: 325
        );
    }

    construct {
        items = new Gee.ArrayList<Dialogs.QuickFind.QuickFindItem> ();

        var headerbar = new Adw.HeaderBar ();
        headerbar.add_css_class (Granite.STYLE_CLASS_FLAT);

        search_entry = new Gtk.SearchEntry () {
            placeholder_text = _("Quick Find"),
            hexpand = true,
            margin_bottom = 3,
            margin_top = 3
        };

        search_entry.add_css_class ("border-radius-9");

        headerbar.title_widget = search_entry;

        listbox = new Gtk.ListBox ();
        listbox.hexpand = true;
        listbox.vexpand = true;
        listbox.set_placeholder (get_placeholder ());
        listbox.set_header_func (header_function);

        var listbox_grid = new Gtk.Grid ();
        listbox_grid.attach (listbox, 0, 0);

        var listbox_scrolled = new Gtk.ScrolledWindow () {
            hexpand = true,
            vexpand = true,
            hscrollbar_policy = Gtk.PolicyType.NEVER
        };

        listbox_scrolled.child = listbox_grid;

        var content_grid = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

        content_grid.append (headerbar);
        content_grid.append (listbox_scrolled);

        content = content_grid;

        search_entry.search_changed.connect (() => {
            search_changed ();
        });

        var controller_key = new Gtk.EventControllerKey ();
        content.add_controller (controller_key);

        controller_key.key_pressed.connect ((keyval, keycode, state) => {
            var key = Gdk.keyval_name (keyval).replace ("KP_", "");
                        
            if (key == "Up" || key == "Down") {
                return false;
            } else if (key == "Enter" || key == "Return" || key == "KP_Enter") {
                row_activated (listbox.get_selected_row ());
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

        listbox.row_activated.connect ((row) => {
            row_activated (row);
        });

        var search_entry_ctrl_key = new Gtk.EventControllerKey ();
        search_entry.add_controller (search_entry_ctrl_key);

        search_entry_ctrl_key.key_pressed.connect ((keyval, keycode, state) => {
            if (keyval == 65307) {
                hide_destroy ();
            }

            return false;
        });
    }

    private void search_changed () {
        if (search_entry.text.strip () != "") {
            clean_results ();
            search_local_todoist ();
        } else {
            clean_results ();
        }
    }

    private void search_local_todoist () {
        Objects.BaseObject[] filters = {
            Objects.Today.get_default (),
            Objects.Scheduled.get_default (),
            Objects.Pinboard.get_default (),
            new Objects.Priority (Constants.PRIORITY_1),
            new Objects.Priority (Constants.PRIORITY_2),
            new Objects.Priority (Constants.PRIORITY_3),
            new Objects.Priority (Constants.PRIORITY_4),
            Objects.Completed.get_default ()
        };

        foreach (Objects.BaseObject object in filters) {
            if (search_entry.text.down () in object.name.down () || search_entry.text.down () in object.keywords.down ()) {
                var row = new Dialogs.QuickFind.QuickFindItem (object, search_entry.text);
                listbox.append (row);
                items.add (row);
            }
        }

        foreach (Objects.Project project in Services.Database.get_default ().get_all_projects_by_search (search_entry.text)) {
            var row = new Dialogs.QuickFind.QuickFindItem (project, search_entry.text);
            listbox.append (row);
            items.add (row);
        }

        foreach (Objects.Item item in Services.Database.get_default ().get_all_items_by_search (search_entry.text)) {
            var row = new Dialogs.QuickFind.QuickFindItem (item, search_entry.text);
            listbox.append (row);
            items.add (row);
        }

        foreach (Objects.Label label in Services.Database.get_default ().get_all_labels_by_search (search_entry.text)) {
            var row = new Dialogs.QuickFind.QuickFindItem (label, search_entry.text);
            listbox.append (row);
            items.add (row);
        }
    }

    private Gtk.Widget get_placeholder () {
        var message_label = new Gtk.Label (_("Quickly switch projects and views, find tasks, search by labels.")) {
            wrap = true,
            justify = Gtk.Justification.CENTER,
            hexpand = true,
            vexpand = true,
            margin_top = 6,
            margin_start = 6,
            margin_end = 6,
            margin_bottom = 6
        };
        
        var placeholder_grid = new Gtk.Grid () {
            hexpand = true,
            vexpand = true,
            margin_top = 24,
            margin_start = 24,
            margin_end = 24,
            margin_bottom = 24
        };

        placeholder_grid.attach (message_label, 0, 0);

        return placeholder_grid;
    }

    private void row_activated (Gtk.ListBoxRow row) {
        var base_object = ((Dialogs.QuickFind.QuickFindItem) row).base_object;

        if (base_object.object_type == ObjectType.PROJECT) {
            Services.EventBus.get_default ().pane_selected (PaneType.PROJECT, base_object.id_string);
        } else if (base_object.object_type == ObjectType.ITEM) {
            Services.EventBus.get_default ().pane_selected (PaneType.PROJECT,
                ((Objects.Item) base_object).project_id.to_string ()
            );
        } else if (base_object.object_type == ObjectType.LABEL) {
            Services.EventBus.get_default ().pane_selected (PaneType.LABEL,
                ((Objects.Label) base_object).id_string
            );
        } else if (base_object.object_type == ObjectType.FILTER) {
            if (base_object is Objects.Today) {
                Services.EventBus.get_default ().pane_selected (PaneType.FILTER, FilterType.TODAY.to_string ()); 
            } else if (base_object is Objects.Scheduled) {
                Services.EventBus.get_default ().pane_selected (PaneType.FILTER, FilterType.SCHEDULED.to_string ()); 
            } else if (base_object is Objects.Pinboard) {
                Services.EventBus.get_default ().pane_selected (PaneType.FILTER, FilterType.PINBOARD.to_string ());
            } else if (base_object is Objects.Priority) {
                Objects.Priority priority = ((Objects.Priority) base_object);
                Services.EventBus.get_default ().pane_selected (PaneType.FILTER, priority.view_id);
            } else if (base_object is Objects.Completed) {
                Objects.Completed completed = ((Objects.Completed) base_object);
                Services.EventBus.get_default ().pane_selected (PaneType.FILTER, completed.view_id);
            }
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
        foreach (Dialogs.QuickFind.QuickFindItem item in items) {
            item.hide_destroy ();
        }

        items.clear ();
    }

    private void header_function (Gtk.ListBoxRow lbrow, Gtk.ListBoxRow? lbbefore) {
        var row = (Dialogs.QuickFind.QuickFindItem) lbrow;

        if (lbbefore != null) {
            var before = (Dialogs.QuickFind.QuickFindItem) lbbefore;
            if (row.base_object.object_type == before.base_object.object_type) {
                return;
            }
        }

        var header_label = new Granite.HeaderLabel (row.base_object.object_type.get_header ()) {
            margin_start = 12
        };

        row.set_header (header_label);
    }
}
