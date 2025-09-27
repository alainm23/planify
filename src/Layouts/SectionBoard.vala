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

public class Layouts.SectionBoard : Gtk.FlowBoxChild {
    public Objects.Section section { get; construct; }

    private Gtk.Grid widget_color;
    private Gtk.Label name_label;
    private Gtk.Label count_label;
    private Gtk.Label description_label;
    private Gtk.Revealer description_revealer;
    private Gtk.ListBox listbox;
    private Gtk.Box listbox_target;
    private Gtk.ListBox checked_listbox;
    private Gtk.Button load_more_button;
    private Gtk.Revealer load_more_button_revealer;
    private Gtk.Revealer checked_revealer;
    private Gtk.Box content_box;

    public bool is_inbox_section {
        get {
            return section.id == "";
        }
    }

    public bool is_loading {
        set {
            // add_button.is_loading = value;
        }
    }

    public int section_count {
        get {
            return items_map.size;
        }
    }

    public Gee.HashMap<string, Layouts.ItemBoard> items_map = new Gee.HashMap<string, Layouts.ItemBoard> ();
    public Gee.HashMap<string, Layouts.ItemBoard> checked_items_map = new Gee.HashMap<string, Layouts.ItemBoard> ();
    private Gee.HashMap<ulong, weak GLib.Object> signals_map = new Gee.HashMap<ulong, weak GLib.Object> ();

    private Gee.ArrayList<Objects.Item> completed_items_list;
    private int completed_page_index = 0;
    private const int PAGE_SIZE = Constants.COMPLETED_PAGE_SIZE;

    public SectionBoard (Objects.Section section) {
        Object (
            section: section,
            focusable: false,
            width_request: 350,
            vexpand: true
        );
    }

    public SectionBoard.for_project (Objects.Project project) {
        var section = new Objects.Section ();
        section.id = "";
        section.project_id = project.id;
        section.name = _ ("(No Section)");

        Object (
            section: section,
            focusable: false,
            width_request: 350,
            vexpand: true
        );
    }

    ~SectionBoard () {
        debug ("Destroying - Layouts.SectionBoard\n");
    }

    construct {
        add_css_class ("no-selectable");
        add_css_class ("no-padding");

        widget_color = new Gtk.Grid () {
            valign = Gtk.Align.CENTER,
            height_request = 16,
            width_request = 3,
            css_classes = { "event-bar" }
        };

        name_label = new Gtk.Label (section.name) {
            halign = START,
            css_classes = { "font-bold" },
            margin_start = 6
        };

        count_label = new Gtk.Label (null) {
            margin_start = 9,
            halign = Gtk.Align.CENTER,
            css_classes = { "dimmed", "caption" }
        };

        var menu_button = new Gtk.MenuButton () {
            hexpand = true,
            halign = END,
            icon_name = "view-more-symbolic",
            popover = build_context_menu (),
            css_classes = { "flat" }
        };

        var header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            margin_start = 6
        };

        header_box.append (widget_color);
        header_box.append (name_label);
        header_box.append (count_label);
        header_box.append (menu_button);

        description_label = new Gtk.Label (section.description.strip ()) {
            wrap = true,
            selectable = true,
            halign = START,
            css_classes = { "dimmed" },
            margin_start = 6,
            margin_top = 6,
            margin_bottom = 6
        };

