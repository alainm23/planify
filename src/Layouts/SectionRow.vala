
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

public class Layouts.SectionRow : Gtk.ListBoxRow {
    public Objects.Section section { get; construct; }

    private Widgets.EditableLabel name_editable;
    private Gtk.ListBox listbox;
    private Gtk.ListBox checked_listbox;
    private Gtk.Revealer checked_revealer;
    private Gtk.Revealer main_revealer;
    private Gtk.Grid handle_grid;
    private Gtk.EventBox sectionrow_eventbox;
    private Gtk.Grid placeholder_grid;
    private Gtk.EventBox placeholder_eventbox;
    private Gtk.Revealer placeholder_revealer;

    public bool is_inbox_section {
        get {
            return section.id == Constants.INACTIVE;
        }
    }

    public bool has_children {
        get {
            return listbox.get_children ().length () > 0 || checked_listbox.get_children ().length () > 0;
        }
    }

    public bool is_creating {
        get {
            return section.id == Constants.INACTIVE;
        }
    }

    public Gee.HashMap <string, Layouts.ItemRow> items;
    public Gee.HashMap <string, Layouts.ItemRow> items_checked;

    public signal void children_size_changed ();

    public SectionRow (Objects.Section section) {
        Object (
            section: section,
            can_focus: false
        );
    }

    public SectionRow.for_project (Objects.Project project) {
        var section = new Objects.Section ();
        section.id = Constants.INACTIVE;
        section.project_id = project.id;
        section.name = _("(No Section)");

        Object (
            section: section,
            can_focus: false
        );
    }

    construct {
        get_style_context ().add_class ("row");
        
        items = new Gee.HashMap <string, Layouts.ItemRow> ();
        items_checked = new Gee.HashMap <string, Layouts.ItemRow> ();

        name_editable = new Widgets.EditableLabel ("font-bold", _("New section")) {
            valign = Gtk.Align.CENTER,
            hexpand = true
        };
        name_editable.text = section.name;

        var menu_image = new Gtk.Image () {
            gicon = new ThemedIcon ("content-loading-symbolic"),
            pixel_size = 16
        };
        
        var menu_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.END,
            can_focus = false,
            hexpand = false
        };

        menu_button.add (menu_image);
        menu_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var sectionrow_grid = new Gtk.Grid () {
            column_spacing = 6,
            margin_start = 6,
            margin_end = 6
        };
        sectionrow_grid.add (name_editable);
        sectionrow_grid.add (menu_button);

