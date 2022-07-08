
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

    private Gtk.Button hide_button;
    private Gtk.Revealer hide_revealer;
    private Gtk.Revealer bottom_revealer;
    private Widgets.EditableLabel name_editable;
    private Widgets.LoadingButton menu_loading_button;
    private Gtk.ListBox listbox;
    private Gtk.ListBox checked_listbox;
    private Gtk.Revealer checked_revealer;
    private Gtk.Revealer main_revealer;
    private Gtk.Grid handle_grid;
    private Gtk.EventBox sectionrow_eventbox;
    private Gtk.Grid placeholder_grid;
    private Gtk.EventBox placeholder_eventbox;
    private Gtk.Revealer placeholder_revealer;
    private Gtk.Grid content_grid;
    private Gtk.Revealer top_motion_revealer;
    private Gtk.Revealer bottom_motion_revealer;

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
        
        var chevron_right_image = new Widgets.DynamicIcon ();
        chevron_right_image.size = 19;
        chevron_right_image.update_icon_name ("chevron-right"); 

        hide_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            can_focus = false
        };

        hide_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        hide_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
        hide_button.get_style_context ().add_class ("no-padding");
        hide_button.get_style_context ().add_class ("hidden-button");
        hide_button.add (chevron_right_image);

        if (section.collapsed) {
            hide_button.get_style_context ().add_class ("opened");
        } 

        hide_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.CROSSFADE,
            reveal_child = false
        };

        hide_revealer.add (hide_button);

        name_editable = new Widgets.EditableLabel ("font-bold", _("New section"), false) {
            valign = Gtk.Align.CENTER,
            hexpand = true,
            margin_start = 6,
            margin_top = 3,
            margin_bottom = 3
        };

        name_editable.text = section.name;

        menu_loading_button = new Widgets.LoadingButton (LoadingButtonType.ICON, "content-loading-symbolic") {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.END,
            can_focus = false,
            hexpand = false,
            margin_end = 6
        };
        menu_loading_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        menu_loading_button.get_style_context ().add_class ("no-padding");
        menu_loading_button.get_style_context ().add_class (Granite.STYLE_CLASS_SMALL_LABEL);

        var name_menu_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.HORIZONTAL
        };
        name_menu_grid.add (name_editable);
        name_menu_grid.add (menu_loading_button);
        name_menu_grid.get_style_context ().add_class ("transition");

        var sectionrow_grid = new Gtk.Grid () {
            margin_top = 3,
            margin_bottom = 3
        };

        sectionrow_grid.add (hide_revealer);
        sectionrow_grid.add (name_menu_grid);

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

        if (is_inbox_section) {
            listbox.set_placeholder (get_inbox_placeholder ());
        } else {
            listbox.set_placeholder (get_placeholder ());
        }

        unowned Gtk.StyleContext listbox_context = listbox.get_style_context ();
        listbox_context.add_class ("listbox-background");

        var listbox_grid = new Gtk.Grid () {
            margin_top = is_inbox_section ? 6 : 3
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

        var top_motion_grid = new Gtk.Grid () {
            margin_top = 6,
            margin_start = 6,
            margin_end = 6,
            margin_bottom = 12,
            height_request = 16
        };
        top_motion_grid.get_style_context ().add_class ("grid-motion");

        top_motion_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };
        top_motion_revealer.add (top_motion_grid);

        var bottom_motion_grid = new Gtk.Grid () {
            margin_start = 6,
            margin_end = 6,
            margin_top = 12
        };
        
        bottom_motion_grid.get_style_context ().add_class ("grid-motion");
        bottom_motion_grid.height_request = 16;

        bottom_motion_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };
        bottom_motion_revealer.add (bottom_motion_grid);

        var bottom_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            hexpand = true
        };
        
        bottom_grid.add (listbox_grid);
        bottom_grid.add (checked_revealer);

        bottom_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            reveal_child = section.collapsed
        };

        bottom_revealer.add (bottom_grid);

        checked_revealer.add (checked_listbox_grid);

        content_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            hexpand = true
        };

        content_grid.add (top_motion_revealer);
        content_grid.add (sectionrow_eventbox);
        content_grid.add (bottom_revealer);
        content_grid.add (bottom_motion_revealer);
        
        main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };
        main_revealer.add (content_grid);
        
        add (main_revealer);

        if (!is_inbox_section) {
            // build_drag_and_drop ();
        }

        add_items ();
        show_completed_changed ();

        Timeout.add (main_revealer.transition_duration, () => {
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

        if (is_inbox_section) {
            section.project.item_added.connect ((item) => {
                add_item (item);
            });
        } else {
            section.item_added.connect ((item) => {
                add_item (item);
            });            
        }

        listbox.add.connect ((widget) => {
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
            if (evt.type == Gdk.EventType.BUTTON_PRESS && evt.button == 1) {
                Timeout.add (Constants.DRAG_TIMEOUT, () => {
                    if (main_revealer.reveal_child) {
                        name_editable.editing (true);
                    }
                    return GLib.Source.REMOVE;
                });
            } else if (evt.type == Gdk.EventType.BUTTON_PRESS && evt.button == 3) {
                build_content_menu ();
            }

            return Gdk.EVENT_PROPAGATE;
        });

        sectionrow_eventbox.enter_notify_event.connect ((event) => {
            hide_revealer.reveal_child = !is_creating && has_children;
            return false;
        });

        sectionrow_eventbox.leave_notify_event.connect ((event) => {
            if (event.detail == Gdk.NotifyType.INFERIOR) {
                return false;
            }

            hide_revealer.reveal_child = false;
            return false;
        });

        menu_loading_button.clicked.connect (build_content_menu);

        Planner.event_bus.checked_toggled.connect ((item, old_checked) => {
            if (item.project_id == section.project_id && item.section_id == section.id &&
                item.parent_id == Constants.INACTIVE) {
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
                    update_sort ();
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

        Planner.event_bus.item_moved.connect ((item, old_project_id, old_section_id, old_parent_id, insert) => {
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

            if (item.project_id == section.project_id && item.section_id == section.id &&
                item.parent_id == Constants.INACTIVE) {
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
                update_sort ();
            }
        });

        name_editable.focus_changed.connect ((active) => {
            Planner.event_bus.unselect_all ();

            if (active) {
                hide_revealer.reveal_child = false;
                placeholder_revealer.reveal_child = false;
                name_menu_grid.get_style_context ().add_class ("editable-label-focus");
            } else {
                placeholder_revealer.reveal_child = true;
                name_menu_grid.get_style_context ().remove_class ("editable-label-focus");
            }
        });

        section.project.show_completed_changed.connect (show_completed_changed);

        section.project.sort_order_changed.connect (() => {
            update_sort ();
        });

        hide_button.clicked.connect (() => {
            section.collapsed = !section.collapsed;
            bottom_revealer.reveal_child = section.collapsed;
            
            if (section.collapsed) {
                hide_button.get_style_context ().add_class ("opened");
            } else {
                hide_button.get_style_context ().remove_class ("opened");
            }

            section.update (false);
        });

        Planner.event_bus.update_section_sort_func.connect ((project_id, section_id, value) => {
            if (section.project_id == project_id && section.id == section_id) {
                if (value) {
                    update_sort ();
                } else {
                    listbox.set_sort_func (null);
                }
            }
        });
    }

    private void show_completed_changed () {
        if (section.project.show_completed) {
            add_completed_items ();
        } else {
            items_checked.clear ();

            foreach (unowned Gtk.Widget child in checked_listbox.get_children ()) {
                child.destroy ();
            }
        }

        checked_revealer.reveal_child = section.project.show_completed;
    }

    private void update_items_position () {
        Timeout.add (main_revealer.transition_duration, () => {
            Layouts.ItemRow item_row = null;
            var row_index = 0;

            do {
                item_row = (Layouts.ItemRow) listbox.get_row_at_index (row_index);

                if (item_row != null) {
                    item_row.item.child_order = row_index;
                    print ("%s - %d\n".printf (item_row.item.content, row_index));
                    Planner.database.update_child_order (item_row.item);
                }

                row_index++;
            } while (item_row != null);

            return GLib.Source.REMOVE;
        });
    }   

    private void update_sort () {
        if (section.project.sort_order == 0) {
            listbox.set_sort_func (null);
        } else {
            listbox.set_sort_func (set_sort_func);
        }
    }

    private int set_sort_func (Gtk.ListBoxRow lbrow, Gtk.ListBoxRow lbbefore) {
        Objects.Item item1 = ((Layouts.ItemRow) lbrow).item;
        Objects.Item item2 = ((Layouts.ItemRow) lbbefore).item;
        
        if (section.project.sort_order == 1) {
            return item1.content.collate (item2.content);
        }
        
        if (section.project.sort_order == 2) {
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
        
        if (section.project.sort_order == 3) {
            return item1.added_datetime.compare (item2.added_datetime);
        }
        
        if (section.project.sort_order == 4) {
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

        update_sort ();
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

        section.collapsed = true;
        bottom_revealer.reveal_child = section.collapsed;
            
        if (section.collapsed) {
            hide_button.get_style_context ().add_class ("opened");
        }

        section.update (false);

        Layouts.ItemRow row;
        if (is_inbox_section) {
            row = new Layouts.ItemRow.for_project (section.project);
        } else {
            row = new Layouts.ItemRow.for_section (section);
        }

        row.update_content (content);
        row.update_priority (Util.get_default ().get_default_priority ());

        row.item_added.connect (() => {
            Util.get_default ().item_added (row);
        });
        
        if (has_children) {
            listbox.insert (row, 0);
        } else {
            listbox.add (row);
        }
        
        listbox.show_all ();
    }

    private void build_content_menu () {
        Planner.event_bus.unselect_all ();
        
        var menu = new Dialogs.ContextMenu.Menu ();

        var add_item = new Dialogs.ContextMenu.MenuItem (_("Add task"), "planner-plus-circle");
        var edit_item = new Dialogs.ContextMenu.MenuItem (_("Edit section"), "planner-edit");
        var move_item = new Dialogs.ContextMenu.MenuItem (_("Move section"), "chevron-right");
        var delete_item = new Dialogs.ContextMenu.MenuItem (_("Delete section"), "planner-trash");
        
        var delete_item_context = delete_item.get_style_context ();
        delete_item_context.add_class ("menu-item-danger");

        menu.add_item (add_item);
        menu.add_item (new Dialogs.ContextMenu.MenuSeparator ());
        menu.add_item (edit_item);
        menu.add_item (move_item);
        menu.add_item (new Dialogs.ContextMenu.MenuSeparator ());
        menu.add_item (delete_item);

        menu.popup ();

        add_item.activate_item.connect (() => {
            menu.hide_destroy ();
            prepare_new_item ();
        });

        edit_item.activate_item.connect (() => {
            menu.hide_destroy ();
            name_editable.editing (true);
        });

        delete_item.activate_item.connect (() => {
            menu.hide_destroy ();
            section.delete ();
        });

        move_item.activate_item.connect ((row) => {
            var picker = new Dialogs.ProjectPicker.ProjectPicker (false);
            picker.popup ();

            picker.project = section.project;

            picker.changed.connect ((project_id, section_id) => {
                move_section (project_id);
            });
        });
    }

    private void move_section (int64 project_id) {
        int64 old_section_id = int64.parse (section.project_id.to_string ());
        section.project_id = project_id;

        if (section.project.todoist) {
            menu_loading_button.is_loading = true;
            Planner.todoist.move_project_section.begin (section, project_id, (obj, res) => {
                if (Planner.todoist.move_project_section.end (res)) {
                    Planner.database.move_section (section, old_section_id);
                    menu_loading_button.is_loading = false;
                } else {
                    menu_loading_button.is_loading = false;
                }
            });
        } else {
            Planner.database.move_section (section, project_id);
        }
    }

    private Gtk.Widget get_inbox_placeholder () {
        placeholder_grid = new Gtk.Grid () {
            margin_start = 20,
            margin_end = 6,
            height_request = 0
        };

        unowned Gtk.StyleContext placeholder_grid_context = placeholder_grid.get_style_context ();
        placeholder_grid_context.add_class ("transition");
        // placeholder_grid_context.add_class ("pane-content");

        placeholder_eventbox = new Gtk.EventBox ();
        placeholder_eventbox.add (placeholder_grid);

        placeholder_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            reveal_child = true
        };
        placeholder_revealer.add (placeholder_eventbox);

        placeholder_eventbox.button_press_event.connect ((sender, evt) => {
            if (evt.type == Gdk.EventType.BUTTON_PRESS && evt.button == 1) {
                prepare_new_item ();
            }

            return Gdk.EVENT_PROPAGATE;
        });

        placeholder_revealer.show_all ();
        build_placeholder_drag_and_drop (false);

        return placeholder_revealer;
    }

    private Gtk.Widget get_placeholder () {
        var message_label = new Gtk.Label (_("No tasks available. Create one by dragging the '+' button here or clicking on this space.")) {
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
            margin_start = 20,
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

        placeholder_eventbox.button_press_event.connect ((sender, evt) => {
            if (evt.type == Gdk.EventType.BUTTON_PRESS && evt.button == 1) {
                prepare_new_item ();
            }

            return Gdk.EVENT_PROPAGATE;
        });

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

        if (source_row.item.project_id != section.project_id ||
            source_row.item.section_id != section.id) {

            if (source_row.item.project_id != section.project_id) {
                source_row.item.project_id = section.project_id;
            }

            if (source_row.item.section_id != section.id) {
                source_row.item.section_id = section.id;
            }

            source_row.item.parent_id = Constants.INACTIVE;

            if (source_row.item.project.todoist) {
                int64 move_id = source_row.item.project_id;
                string move_type = "project_id";

                if (source_row.item.section_id != Constants.INACTIVE) {
                    move_id = source_row.item.section_id;
                    move_type = "section_id";
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

        items [source_row.item.id_string] = source_row;
        listbox.add (items [source_row.item.id_string]);

        Planner.event_bus.update_items_position (section.project_id, section.id);
    }

    private void build_drag_and_drop () {
        Gtk.drag_source_set (this, Gdk.ModifierType.BUTTON1_MASK, Util.get_default ().SECTIONROW_TARGET_ENTRIES, Gdk.DragAction.MOVE);
        drag_begin.connect (on_drag_begin);
        drag_data_get.connect (on_drag_data_get);
        drag_end.connect (clear_indicator);

        Gtk.drag_dest_set (this, Gtk.DestDefaults.MOTION, Util.get_default ().SECTIONROW_TARGET_ENTRIES, Gdk.DragAction.MOVE);
        drag_motion.connect (on_drag_motion);
        drag_leave.connect (on_drag_leave);
    }

    public bool on_drag_motion (Gdk.DragContext context, int x, int y, uint time) {
        Gtk.Allocation alloc;
        get_allocation (out alloc);
        
        if (get_index () == 1) {
            if (y > (alloc.height / 2)) {
                bottom_motion_revealer.reveal_child = true;
                top_motion_revealer.reveal_child = false;
            } else {
                bottom_motion_revealer.reveal_child = false;
                top_motion_revealer.reveal_child = true;
            }
        } else {
            bottom_motion_revealer.reveal_child = true;
        }

        return true;
    }

    public void on_drag_leave (Gdk.DragContext context, uint time) {
        bottom_motion_revealer.reveal_child = false;
        top_motion_revealer.reveal_child = false;
    }

    private void on_drag_begin (Gtk.Widget widget, Gdk.DragContext context) {
        var row = ((Layouts.SectionRow) widget).handle_grid;

        Gtk.Allocation row_alloc;
        row.get_allocation (out row_alloc);

        var surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, row_alloc.width, row_alloc.height);
        var cairo_context = new Cairo.Context (surface);

        var style_context = row.get_style_context ();
        style_context.add_class ("drag-begin");
        row.draw_to_cairo_context (cairo_context);
        style_context.remove_class ("drag-begin");

        int drag_icon_x, drag_icon_y;
        widget.translate_coordinates (row, 0, 0, out drag_icon_x, out drag_icon_y);
        surface.set_device_offset (-drag_icon_x, -drag_icon_y);

        Gtk.drag_set_icon_surface (context, surface);
        main_revealer.reveal_child = false;
    }

    private void on_drag_data_get (Gtk.Widget widget, Gdk.DragContext context,
        Gtk.SelectionData selection_data, uint target_type, uint time) {
        uchar[] data = new uchar[(sizeof (Layouts.SectionRow))];
        ((Gtk.Widget[])data)[0] = widget;

        selection_data.set (
            Gdk.Atom.intern_static_string ("SECTIONROW"), 32, data
        );
    }

    public void clear_indicator (Gdk.DragContext context) {
        main_revealer.reveal_child = true;
    }
}