        description_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            child = description_label
        };

        listbox = new Gtk.ListBox () {
            selection_mode = Gtk.SelectionMode.SINGLE,
            css_classes = { "listbox-background", "drop-target-list" }
        };

        var add_button_box = new Gtk.Box (HORIZONTAL, 6) {
            valign = CENTER
        };
        add_button_box.append (new Gtk.Image.from_icon_name ("plus-large-symbolic") {
            css_classes = { "color-primary" }
        });
        add_button_box.append (new Gtk.Label (_("Add tasks")));

        var add_button = new Gtk.Button () {
            child = add_button_box,
            margin_top = 6,
            margin_bottom = 6,
            halign = START
        };
        add_button.add_css_class ("flat");
        add_button.add_css_class ("add-button");

        checked_listbox = new Gtk.ListBox () {
            valign = Gtk.Align.START,
            selection_mode = Gtk.SelectionMode.NONE,
            hexpand = true,
            css_classes = { "listbox-background", "listbox-separator-3" }
        };

        load_more_button = new Gtk.Button.with_label (_("Load more")) {
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
            child = checked_listbox_container
        };

        listbox_target = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            vexpand = true,
            margin_end = 6,
            margin_bottom = 12
        };

        listbox_target.append (listbox);
        listbox_target.append (add_button);
        listbox_target.append (checked_revealer);

        var items_scrolled = new Widgets.ScrolledWindow (listbox_target);

        content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            vexpand = true,
            css_classes = { "transition", "drop-target-list" }
        };

        content_box.append (header_box);
        content_box.append (description_revealer);
        content_box.append (items_scrolled);

        child = content_box;
        update_request ();
        add_items ();
        show_completed_changed ();
        build_drag_and_drop ();
        update_count_label (section_count);

        listbox.set_filter_func ((row) => {
            var item = ((Layouts.ItemBoard) row).item;
            return Utils.TaskUtils.items_filter_func (item, section.project.filters);
        });

        signals_map[listbox.row_selected.connect ((row) => {
            var item = ((Layouts.ItemBoard) row).item;
        })] = listbox;

        signals_map[section.updated.connect (() => {
            update_request ();
        })] = section;

        if (is_inbox_section) {
            signals_map[section.project.item_added.connect ((item) => {
                add_item (item);
            })] = section.project;
        } else {
            signals_map[section.item_added.connect ((item) => {
                add_item (item);
            })] = section;
        }

        signals_map[Services.EventBus.get_default ().checked_toggled.connect ((item, old_checked) => {
            if (item.project_id == section.project_id && item.section_id == section.id &&
                !item.has_parent) {
                if (!old_checked) {
                    if (items_map.has_key (item.id)) {
                        items_map[item.id].hide_destroy ();
                        items_map.unset (item.id);
                    }

                    if (!checked_items_map.has_key (item.id)) {
                        checked_items_map[item.id] = new Layouts.ItemBoard (item);
                        checked_listbox.insert (checked_items_map[item.id], 0);
                    }
                } else {
                    if (checked_items_map.has_key (item.id)) {
                        checked_items_map[item.id].hide_destroy ();
                        checked_items_map.unset (item.id);
                    }

                    if (!items_map.has_key (item.id)) {
                        items_map[item.id] = new Layouts.ItemBoard (item);
                        listbox.append (items_map[item.id]);
                    }
                }
            }
        })] = Services.EventBus.get_default ();

        signals_map[Services.Store.instance ().item_updated.connect ((item, update_id) => {
            if (items_map.has_key (item.id)) {
                items_map[item.id].update_request ();
                if (section.project.sorted_by != SortedByType.MANUAL) {
                    update_sort ("item_updated");
                }
            }

            if (checked_items_map.has_key (item.id_string)) {
                checked_items_map[item.id_string].update_request ();
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
        })] = Services.Store.instance ();

        signals_map[Services.EventBus.get_default ().item_moved.connect ((item, old_project_id, old_section_id, old_parent_id) => {
            if (old_project_id == section.project_id && old_section_id == section.id) {
                if (items_map.has_key (item.id)) {
                    items_map[item.id].hide_destroy ();
                    items_map.unset (item.id);
                }

                if (checked_items_map.has_key (item.id_string)) {
                    checked_items_map[item.id_string].hide_destroy ();
                    checked_items_map.unset (item.id_string);
                }
            }

            if (item.project_id == section.project_id && item.section_id == section.id && !item.has_parent) {
                add_item (item);
            }
        })] = Services.EventBus.get_default ();

        signals_map[section.project.sorted_by_changed.connect (() => {
            update_sort ();
        })] = section.project;

        signals_map[section.project.sort_order_changed.connect (() => {
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

        signals_map[Services.EventBus.get_default ().update_inserted_item_map.connect ((_row, old_section_id) => {
            if (_row is Layouts.ItemBoard) {
                var row = (Layouts.ItemBoard) _row;

                if (row.item.project_id == section.project_id && row.item.section_id == section.id) {
                    if (!items_map.has_key (row.item.id)) {
                        items_map[row.item.id] = row;
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

        var edit_gesture = new Gtk.GestureClick ();
        name_label.add_controller (edit_gesture);
        signals_map[edit_gesture.released.connect ((n_press, x, y) => {
            if (n_press == 2) {
                var dialog = new Dialogs.Section (section);
                dialog.present (Planify._instance.main_window);
            }
        })] = edit_gesture;

        signals_map[section.project.show_completed_changed.connect (show_completed_changed)] = section.project;

        signals_map[load_more_button.clicked.connect (() => {
            load_next_completed_page ();
        })] = load_more_button;

        signals_map[add_button.clicked.connect (() => {
            prepare_new_item ("", NewTaskPosition.END);
        })] = add_button;

        signals_map[section.project.source.sync_finished.connect (() => {
            update_sort ();
        })] = section.project.source;

        signals_map[Services.EventBus.get_default ().drag_n_drop_active.connect ((project_id, active) => {
            if (section.project_id == project_id) {
                if (active) {
                    listbox.set_sort_func (null);
                }
            }
        })] = Services.EventBus.get_default ();
    }

    private void update_request () {
        name_label.label = section.name;
        description_label.label = section.description.strip ();
        description_revealer.reveal_child = description_label.label.length > 0;
        Util.get_default ().set_widget_color (Util.get_default ().get_color (section.color), widget_color);
    }

    private void update_count_label (int count) {
        count_label.label = count <= 0 ? "" : count.to_string ();
    }

    public void add_items () {
        items_map.clear ();

        var items = is_inbox_section ? section.project.items : section.items;
        items.sort ((item1, item2) => {
            return Util.get_default ().set_item_sort_func (
                item1,
                item2,
                section.project.sorted_by,
                section.project.sort_order
            );
        });

        foreach (Objects.Item item in items) {
            add_item (item);
        }

        update_sort ();
    }

    private void update_sort (string key = "") {
        listbox.set_sort_func (set_sort_func);
        listbox.set_sort_func (null);

        listbox.invalidate_filter ();
    }

    private int set_sort_func (Gtk.ListBoxRow lbrow, Gtk.ListBoxRow lbbefore) {
        Objects.Item item1 = ((Layouts.ItemBoard) lbrow).item;
        Objects.Item item2 = ((Layouts.ItemBoard) lbbefore).item;

        return Util.get_default ().set_item_sort_func (
            item1,
            item2,
            section.project.sorted_by,
            section.project.sort_order
        );
    }

    public void add_item (Objects.Item item, int position = -1) {
        if (item.checked) {
            return;
        }

        if (item.pinned) {
            return;
        }

        if (items_map.has_key (item.id)) {
            return;
        }

        items_map[item.id] = new Layouts.ItemBoard (item);
        listbox.append (items_map[item.id]);
    }

    private void show_completed_changed () {
        if (section.project.show_completed) {
            add_completed_items ();
        } else {
            foreach (Layouts.ItemBoard row in checked_items_map.values) {
                row.hide_destroy ();
            }

            checked_items_map.clear ();
        }

        checked_revealer.reveal_child = section.project.show_completed;
    }

    public void add_completed_items () {
        foreach (Layouts.ItemBoard row in checked_items_map.values) {
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
        if (section.project.show_completed && item.checked) {
            if (!checked_items_map.has_key (item.id_string)) {
                checked_items_map[item.id_string] = new Layouts.ItemBoard (item);
                checked_listbox.append (checked_items_map[item.id_string]);
            }
        }
    }

    private Gtk.Popover build_context_menu () {
        var add_item = new Widgets.ContextMenu.MenuItem (_ ("Add Task"), "plus-large-symbolic");
        var edit_item = new Widgets.ContextMenu.MenuItem (_ ("Edit Section"), "edit-symbolic");
        var move_item = new Widgets.ContextMenu.MenuItem (_ ("Move Section"), "arrow3-right-symbolic");
        var manage_item = new Widgets.ContextMenu.MenuItem (_ ("Manage Section Order"), "view-list-ordered-symbolic");
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
            menu_box.append (move_item);
            menu_box.append (manage_item);
            menu_box.append (duplicate_item);
            menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
            menu_box.append (show_completed_item);
            menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
            menu_box.append (archive_item);
            menu_box.append (delete_item);
        } else {
            menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
            menu_box.append (show_completed_item);
            menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
            menu_box.append (manage_item);
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

        archive_item.clicked.connect (() => {
            section.archive_section ((Gtk.Window) Planify.instance.main_window);
        });

        delete_item.clicked.connect (() => {
            var dialog = new Adw.AlertDialog (
                _ ("Delete Section %s".printf (section.name)),
                _ ("This can not be undone")
            );

            dialog.add_response ("cancel", _ ("Cancel"));
            dialog.add_response ("delete", _ ("Delete"));
            dialog.set_response_appearance ("delete", Adw.ResponseAppearance.DESTRUCTIVE);
            dialog.present (Planify._instance.main_window);

            dialog.response.connect ((response) => {
                if (response == "delete") {
                    is_loading = true;

                    if (section.project.source_type == SourceType.TODOIST) {
                        Services.Todoist.get_default ().delete.begin (section, (obj, res) => {
                            Services.Todoist.get_default ().delete.end (res);
                            Services.Store.instance ().delete_section (section);
                        });
                    } else {
                        Services.Store.instance ().delete_section (section);
                    }
                }
            });
        });

        show_completed_item.clicked.connect (() => {
            var dialog = new Dialogs.CompletedTasks (section.project);
            dialog.add_update_filter (section);
            dialog.present (Planify._instance.main_window);
        });

        duplicate_item.clicked.connect (() => {
            Util.get_default ().duplicate_section.begin (section, section.project_id);
        });

        return menu_popover;
    }

    public void prepare_new_item (string content = "", NewTaskPosition new_task_position = Services.Settings.get_default ().get_new_task_position ()) {
        var dialog = new Dialogs.QuickAdd ();
        dialog.for_base_object (section);
        dialog.update_content (content);
        dialog.set_new_task_position (new_task_position);
        dialog.present (Planify._instance.main_window);
    }

    private void move_section (string project_id) {
        string old_section_id = section.project_id;
        section.project_id = project_id;

        if (section.project.source_type == SourceType.TODOIST) {
            is_loading = true;

            Services.Todoist.get_default ().move_project_section.begin (section, project_id, (obj, res) => {
                if (Services.Todoist.get_default ().move_project_section.end (res).status) {
                    Services.Store.instance ().move_section (section, old_section_id);
                    is_loading = false;
                }
            });
        } else if (section.project.source_type == SourceType.LOCAL) {
            Services.Store.instance ().move_section (section, project_id);
            is_loading = false;
        }
    }

    private void build_drag_and_drop () {
        // Drop
        build_drop_target ();
    }

    private void build_drop_target () {
        var drop_target = new Gtk.DropTarget (typeof (Layouts.ItemBoard), Gdk.DragAction.MOVE);
        content_box.add_controller (drop_target);
        signals_map[drop_target.drop.connect ((value, x, y) => {
            var picked_widget = (Layouts.ItemBoard) value;
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
                        Services.Store.instance ().move_item (picked_widget.item); 
                    }
                });
            } else if (picked_widget.item.project.source_type == SourceType.LOCAL) {
                Services.Store.instance ().move_item (picked_widget.item);
            }

            var source_list = (Gtk.ListBox) picked_widget.parent;
            source_list.remove (picked_widget);

            listbox.append (picked_widget);
            Utils.TaskUtils.update_single_item_order (listbox, picked_widget, picked_widget.get_index () + 1);

            Services.EventBus.get_default ().update_inserted_item_map (picked_widget, old_section_id, old_parent_id);
            
            return true;
        })] = drop_target;
    }

    public void hide_destroy () {
        visible = false;
        clean_up ();
        Timeout.add (225, () => {
            ((Gtk.FlowBox) parent).remove (this);
            return GLib.Source.REMOVE;
        });
    }

    public void clean_up () {
        listbox.set_sort_func (null);
        listbox.set_filter_func (null);

        foreach (var row in Util.get_default ().get_children (listbox)) {
            ((Layouts.ItemBoard) row).clean_up ();
        }

        foreach (var row in Util.get_default ().get_children (checked_listbox)) {
            ((Layouts.ItemBoard) row).clean_up ();
        }

        // Clean Signals
        foreach (var entry in signals_map.entries) {
            entry.value.disconnect (entry.key);
        }

        signals_map.clear ();
    }
}
