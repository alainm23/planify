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

    /**
     * Sort key used to group tasks by their parent project. This is the historical
     * (and default) ordering of the All Tasks view, and has no SortedByType member
     * because it is only meaningful in a view that spans several projects.
     */
    private const string SORT_BY_PROJECT = "project";

    private const string SORT_ORDER_KEY = "all-items-sort-order";
    private const string SORT_ASCENDING_KEY = "all-items-sort-ascending";
    private const string FILTERS_KEY = "all-items-filters";

    private Widgets.ContextMenu.MenuPicker due_date_item;
    private Widgets.ContextMenu.MenuCheckPicker priority_filter;
    private Gtk.Revealer indicator_revealer;
    private uint rebuild_idle_id = 0;

    private Layouts.HeaderBar headerbar;
    private Gtk.Image title_icon;
    private Gtk.Label title_label;
    private Gtk.ListBox listbox;
    private Gtk.Stack listbox_stack;
    private Widgets.MagicButton magic_button;
    private Gtk.Revealer view_setting_revealer;
    private Gtk.Button load_more_button;
    private Gtk.Revealer load_more_button_revealer;
    private Gtk.MenuButton project_filter_button;
    private Gtk.Revealer project_filter_revealer;
    private Widgets.FilterFlowBox ? filters_flowbox;
    private Adw.StatusPage listbox_placeholder;
    private Gee.ArrayList<string> selected_project_ids = new Gee.ArrayList<string> ();

    private Gee.HashMap<string, Layouts.ItemRow> items = new Gee.HashMap<string, Layouts.ItemRow> ();
    private Gee.HashMap<ulong, weak GLib.Object> signal_map = new Gee.HashMap<ulong, weak GLib.Object> ();

    private Gee.ArrayList<Objects.Item> items_list;
    private int page_index = 0;
    private const int PAGE_SIZE = Constants.COMPLETED_PAGE_SIZE;

    /**
     * Whether this filter view offers the sort menu. Only All Tasks does for now;
     * when the Label view gains the same menu the settings keys above should become
     * a per-view prefix rather than constants.
     */
    private bool sorting_supported {
        get {
            return filter is Objects.Filters.AllItems;
        }
    }

    private bool has_visible_items {
        get {
            if (items_list == null || items_list.size == 0) return false;
            if (selected_project_ids.size == 0 && filter.filters.size == 0) return true;
            foreach (var item in items_list) {
                if (item_matches_filters (item)) {
                    return true;
                }
            }
            return false;
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
            margin_start = 30
        };

        title_box.append (title_icon);
        title_box.append (title_label);

        var project_picker_core = new Widgets.ProjectPickerCore.with_multiselect () {
            margin_top = 12
        };

        var project_picker_popover = new Gtk.Popover () {
            has_arrow = false,
            position = BOTTOM,
            width_request = 260,
            height_request = 300,
            child = project_picker_core,
            css_classes = { "popover-contents" }
        };

        project_filter_button = new Gtk.MenuButton () {
            label = _("All Projects"),
            popover = project_picker_popover,
            css_classes = { "flat", "suggestion-chip" },
            margin_start = 30,
            margin_top = 12,
            halign = START
        };

        project_picker_core.multiselect_changed.connect ((ids) => {
            selected_project_ids = ids;
            update_project_filter_label ();
            rebuild_list ();
        });

        project_filter_revealer = new Gtk.Revealer () {
            transition_type = SLIDE_DOWN,
            child = project_filter_button
        };

        var view_setting_button = new Gtk.MenuButton () {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER,
            margin_end = 12,
            popover = build_view_setting_popover (),
            icon_name = "view-sort-descending-rtl-symbolic",
            css_classes = { "flat" },
            tooltip_text = _("View Option Menu")
        };

        var indicator_grid = new Gtk.Grid () {
            width_request = 9,
            height_request = 9,
            margin_top = 6,
            margin_end = 6,
            css_classes = { "indicator" }
        };

        indicator_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.CROSSFADE,
            child = indicator_grid,
            halign = END,
            valign = START,
            sensitive = false,
        };

        var view_setting_overlay = new Gtk.Overlay () {
            child = view_setting_button
        };
        view_setting_overlay.add_overlay (indicator_revealer);

        view_setting_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.CROSSFADE,
            child = view_setting_overlay
        };

        headerbar = new Layouts.HeaderBar ();
        headerbar.pack_end (view_setting_revealer);

        listbox = new Gtk.ListBox () {
            valign = Gtk.Align.START,
            selection_mode = Gtk.SelectionMode.NONE,
            hexpand = true,
            css_classes = { "listbox-background" }
        };

        load_more_button = new Gtk.Button.with_label (_("Load more")) {
            margin_start = 20,
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

        listbox_placeholder = new Adw.StatusPage () {
            icon_name = "check-round-outline-symbolic",
            title = _("Add Some Tasks"),
            description = _("Press 'a' to create a new task")
        };

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
        content.append (project_filter_revealer);

        // Removable chips for the active filters, the same affordance the project views offer.
        // The widget renders the current bag on assignment and then keeps itself in sync from
        // BaseObject's filter signals, so it needs no wiring beyond the base_object.
        if (sorting_supported) {
            filters_flowbox = new Widgets.FilterFlowBox () {
                valign = Gtk.Align.START,
                vexpand = false,
                vexpand_set = true,
                base_object = filter
            };

            filters_flowbox.flowbox.margin_start = 30;
            filters_flowbox.flowbox.margin_top = 12;
            filters_flowbox.flowbox.margin_end = 12;
            filters_flowbox.flowbox.margin_bottom = 3;

            content.append (filters_flowbox);
        }

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

        listbox.set_filter_func ((row) => {
            return item_matches_filters (((Layouts.ItemRow) row).item);
        });

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

            if (filters_flowbox != null) {
                filters_flowbox.sensitive = !active;
            }
        })] = Services.EventBus.get_default ();

        if (sorting_supported) {
            signal_map[Services.Settings.get_default ().settings.changed[SORT_ORDER_KEY].connect (() => {
                rebuild_list ();
                check_default_filters ();
            })] = Services.Settings.get_default ().settings;

            signal_map[Services.Settings.get_default ().settings.changed[SORT_ASCENDING_KEY].connect (() => {
                rebuild_list ();
                check_default_filters ();
            })] = Services.Settings.get_default ().settings;

            signal_map[filter.filter_added.connect (() => {
                apply_filters_changed ();
            })] = filter;

            signal_map[filter.filter_removed.connect ((filter_item) => {
                if (filter_item.filter_type == FilterItemType.PRIORITY) {
                    priority_filter.unchecked (filter_item);
                } else if (filter_item.filter_type == FilterItemType.DUE_DATE) {
                    due_date_item.update_selected ("0");
                }

                apply_filters_changed ();
            })] = filter;

            signal_map[filter.filter_updated.connect (() => {
                apply_filters_changed ();
            })] = filter;

            check_default_filters ();
        }
    }

    private void apply_filters_changed () {
        save_filters ();
        rebuild_list ();
        check_default_filters ();
    }

    /**
     * Re-sorts, re-filters and re-pages the list after the sort or filter settings change.
     * The whole list has to be rebuilt rather than merely invalidated, because pagination
     * decides which items are loaded at all from the sorted and filtered backing list —
     * invalidating the loaded rows alone would leave matches beyond the first page unreachable.
     */
    private void rebuild_list () {
        // Deferred to an idle callback rather than run inline. Rebuilding tears down and
        // frees every ItemRow, and this runs from inside a signal emission (a GSettings
        // "changed" handler) that can still touch those rows once we return — which shows
        // up as GTK_IS_LABEL/GTK_IS_WIDGET assertions on freed widgets. The idle source
        // also coalesces a burst of rapid filter clicks into a single rebuild.
        if (rebuild_idle_id != 0) {
            return;
        }

        rebuild_idle_id = Idle.add (() => {
            rebuild_idle_id = 0;
            update_header_func ();
            add_items ();
            validate_placeholder ();
            return GLib.Source.REMOVE;
        });
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
            update_header_func ();
            magic_button.visible = true;
        } else {
            title_icon.icon_name = filter.icon_name;
            Util.get_default ().set_widget_color (filter.theme_color (), title_icon);
            title_label.label = filter.name;
            magic_button.visible = true;

            if (filter is Objects.Filters.Completed) {
                magic_button.visible = false;
                listbox.set_sort_func ((row1, row2) => {
                    return sort_completed_function (((Layouts.ItemRow) row1).item, ((Layouts.ItemRow) row2).item);
                });
            } else if (sorting_supported) {
                listbox.set_sort_func ((row1, row2) => {
                    return sort_items_function (((Layouts.ItemRow) row1).item, ((Layouts.ItemRow) row2).item);
                });
            }

            update_header_func ();
        }

        headerbar.title = title_label.label;
        view_setting_revealer.reveal_child = filter is Objects.Filters.Completed || sorting_supported;
        project_filter_revealer.reveal_child = filter is Objects.Filters.Completed;
    }

    /**
     * Whether an item survives the view's active filters — the project picker of the
     * Completed view and the sort/filter menu of the All Tasks view.
     */
    private bool item_matches_filters (Objects.Item item) {
        if (selected_project_ids.size > 0 && !selected_project_ids.contains (item.project_id)) {
            return false;
        }

        if (sorting_supported && !Utils.TaskUtils.items_filter_func (item, filter.filters)) {
            return false;
        }

        return true;
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

        // The filters have to be applied to the backing list, not merely to the loaded rows:
        // pagination decides which items are loaded at all, so filtering afterwards would
        // hide the first page and never reach the matches behind it. Keeping the backing
        // list filtered also keeps the "Load more" count honest.
        var filtered_list = new Gee.ArrayList<Objects.Item> ();
        foreach (Objects.Item item in items_list) {
            if (item_matches_filters (item)) {
                filtered_list.add (item);
            }
        }

        items_list = filtered_list;

        if (filter is Objects.Filters.Completed) {
            items_list.sort ((a, b) => {
                return sort_completed_function (a, b);
            });
        } else if (sorting_supported) {
            // The list is paginated, so the backing list has to carry the sort too:
            // otherwise the first page would be chosen by the old order and only
            // re-sorted among itself.
            items_list.sort ((a, b) => {
                return sort_items_function (a, b);
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
            load_more_button.label = "+%d %s".printf (to_show, _("tasks"));
            load_more_button_revealer.reveal_child = true;
        } else {
            load_more_button.set_label (_("No more tasks"));
            load_more_button_revealer.reveal_child = false;
        }
    }

    private void add_item (Objects.Item item) {
        items[item.id] = new Layouts.ItemRow (item);
        items[item.id].disable_drag_and_drop ();
        listbox.append (items[item.id]);
    }

    private void valid_add_item (Objects.Item item, bool insert = true) {
        if (!insert || items.has_key (item.id)) {
            validate_placeholder ();
            return;
        }

        bool should_add = false;

        if (filter is Objects.Filters.Priority) {
            Objects.Filters.Priority priority = ((Objects.Filters.Priority) filter);
            should_add = item.priority == priority.priority;
        } else if (filter is Objects.Filters.Completed) {
            should_add = item.checked;
        } else if (filter is Objects.Filters.Tomorrow) {
            should_add = item.has_due && Utils.Datetime.is_tomorrow (item.due.datetime);
        } else if (filter is Objects.Filters.Pinboard) {
            should_add = item.pinned;
        } else if (filter is Objects.Filters.Anytime) {
            should_add = !item.has_due;
        } else if (filter is Objects.Filters.Repeating) {
            should_add = item.has_due && item.due.is_recurring;
        } else if (filter is Objects.Filters.Unlabeled) {
            should_add = item.labels.size <= 0;
        } else if (filter is Objects.Filters.AllItems) {
            // Unchecked only, matching what add_items () loads. A newly added item is never
            // checked, but this path is also reached from valid_update_item (), where the item may
            // be a completed one whose content changed.
            should_add = !item.checked;
        }

        if (should_add && item_matches_filters (item)) {
            items_list.add (item);
            add_item (item);
            update_load_more_button_label ();
        }

        validate_placeholder ();
    }

    private void valid_delete_item (Objects.Item item) {
        if (items.has_key (item.id)) {
            items[item.id].hide_destroy ();
            items.unset (item.id);
        }

        items_list.remove (item);
        update_load_more_button_label ();
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
                Services.EventBus.get_default ().unfocus_item ();
            }

            if (items.has_key (item.id) && !item.checked) {
                items[item.id].hide_destroy ();
                items.unset (item.id);
                Services.EventBus.get_default ().unfocus_item ();
            }

            valid_add_item (item);
        } else if (filter is Objects.Filters.Completed) {
            if (items.has_key (item.id) && item.checked) {
                items[item.id].hide_destroy ();
                items.unset (item.id);
                Services.EventBus.get_default ().unfocus_item ();
            }

            valid_add_item (item);
        } else if (filter is Objects.Filters.Tomorrow) {
            if (items.has_key (item.id) && (!item.has_due || !Utils.Datetime.is_tomorrow (item.due.datetime))) {
                items[item.id].hide_destroy ();
                items.unset (item.id);
                Services.EventBus.get_default ().unfocus_item ();
            }

            valid_add_item (item);
        } else if (filter is Objects.Filters.Pinboard) {
            if (items.has_key (item.id) && !item.pinned) {
                items[item.id].hide_destroy ();
                items.unset (item.id);
                Services.EventBus.get_default ().unfocus_item ();
            }

            valid_add_item (item);
        } else if (filter is Objects.Filters.Anytime) {
            if (items.has_key (item.id) && item.has_due) {
                items[item.id].hide_destroy ();
                items.unset (item.id);
                Services.EventBus.get_default ().unfocus_item ();
            }

            valid_add_item (item);
        } else if (filter is Objects.Filters.Repeating) {
            if (items.has_key (item.id) && (!item.has_due || !item.due.is_recurring)) {
                items[item.id].hide_destroy ();
                items.unset (item.id);
                Services.EventBus.get_default ().unfocus_item ();
            }

            valid_add_item (item);
        } else if (filter is Objects.Filters.Unlabeled) {
            if (items.has_key (item.id) && item.labels.size > 0) {
                items[item.id].hide_destroy ();
                items.unset (item.id);
                Services.EventBus.get_default ().unfocus_item ();
            }

            valid_add_item (item);
        } else if (filter is Objects.Filters.AllItems) {
            // Membership of this view is conditional now that it carries filters, so an edit can
            // move an item into or out of the list: an item added before it matched arrives here
            // still absent, and one that no longer matches has to go. The view is kept alive in
            // MainWindow's stack between visits, so this signal is the only thing that reaches it.
            if (items.has_key (item.id) && !item_matches_filters (item)) {
                items[item.id].hide_destroy ();
                items.unset (item.id);
                items_list.remove (item);
                update_load_more_button_label ();
                Services.EventBus.get_default ().unfocus_item ();
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
                    Services.EventBus.get_default ().unfocus_item ();
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
                    Services.EventBus.get_default ().unfocus_item ();
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
            // Group on the item's own project, not Layouts.ItemRow's cached project_id: that copy
            // is taken in construct and never refreshed, so after a task is moved to another
            // project the row still carries the old id and is read as the start of a new group —
            // a second header for a project that already has one. The header text below already
            // comes from the live item, which is why the duplicate is labelled identically.
            if (row.item.project_id == before.item.project_id) {
                row.set_header (null);
                return;
            }
        }

        Objects.Project ? project = row.item.project;
        row.set_header (get_header_box (project == null ? "" : project.name));
    }

    private void validate_placeholder () {
        if (filter is Objects.Filters.Completed && !has_visible_items && selected_project_ids.size > 0) {
            listbox_placeholder.title = _("No completed tasks");
            listbox_placeholder.description = _("No tasks found for the selected projects");
        } else if (filter is Objects.Filters.Completed) {
            listbox_placeholder.title = _("All tasks completed!");
            listbox_placeholder.description = _("Great job, nothing left to do 🎉");
        } else if (sorting_supported && !has_visible_items && filter.filters.size > 0) {
            listbox_placeholder.title = _("No tasks found");
            listbox_placeholder.description = _("No tasks match the selected filters");
        } else {
            listbox_placeholder.title = _("Add Some Tasks");
            listbox_placeholder.description = _("Press 'a' to create a new task");
        }
        listbox_stack.visible_child_name = has_visible_items ? "listbox" : "placeholder";
        invalidate_listbox ();
    }

    private Gtk.Widget get_header_box (string title) {
        var header_label = new Gtk.Label (title) {
            css_classes = { "font-bold" },
            halign = START
        };

        var header_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
            margin_top = 12,
            margin_start = 34,
            margin_bottom = 6
        };

        header_box.append (header_label);
        header_box.append (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));

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

    private void update_project_filter_label () {
        if (selected_project_ids.size == 0) {
            project_filter_button.label = _("All Projects");
        } else {
            project_filter_button.label = ngettext ("%d Project", "%d Projects", selected_project_ids.size)
                .printf (selected_project_ids.size);
        }
    }

    private Gtk.Popover build_view_setting_popover () {
        if (sorting_supported) {
            return build_sort_setting_popover ();
        }

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
            var items_checked = Services.Store.instance ().get_items_checked ();

            var dialog = new Adw.AlertDialog (
                GLib.ngettext (
                    "Delete Completed Task",
                    "Delete Completed Tasks",
                    items_checked.size
                ),
                GLib.ngettext (
                    "This will delete %d completed task and its subtasks",
                    "This will delete %d completed tasks and their subtasks",
                    items_checked.size
                ).printf (items_checked.size)
            );

            dialog.body_use_markup = true;
            dialog.add_response ("cancel", _("Cancel"));
            dialog.add_response ("delete", _("Delete"));
            dialog.set_response_appearance ("delete", Adw.ResponseAppearance.DESTRUCTIVE);
            dialog.present (Planify._instance.main_window);

            dialog.response.connect ((response) => {
                if (response == "delete") {
                    foreach (Objects.Item item in items_checked) {
                        item.delete_item ();
                    }
                }
            });
        });

        return popover;
    }

    private Gtk.Popover build_sort_setting_popover () {
        var sorted_by_item = new Widgets.ContextMenu.MenuPicker (_("Sorting"), "vertical-arrows-long-symbolic") {
            selected = Services.Settings.get_default ().settings.get_string (SORT_ORDER_KEY)
        };

        sorted_by_item.add_item (_("Project"), SORT_BY_PROJECT);
        sorted_by_item.add_item (_("Alphabetically"), SortedByType.NAME.to_string ());
        sorted_by_item.add_item (_("Due Date"), SortedByType.DUE_DATE.to_string ());
        sorted_by_item.add_item (_("Date Added"), SortedByType.ADDED_DATE.to_string ());
        sorted_by_item.add_item (_("Date Modified"), SortedByType.UPDATED_DATE.to_string ());
        sorted_by_item.add_item (_("Priority"), SortedByType.PRIORITY.to_string ());

        var sort_order_item = new Widgets.ContextMenu.MenuSwitch (_("Ascending Order"), "vertical-arrows-long-symbolic") {
            active = Services.Settings.get_default ().settings.get_boolean (SORT_ASCENDING_KEY)
        };

        due_date_item = new Widgets.ContextMenu.MenuPicker (_("Duedate"), "month-symbolic") {
            selected = "0"
        };
        due_date_item.add_item (_("All (default)"), "0");
        due_date_item.add_item (_("Today"), "1");
        due_date_item.add_item (_("This Week"), "2");
        due_date_item.add_item (_("Next 7 Days"), "3");
        due_date_item.add_item (_("This Month"), "4");
        due_date_item.add_item (_("Next 30 Days"), "5");
        due_date_item.add_item (_("No Date"), "6");

        var priority_items = new Gee.ArrayList<Objects.Filters.FilterItem> ();
        priority_items.add (new Objects.Filters.FilterItem () {
            filter_type = FilterItemType.PRIORITY,
            name = _("P1"),
            value = Constants.PRIORITY_1.to_string ()
        });
        priority_items.add (new Objects.Filters.FilterItem () {
            filter_type = FilterItemType.PRIORITY,
            name = _("P2"),
            value = Constants.PRIORITY_2.to_string ()
        });
        priority_items.add (new Objects.Filters.FilterItem () {
            filter_type = FilterItemType.PRIORITY,
            name = _("P3"),
            value = Constants.PRIORITY_3.to_string ()
        });
        priority_items.add (new Objects.Filters.FilterItem () {
            filter_type = FilterItemType.PRIORITY,
            name = _("P4"),
            value = Constants.PRIORITY_4.to_string ()
        });

        priority_filter = new Widgets.ContextMenu.MenuCheckPicker (_("Priority"), "flag-outline-thick-symbolic");
        priority_filter.set_items (priority_items);

        var labels_filter = new Widgets.ContextMenu.MenuItem (_("Filter by Labels"), "tag-outline-symbolic") {
            arrow = true
        };

        var menu_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        menu_box.margin_top = menu_box.margin_bottom = 3;
        menu_box.append (new Gtk.Label (_("Sort By")) {
            css_classes = { "heading", "h4" },
            margin_start = 6,
            margin_top = 6,
            margin_bottom = 6,
            halign = Gtk.Align.START
        });
        menu_box.append (sorted_by_item);
        menu_box.append (sort_order_item);
        menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
        menu_box.append (new Gtk.Label (_("Filter By")) {
            css_classes = { "heading", "h4" },
            margin_start = 6,
            margin_top = 6,
            margin_bottom = 6,
            halign = Gtk.Align.START
        });
        menu_box.append (due_date_item);
        menu_box.append (priority_filter);
        menu_box.append (labels_filter);

        var popover = new Gtk.Popover () {
            has_arrow = false,
            position = Gtk.PositionType.BOTTOM,
            child = menu_box,
            width_request = 250
        };

        restore_filters ();

        signal_map[sorted_by_item.notify["selected"].connect (() => {
            Services.Settings.get_default ().settings.set_string (SORT_ORDER_KEY, sorted_by_item.selected);
        })] = sorted_by_item;

        signal_map[sort_order_item.activate_item.connect (() => {
            Services.Settings.get_default ().settings.set_boolean (SORT_ASCENDING_KEY, sort_order_item.active);
        })] = sort_order_item;

        signal_map[due_date_item.notify["selected"].connect (() => {
            update_due_date_filter (int.parse (due_date_item.selected));
        })] = due_date_item;

        signal_map[priority_filter.filter_change.connect ((filter_item, active) => {
            if (active) {
                filter.add_filter (filter_item);
            } else {
                filter.remove_filter (filter_item);
            }
        })] = priority_filter;

        signal_map[labels_filter.activate_item.connect (() => {
            show_labels_filter_dialog ();
        })] = labels_filter;

        return popover;
    }

    private void update_due_date_filter (int selected) {
        Objects.Filters.FilterItem ? due_filter = filter.get_filter (FilterItemType.DUE_DATE.to_string ());

        if (selected <= 0) {
            if (due_filter != null) {
                filter.remove_filter (due_filter);
            }

            return;
        }

        bool insert = false;
        if (due_filter == null) {
            due_filter = new Objects.Filters.FilterItem ();
            due_filter.filter_type = FilterItemType.DUE_DATE;
            insert = true;
        }

        due_filter.name = due_date_name (selected);
        due_filter.value = selected.to_string ();

        if (insert) {
            filter.add_filter (due_filter);
        } else {
            filter.update_filter (due_filter);
        }
    }

    private string due_date_name (int selected) {
        switch (selected) {
            case 1:
                return _("Today");

            case 2:
                return _("This Week");

            case 3:
                return _("Next 7 Days");

            case 4:
                return _("This Month");

            case 5:
                return _("Next 30 Days");

            case 6:
                return _("No Date");

            default:
                return _("All (default)");
        }
    }

    private void show_labels_filter_dialog () {
        Gee.ArrayList<Objects.Label> selected_labels = new Gee.ArrayList<Objects.Label> ();
        foreach (Objects.Filters.FilterItem filter_item in filter.filters.values) {
            if (filter_item.filter_type == FilterItemType.LABEL) {
                Objects.Label ? label = Services.Store.instance ().get_label (filter_item.value);
                if (label != null) {
                    selected_labels.add (label);
                }
            }
        }

        var dialog = new Dialogs.LabelPicker ();
        dialog.add_labels_list (Services.Store.instance ().labels);
        dialog.labels = selected_labels;

        // Scoped to the dialog, not the view's signal_map: handler ids are per-instance,
        // so tracking a transient object there collides with an existing key and leaves the
        // view disconnecting that id against the wrong instance.
        ulong labels_handler = dialog.labels_changed.connect ((labels) => {
            foreach (Objects.Label label in labels.values) {
                var label_filter = new Objects.Filters.FilterItem ();
                label_filter.filter_type = FilterItemType.LABEL;
                label_filter.name = label.name;
                label_filter.value = label.id;

                filter.add_filter (label_filter);
            }

            var to_remove = new Gee.ArrayList<Objects.Filters.FilterItem> ();
            foreach (Objects.Filters.FilterItem filter_item in filter.filters.values) {
                if (filter_item.filter_type == FilterItemType.LABEL && !labels.has_key (filter_item.value)) {
                    to_remove.add (filter_item);
                }
            }

            foreach (Objects.Filters.FilterItem filter_item in to_remove) {
                filter.remove_filter (filter_item);
            }
        });

        dialog.closed.connect (() => {
            if (GLib.SignalHandler.is_connected (dialog, labels_handler)) {
                dialog.disconnect (labels_handler);
            }
        });

        dialog.present (Planify._instance.main_window);
    }

    /**
     * Restores the filters persisted for this view and syncs the menu widgets to them.
     * Each entry is stored as "filter-type:value"; the display name is re-derived rather
     * than persisted, so a renamed label shows its current name.
     */
    private void restore_filters () {
        string[] stored = Services.Settings.get_default ().settings.get_strv (FILTERS_KEY);

        foreach (string entry in stored) {
            string[] parts = entry.split (":", 2);
            if (parts.length != 2) {
                continue;
            }

            string type = parts[0];
            string value = parts[1];

            var filter_item = new Objects.Filters.FilterItem ();
            filter_item.value = value;

            if (type == FilterItemType.PRIORITY.to_string ()) {
                filter_item.filter_type = FilterItemType.PRIORITY;
                filter_item.name = "P%d".printf (Constants.PRIORITY_1 - int.parse (value) + 1);
            } else if (type == FilterItemType.LABEL.to_string ()) {
                Objects.Label ? label = Services.Store.instance ().get_label (value);
                if (label == null) {
                    // The label was deleted since the filter was stored.
                    continue;
                }

                filter_item.filter_type = FilterItemType.LABEL;
                filter_item.name = label.name;
            } else if (type == FilterItemType.DUE_DATE.to_string ()) {
                filter_item.filter_type = FilterItemType.DUE_DATE;
                filter_item.name = due_date_name (int.parse (value));
            } else {
                continue;
            }

            filter.add_filter (filter_item);
        }

        sync_menu_to_filters ();
    }

    private void sync_menu_to_filters () {
        foreach (Objects.Filters.FilterItem filter_item in filter.filters.values) {
            if (filter_item.filter_type == FilterItemType.PRIORITY) {
                if (priority_filter.filters_map.has_key (filter_item.id)) {
                    priority_filter.filters_map[filter_item.id].active = true;
                }
            } else if (filter_item.filter_type == FilterItemType.DUE_DATE) {
                due_date_item.update_selected (filter_item.value);
            }
        }
    }

    private void save_filters () {
        // Build a native string[] rather than going through Gee's generic to_array():
        // for a reference-type generic that returns unowned element pointers, which are
        // freed before set_strv() reads them (SIGSEGV inside g_utf8_validate).
        string[] stored = {};

        foreach (Objects.Filters.FilterItem filter_item in filter.filters.values) {
            stored += "%s:%s".printf (filter_item.filter_type.to_string (), filter_item.value);
        }

        Services.Settings.get_default ().settings.set_strv (FILTERS_KEY, stored);
    }

    /**
     * Reveals the dot on the view-settings button whenever the view is not showing
     * its default sort and no filters, mirroring the project view's affordance.
     */
    private void check_default_filters () {
        bool has_filters = filter.filters.size > 0;
        bool default_sort = sorted_by_project () &&
            Services.Settings.get_default ().settings.get_boolean (SORT_ASCENDING_KEY);

        indicator_revealer.reveal_child = has_filters || !default_sort;
    }

    private SortOrderType get_sort_order () {
        return Services.Settings.get_default ().settings.get_boolean (SORT_ASCENDING_KEY)
            ? SortOrderType.ASC : SortOrderType.DESC;
    }

    private bool sorted_by_project () {
        return Services.Settings.get_default ().settings.get_string (SORT_ORDER_KEY) == SORT_BY_PROJECT;
    }

    private int sort_items_function (Objects.Item item1, Objects.Item item2) {
        if (sorted_by_project ()) {
            return Util.get_default ().set_item_project_sort_func (item1, item2, get_sort_order ());
        }

        return Util.get_default ().set_item_sort_func (
            item1,
            item2,
            SortedByType.parse (Services.Settings.get_default ().settings.get_string (SORT_ORDER_KEY)),
            get_sort_order ()
        );
    }

    private void update_header_func () {
        if (filter is Objects.Filters.Completed) {
            listbox.set_header_func (header_completed_function);
            return;
        }

        // Grouping headers only make sense while the list is grouped by project;
        // under any other sort they would fragment the order into noise.
        if (sorting_supported && !sorted_by_project ()) {
            listbox.set_header_func (null);
            return;
        }

        listbox.set_header_func (header_project_function);
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
        if (rebuild_idle_id != 0) {
            GLib.Source.remove (rebuild_idle_id);
            rebuild_idle_id = 0;
        }

        listbox.set_sort_func (null);
        listbox.set_header_func (null);

        foreach (var row in Util.get_default ().get_children (listbox)) {
            ((Layouts.ItemRow) row).clean_up ();
        }
        
        foreach (var entry in signal_map.entries) {
            if (entry.value != null && GLib.SignalHandler.is_connected (entry.value, entry.key)) {
                entry.value.disconnect (entry.key);
            }
        }

        signal_map.clear ();
    }
}