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

public class Layouts.SectionRow : Gtk.ListBoxRow {
    public Objects.Section section { get; construct; }

    private Gtk.Revealer bottom_revealer;
    private Gtk.Label name_label;
    private Gtk.Label count_label;
    private Gtk.ListBox listbox;
    private Gtk.ListBox checked_listbox;
    private Gtk.Button load_more_button;
    private Gtk.Revealer load_more_button_revealer;
    private Gtk.Revealer checked_revealer;
    private Gtk.Revealer content_revealer;
    private Gtk.Grid drop_inbox_widget;
    private Gtk.Revealer drop_inbox_revealer;
    private Adw.Bin handle_grid;
    private Gtk.Box sectionrow_box;
    private Widgets.LoadingButton add_button;
    private Gtk.Button hide_subtask_button;

    public bool is_inbox_section {
        get {
            return section.id == "";
        }
    }

    public bool has_children {
        get {
            return items_map.size > 0 ||
                   checked_items_map.size > 0;
        }
    }

    public bool is_creating {
        get {
            return section.id == "";
        }
    }

    public bool is_loading {
        set {
            add_button.is_loading = value;
        }
    }

    public Gee.HashMap<string, Layouts.ItemRow> items_map = new Gee.HashMap<string, Layouts.ItemRow> ();
    public Gee.HashMap<string, Layouts.ItemRow> checked_items_map = new Gee.HashMap<string, Layouts.ItemRow> ();

    private Gee.ArrayList<Objects.Item> completed_items_list;
    private int completed_page_index = 0;
    private const int PAGE_SIZE = Constants.COMPLETED_PAGE_SIZE;

    private Gee.HashMap<ulong, weak GLib.Object> signals_map = new Gee.HashMap<ulong, weak GLib.Object> ();

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
        section.id = "";
        section.project_id = project.id;
        section.name = _ ("(No Section)");

