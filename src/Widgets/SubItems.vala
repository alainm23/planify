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

public class Widgets.SubItems : Adw.Bin {
    public Objects.Item item_parent { get; construct; }
    
    private Gtk.ListBox listbox;
    private Gtk.ListBox checked_listbox;
    private Gtk.Revealer checked_revealer;
    private Gtk.Revealer main_revealer;

    public Gee.HashMap <string, Layouts.ItemRow> items = new Gee.HashMap <string, Layouts.ItemRow> ();
    public Gee.HashMap <string, Layouts.ItemRow> items_checked = new Gee.HashMap <string, Layouts.ItemRow> ();

    public bool has_children {
        get {
            return items.size > 0 || (items_checked.size > 0 && item_parent.project.show_completed);
        }
    }

    public bool reveal_child {
        get {
            return main_revealer.reveal_child;
        }

        set {
            main_revealer.reveal_child = value;
        }
    }

    public signal void children_changes ();

    public SubItems (Objects.Item item_parent) {
        Object (
            item_parent: item_parent
        );
    }

    construct {
        listbox = new Gtk.ListBox () {
            valign = Gtk.Align.START,
            activate_on_single_click = true,
            selection_mode = Gtk.SelectionMode.SINGLE,
            hexpand = true,
            css_classes = { "listbox-background" }
        };
        
        checked_listbox = new Gtk.ListBox () {
            valign = Gtk.Align.START,
            activate_on_single_click = true,
            selection_mode = Gtk.SelectionMode.SINGLE,
            hexpand = true,
            css_classes = { "listbox-background" }
        };

        checked_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            reveal_child = item_parent.project.show_completed,
            child = checked_listbox
        };

        var main_grid = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            hexpand = true,
            margin_start = 3
        };

        main_grid.append (listbox);
        main_grid.append (checked_revealer);

        main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            child = main_grid
        };
        
        child = main_revealer;
        add_items ();

        item_parent.item_added.connect (add_item);

        Services.Database.get_default ().item_updated.connect ((item, update_id) => {
            if (items.has_key (item.id_string)) {
                if (items [item.id_string].update_id != update_id) {
                    items [item.id_string].update_request ();
                }
            }

            if (items_checked.has_key (item.id_string)) {
                items_checked [item.id_string].update_request ();
            }
        });

        Services.Database.get_default ().item_deleted.connect ((item) => {
            if (items.has_key (item.id_string)) {
                items [item.id_string].hide_destroy ();
                items.unset (item.id_string);
            }

            if (items_checked.has_key (item.id_string)) {
                items_checked [item.id_string].hide_destroy ();
                items_checked.unset (item.id_string);
            }

            children_changes ();
        });

        Services.EventBus.get_default ().item_moved.connect ((item, old_project_id, old_section_id, old_parent_id) => {
            if (old_parent_id == item_parent.id) {
                if (items.has_key (item.id_string)) {
                    items [item.id_string].hide_destroy ();
                    items.unset (item.id_string);
                }

                if (items_checked.has_key (item.id_string)) {
                    items_checked [item.id_string].hide_destroy ();
                    items_checked.unset (item.id_string);
                }
            }

            if (item.parent_id == item_parent.id) {
                add_item (item);
            }

            children_changes ();
        });

        Services.EventBus.get_default ().checked_toggled.connect ((item, old_checked) => {
            if (item.parent.id == item_parent.id) {
                if (!old_checked) {
                    if (items.has_key (item.id)) {
                        items [item.id].hide_destroy ();
                        items.unset (item.id);
                    }

                    if (!items_checked.has_key (item.id)) {
                        items_checked [item.id] = new Layouts.ItemRow (item);
                        checked_listbox.insert (items_checked [item.id], 0);
                    }
                } else {
                    if (items_checked.has_key (item.id)) {
                        items_checked [item.id].hide_destroy ();
                        items_checked.unset (item.id);
                    }

                    if (!items.has_key (item.id)) {
                        items [item.id] = new Layouts.ItemRow (item);
                        listbox.append (items [item.id]);
                        children_changes ();
                    }
                }

                children_changes ();
            }
        });

        Services.EventBus.get_default ().update_inserted_item_map.connect ((_row, old_section_id, old_parent_id) => {
            var row = (Layouts.ItemRow) _row;

            if (old_parent_id == item_parent.id) {
                if (items.has_key (row.item.id)) {
                    items.unset (row.item.id);
                }

                if (items_checked.has_key (row.item.id)) {
                    items_checked.unset (row.item.id);
                }

                children_changes ();
            }
		});

        item_parent.project.show_completed_changed.connect (() => {
            checked_revealer.reveal_child = item_parent.project.show_completed;

            if (item_parent.project.show_completed) {
                add_completed_items ();
            } else {
                foreach (var entry in items_checked.entries) {
                    entry.value.hide_destroy ();
                }

                items_checked.clear ();
            }
        });
    }

    public void add_items () {
        items.clear ();

        foreach (Objects.Item item in item_parent.items) {
            add_item (item);
        }

        if (item_parent.project.show_completed) {
            add_completed_items ();
        }
    }

    public void add_completed_items () {
        items_checked.clear ();

        foreach (Objects.Item item in item_parent.items) {
            add_complete_item (item);
        }
    }

    public void add_complete_item (Objects.Item item) {
        if (item_parent.project.show_completed && item.checked) {
            if (!items_checked.has_key (item.id_string)) {
                items_checked [item.id_string] = new Layouts.ItemRow (item);
                checked_listbox.append (items_checked [item.id_string]);
            }
        }
    }

    public void add_item (Objects.Item item) {
        if (!item.checked && !items.has_key (item.id_string)) {
            items [item.id_string] = new Layouts.ItemRow (item);
            listbox.append (items [item.id_string]);
            children_changes ();
        }
    }

    public void prepare_new_item (string content = "") {
        var dialog = new Dialogs.QuickAdd ();
        dialog.for_base_object (item_parent);
        dialog.update_content (content);
        dialog.show ();
    }
}