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

public class Views.Filter : Adw.Bin {
    public Objects.BaseObject filter { get; construct; }

    private Layouts.HeaderBar headerbar;
    private Gtk.Image title_icon;
    private Gtk.Label title_label;
    private Gtk.ListBox listbox;
    private Gtk.Stack listbox_stack;
    private Widgets.MagicButton magic_button;
    private Gtk.Revealer view_setting_revealer;
    private Gtk.Button load_more_button;
    private Gtk.Revealer load_more_button_revealer;

    private Gee.HashMap<string, Layouts.ItemRow> items = new Gee.HashMap<string, Layouts.ItemRow> ();
    private Gee.HashMap<ulong, weak GLib.Object> signal_map = new Gee.HashMap<ulong, weak GLib.Object> ();

    private Gee.ArrayList<Objects.Item> items_list;
    private int page_index = 0;
    private const int PAGE_SIZE = Constants.COMPLETED_PAGE_SIZE;

    private bool has_items {
        get {
            return items.size > 0;
        }
    }

    public Filter (Objects.BaseObject filter) {
        Object (
            filter: filter
        );
    }

    ~Filter () {
        debug ("Destroying - Views.Filter\n");
    }

    construct {
        title_icon = new Gtk.Image () {
            pixel_size = 16,
            valign = CENTER,
            halign = CENTER,
        };
        title_icon.add_css_class ("view-icon");
        
        title_label = new Gtk.Label (null) {
            css_classes = { "font-bold", "title-2" },
            ellipsize = END,
            halign = START
        };

        var title_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            margin_start = 24
        };

        title_box.append (title_icon);
        title_box.append (title_label);

        var view_setting_button = new Gtk.MenuButton () {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER,
            margin_end = 12,
            popover = build_view_setting_popover (),
            icon_name = "view-sort-descending-rtl-symbolic",
            css_classes = { "flat" },
            tooltip_text = _("View Option Menu")
        };