        Object (
            section: section,
            focusable: false,
            can_focus: true
        );
    }

    ~SectionRow () {
        print ("Destroying Layouts.SectionRow\n");
    }

    construct {
        add_css_class ("no-selectable");
        add_css_class ("no-padding");

        hide_subtask_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            css_classes = { "flat", "dimmed", "no-padding", "hidden-button" },
            child = new Gtk.Image.from_icon_name ("go-next-symbolic") {
                pixel_size = 12
            }
        };

        name_label = new Gtk.Label (section.name) {
            halign = START,
            css_classes = { "font-bold" },
            margin_start = 9
        };

        count_label = new Gtk.Label (null) {
            margin_start = 9,
            halign = Gtk.Align.CENTER,
            css_classes = { "dimmed", "caption" }
        };

        var menu_button = new Gtk.MenuButton () {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER,
            popover = build_context_menu (),
            icon_name = "view-more-symbolic",
            css_classes = { "flat" }
        };

        var actions_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            hexpand = true,
            halign = END
        };
        actions_box.append (menu_button);

        var actions_box_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.CROSSFADE,
            reveal_child = true,
            child = actions_box,
            margin_end = 6
        };

        var sectionrow_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            margin_start = 3
        };

        sectionrow_box.append (hide_subtask_button);
        sectionrow_box.append (name_label);
        sectionrow_box.append (count_label);
        sectionrow_box.append (actions_box_revealer);

        var sectionrow_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            reveal_child = !is_inbox_section,
            child = sectionrow_box
        };

        handle_grid = new Adw.Bin () {
            margin_top = is_inbox_section ? 12 : 0,
            css_classes = { "transition", "drop-target" },
            child = sectionrow_revealer
        };

        drop_inbox_widget = new Gtk.Grid () {
            css_classes = { "transition", "drop-target" },
            height_request = 30,
            margin_start = 24,
            margin_end = 24,
            margin_top = 6,
            margin_bottom = 6
        };

        drop_inbox_revealer = new Gtk.Revealer () {
            transition_type = SLIDE_DOWN,
            child = drop_inbox_widget
        };

        listbox = new Gtk.ListBox () {
            valign = Gtk.Align.START,
            hexpand = true,
            css_classes = { "listbox-background" }
        };

        checked_listbox = new Gtk.ListBox () {
            valign = Gtk.Align.START,
            hexpand = true,
            css_classes = { "listbox-background" }
        };

        load_more_button = new Gtk.Button.with_label ("Cargar más") {
            margin_start = 9,
            halign = START,
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
            reveal_child = true,
            child = checked_listbox_container
        };

        var bottom_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            hexpand = true,
            margin_end = 24
        };

        var add_button_box = new Gtk.Box (HORIZONTAL, 6) {
            valign = CENTER
        };
        add_button_box.append (new Gtk.Image.from_icon_name ("plus-large-symbolic") {
            css_classes = { "color-primary" }
        });
        add_button_box.append (new Gtk.Label (_("Add taks")));

        var add_button = new Gtk.Button () {
            child = add_button_box,
            margin_start = 16,
            margin_bottom = 6,
            halign = START
        };
        add_button.add_css_class ("flat");
        add_button.add_css_class ("add-button");

        bottom_box.append (listbox);
        bottom_box.append (drop_inbox_revealer);
        bottom_box.append (add_button);
        bottom_box.append (checked_revealer);

        bottom_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            reveal_child = section.collapsed,
            child = bottom_box
        };

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            hexpand = true
        };

        content_box.append (handle_grid);
        content_box.append (bottom_revealer);

        content_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            child = content_box
        };

        child = content_revealer;

        add_items ();
        show_completed_changed ();
        build_drag_and_drop ();
        update_count_label (section.section_count);
        update_collapsed_button ();

        Timeout.add (content_revealer.transition_duration, () => {
            content_revealer.reveal_child = true;
            return GLib.Source.REMOVE;
        });

        signals_map[section.updated.connect (() => {
            name_label.label = section.name;
            bottom_revealer.reveal_child = section.collapsed;
            update_collapsed_button ();
        })] = section;

        if (is_inbox_section) {
            signals_map[section.project.item_added.connect ((item) => {
                add_item (item);
            })] = section;
        } else {
            signals_map[section.item_added.connect ((item) => {
                add_item (item);
            })] = section;
        }

        var edit_gesture = new Gtk.GestureClick ();
        name_label.add_controller (edit_gesture);
        signals_map[edit_gesture.released.connect ((n_press, x, y) => {
            if (n_press == 2) {
                var dialog = new Dialogs.Section (section);
                dialog.present (Planify._instance.main_window);
            }
        })] = edit_gesture;

        signals_map[Services.EventBus.get_default ().checked_toggled.connect ((item, old_checked) => {
            if (item.project_id == section.project_id && item.section_id == section.id && !item.has_parent) {
                if (!old_checked) {
                    if (items_map.has_key (item.id)) {
                        items_map[item.id].hide_destroy ();
                        items_map.unset (item.id);
                    }

                    if (!checked_items_map.has_key (item.id)) {
                        checked_items_map[item.id] = new Layouts.ItemRow (item, true);
                        checked_listbox.insert (checked_items_map[item.id], 0);
                    }
                } else {
                    if (checked_items_map.has_key (item.id)) {
                        checked_items_map[item.id].hide_destroy ();
                        checked_items_map.unset (item.id);
                    }

                    if (!items_map.has_key (item.id)) {
                        items_map[item.id] = new Layouts.ItemRow (item, true);
                        listbox.append (items_map[item.id]);
                    }
                }
            }
        })] = Services.EventBus.get_default ();

        signals_map[Services.Store.instance ().item_updated.connect ((item, update_id) => {
            if (items_map.has_key (item.id)) {
                if (items_map[item.id].update_id != update_id) {
                    items_map[item.id].update_request ();
                    update_sort ();
                }

                if (checked_items_map.has_key (item.id)) {
                    checked_items_map[item.id].update_request ();
                }
            }
        })] = Services.Store.instance ();

        signals_map[Services.Store.instance ().item_pin_change.connect ((item) => {
            // vala-lint=no-space
            if (!item.pinned && item.project_id == section.project_id &&
                item.section_id == section.id && !item.has_parent &&
                !items_map.has_key (item.id)) {
                add_item (item);
            }

            if (item.pinned && items_map.has_key (item.id)) {
                items_map[item.id].hide_destroy ();
                items_map.unset (item.id);
            }
        })] = Services.Store.instance ();

        signals_map[Services.Store.instance ().item_deleted.connect ((item) => {
            if (items_map.has_key (item.id)) {
                items_map[item.id].hide_destroy ();
                items_map.unset (item.id);
            }

            if (checked_items_map.has_key (item.id)) {
                checked_items_map[item.id].hide_destroy ();
                checked_items_map.unset (item.id);
            }
        })] = Services.Store.instance ();

        signals_map[Services.EventBus.get_default ().item_moved.connect ((item, old_project_id, old_section_id, old_parent_id) => {
            // vala-lint=no-space
            if (old_project_id == section.project_id && old_section_id == section.id) {
                if (items_map.has_key (item.id)) {
                    items_map[item.id].hide_destroy ();
                    items_map.unset (item.id);
                }

                if (checked_items_map.has_key (item.id)) {
                    checked_items_map[item.id].hide_destroy ();
                    checked_items_map.unset (item.id);
                }
            }

            // vala-lint=no-space
            if (item.project_id == section.project_id && item.section_id == section.id && !item.has_parent) {
                add_item (item);
            }

            update_sort ();
        })] = Services.EventBus.get_default ();

        signals_map[Services.EventBus.get_default ().update_inserted_item_map.connect ((_row, old_section_id) => {
            if (_row is Layouts.ItemRow) {
                var row = (Layouts.ItemRow) _row;

                if (row.item.project_id == section.project_id && row.item.section_id == section.id) {
                    if (!items_map.has_key (row.item.id)) {
                        items_map[row.item.id] = row;
                        update_sort ();
                    }
                }

                // vala-lint=no-space
                if (row.item.project_id == section.project_id && row.item.section_id != section.id && old_section_id == section.id) {
                    if (items_map.has_key (row.item.id)) {
                        items_map.unset (row.item.id);
                    }
                }
            }
        })] = Services.EventBus.get_default ();

        signals_map[section.project.show_completed_changed.connect (show_completed_changed)] = section.project;

        signals_map[section.project.sort_order_changed.connect (() => {
            update_sort ();
        })] = section.project;

        signals_map[section.project.sorted_by_changed.connect (() => {
            update_sort ();
        })] = section.project;

        signals_map[Services.EventBus.get_default ().update_section_sort_func.connect ((project_id, section_id, value) => {
            if (section.project_id == project_id && section.id == section_id) {
                update_sort ();
            }
        })] = Services.EventBus.get_default ();

        signals_map[section.section_count_updated.connect (() => {
            update_count_label (section.section_count);
        })] = section;

        signals_map[Services.EventBus.get_default ().drag_n_drop_active.connect ((project_id, active) => {
            if (section.project_id == project_id) {
                drop_inbox_revealer.reveal_child = active;
            }
        })] = Services.EventBus.get_default ();

        listbox.set_filter_func ((row) => {
            var item = ((Layouts.ItemRow) row).item;
            bool return_value = true;

            if (section.project.filters.size <= 0) {
                return true;
            }

            return_value = false;
            foreach (Objects.Filters.FilterItem filter in section.project.filters.values) {
                if (filter.filter_type == FilterItemType.PRIORITY) {
                    return_value = return_value || item.priority == int.parse (filter.value);
                } else if (filter.filter_type == FilterItemType.LABEL) {
                    return_value = return_value || item.has_label (filter.value);
                } else if (filter.filter_type == FilterItemType.DUE_DATE) {
                    if (filter.value == "1") {
                        return_value = return_value || (item.has_due && Utils.Datetime.is_today (item.due.datetime));
                    } else if (filter.value == "2") {
                        return_value = return_value || (item.has_due && Utils.Datetime.is_this_week (item.due.datetime));
                    } else if (filter.value == "3") {
                        return_value = return_value || (item.has_due && Utils.Datetime.is_next_x_week (item.due.datetime, 7));
                    } else if (filter.value == "4") {
                        return_value = return_value || (item.has_due && Utils.Datetime.is_this_month (item.due.datetime));
                    } else if (filter.value == "5") {
                        return_value = return_value || (item.has_due && Utils.Datetime.is_next_x_week (item.due.datetime, 30));
                    } else if (filter.value == "6") {
                        return_value = return_value || !item.has_due;
                    }
                }
            }

            return return_value;
        });

        signals_map[section.project.filter_added.connect (() => {
            update_sort ();
        })] = section.project;

        signals_map[section.project.filter_removed.connect (() => {
            update_sort ();
        })] = section.project;

        signals_map[section.project.filter_updated.connect (() => {
            update_sort ();
        })] = section.project;

        signals_map[section.sensitive_change.connect (() => {
            sensitive = section.sensitive;
        })] = section;

        signals_map[section.loading_change.connect (() => {
            is_loading = section.loading;
        })] = section;

        signals_map[Services.EventBus.get_default ().expand_all.connect ((project_id, value) => {
            if (section.project_id == project_id) {
                foreach (Layouts.ItemRow row in items_map.values) {
                    row.edit = value;
                }
            }
        })] = Services.EventBus.get_default ();

        signals_map[hide_subtask_button.clicked.connect (() => {
            section.collapsed = !section.collapsed;
            section.update_local ();
        })] = hide_subtask_button;

        signals_map[load_more_button.clicked.connect (() => {
            load_next_completed_page ();
        })] = load_more_button;

        signals_map[add_button.clicked.connect (() => {
            prepare_new_item ("", NewTaskPosition.END);
        })] = add_button;

        signals_map[section.project.source.sync_finished.connect (() => {
            update_sort ();
        })] = section.project.source;
    }

    private void update_count_label (int count) {
        count_label.label = count <= 0 ? "" : count.to_string ();
    }

    private void update_sort () {
        listbox.set_sort_func (set_sort_func);
        listbox.set_sort_func (null);
        listbox.invalidate_filter ();
    }

    private int set_sort_func (Gtk.ListBoxRow lbrow, Gtk.ListBoxRow lbbefore) {
        Objects.Item item1 = ((Layouts.ItemRow) lbrow).item;
        Objects.Item item2 = ((Layouts.ItemRow) lbbefore).item;

        return Util.get_default ().set_item_sort_func (
            item1,
            item2,
            section.project.sorted_by,
            section.project.sort_order
        );
    }

    public void add_items () {
        items_map.clear ();

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
        if (item.checked) {
            return;
        }

        if (item.pinned) {
            return;
        }

        if (items_map.has_key (item.id)) {
            return;
        }

        items_map[item.id] = new Layouts.ItemRow (item, true);
        listbox.append (items_map[item.id]);
    }

    private void show_completed_changed () {
        if (section.project.show_completed) {
            add_completed_items ();
        } else {
            foreach (Layouts.ItemRow row in checked_items_map.values) {
                row.hide_destroy ();
            }

            checked_items_map.clear ();
        }

        checked_revealer.reveal_child = section.project.show_completed;
    }

    public void add_completed_items () {
        foreach (Layouts.ItemRow row in checked_items_map.values) {
            row.hide_destroy ();
        }

        checked_items_map.clear ();

        completed_items_list = new Gee.ArrayList<Objects.Item> ();
        foreach (Objects.Item item in is_inbox_section ? section.project.items : section.items) {
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
        if (!section.project.show_completed) {
            return;
        }

        if (!item.checked) {
            return;
        }

        if (checked_items_map.has_key (item.id_string)) {
            return;
        }

        checked_items_map[item.id_string] = new Layouts.ItemRow (item);
        checked_listbox.append (checked_items_map[item.id_string]);
    }

    public void prepare_new_item (string content = "", NewTaskPosition new_task_position = Services.Settings.get_default ().get_new_task_position ()) {
        var dialog = new Dialogs.QuickAdd ();
        dialog.for_base_object (section);
        dialog.update_content (content);
        dialog.set_new_task_position (new_task_position);
        dialog.present (Planify._instance.main_window);
    }

    public void hide_destroy () {
        content_revealer.reveal_child = false;
        clean_up ();
        Timeout.add (content_revealer.transition_duration, () => {
            ((Gtk.ListBox) parent).remove (this);
            return GLib.Source.REMOVE;
        });
    }

    private Gtk.Popover build_context_menu () {
        var add_item = new Widgets.ContextMenu.MenuItem (_ ("Add Task"), "plus-large-symbolic");
        var edit_item = new Widgets.ContextMenu.MenuItem (_ ("Edit Section"), "edit-symbolic");
        var move_item = new Widgets.ContextMenu.MenuItem (_ ("Move Section"), "arrow3-right-symbolic");
        var manage_item = new Widgets.ContextMenu.MenuItem (_ ("Manage Sections"), "view-list-ordered-symbolic");
        var duplicate_item = new Widgets.ContextMenu.MenuItem (_ ("Duplicate"), "tabs-stack-symbolic");
        var show_completed_item = new Widgets.ContextMenu.MenuItem (_ ("Show Completed Tasks"), "check-round-outline-symbolic");

        var archive_item = new Widgets.ContextMenu.MenuItem (_ ("Archive"), "shoe-box-symbolic");
        var delete_item = new Widgets.ContextMenu.MenuItem (_ ("Delete Section"), "user-trash-symbolic");
        delete_item.add_css_class ("menu-item-danger");

        var menu_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        menu_box.margin_top = menu_box.margin_bottom = 3;
        menu_box.append (add_item);

        if (!is_inbox_section) {
            menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
            menu_box.append (edit_item);
        }

        menu_box.append (move_item);
        menu_box.append (manage_item);
        menu_box.append (duplicate_item);
        menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
        menu_box.append (show_completed_item);

        if (!is_inbox_section) {
            menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
            menu_box.append (archive_item);
            menu_box.append (delete_item);
        }

        var menu_popover = new Gtk.Popover () {
            has_arrow = false,
            child = menu_box,
            position = Gtk.PositionType.BOTTOM,
            width_request = 250
        };

        add_item.clicked.connect (() => {
            prepare_new_item ();
        });

        edit_item.clicked.connect (() => {
            var dialog = new Dialogs.Section (section);
            dialog.present (Planify._instance.main_window);
        });

        move_item.clicked.connect (() => {
            var dialog = new Dialogs.ProjectPicker.ProjectPicker.for_project (section.source);
            dialog.project = section.project;
            dialog.present (Planify._instance.main_window);

            dialog.changed.connect ((type, id) => {
                if (type == "project") {
                    move_section (id);
                }
            });
        });

        manage_item.clicked.connect (() => {
            var dialog = new Dialogs.ManageSectionOrder (section.project);
            dialog.present (Planify._instance.main_window);
        });

        delete_item.clicked.connect (() => {
            section.delete_section ((Gtk.Window) Planify.instance.main_window);
        });

        show_completed_item.clicked.connect (() => {
            var dialog = new Dialogs.CompletedTasks (section.project);
            dialog.add_update_filter (section);
            dialog.present (Planify._instance.main_window);
        });

        archive_item.clicked.connect (() => {
            section.archive_section ((Gtk.Window) Planify.instance.main_window);
        });

        duplicate_item.clicked.connect (() => {
            Util.get_default ().duplicate_section.begin (section, section.project_id);
        });

        return menu_popover;
    }

    private void build_drag_and_drop () {
        var drop_inbox_target = new Gtk.DropTarget (typeof (Layouts.ItemRow), Gdk.DragAction.MOVE);
        drop_inbox_widget.add_controller (drop_inbox_target);
        signals_map[drop_inbox_target.drop.connect ((target, value, x, y) => {
            var picked_widget = (Layouts.ItemRow) value;
            picked_widget.drag_end ();

            string old_section_id = picked_widget.item.section_id;
            string old_parent_id = picked_widget.item.parent_id;

            picked_widget.item.project_id = section.project_id;
            picked_widget.item.section_id = section.id;
            picked_widget.item.parent_id = "";

            if (picked_widget.item.project.source_type == SourceType.TODOIST) {
                string type = "section_id";
                string id = section.id;

                if (is_inbox_section) {
                    type = "project_id";
                    id = section.project_id;
                }

                Services.Todoist.get_default ().move_item.begin (picked_widget.item, type, id, (obj, res) => {
                    if (Services.Todoist.get_default ().move_item.end (res).status) {
                        Services.Store.instance ().move_item (picked_widget.item, old_section_id, old_parent_id);
                    }
                });
            } else if (picked_widget.item.project.source_type == SourceType.LOCAL) {
                Services.Store.instance ().move_item (picked_widget.item, old_section_id, old_parent_id);
            }

            var source_list = (Gtk.ListBox) picked_widget.parent;
            source_list.remove (picked_widget);

            listbox.append (picked_widget);
            Services.EventBus.get_default ().update_inserted_item_map (picked_widget, old_section_id, old_parent_id);

            int new_index = Util.get_default ().get_children (listbox).index (picked_widget);
            Utils.TaskUtils.update_single_item_order (listbox, picked_widget, new_index);

            return true;
        })] = drop_inbox_target;
    }

    private void move_section (string project_id) {
        string old_project_id = section.project_id;
        section.project_id = project_id;

        is_loading = true;

        if (section.project.source_type == SourceType.TODOIST) {
            Services.Todoist.get_default ().move_project_section.begin (section, project_id, (obj, res) => {
                if (Services.Todoist.get_default ().move_project_section.end (res).status) {
                    Services.Store.instance ().move_section (section, old_project_id);
                }

                is_loading = false;
            });
        } else if (section.project.source_type == SourceType.LOCAL) {
            Services.Store.instance ().move_section (section, old_project_id);
            is_loading = false;
        }
    }

    private void update_collapsed_button () {
        if (section.collapsed) {
            hide_subtask_button.add_css_class ("opened");
        } else {
            hide_subtask_button.remove_css_class ("opened");
        }
    }

    public void clean_up () {
        listbox.set_sort_func (null);
        listbox.set_filter_func (null);

        // Clear Signals
        foreach (var entry in signals_map.entries) {
            entry.value.disconnect (entry.key);
        }

        signals_map.clear ();
    }
}
