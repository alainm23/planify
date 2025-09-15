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
    private Gtk.Button load_more_button;
    private Gtk.Revealer load_more_button_revealer;
    private Gtk.Revealer checked_revealer;
    private Gtk.Revealer main_revealer;
    public Widgets.LoadingButton add_button;

    private Gee.HashMap<ulong, GLib.Object> signal_map = new Gee.HashMap<ulong, GLib.Object> ();
    public Gee.HashMap<string, Layouts.ItemBase> items_map = new Gee.HashMap<string, Layouts.ItemBase> ();
    public Gee.HashMap<string, Layouts.ItemBase> items_checked = new Gee.HashMap<string, Layouts.ItemBase> ();

    private Gee.ArrayList<Objects.Item> completed_items_list;
    private int completed_page_index = 0;
    private const int PAGE_SIZE = Constants.COMPLETED_PAGE_SIZE;
    
    public bool has_children {
        get {
            return items_map.size > 0 || (items_checked.size > 0 && show_completed);
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

    ~SubItems () {
        print ("Destroying - Widgets.SubItems\n");
    }

    construct {
        var sub_tasks_title = new Gtk.Label (_ ("Sub-tasks")) {
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
            margin_start = is_board ? 6 : 0,
            margin_end = is_board ? 12 : 0,
        };

        if (is_board) {
            listbox.set_placeholder (get_placeholder ());
        }

        checked_listbox = new Gtk.ListBox () {
            valign = Gtk.Align.START,
            activate_on_single_click = true,
            selection_mode = Gtk.SelectionMode.SINGLE,
            hexpand = true,
            css_classes = { "listbox-background" },
            margin_start = is_board ? 6 : 0,
            margin_end = is_board ? 12 : 0,
        };

        load_more_button = new Gtk.Button.with_label ("Cargar más") {
            halign = START,
            margin_start = 9
        };
        load_more_button.add_css_class ("flat");

        load_more_button_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            reveal_child = false,
            child = load_more_button
        };

        var checked_listbox_container = new Gtk.Box (VERTICAL, 6);
        checked_listbox_container.append (checked_listbox);
        checked_listbox_container.append (load_more_button_revealer);

        checked_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            child = checked_listbox_container
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

        signal_map[item_parent.item_added.connect (add_item)] = item_parent;

        signal_map[Services.Store.instance ().item_updated.connect ((item, update_id) => {
            if (items_map.has_key (item.id)) {
                if (items_map[item.id].update_id != update_id) {
                    items_map[item.id].update_request ();
                    update_sort ();
                }
            }

            if (items_checked.has_key (item.id)) {
                items_checked[item.id].update_request ();
            }
        })] = Services.Store.instance ();

        signal_map[Services.Store.instance ().item_pin_change.connect ((item) => {
            // vala-lint=no-space
            if (!item.pinned && item.parent_id == item_parent.id &&
                !items_map.has_key (item.id)) {
                add_item (item);
            }

            if (item.pinned && items_map.has_key (item.id)) {
                items_map[item.id].hide_destroy ();
                items_map.unset (item.id);
            }
        })] = Services.Store.instance ();

        signal_map[Services.Store.instance ().item_deleted.connect ((item) => {
            if (items_map.has_key (item.id)) {
                items_map[item.id].hide_destroy ();
                items_map.unset (item.id);
            }

            if (items_checked.has_key (item.id)) {
                items_checked[item.id].hide_destroy ();
                items_checked.unset (item.id);
            }

            children_changes ();
        })] = Services.Store.instance ();

        signal_map[Services.EventBus.get_default ().item_moved.connect ((item, old_project_id, old_section_id, old_parent_id) => {
            if (old_parent_id == item_parent.id) {
                if (items_map.has_key (item.id)) {
                    items_map[item.id].hide_destroy ();
                    items_map.unset (item.id);
                }

                if (items_checked.has_key (item.id)) {
                    items_checked[item.id].hide_destroy ();
                    items_checked.unset (item.id);
                }
            }

            if (item.parent_id == item_parent.id) {
                add_item (item);
            }

            update_sort ();
            children_changes ();
        })] = Services.EventBus.get_default ();

        signal_map[Services.EventBus.get_default ().checked_toggled.connect ((item, old_checked) => {
            if (item.parent_id == item_parent.id) {
                if (!old_checked) {
                    if (items_map.has_key (item.id)) {
                        items_map[item.id].hide_destroy ();
                        items_map.unset (item.id);
                    }

                    if (!items_checked.has_key (item.id)) {
                        if (is_board) {
                            items_checked[item.id] = new Layouts.ItemBoard (item);
                        } else {
                            items_checked[item.id] = new Layouts.ItemRow (item, is_project_view);
                        }

                        checked_listbox.insert (items_checked[item.id], 0);
                    }
                } else {
                    if (items_checked.has_key (item.id)) {
                        items_checked[item.id].hide_destroy ();
                        items_checked.unset (item.id);
                    }

                    if (!items_map.has_key (item.id)) {
                        if (is_board) {
                            items_map[item.id] = new Layouts.ItemBoard (item);
                        } else {
                            items_map[item.id] = new Layouts.ItemRow (item, is_project_view);
                        }

                        listbox.append (items_map[item.id]);
                        children_changes ();
                    }
                }

                children_changes ();
            }
        })] = Services.EventBus.get_default ();

        signal_map[Services.EventBus.get_default ().update_inserted_item_map.connect ((_row, old_section_id, old_parent_id) => {
            if (!is_board) {
                var row = (Layouts.ItemRow) _row;

                if (old_parent_id == item_parent.id) {
                    if (items_map.has_key (row.item.id)) {
                        items_map.unset (row.item.id);
                    }

                    if (items_checked.has_key (row.item.id)) {
                        items_checked.unset (row.item.id);
                    }

                    children_changes ();
                }
            }
        })] = Services.EventBus.get_default ();

        signal_map[add_button.clicked.connect (() => {
            prepare_new_item ();
        })] = add_button;

        signal_map[item_parent.project.sort_order_changed.connect (() => {
            update_sort ();
        })] = item_parent.project;

        signal_map[item_parent.project.sorted_by_changed.connect (() => {
            update_sort ();
        })] = item_parent.project;

        signal_map[Services.Settings.get_default ().settings.changed["always-show-completed-subtasks"].connect (() => {
            checked_revealer.reveal_child = show_completed;
            if (show_completed) {
                add_completed_items ();
            }
        })] = Services.Settings.get_default ().settings;

        signal_map[Services.EventBus.get_default ().expand_all.connect ((project_id, value) => {
            if (item_parent.project_id == project_id) {
                foreach (Layouts.ItemBase row_base in items_map.values) {
                    if (row_base is Layouts.ItemRow) {
                        ((Layouts.ItemRow) row_base).edit = value;
                    }
                }
            }
        })] = Services.Settings.get_default ();

        signal_map[item_parent.project.show_completed_changed.connect (() => {
            if (!Services.Settings.get_default ().settings.get_boolean ("always-show-completed-subtasks")) {
                checked_revealer.reveal_child = show_completed;

                if (show_completed) {
                    add_completed_items ();
                } else {
                    items_checked.clear ();

                    foreach (unowned Gtk.Widget child in Util.get_default ().get_children (checked_listbox)) {
                        checked_listbox.remove (child);
                    }
                }
            }
        })] = item_parent.project;

        signal_map[load_more_button.clicked.connect (() => {
            load_next_completed_page ();
        })] = load_more_button;
    }

    public void add_items () {
        items_map.clear ();

        foreach (unowned Gtk.Widget child in Util.get_default ().get_children (listbox)) {
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

        foreach (unowned Gtk.Widget child in Util.get_default ().get_children (checked_listbox)) {
            checked_listbox.remove (child);
        }

        completed_items_list = new Gee.ArrayList<Objects.Item> ();
        foreach (Objects.Item item in item_parent.items) {
            if (item.checked) {
                completed_items_list.add (item);
            }
        }

        completed_items_list.sort ((a, b) => {
            var completed_a = Utils.Datetime.get_date_only (
                Utils.Datetime.get_date_from_string (a.completed_at)
            );

            var completed_b = Utils.Datetime.get_date_only (
                Utils.Datetime.get_date_from_string (b.completed_at)
            );
            
            return completed_b.compare (completed_a);
        });

        completed_page_index = 0;
        load_next_completed_page ();
    }

    private void load_next_completed_page () {
        int start = completed_page_index * PAGE_SIZE;
        int end = (start + PAGE_SIZE < completed_items_list.size) ? (start + PAGE_SIZE) : completed_items_list.size;

        for (int i = start; i < end; i++) {
            Objects.Item item = completed_items_list[i];
            add_complete_item (item);
        }

        completed_page_index++;
        update_load_more_button_label ();
    }

     private void update_load_more_button_label () {
        int loaded = completed_page_index * PAGE_SIZE;
        int remaining = completed_items_list.size - loaded;

        if (remaining > 0) {
            int to_show = remaining < PAGE_SIZE ? remaining : PAGE_SIZE;
            load_more_button.label = "+%d %s".printf (to_show, _ ("completed tasks"));
            load_more_button_revealer.reveal_child = true;
        } else {
            load_more_button.set_label ("No more tasks");
            load_more_button_revealer.reveal_child = false;
        }
    }

    public void add_complete_item (Objects.Item item) {
        if (show_completed && item.checked) {
            if (!items_checked.has_key (item.id)) {
                if (is_board) {
                    items_checked[item.id] = new Layouts.ItemBoard (item);
                } else {
                    items_checked[item.id] = new Layouts.ItemRow (item, is_project_view);
                }

                checked_listbox.append (items_checked[item.id]);
            }
        }
    }

    public void add_item (Objects.Item item) {
        if (item.checked) {
            return;
        }

        if (item.pinned) {
            return;
        }

        if (items_map.has_key (item.id)) {
            return;
        }

        if (is_board) {
            items_map[item.id] = new Layouts.ItemBoard (item);
        } else {
            items_map[item.id] = new Layouts.ItemRow (item, is_project_view);
        }

        listbox.append (items_map[item.id]);
        
        children_changes ();
    }

    private void update_sort () {
        listbox.set_sort_func (set_sort_func);
        listbox.set_sort_func (null);
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

        return Util.get_default ().set_item_sort_func (
            item1,
            item2,
            item_parent.project.sorted_by,
            item_parent.project.sort_order
        );
    }

    public void prepare_new_item (string content = "") {
        var dialog = new Dialogs.QuickAdd ();
        dialog.for_base_object (item_parent);
        dialog.update_content (content);
        dialog.present (Planify._instance.main_window);
    }

    public void clean_up () {
        listbox.set_sort_func (null);

        foreach (var row in Util.get_default ().get_children (listbox)) {
            ((Layouts.ItemBase) row).clean_up ();  
        }

        foreach (var row in Util.get_default ().get_children (checked_listbox)) {
            ((Layouts.ItemBase) row).clean_up ();  
        }

        foreach (var entry in signal_map.entries) {
            entry.value.disconnect (entry.key);
        }

        signal_map.clear ();
    }

    public void disable_drag_and_drop () {
        foreach (Layouts.ItemBase row in items_map.values) {
            ((Layouts.ItemRow) row).disable_drag_and_drop ();
        }
    }

    private Gtk.Widget get_placeholder () {
        var message_label = new Gtk.Label (_ ("No subtasks added yet. Get started!")) {
            wrap = true,
            justify = Gtk.Justification.CENTER,
            hexpand = true,
            vexpand = true,
            margin_top = 24,
            margin_start = 24,
            margin_end = 24,
            margin_bottom = 24
        };

        var placeholder_grid = new Adw.Bin () {
            hexpand = true,
            vexpand = true,
            margin_top = 6,
            margin_start = 6,
            margin_end = 12,
            margin_bottom = 6,
            child = message_label,
            css_classes = { "card" }
        };

        return placeholder_grid;
    }
}
