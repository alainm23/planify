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
    public bool is_board { get; construct; }
    public bool is_project_view { get; construct; }

    public Objects.Item item_parent { get; set; }
    
    private Gtk.Revealer sub_tasks_header_revealer;
    private Gtk.ListBox listbox;
    private Gtk.ListBox checked_listbox;
    private Gtk.Revealer checked_revealer;
    private Gtk.Revealer main_revealer;
    public Widgets.LoadingButton add_button;

    private Gee.HashMap<ulong, GLib.Object> signals_map = new Gee.HashMap<ulong, GLib.Object> ();
    public Gee.HashMap <string, Layouts.ItemBase> items = new Gee.HashMap <string, Layouts.ItemBase> ();
    public Gee.HashMap <string, Layouts.ItemBase> items_checked = new Gee.HashMap <string, Layouts.ItemBase> ();

    public bool has_children {
        get {
            return items.size > 0 || (items_checked.size > 0 && show_completed);
        }
    }

    public bool show_completed {
        get {
            if (Services.Settings.get_default ().settings.get_boolean ("always-show-completed-subtasks")) {
                return true;
            } else {
                return item_parent.project.show_completed;
            }
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

    public SubItems (bool is_project_view = false) {
        Object (
            is_board: false,
            is_project_view: is_project_view
        );
    }

    public SubItems.for_board () {
        Object (
            is_board: true,
            is_project_view: false
        );
    }

    construct {
        var sub_tasks_title = new Gtk.Label (_("Sub-tasks")) {
            css_classes = { "heading", "h4" }
        };

        add_button = new Widgets.LoadingButton.with_icon ("plus-large-symbolic", 16) {
            css_classes = { "flat" },
            hexpand = true,
            halign = END
        };

        var sub_tasks_header = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            margin_start = 9,
            margin_end = 9
        };
        sub_tasks_header.append (sub_tasks_title);
        sub_tasks_header.append (add_button);

        sub_tasks_header_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            reveal_child = is_board,
            child = sub_tasks_header
        };

        listbox = new Gtk.ListBox () {
            valign = Gtk.Align.START,
            activate_on_single_click = true,
            selection_mode = Gtk.SelectionMode.SINGLE,
            hexpand = true,
            css_classes = { "listbox-background" },
            margin_start = 3
        };
        
        checked_listbox = new Gtk.ListBox () {
            valign = Gtk.Align.START,
            activate_on_single_click = true,
            selection_mode = Gtk.SelectionMode.SINGLE,
            hexpand = true,
            css_classes = { "listbox-background" },
            margin_start = 3,
            margin_end = 6
        };

        checked_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            child = checked_listbox
        };

        var main_grid = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            hexpand = true,
            margin_start = 3
        };

        main_grid.append (sub_tasks_header_revealer);
        main_grid.append (listbox);
        main_grid.append (checked_revealer);

        main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            child = main_grid
        };
        
        child = main_revealer;
    }

    public void present_item (Objects.Item _item_parent) {
        item_parent = _item_parent;

        add_items ();
        checked_revealer.reveal_child = show_completed;

        signals_map[item_parent.item_added.connect (add_item)] = item_parent;

        signals_map[Services.Database.get_default ().item_updated.connect ((item, update_id) => {
            if (items.has_key (item.id_string)) {
                if (items [item.id_string].update_id != update_id) {
                    items [item.id_string].update_request ();
                }
            }

            if (items_checked.has_key (item.id_string)) {
                items_checked [item.id_string].update_request ();
            }
        })] = Services.Database.get_default ();

        signals_map[Services.Database.get_default ().item_deleted.connect ((item) => {
            if (items.has_key (item.id_string)) {
                items [item.id_string].hide_destroy ();
                items.unset (item.id_string);
            }

            if (items_checked.has_key (item.id_string)) {
                items_checked [item.id_string].hide_destroy ();
                items_checked.unset (item.id_string);
            }

            children_changes ();
        })] = Services.Database.get_default ();

        signals_map[Services.EventBus.get_default ().item_moved.connect ((item, old_project_id, old_section_id, old_parent_id) => {
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
        })] = Services.EventBus.get_default ();

        signals_map[Services.EventBus.get_default ().checked_toggled.connect ((item, old_checked) => {
            if (item.parent.id == item_parent.id) {
                if (!old_checked) {
                    if (items.has_key (item.id)) {
                        items [item.id_string].hide_destroy ();
                        items.unset (item.id);
                    }

                    if (!items_checked.has_key (item.id)) {
                        if (is_board) {
                            items_checked [item.id] = new Layouts.ItemBoard (item);
                        } else {
                            items_checked [item.id] = new Layouts.ItemRow (item, is_project_view);
                        }

                        checked_listbox.insert (items_checked [item.id], 0);
                    }
                } else {
                    if (items_checked.has_key (item.id)) {
                        items_checked [item.id_string].hide_destroy ();
                        items_checked.unset (item.id);
                    }

                    if (!items.has_key (item.id)) {
                        if (is_board) {
                            items [item.id] = new Layouts.ItemBoard (item);
                        } else {
                            items [item.id] = new Layouts.ItemRow (item, is_project_view);
                        }

                        listbox.append (items [item.id]);
                        children_changes ();
                    }
                }

                children_changes ();
            }
        })] = Services.EventBus.get_default ();

        signals_map[Services.EventBus.get_default ().update_inserted_item_map.connect ((_row, old_section_id, old_parent_id) => {
            if (!is_board) {
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
            }
		})] = Services.EventBus.get_default ();

        signals_map[item_parent.project.show_completed_changed.connect (() => {
            if (!Services.Settings.get_default ().settings.get_boolean ("always-show-completed-subtasks")) {
                checked_revealer.reveal_child = show_completed;

                if (show_completed) {
                    add_completed_items ();
                } else {
                    items_checked.clear ();
                    
                    foreach (unowned Gtk.Widget child in Util.get_default ().get_children (checked_listbox) ) {
                        checked_listbox.remove (child);
                    }
                }
            }
        })] = item_parent.project;

        signals_map[add_button.clicked.connect (() => {
            prepare_new_item ();
        })] = add_button;

        signals_map[item_parent.project.sort_order_changed.connect (() => {
			update_sort ();
		})] = item_parent.project;

        signals_map[Services.Settings.get_default ().settings.changed.connect ((key) => {
			if (key == "always-show-completed-subtasks") {
                checked_revealer.reveal_child = show_completed;
                if (show_completed) {
                    add_completed_items ();
                }
			}
		})] = Services.Settings.get_default ().settings;

        signals_map[Services.EventBus.get_default ().expand_all.connect ((project_id, value) => {
			if (item_parent.project_id == project_id) {
				foreach (Layouts.ItemBase row_base in items.values) {
                    if (row_base is Layouts.ItemRow) {
                        ((Layouts.ItemRow) row_base).edit = value;
                    }
				}
			}
		})] = Services.Settings.get_default ();
    }

    public void add_items () {
        items.clear ();

        foreach (unowned Gtk.Widget child in Util.get_default ().get_children (listbox) ) {
            listbox.remove (child);
        }

        foreach (Objects.Item item in item_parent.items) {
            add_item (item);
        }

        if (show_completed) {
            add_completed_items ();
        }

        update_sort ();
    }

    public void add_completed_items () {
        items_checked.clear ();

        foreach (unowned Gtk.Widget child in Util.get_default ().get_children (checked_listbox) ) {
            checked_listbox.remove (child);
        }

        foreach (Objects.Item item in item_parent.items) {
            add_complete_item (item);
        }
    }

    public void add_complete_item (Objects.Item item) {
        if (show_completed && item.checked) {
            if (!items_checked.has_key (item.id)) {
                if (is_board) {
                    items_checked [item.id] = new Layouts.ItemBoard (item);
                } else {
                    items_checked [item.id] = new Layouts.ItemRow (item, is_project_view);
                }
                
                checked_listbox.append (items_checked [item.id]);
            }
        }
    }

    public void add_item (Objects.Item item) {
        if (!item.checked && !items.has_key (item.id)) {
            if (is_board) {
                items [item.id] = new Layouts.ItemBoard (item);
            } else {
                items [item.id] = new Layouts.ItemRow (item, is_project_view);
            }

            if (item.custom_order) {
				listbox.insert (items [item.id], item.child_order);
			} else {
				listbox.append (items [item.id]);
			}
            
            children_changes ();
        }
    }

    private void update_sort () {
		if (item_parent.project.sort_order == 0) {
			listbox.set_sort_func (null);
		} else {
			listbox.set_sort_func (set_sort_func);
		}
	}

    private int set_sort_func (Gtk.ListBoxRow lbrow, Gtk.ListBoxRow lbbefore) {
        Objects.Item item1;
		Objects.Item item2;
        
        if (is_board) {
            item1 = ((Layouts.ItemBoard) lbrow).item;
            item2 = ((Layouts.ItemBoard) lbbefore).item;
        } else {
            item1 = ((Layouts.ItemRow) lbrow).item;
            item2 = ((Layouts.ItemRow) lbbefore).item;
        }

		if (item_parent.project.sort_order == 1) {
			return item1.content.strip ().collate (item2.content.strip ());
		}

		if (item_parent.project.sort_order == 2) {
			if (item1.has_due && item2.has_due) {
				var date1 = item1.due.datetime;
				var date2 = item2.due.datetime;

				return date1.compare (date2);
			}

			if (!item1.has_due && item2.has_due) {
				return 1;
			}

			return 0;
		}

		if (item_parent.project.sort_order == 3) {
			return item1.added_datetime.compare (item2.added_datetime);
		}

		if (item_parent.project.sort_order == 4) {
			if (item1.priority < item2.priority) {
				return 1;
			}

			if (item1.priority < item2.priority) {
				return -1;
			}

			return 0;
		}

		return 0;
	}

    public void prepare_new_item (string content = "") {
        var dialog = new Dialogs.QuickAdd ();
        dialog.for_base_object (item_parent);
        dialog.update_content (content);
        dialog.present (Planify._instance.main_window);
    }

    public void disconnect_all () {
        foreach (var entry in signals_map.entries) {
            entry.value.disconnect (entry.key);
        }

        signals_map.clear ();
    }

    public void disable_drag_and_drop () {
        foreach (Layouts.ItemBase row in items.values) {
            ((Layouts.ItemRow) row).disable_drag_and_drop ();
        }
    }
}