        view_setting_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.CROSSFADE,
            child = view_setting_button
        };

        headerbar = new Layouts.HeaderBar ();
        headerbar.pack_end (view_setting_revealer);

        listbox = new Gtk.ListBox () {
            valign = Gtk.Align.START,
            selection_mode = Gtk.SelectionMode.NONE,
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

        var listbox_box = new Gtk.Box (VERTICAL, 12) {
            margin_end = 24,
            margin_top = 12
        };
        listbox_box.append (listbox);
        listbox_box.append (load_more_button_revealer);

        var listbox_placeholder = new Adw.StatusPage ();
        listbox_placeholder.icon_name = "check-round-outline-symbolic";
        listbox_placeholder.title = _("Add Some Tasks");
        listbox_placeholder.description = _("Press 'a' to create a new task");
        
        if (filter is Objects.Filters.Completed) {
            listbox_placeholder.title = _("All tasks completed!");
            listbox_placeholder.description = _("Great job, nothing left to do 🎉");
        }

        listbox_stack = new Gtk.Stack () {
            hexpand = true,
            vexpand = true,
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };

        listbox_stack.add_named (listbox_box, "listbox");
        listbox_stack.add_named (listbox_placeholder, "placeholder");

        var content = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            hexpand = true,
            vexpand = true
        };

        content.append (title_box);
        content.append (listbox_stack);

        var content_clamp = new Adw.Clamp () {
            maximum_size = 864,
            tightening_threshold = 600,
            margin_bottom = 64,
            child = content
        };

        var scrolled_window = new Gtk.ScrolledWindow () {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            hexpand = true,
            vexpand = true,
            child = content_clamp
        };

        magic_button = new Widgets.MagicButton ();

        var content_overlay = new Gtk.Overlay () {
            hexpand = true,
            vexpand = true,
            child = scrolled_window
        };
        content_overlay.add_overlay (magic_button);

        var toolbar_view = new Adw.ToolbarView () {
            content = content_overlay
        };
        toolbar_view.add_top_bar (headerbar);

        child = toolbar_view;
        update_request ();
        add_items ();

        Timeout.add (listbox_stack.transition_duration, () => {
            validate_placeholder ();
            return GLib.Source.REMOVE;
        });

        signal_map[Services.Store.instance ().item_added.connect (valid_add_item)] = Services.Store.instance ();
        signal_map[Services.Store.instance ().item_deleted.connect (valid_delete_item)] = Services.Store.instance ();
        signal_map[Services.Store.instance ().item_updated.connect (valid_update_item)] = Services.Store.instance ();
        signal_map[Services.EventBus.get_default ().checked_toggled.connect (valid_checked_item)] = Services.EventBus.get_default ();
        signal_map[Services.Store.instance ().item_archived.connect (valid_delete_item)] = Services.Store.instance ();
        signal_map[Services.Store.instance ().item_unarchived.connect ((item) => {
            valid_add_item (item);
        })] = Services.Store.instance ();

        signal_map[Services.EventBus.get_default ().item_moved.connect ((item) => {
            if (items.has_key (item.id)) {
                items[item.id].update_request ();
            }

            listbox.invalidate_sort ();
        })] = Services.EventBus.get_default ();

        signal_map[magic_button.clicked.connect (() => {
            prepare_new_item ();
        })] = magic_button;

        signal_map[Services.EventBus.get_default ().theme_changed.connect (() => {
            update_request ();
        })] = Services.EventBus.get_default ();

        signal_map[scrolled_window.vadjustment.value_changed.connect (() => {
            headerbar.revealer_title_box (scrolled_window.vadjustment.value >= Constants.HEADERBAR_TITLE_SCROLL_THRESHOLD);            
        })] = scrolled_window.vadjustment;

        signal_map[load_more_button.clicked.connect (() => {
            load_next_page ();
        })] = load_more_button;

        signal_map[Services.EventBus.get_default ().dim_content.connect ((active, focused_item_id) => {
            title_box.sensitive = !active;
        })] = Services.EventBus.get_default ();
    }

    public void prepare_new_item (string content = "") {
        var inbox_project = Services.Store.instance ().get_project (
            Services.Settings.get_default ().settings.get_string ("local-inbox-project-id")
        );

        var dialog = new Dialogs.QuickAdd ();
        dialog.set_project (inbox_project);
        dialog.update_content (content);

        if (filter is Objects.Filters.Priority) {
            Objects.Filters.Priority priority = ((Objects.Filters.Priority) filter);
            dialog.set_priority (priority.priority);
        } else if (filter is Objects.Filters.Tomorrow) {
            dialog.set_due (Utils.Datetime.get_date_only (
                                new GLib.DateTime.now_local ().add_days (1)
            ));
        } else if (filter is Objects.Filters.Pinboard) {
            dialog.set_pinned (true);
        }

        dialog.present (Planify._instance.main_window);
    }

    private void update_request () {
        if (filter is Objects.Filters.Priority) {
            Objects.Filters.Priority priority = (Objects.Filters.Priority) filter;

            title_icon.icon_name = priority.icon;
            Util.get_default ().set_widget_color (priority.color, title_icon);
            
            title_label.label = priority.title;
            listbox.set_header_func (header_project_function);
            magic_button.visible = true;
        } else {
            title_icon.icon_name = filter.icon_name;
            Util.get_default ().set_widget_color (filter.theme_color (), title_icon);
            title_label.label = filter.name;
            magic_button.visible = true;

            if (filter is Objects.Filters.Completed) {
                magic_button.visible = false;
                listbox.set_header_func (header_completed_function);
                listbox.set_sort_func ((row1, row2) => {
                    return sort_completed_function (((Layouts.ItemRow) row1).item, ((Layouts.ItemRow) row2).item);
                });
            } else {
                listbox.set_header_func (header_project_function);
            }
        } 

        headerbar.title = title_label.label;
        view_setting_revealer.reveal_child = filter is Objects.Filters.Completed;
    }

    private void add_items () {
        foreach (Layouts.ItemRow row in items.values) {
            row.clean_up ();
            listbox.remove (row);
        }

        items.clear ();

        if (items_list == null) {
            items_list = new Gee.ArrayList<Objects.Item> ();
        } else {
            items_list.clear ();
        }

        if (filter is Objects.Filters.Priority) {
            Objects.Filters.Priority priority = ((Objects.Filters.Priority) filter);
            foreach (Objects.Item item in Services.Store.instance ().get_items_by_priority (priority.priority, false)) {
                items_list.add (item);
            }
        } else if (filter is Objects.Filters.Completed) {
            foreach (Objects.Item item in Services.Store.instance ().get_items_completed ()) {
                items_list.add (item);
            }
        } else if (filter is Objects.Filters.Tomorrow) {
            foreach (Objects.Item item in Services.Store.instance ().get_items_by_date (new GLib.DateTime.now_local ().add_days (1), false)) {
                items_list.add (item);
            }
        } else if (filter is Objects.Filters.Pinboard) {
            foreach (Objects.Item item in Services.Store.instance ().get_items_pinned (false)) {
                items_list.add (item);
            }
        } else if (filter is Objects.Filters.Anytime) {
            foreach (Objects.Item item in Services.Store.instance ().get_items_no_date (false)) {
                items_list.add (item);
            }
        } else if (filter is Objects.Filters.Repeating) {
            foreach (Objects.Item item in Services.Store.instance ().get_items_repeating (false)) {
                items_list.add (item);
            }
        } else if (filter is Objects.Filters.Unlabeled) {
            foreach (Objects.Item item in Services.Store.instance ().get_items_unlabeled (false)) {
                items_list.add (item);
            }
        } else if (filter is Objects.Filters.AllItems) {
            foreach (Objects.Item item in Services.Store.instance ().get_items_no_parent (false)) {
                items_list.add (item);
            }
        }

        if (filter is Objects.Filters.Completed) {
            items_list.sort ((a, b) => {
                return sort_completed_function (a, b);
            });
        } else {
            items_list.sort ((a, b) => {
                return a.project_id.strip ().collate (b.project_id.strip ());
            });
        }

        page_index = 0;
        load_next_page ();
    }

    private void load_next_page () {
        int start = page_index * PAGE_SIZE;
        int end = (start + PAGE_SIZE < items_list.size) ? (start + PAGE_SIZE) : items_list.size;

        for (int i = start; i < end; i++) {
            Objects.Item item = items_list[i];
            add_item (item);
        }

        page_index++;
        update_load_more_button_label ();
    }

    private void update_load_more_button_label () {
        int loaded = page_index * PAGE_SIZE;
        int remaining = items_list.size - loaded;

        if (remaining > 0) {
            int to_show = remaining < PAGE_SIZE ? remaining : PAGE_SIZE;
            load_more_button.label = "+%d %s".printf (to_show, _ ("completed tasks"));
            load_more_button_revealer.reveal_child = true;
        } else {
            load_more_button.set_label ("No more tasks");
            load_more_button_revealer.reveal_child = false;
        }
    }

    private void add_item (Objects.Item item) {
        items[item.id] = new Layouts.ItemRow (item);
        items[item.id].disable_drag_and_drop ();
        listbox.append (items[item.id]);
    }

    private void valid_add_item (Objects.Item item, bool insert = true) {
        if (filter is Objects.Filters.Priority) {
            Objects.Filters.Priority priority = ((Objects.Filters.Priority) filter);

            if (!items.has_key (item.id) && item.priority == priority.priority && insert) {
                add_item (item);
            }
        } else if (filter is Objects.Filters.Completed) {
            if (!items.has_key (item.id) && item.checked && insert) {
                add_item (item);
            }
        } else if (filter is Objects.Filters.Tomorrow) {
            if (!items.has_key (item.id) && item.has_due &&
                Utils.Datetime.is_tomorrow (item.due.datetime) && insert) {
                add_item (item);
            }
        } else if (filter is Objects.Filters.Pinboard) {
            if (!items.has_key (item.id) && item.pinned && insert) {
                add_item (item);
            }
        } else if (filter is Objects.Filters.Anytime) {
            if (!items.has_key (item.id) && !item.has_due && insert) {
                add_item (item);
            }
        } else if (filter is Objects.Filters.Repeating) {
            if (!items.has_key (item.id) && item.has_due && item.due.is_recurring && insert) {
                add_item (item);
            }
        } else if (filter is Objects.Filters.Unlabeled) {
            if (!items.has_key (item.id) && item.labels.size <= 0 && insert) {
                add_item (item);
            }
        } else if (filter is Objects.Filters.AllItems) {
            if (!items.has_key (item.id) && insert) {
                add_item (item);
            }
        }

        validate_placeholder ();
    }

    private void valid_delete_item (Objects.Item item) {
        if (items.has_key (item.id)) {
            items[item.id].hide_destroy ();
            items.unset (item.id);
        }

        validate_placeholder ();
    }

    private void valid_update_item (Objects.Item item, string update_id = "") {
        if (items.has_key (item.id) && items[item.id].update_id != update_id) {
            items[item.id].update_request ();
        }

        if (filter is Objects.Filters.Priority) {
            Objects.Filters.Priority priority = ((Objects.Filters.Priority) filter);

            if (items.has_key (item.id) && item.priority != priority.priority) {
                items[item.id].hide_destroy ();
                items.unset (item.id);
            }

            if (items.has_key (item.id) && !item.checked) {
                items[item.id].hide_destroy ();
                items.unset (item.id);
            }

            valid_add_item (item);
        } else if (filter is Objects.Filters.Completed) {
            if (items.has_key (item.id) && item.checked) {
                items[item.id].hide_destroy ();
                items.unset (item.id);
            }

            valid_add_item (item);
        } else if (filter is Objects.Filters.Tomorrow) {
            if (items.has_key (item.id) && (!item.has_due || !Utils.Datetime.is_tomorrow (item.due.datetime))) {
                items[item.id].hide_destroy ();
                items.unset (item.id);
            }

            valid_add_item (item);
        } else if (filter is Objects.Filters.Pinboard) {
            if (items.has_key (item.id) && !item.pinned) {
                items[item.id].hide_destroy ();
                items.unset (item.id);
            }

            valid_add_item (item);
        } else if (filter is Objects.Filters.Anytime) {
            if (items.has_key (item.id) && item.has_due) {
                items[item.id].hide_destroy ();
                items.unset (item.id);
            }

            valid_add_item (item);
        } else if (filter is Objects.Filters.Repeating) {
            if (items.has_key (item.id) && (!item.has_due || !item.due.is_recurring)) {
                items[item.id].hide_destroy ();
                items.unset (item.id);
            }

            valid_add_item (item);
        } else if (filter is Objects.Filters.Unlabeled) {
            if (items.has_key (item.id) && item.labels.size > 0) {
                items[item.id].hide_destroy ();
                items.unset (item.id);
            }

            valid_add_item (item);
        }

        validate_placeholder ();
    }

    private void valid_checked_item (Objects.Item item, bool old_checked) {
        if (filter is Objects.Filters.Priority || filter is Objects.Filters.Tomorrow ||
            filter is Objects.Filters.Pinboard || filter is Objects.Filters.Anytime ||
            filter is Objects.Filters.Repeating || filter is Objects.Filters.Unlabeled ||
            filter is Objects.Filters.AllItems
        ) {
            if (!old_checked) {
                if (items.has_key (item.id) && item.completed) {
                    items[item.id].hide_destroy ();
                    items.unset (item.id);
                }
            } else {
                valid_update_item (item);
            }
        } else if (filter is Objects.Filters.Completed) {
            if (!old_checked) {
                valid_update_item (item);
            } else {
                if (items.has_key (item.id) && !item.completed) {
                    items[item.id].hide_destroy ();
                    items.unset (item.id);
                }
            }
        }

        validate_placeholder ();
    }

    private void header_completed_function (Gtk.ListBoxRow lbrow, Gtk.ListBoxRow ? lbbefore) {
        var row = (Layouts.ItemRow) lbrow;
        if (row.item.completed_at == "") {
            return;
        }

        if (lbbefore != null) {
            var before = (Layouts.ItemRow) lbbefore;
            var comp_before = Utils.Datetime.get_date_only (Utils.Datetime.get_date_from_string (before.item.completed_at));
            var comp_after = Utils.Datetime.get_date_only (Utils.Datetime.get_date_from_string (row.item.completed_at));
            if (comp_before.compare (comp_after) == 0) {
                return;
            }
        }

        row.set_header (
            get_header_box (
                Utils.Datetime.get_relative_date_from_date (
                    Utils.Datetime.get_date_only (Utils.Datetime.get_date_from_string (row.item.completed_at))
                )
            )
        );
    }

    private void header_project_function (Gtk.ListBoxRow lbrow, Gtk.ListBoxRow ? lbbefore) {
        if (!(lbrow is Layouts.ItemRow)) {
            return;
        }

        var row = (Layouts.ItemRow) lbrow;
        if (lbbefore != null && lbbefore is Layouts.ItemRow) {
            var before = (Layouts.ItemRow) lbbefore;
            if (row.project_id == before.project_id) {
                row.set_header (null);
                return;
            }
        }

        row.set_header (get_header_box (row.item.project.name));
    }

    private void validate_placeholder () {
        listbox_stack.visible_child_name = has_items ? "listbox" : "placeholder";
        invalidate_listbox ();
    }

    private Gtk.Widget get_header_box (string title) {
        var header_label = new Gtk.Label (title) {
            css_classes = { "font-bold" },
            halign = START
        };

        var header_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
            margin_top = 12,
            margin_start = 24,
            margin_bottom = 12
        };

        header_box.append (header_label);

        if (Services.Settings.get_default ().settings.get_boolean ("attention-at-one")) {
            ulong handler_id = Services.EventBus.get_default ().dim_content.connect ((active, focused_item_id) => {
                header_box.sensitive = !active;
            });
            
            header_box.destroy.connect (() => {
                Services.EventBus.get_default ().disconnect (handler_id);
            });
        }

        return header_box;
    }

    private Gtk.Popover build_view_setting_popover () {
        var delete_all_completed = new Widgets.ContextMenu.MenuItem (_("Delete All Completed Tasks"), "user-trash-symbolic");
        delete_all_completed.add_css_class ("menu-item-danger");

        var menu_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        menu_box.margin_top = menu_box.margin_bottom = 3;
        menu_box.append (delete_all_completed);

        var popover = new Gtk.Popover () {
            has_arrow = false,
            position = Gtk.PositionType.BOTTOM,
            child = menu_box,
            width_request = 250
        };

        delete_all_completed.activate_item.connect (() => {
            var items = Services.Store.instance ().get_items_checked ();

            var dialog = new Adw.AlertDialog (
                _("Delete All Completed Tasks"),
                _("This will delete %d completed tasks and their subtasks".printf (items.size))
            );

            dialog.body_use_markup = true;
            dialog.add_response ("cancel", _("Cancel"));
            dialog.add_response ("delete", _("Delete"));
            dialog.set_response_appearance ("delete", Adw.ResponseAppearance.DESTRUCTIVE);
            dialog.present (Planify._instance.main_window);

            dialog.response.connect ((response) => {
                if (response == "delete") {
                    foreach (Objects.Item item in items) {
                        item.delete_item ();
                    }
                }
            });
        });

        return popover;
    }

    private void invalidate_listbox () {
        listbox.invalidate_sort ();
        listbox.invalidate_headers ();
    }

    private int sort_completed_function (Objects.Item a, Objects.Item b) {
        var completed_a = Utils.Datetime.get_date_only (
            Utils.Datetime.get_date_from_string (a.completed_at)
        );

        var completed_b = Utils.Datetime.get_date_only (
            Utils.Datetime.get_date_from_string (b.completed_at)
        );
        
        return completed_b.compare (completed_a);
    }

    public void clean_up () {
        listbox.set_sort_func (null);
        listbox.set_header_func (null);

        foreach (var row in Util.get_default ().get_children (listbox)) {
            ((Layouts.ItemRow) row).clean_up ();
        }
        
        foreach (var entry in signal_map.entries) {
            entry.value.disconnect (entry.key);
        }

        signal_map.clear ();
    }
}