        var sectionrow_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            reveal_child = !is_inbox_section
        };

        sectionrow_revealer.add (sectionrow_grid);

        handle_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL
        };
        handle_grid.add (sectionrow_revealer);
        handle_grid.get_style_context ().add_class ("transition");

        sectionrow_eventbox = new Gtk.EventBox ();
        sectionrow_eventbox.get_style_context ().add_class ("transition");
        sectionrow_eventbox.add (handle_grid);

        listbox = new Gtk.ListBox () {
            valign = Gtk.Align.START,
            activate_on_single_click = true,
            selection_mode = Gtk.SelectionMode.SINGLE,
            expand = true
        };

        if (!is_inbox_section) {
            listbox.set_placeholder (get_placeholder ());
        }

        unowned Gtk.StyleContext listbox_context = listbox.get_style_context ();
        listbox_context.add_class ("listbox-background");

        var listbox_grid = new Gtk.Grid () {
            margin_top = is_inbox_section ? 12 : 3
        };
        listbox_grid.add (listbox);

        checked_listbox = new Gtk.ListBox () {
            valign = Gtk.Align.START,
            activate_on_single_click = true,
            selection_mode = Gtk.SelectionMode.SINGLE,
            expand = true
        };

        unowned Gtk.StyleContext checked_listbox_context = checked_listbox.get_style_context ();
        checked_listbox_context.add_class ("listbox-background");

        var checked_listbox_grid = new Gtk.Grid ();
        checked_listbox_grid.add (checked_listbox);

        checked_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            reveal_child = section.project.show_completed
        };

        checked_revealer.add (checked_listbox_grid);

        var main_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            hexpand = true
        };

        main_grid.add (sectionrow_eventbox);
        main_grid.add (listbox_grid);
        main_grid.add (checked_revealer);

        main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };
        main_revealer.add (main_grid);
        
        add (main_revealer);

        add_items ();
        
        Timeout.add (main_revealer.transition_duration, () => {
            set_sort_func ();
            main_revealer.reveal_child = true;
            if (section.activate_name_editable) {
                name_editable.editing (true, true);
            }
            return GLib.Source.REMOVE;
        });

        name_editable.changed.connect (() => {
            section.name = name_editable.text;
            section.update ();
        });

        section.updated.connect (() => {
            name_editable.text = section.name;
        });

        section.deleted.connect (() => {
            hide_destroy ();
        });

        if (is_inbox_section) {
            section.project.item_added.connect ((item) => {
                add_item (item);
            });
        } else {
            section.item_added.connect ((item) => {
                add_item (item);
            });            
        }

        listbox.add.connect (() => {
            children_size_changed ();
        });

        listbox.remove.connect (() => {
            children_size_changed ();
        });

        checked_listbox.add.connect (() => {
            children_size_changed ();
        });

        checked_listbox.remove.connect (() => {
            children_size_changed ();
        });

        sectionrow_eventbox.button_press_event.connect ((sender, evt) => {
            if (evt.type == Gdk.EventType.BUTTON_PRESS && evt.button == 3) {
                build_content_menu ();
            }

            return Gdk.EVENT_PROPAGATE;
        });

        menu_button.clicked.connect (build_content_menu);

        Planner.event_bus.checked_toggled.connect ((item, old_checked) => {
            if (item.project_id == section.project_id && item.section_id == section.id) {
                if (!old_checked) {
                    if (items.has_key (item.id_string)) {
                        items [item.id_string].hide_destroy ();
                        items.unset (item.id_string);
                    }

                    if (!items_checked.has_key (item.id_string)) {
                        items_checked [item.id_string] = new Layouts.ItemRow (item);
                        checked_listbox.insert (items_checked [item.id_string], 0);
                        checked_listbox.show_all ();
                    }
                } else {
                    if (items_checked.has_key (item.id_string)) {
                        items_checked [item.id_string].hide_destroy ();
                        items_checked.unset (item.id_string);
                    }

                    if (!items.has_key (item.id_string)) {
                        items [item.id_string] = new Layouts.ItemRow (item);
                        listbox.add (items [item.id_string]);
                        listbox.show_all ();
                    }
                }
            }
        });

        Planner.database.item_updated.connect ((item, update_id) => {
            if (items.has_key (item.id_string)) {
                if (items [item.id_string].update_id != update_id) {
                    items [item.id_string].update_request ();
                }
            }

            if (items_checked.has_key (item.id_string)) {
                items_checked [item.id_string].update_request ();
            }
        });

        Planner.database.item_deleted.connect ((item) => {
            if (items.has_key (item.id_string)) {
                items [item.id_string].hide_destroy ();
                items.unset (item.id_string);
            }

            if (items_checked.has_key (item.id_string)) {
                items_checked [item.id_string].hide_destroy ();
                items_checked.unset (item.id_string);
            }
        });

        Planner.event_bus.item_moved.connect ((item, old_project_id, old_section_id, insert) => {
            if (old_project_id == section.project_id && old_section_id == section.id) {
                if (items.has_key (item.id_string)) {
                    items [item.id_string].hide_destroy ();
                    items.unset (item.id_string);
                }

                if (items_checked.has_key (item.id_string)) {
                    items_checked [item.id_string].hide_destroy ();
                    items_checked.unset (item.id_string);
                }
            }

            if (item.project_id == section.project_id && item.section_id == section.id) {
                add_item (item);
            }
        });

        Planner.event_bus.update_items_position.connect ((project_id, section_id) => {
            if (section.project_id == project_id && section.id == section_id) {
                update_items_position ();
            }
        });

        Planner.event_bus.magic_button_activated.connect ((value) => {
            if (!is_inbox_section) {
                build_placeholder_drag_and_drop (value);
            }
        });

        Planner.event_bus.update_inserted_item_map.connect ((row) => {
            if (row.item.project_id == section.project_id &&
                row.item.section_id == section.id) {
                items [row.item.id_string] = row;
            }
        });

        name_editable.focus_changed.connect ((active) => {
            if (active) {
                placeholder_revealer.reveal_child = false;
                handle_grid.get_style_context ().add_class ("editable-label-focus");
            } else {
                placeholder_revealer.reveal_child = true;
                handle_grid.get_style_context ().remove_class ("editable-label-focus");
            }
        });

        section.project.show_completed_changed.connect (() => {
            if (section.project.show_completed) {
                add_completed_items ();
                checked_revealer.reveal_child = section.project.show_completed;
            } else {
                items_checked.clear ();

                foreach (unowned Gtk.Widget child in checked_listbox.get_children ()) {
                    child.destroy ();
                }

                checked_revealer.reveal_child = section.project.show_completed;
            }
        });
    }

    private void update_items_position () {
        Timeout.add (main_revealer.transition_duration, () => {
            GLib.List<weak Gtk.Widget> items = listbox.get_children ();
            for (int index = 0; index < items.length (); index++) {
                Objects.Item item = ((Layouts.ItemRow) items.nth_data (index)).item;
                item.child_order = index + 1;
                Planner.database.update_item_position (item);
            }
            return GLib.Source.REMOVE;
        });
    }

    private void set_sort_func (int order = 0) {
        listbox.set_sort_func ((row1, row2) => {
            Objects.Item item1 = ((Layouts.ItemRow) row1).item;
            Objects.Item item2 = ((Layouts.ItemRow) row2).item;

            if (order == 0) {
                return item1.child_order - item2.child_order;
            } else if (order == 1) {
                //  if (item1.due_date != "" && item2.due_date != "") {
                //      var date1 = new GLib.DateTime.from_iso8601 (item1.due_date, new GLib.TimeZone.local ());
                //      var date2 = new GLib.DateTime.from_iso8601 (item2.due_date, new GLib.TimeZone.local ());

                //      return date1.compare (date2);
                //  }

                //  if (item1.due_date == "" && item2.due_date != "") {
                //      return 1;
                //  }

                return 0;
            } else if (order == 2) {
                if (item1.priority < item2.priority) {
                    return 1;
                }
    
                if (item1.priority < item2.priority) {
                    return -1;
                }
    
                return 0;
            } else {
                return item1.content.collate (item2.content);
            }
        });

        listbox.set_sort_func (null);
    }

    public void hide_destroy () {
        main_revealer.reveal_child = false;
        Timeout.add (main_revealer.transition_duration, () => {
            destroy ();
            return GLib.Source.REMOVE;
        });
    }

    public void add_items () {
        items.clear ();

        foreach (unowned Gtk.Widget child in listbox.get_children ()) {
            child.destroy ();
        }

        foreach (Objects.Item item in is_inbox_section ? section.project.items : section.items) {
            add_item (item);
        }
    }

    public void add_completed_items () {
        items_checked.clear ();

        foreach (unowned Gtk.Widget child in checked_listbox.get_children ()) {
            child.destroy ();
        }

        foreach (Objects.Item item in is_inbox_section ? section.project.items : section.items) {
            add_complete_item (item);
        }
    }

    public void add_item (Objects.Item item) {
        if (!item.checked && !items.has_key (item.id_string)) {
            items [item.id_string] = new Layouts.ItemRow (item);
            listbox.add (items [item.id_string]);
            listbox.show_all ();
        }
    }

    public void add_complete_item (Objects.Item item) {
        if (section.project.show_completed && item.checked) {
            if (!items_checked.has_key (item.id_string)) {
                items_checked [item.id_string] = new Layouts.ItemRow (item);
                checked_listbox.add (items_checked [item.id_string]);
                checked_listbox.show_all ();
            }
        }
    }

    public void prepare_new_item (string content = "") {
        Planner.event_bus.item_selected (null);

        Layouts.ItemRow row;
        if (is_inbox_section) {
            row = new Layouts.ItemRow.for_project (section.project);
        } else {
            row = new Layouts.ItemRow.for_section (section);
        }

        row.update_content (content);

        row.item_added.connect (() => {
            Util.get_default ().item_added (row);
        });

        listbox.add (row);
        listbox.show_all ();
    }

    private void build_content_menu () {
        var menu = new Dialogs.ContextMenu.Menu ();

        var edit_item = new Dialogs.ContextMenu.MenuItem (_("Edit section"), "planner-edit");
        // var move_item = new Dialogs.ContextMenu.MenuItemSelector (_("Move section"), true);
        var delete_item = new Dialogs.ContextMenu.MenuItem (_("Delete section"), "planner-trash");
        
        var delete_item_context = delete_item.get_style_context ();
        delete_item_context.add_class ("menu-item-danger");

        //  foreach (Objects.Project project in Planner.database.projects) {
        //      move_item.add_item (new Dialogs.ProjectPicker.ProjectRow (project));
        //  }

        menu.add_item (edit_item);
        // menu.add_item (move_item);
        menu.add_item (delete_item);

        menu.popup ();

        edit_item.activate_item.connect (() => {
            menu.hide_destroy ();
            name_editable.editing (true);
        });

        delete_item.activate_item.connect (() => {
            menu.hide_destroy ();
            section.delete ();
        });

        //  move_item.activate_item.connect ((row) => {
        //      menu.hide_destroy ();
            
        //      // int64 old_parent_id = project.parent_id;

        //      // project.parent_id = ((Dialogs.ProjectSelector.ProjectRow) row).project.id;
        //      // Planner.database.update_project (project);

        //      // if (project.parent_id != old_parent_id) {
        //      //     Planner.event_bus.project_parent_changed (project, old_parent_id);
        //      // }
        //  });
    }

    private Gtk.Widget get_placeholder () {
        var message_label = new Gtk.Label (_("No tasks available. Create one by clicking on the '+' button")) {
            wrap = true,
            justify = Gtk.Justification.CENTER,
            hexpand = true,
            margin = 6
        };
        
        unowned Gtk.StyleContext message_label_context = message_label.get_style_context ();
        message_label_context.add_class ("dim-label");
        message_label_context.add_class (Granite.STYLE_CLASS_SMALL_LABEL);

        placeholder_grid = new Gtk.Grid () {
            margin = 6,
            margin_top = 0
        };

        unowned Gtk.StyleContext placeholder_grid_context = placeholder_grid.get_style_context ();
        placeholder_grid_context.add_class ("transition");
        placeholder_grid_context.add_class ("pane-content");

        placeholder_grid.add (message_label);

        placeholder_eventbox = new Gtk.EventBox ();
        placeholder_eventbox.add (placeholder_grid);

        placeholder_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            reveal_child = true
        };
        placeholder_revealer.add (placeholder_eventbox);
        placeholder_revealer.show_all ();
        build_placeholder_drag_and_drop (false);

        return placeholder_revealer;
    }

    private void build_placeholder_drag_and_drop (bool is_magic_button_active) {
        if (is_magic_button_active) {
            Gtk.drag_dest_set (placeholder_eventbox, Gtk.DestDefaults.ALL,
                Util.get_default ().MAGICBUTTON_TARGET_ENTRIES, Gdk.DragAction.MOVE);
            placeholder_eventbox.drag_data_received.disconnect (on_drag_item_received); 
            placeholder_eventbox.drag_data_received.connect (on_drag_magicbutton_received);
        } else {
            placeholder_eventbox.drag_data_received.disconnect (on_drag_magicbutton_received);
            placeholder_eventbox.drag_data_received.connect (on_drag_item_received);
            Gtk.drag_dest_set (placeholder_eventbox, Gtk.DestDefaults.ALL,
                Util.get_default ().ITEMROW_TARGET_ENTRIES, Gdk.DragAction.MOVE);
        }

        placeholder_eventbox.drag_motion.connect (on_placeholder_drag_motion);
        placeholder_eventbox.drag_leave.connect (on_placeholder_drag_leave);
    }

    public bool on_placeholder_drag_motion (Gdk.DragContext context, int x, int y, uint time) {
        unowned Gtk.StyleContext placeholder_grid_context = placeholder_grid.get_style_context ();
        placeholder_grid_context.add_class ("placeholder-drag-motion");

        return true;
    }

    public void on_placeholder_drag_leave (Gdk.DragContext context, uint time) {
        unowned Gtk.StyleContext placeholder_grid_context = placeholder_grid.get_style_context ();
        placeholder_grid_context.remove_class ("placeholder-drag-motion");
    }

    private void on_drag_magicbutton_received (Gdk.DragContext context, int x, int y,
        Gtk.SelectionData selection_data, uint target_type, uint time) {
        prepare_new_item ();
    }

    private void on_drag_item_received (Gdk.DragContext context, int x, int y,
        Gtk.SelectionData selection_data, uint target_type, uint time) {
        var data = ((Gtk.Widget[]) selection_data.get_data ()) [0];
        var source_row = (Layouts.ItemRow) data;
                
        int64 old_project_id = source_row.item.project_id;
        int64 old_section_id = source_row.item.section_id;

        if (source_row.item.project_id != section.project_id) {
            source_row.item.project_id = section.project_id;
        }

        if (source_row.item.section_id != section.id) {
            source_row.item.section_id = section.id;
        }

        if (old_project_id != source_row.item.project_id || old_section_id != source_row.item.section_id) {
            if (source_row.item.project.todoist) {

                int64 move_id = source_row.item.project_id;
                string move_type = "project_id";
                if (source_row.item.section_id != Constants.INACTIVE) {
                    move_type = "section_id";
                    move_id = source_row.item.section_id;
                }
                
                Planner.todoist.move_item.begin (source_row.item, move_type, move_id, (obj, res) => {
                    if (Planner.todoist.move_item.end (res)) {
                        Planner.database.update_item (source_row.item);
                    }
                });
            } else {
                Planner.database.update_item (source_row.item);
            }

            source_row.project_button.update_request ();
        }

        var source_list = (Gtk.ListBox) source_row.parent;
        source_list.remove (source_row);

        listbox.add (source_row);

        Planner.event_bus.update_items_position (section.project_id, section.id);
    }
}
