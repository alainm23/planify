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

    private Gtk.Revealer hide_revealer;
    private Gtk.Revealer bottom_revealer;
    private Widgets.EditableLabel name_editable;
    private Widgets.LoadingButton menu_loading_button;
    private Gtk.ListBox listbox;
    private Gtk.ListBox checked_listbox;
    private Gtk.Revealer checked_revealer;
    private Gtk.Revealer content_revealer;
    private Gtk.Box handle_grid;
    private Gtk.Box sectionrow_grid;
    private Gtk.Label count_label;
    private Gtk.Revealer count_revealer;
    private Gtk.Revealer placeholder_revealer;

    private Gtk.Popover menu_popover = null;

    public bool is_inbox_section {
        get {
            return section.id == Constants.INACTIVE;
        }
    }

    public bool has_children {
        get {
            return Util.get_default ().get_children (listbox).length () > 0 ||
            Util.get_default ().get_children (checked_listbox).length () > 0;
        }
    }

    public bool is_creating {
        get {
            return section.id == Constants.INACTIVE;
        }
    }

    public Gee.HashMap <string, Layouts.ItemRow> items;
    public Gee.HashMap <string, Layouts.ItemRow> items_checked;
    public bool on_drag = false;

    public signal void children_size_changed ();

    public SectionRow (Objects.Section section) {
        Object (
            section: section,
            focusable: false,
            can_focus: true
        );
    }

    public SectionRow.for_project (Objects.Project project) {
        var section = new Objects.Section ();
        section.id = Constants.INACTIVE;
        section.project_id = project.id;
        section.name = _("(No Section)");

        Object (
            section: section,
            focusable: false,
            can_focus: true
        );
    }

    construct {
        add_css_class ("row");

        items = new Gee.HashMap <string, Layouts.ItemRow> ();
        items_checked = new Gee.HashMap <string, Layouts.ItemRow> ();

        name_editable = new Widgets.EditableLabel (("New section"), false) {
            valign = Gtk.Align.CENTER,
            hexpand = true,
            margin_top = 3
        };

        name_editable.add_css_class ("font-bold");
        name_editable.text = section.name;

        count_label = new Gtk.Label (section.section_count.to_string ()) {
            hexpand = true,
            halign = Gtk.Align.CENTER
        };

        count_label.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);
        count_label.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);

        count_revealer = new Gtk.Revealer () {
            reveal_child = int.parse (count_label.label) > 0,
            transition_type = Gtk.RevealerTransitionType.CROSSFADE
        };

        count_revealer.child = count_label;
        
        menu_loading_button = new Widgets.LoadingButton.with_icon ("dots-horizontal", 19) {
            valign = Gtk.Align.CENTER
        };
        menu_loading_button.add_css_class (Granite.STYLE_CLASS_FLAT);

        sectionrow_grid = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        sectionrow_grid.add_css_class ("transition");
        sectionrow_grid.append (name_editable);
        sectionrow_grid.append (menu_loading_button);

        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
            margin_bottom = 6,
            margin_end = 6
        };

        var v_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            margin_start = 3
        };
        v_box.append (sectionrow_grid);
        v_box.append (separator);

        var sectionrow_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            reveal_child = !is_inbox_section
        };

        sectionrow_revealer.child = v_box;

        handle_grid = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            margin_top = is_inbox_section ? 12 : 0
        };
        
        handle_grid.append (sectionrow_revealer);
        handle_grid.add_css_class ("transition");

        listbox = new Gtk.ListBox () {
            valign = Gtk.Align.START,
            selection_mode = Gtk.SelectionMode.NONE,
            hexpand = true,
        };
        
        listbox.add_css_class ("listbox-background");

        var listbox_grid = new Gtk.Grid () {
            margin_top = 0
        };

        listbox_grid.attach (listbox, 0, 0);

        checked_listbox = new Gtk.ListBox () {
            valign = Gtk.Align.START,
            selection_mode = Gtk.SelectionMode.NONE,
            hexpand = true
        };

        checked_listbox.add_css_class ("listbox-background");

        var checked_listbox_grid = new Gtk.Grid ();
        checked_listbox_grid.attach (checked_listbox, 0, 0);

        checked_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            reveal_child = true
        };

        checked_revealer.child = checked_listbox_grid;

        var bottom_grid = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            hexpand = true
        };
        
        bottom_grid.append (listbox_grid);
        bottom_grid.append (checked_revealer);

        bottom_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            reveal_child =  true
        };

        bottom_revealer.child = bottom_grid;

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            hexpand = true
        };

        content_box.append (handle_grid);
        content_box.append (bottom_revealer);

        content_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };
        
        content_revealer.child = content_box;

        child = content_revealer;
        
        add_items ();
        show_completed_changed ();
        // build_drag_and_drop ();

        Timeout.add (content_revealer.transition_duration, () => {
            content_revealer.reveal_child = true;
            
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

        var edit_gesture = new Gtk.GestureClick ();
        edit_gesture.set_button (1);
        handle_grid.add_controller (edit_gesture);

        edit_gesture.pressed.connect (() => {
            Timeout.add (Constants.DRAG_TIMEOUT, () => {
                if (!on_drag) {
                    name_editable.editing (true);
                }

                return GLib.Source.REMOVE;
            });
        });

        var menu_gesture = new Gtk.GestureClick ();
        menu_gesture.set_button (3);
        handle_grid.add_controller (menu_gesture);

        menu_gesture.pressed.connect ((n_press, x, y) => {
            build_context_menu (x, y, this);
        });

        var menu_2_gesture = new Gtk.GestureClick ();
        menu_loading_button.add_controller (menu_2_gesture);

        menu_2_gesture.pressed.connect ((n_press, x, y) => {
            build_context_menu (x, y, menu_loading_button);
        });

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
                    }
                } else {
                    if (items_checked.has_key (item.id_string)) {
                        items_checked [item.id_string].hide_destroy ();
                        items_checked.unset (item.id_string);
                    }

                    if (!items.has_key (item.id_string)) {
                        items [item.id_string] = new Layouts.ItemRow (item);
                        listbox.append (items [item.id_string]);
                    }
                }
            }
        });

        Services.Database.get_default ().item_updated.connect ((item, update_id) => {
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

        Services.Database.get_default ().item_deleted.connect ((item) => {
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
                // update_items_position ();
            }
        });

        Planner.event_bus.magic_button_activated.connect ((value) => {
            if (!is_inbox_section) {
                // build_placeholder_drag_and_drop (value);
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
            } else {
                placeholder_revealer.reveal_child = true;
            }
        });

        section.project.show_completed_changed.connect (show_completed_changed);

        section.project.sort_order_changed.connect (() => {
            update_sort ();
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

        section.section_count_updated.connect (() => {
            count_label.label = section.section_count.to_string ();
            count_revealer.reveal_child = int.parse (count_label.label) > 0;
        });
    }

    private void show_completed_changed () {
        if (section.project.show_completed) {
            add_completed_items ();
        } else {
            items_checked.clear ();

            for (Gtk.Widget child = checked_listbox.get_first_child (); child != null; child = checked_listbox.get_next_sibling ()) {
                checked_listbox.remove (child);
            }
        }

        checked_revealer.reveal_child = section.project.show_completed;
    }


    public void add_completed_items () {
        items_checked.clear ();

        for (Gtk.Widget child = checked_listbox.get_first_child (); child != null; child = checked_listbox.get_next_sibling ()) {
            checked_listbox.remove (child);
        }

        foreach (Objects.Item item in is_inbox_section ? section.project.items : section.items) {
            add_complete_item (item);
        }
    }

    public void add_complete_item (Objects.Item item) {
        if (section.project.show_completed && item.checked) {
            if (!items_checked.has_key (item.id_string)) {
                items_checked [item.id_string] = new Layouts.ItemRow (item);
                checked_listbox.append (items_checked [item.id_string]);
                checked_listbox.show ();
            }
        }
    }

    private void update_items_position () {
        Timeout.add (content_revealer.transition_duration, () => {
            Layouts.ItemRow item_row = null;
            var row_index = 0;

            do {
                item_row = (Layouts.ItemRow) listbox.get_row_at_index (row_index);

                if (item_row != null) {
                    item_row.item.child_order = row_index;
                    Services.Database.get_default ().update_child_order (item_row.item);
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

    public void add_items () {
        items.clear ();

        Gtk.Widget child;
        for (child = listbox.get_first_child (); child != null; child = listbox.get_next_sibling ()) {
            child.destroy ();
        }

        foreach (Objects.Item item in is_inbox_section ? section.project.items : section.items) {
            add_item (item);
        }

        update_sort ();
    }

    public void add_item (Objects.Item item) {
        if (!item.checked && !items.has_key (item.id_string)) {
            items [item.id_string] = new Layouts.ItemRow (item);
            listbox.append (items [item.id_string]);
            listbox.show ();
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
        row.update_priority (Util.get_default ().get_default_priority ());

        row.item_added.connect (() => {
            Util.get_default ().item_added (row);
        });
        
        if (has_children) {
            listbox.insert (row, 0);
        } else {
            listbox.append (row);
        }
        
        listbox.show ();
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
        content_revealer.reveal_child = false;
        Timeout.add (content_revealer.transition_duration, () => {
            ((Gtk.ListBox) parent).remove (this);
            return GLib.Source.REMOVE;
        });
    }

    private void build_context_menu (double x, double y, Gtk.Widget parent) {
        if (menu_popover != null) {
            menu_popover.set_parent (parent);
            menu_popover.pointing_to = { (int) x, (int) y, 1, 1 };
            menu_popover.popup();
            return;
        }

        var add_item = new Widgets.ContextMenu.MenuItem (_("Add task"), "planner-plus-circle");
        var edit_item = new Widgets.ContextMenu.MenuItem (_("Edit section"), "planner-edit");
        var move_item = new Widgets.ContextMenu.MenuItem (_("Move section"), "chevron-right");
        var delete_item = new Widgets.ContextMenu.MenuItem (_("Delete section"), "planner-trash");
        delete_item.add_css_class ("menu-item-danger");
        
        var menu_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        menu_box.margin_top = menu_box.margin_bottom = 3;
        menu_box.append (add_item);
        menu_box.append (edit_item);
        menu_box.append (move_item);
        menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
        menu_box.append (delete_item);

        menu_popover = new Gtk.Popover () {
            has_arrow = false,
            child = menu_box,
            position = Gtk.PositionType.BOTTOM
        };

        menu_popover.set_parent (parent);
        menu_popover.pointing_to = { (int) x, (int) y, 1, 1 };
        menu_popover.popup();

        add_item.clicked.connect (() => {
            menu_popover.popdown ();
            prepare_new_item ();
        });

        edit_item.clicked.connect (() => {
            menu_popover.popdown ();
            name_editable.editing (true);
        });

        move_item.clicked.connect (() => {
            menu_popover.popdown ();
        });

        delete_item.clicked.connect (() => {
            menu_popover.popdown ();

            var dialog = new Adw.MessageDialog ((Gtk.Window) Planner.instance.main_window, 
            _("Delete section"), _("Are you sure you want to delete <b>%s</b>?".printf (Util.get_default ().get_dialog_text (section.short_name))));

            dialog.body_use_markup = true;
            dialog.add_response ("cancel", _("Cancel"));
            dialog.add_response ("delete", _("Delete"));
            dialog.set_response_appearance ("delete", Adw.ResponseAppearance.DESTRUCTIVE);
            dialog.show ();

            dialog.response.connect ((response) => {
                if (response == "delete") {
                    if (section.project.backend_type == BackendType.TODOIST) {
                        //  remove_button.is_loading = true;
                        Services.Todoist.get_default ().delete.begin (section, (obj, res) => {
                            Services.Todoist.get_default ().delete.end (res);
                            Services.Database.get_default ().delete_section (section);
                            // remove_button.is_loading = false;
                            // message_dialog.hide_destroy ();
                        });
                    } else {
                        Services.Database.get_default ().delete_section (section);
                    }
                }
            });
        });
    }

    private void build_drag_and_drop () {
        if (is_inbox_section) {
            return;
        }

        var drag_source = new Gtk.DragSource ();
        drag_source.set_actions (Gdk.DragAction.MOVE);

        drag_source.prepare.connect ((source, x, y) => {
            return new Gdk.ContentProvider.for_value (this);
        });

        drag_source.drag_begin.connect ((source, drag) => {
            var paintable = new Gtk.WidgetPaintable (sectionrow_grid);
            source.set_icon (paintable, 0, 0);
            drag_begin ();
        });
        
        drag_source.drag_end.connect ((source, drag, delete_data) => {
            drag_end ();
        });

        drag_source.drag_cancel.connect ((source, drag, reason) => {
            drag_end ();
            return false;
        });

        add_controller (drag_source);

        var drop_target = new Gtk.DropTarget (typeof (Layouts.SectionRow), Gdk.DragAction.MOVE);
        drop_target.preload = true;

        drop_target.on_drop.connect ((target, value, x, y) => {
            var picked_widget = (Layouts.SectionRow) value;
            var target_widget = (Layouts.SectionRow) target.get_widget ();
            
            Gtk.Allocation alloc;
            target_widget.get_allocation (out alloc);

            picked_widget.drag_end ();
            target_widget.drag_end ();

            if (picked_widget == target_widget || target_widget == null) {
                return false;
            }

            if (target_widget.get_index () == 0) {
                return false;
            }

            var source_list = (Gtk.ListBox) picked_widget.parent;
            var target_list = (Gtk.ListBox) target_widget.parent;

            source_list.remove (picked_widget);
            
            if (target_widget.get_index () == 0) {
                if (y < (alloc.height / 2)) {
                    target_list.insert (picked_widget, 0);
                } else {
                    target_list.insert (picked_widget, target_widget.get_index () + 1);
                }
            } else {
                target_list.insert (picked_widget, target_widget.get_index () + 1);
            }

            return true;
        });

        add_controller (drop_target);
    }

    public void drag_begin () {
        sectionrow_grid.add_css_class ("card");
        opacity = 0.3;
        on_drag = true;
        bottom_revealer.reveal_child = false;
    }

    public void drag_end () {
        sectionrow_grid.remove_css_class ("card");
        opacity = 1;
        on_drag = false;
    }
}