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

public class Views.Today : Adw.Bin {
    private Layouts.HeaderBar headerbar;
    private Gtk.Label title_label;
    private Gtk.Label date_label;
    #if WITH_EVOLUTION
    private Widgets.EventsList event_list;
    private Gtk.Revealer event_list_revealer;
    #endif
    private Gtk.ListBox listbox;
    private Gtk.Revealer today_revealer;
    private Gtk.ListBox overdue_listbox;
    private Gtk.Revealer overdue_revealer;
    private Gtk.Grid listbox_grid;
    private Gtk.ScrolledWindow scrolled_window;
    private Gtk.Stack listbox_placeholder_stack;
    private Gtk.Revealer indicator_revealer;
    private Widgets.ContextMenu.MenuCheckPicker priority_filter;

    public Gee.HashMap<string, Layouts.ItemRow> overdue_items = new Gee.HashMap<string, Layouts.ItemRow> ();
    public Gee.HashMap<string, Layouts.ItemRow> items = new Gee.HashMap<string, Layouts.ItemRow> ();

    public GLib.DateTime date { get; set; default = new GLib.DateTime.now_local (); }

    private bool overdue_has_children {
        get {
            return overdue_items.size > 0;
        }
    }

    private bool today_has_children {
        get {
            return items.size > 0;
        }
    }

    private Gee.HashMap<ulong, weak GLib.Object> signal_map = new Gee.HashMap<ulong, weak GLib.Object> ();

    ~Today () {
        debug ("Destroying - Today View\n");
    }

    construct {
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

        var view_setting_button = new Gtk.MenuButton () {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER,
            margin_end = 12,
            popover = build_view_setting_popover (),
            icon_name = "view-sort-descending-rtl-symbolic",
            css_classes = { "flat" },
            tooltip_text = _("View Option Menu")
        };

        var view_setting_overlay = new Gtk.Overlay ();
        view_setting_overlay.child = view_setting_button;
        view_setting_overlay.add_overlay (indicator_revealer);

        headerbar = new Layouts.HeaderBar () {
            title = Objects.Filters.Today.get_default ().name
        };
        headerbar.pack_end (view_setting_overlay);

        var today_icon = new Gtk.Image.from_icon_name (Objects.Filters.Today.get_default ().icon_name) {
            pixel_size = 16,
            valign = CENTER,
            halign = CENTER,
            css_classes = { "view-icon" }
        };

        Util.get_default ().set_widget_color (Objects.Filters.Today.get_default ().theme_color (), today_icon);

        title_label = new Gtk.Label (Objects.Filters.Today.get_default ().name) {
            css_classes = { "font-bold", "title-2" },
            ellipsize = END,
            halign = START,
        };

        date_label = new Gtk.Label (null) {
            css_classes = { "caption" },
            ellipsize = END,
            margin_top = 3
        };

        var title_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            margin_start = 24,
        };

        title_box.append (today_icon);
        title_box.append (title_label);
        title_box.append (date_label);

        #if WITH_EVOLUTION
        event_list = new Widgets.EventsList.for_day (date) {
            margin_top = 12,
            margin_start = 24,
            margin_end = 24
        };

        event_list_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            reveal_child = event_list.has_items,
            child = event_list
        };
        #endif

        var filters = new Widgets.FilterFlowBox () {
            valign = Gtk.Align.START,
            vexpand = false,
            vexpand_set = true,
            base_object = Objects.Filters.Today.get_default ()
        };

        filters.flowbox.margin_start = 24;
        filters.flowbox.margin_top = 12;
        filters.flowbox.margin_end = 12;
        filters.flowbox.margin_bottom = 3;

        var overdue_label = new Gtk.Label (_("Overdue")) {
            halign = Gtk.Align.START,
            valign = Gtk.Align.CENTER,
            hexpand = true
        };

        overdue_label.add_css_class ("font-bold");

        var reschedule_button = new Widgets.ScheduleButton (_("Reschedule")) {
            visible_clear_button = false,
            visible_no_date = true
        };

        var overdue_header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            margin_start = 24,
            margin_end = 24
        };
        overdue_header_box.append (overdue_label);
        overdue_header_box.append (reschedule_button);

        overdue_listbox = new Gtk.ListBox () {
            valign = Gtk.Align.START,
            activate_on_single_click = true,
            selection_mode = Gtk.SelectionMode.SINGLE,
            hexpand = true,
            css_classes = { "listbox-background" },
            margin_end = 24
        };
        overdue_listbox.set_sort_func (set_sort_func);

        var overdue_listbox_grid = new Gtk.Grid () {
            margin_top = 6
        };

        overdue_listbox_grid.attach (overdue_listbox, 0, 0);

        var overdue_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            margin_top = 12
        };

        overdue_box.append (overdue_header_box);
        overdue_box.append (overdue_listbox_grid);

        overdue_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            child = overdue_box
        };

        var today_label = new Gtk.Label (_("Today")) {
            halign = Gtk.Align.START,
            valign = Gtk.Align.CENTER,
            hexpand = true
        };

        today_label.add_css_class ("font-bold");

        var today_header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            margin_start = 24,
            margin_end = 24
        };
        today_header_box.append (today_label);

        var today_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
            margin_top = 12
        };
        today_box.append (today_header_box);

        today_revealer = new Gtk.Revealer () {
            transition_type = SLIDE_DOWN,
            child = today_box
        };

        listbox = new Gtk.ListBox () {
            valign = Gtk.Align.START,
            activate_on_single_click = true,
            selection_mode = Gtk.SelectionMode.SINGLE,
            hexpand = true,
            css_classes = { "listbox-background" }
        };
        listbox.set_sort_func (set_sort_func);

        listbox_grid = new Gtk.Grid () {
            margin_top = 6,
            margin_start = 3,
            margin_end = 24
        };

        listbox_grid.attach (listbox, 0, 0);

        var content = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            hexpand = true,
            vexpand = true
        };

        content.append (overdue_revealer);
        content.append (today_revealer);
        content.append (listbox_grid);

        var listbox_placeholder = new Adw.StatusPage ();
        listbox_placeholder.icon_name = "check-round-outline-symbolic";
        listbox_placeholder.title = _("Add Some Tasks");
        listbox_placeholder.description = _("Press 'a' to create a new task");

        listbox_placeholder_stack = new Gtk.Stack () {
            vexpand = true,
            hexpand = true,
            transition_type = CROSSFADE,
            vhomogeneous = false,
            hhomogeneous = false
        };

        listbox_placeholder_stack.add_named (content, "listbox");
        listbox_placeholder_stack.add_named (listbox_placeholder, "placeholder");

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            hexpand = true,
            vexpand = true
        };

        content_box.append (title_box);
        #if WITH_EVOLUTION
        content_box.append (event_list_revealer);
        #endif
        content_box.append (filters);
        content_box.append (listbox_placeholder_stack);

        var content_clamp = new Adw.Clamp () {
            maximum_size = 864,
            margin_bottom = 64,
            child = content_box
        };

        scrolled_window = new Gtk.ScrolledWindow () {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            hexpand = true,
            vexpand = true,
            child = content_clamp
        };

        var magic_button = new Widgets.MagicButton ();

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
        update_today_label ();
        add_today_items ();

        Timeout.add (listbox_placeholder_stack.transition_duration, () => {
            check_placeholder ();
            return GLib.Source.REMOVE;
        });

        signal_map[Services.EventBus.get_default ().day_changed.connect (() => {
            date = new GLib.DateTime.now_local ();
            update_today_label ();
            add_today_items ();
        })] = Services.EventBus.get_default ();

        signal_map[Services.Store.instance ().item_added.connect (valid_add_item)] = Services.Store.instance ();
        signal_map[Services.Store.instance ().item_deleted.connect (valid_delete_item)] = Services.Store.instance ();
        signal_map[Services.Store.instance ().item_updated.connect (valid_update_item)] = Services.Store.instance ();
        signal_map[Services.Store.instance ().item_archived.connect (valid_delete_item)] = Services.Store.instance ();
        signal_map[Services.Store.instance ().item_unarchived.connect (valid_add_item)] = Services.Store.instance ();

        signal_map[Services.EventBus.get_default ().item_moved.connect ((item) => {
            // Handle existing items that may no longer belong in Today view
            if (items.has_key (item.id)) {
                if (Services.Store.instance ().valid_item_by_date (item, date, false)) {
                    items[item.id].update_request ();
                } else {
                    // Remove item that no longer belongs in today
                    items[item.id].hide_destroy ();
                    items.unset (item.id);
                }
            }

            if (overdue_items.has_key (item.id)) {
                if (Services.Store.instance ().valid_item_by_overdue (item, date, false)) {
                    overdue_items[item.id].update_request ();
                } else {
                    // Remove item that no longer belongs in overdue
                    overdue_items[item.id].hide_destroy ();
                    overdue_items.unset (item.id);
                }
            }

            // Check if item should be added to Today view (wasn't there before but should be now)
            if (!items.has_key (item.id) &&
                Services.Store.instance ().valid_item_by_date (item, date, false)) {
                add_item (item);
            }

            if (!overdue_items.has_key (item.id) &&
                Services.Store.instance ().valid_item_by_overdue (item, date, false)) {
                add_overdue_item (item);
            }

            // Update UI state
            update_headers ();
            check_placeholder ();
            listbox.invalidate_filter ();
            overdue_listbox.invalidate_filter ();
        })] = Services.EventBus.get_default ();

        signal_map[magic_button.clicked.connect (() => {
            prepare_new_item ();
        })] = magic_button;

        #if WITH_EVOLUTION
        signal_map[event_list.change.connect (() => {
            event_list_revealer.reveal_child = event_list.has_items;
        })] = event_list;
        #endif

        signal_map[Services.Settings.get_default ().settings.changed["today-sort-order"].connect (() => {
            listbox.invalidate_sort ();
            overdue_listbox.invalidate_sort ();
        })] = Services.Settings.get_default ().settings;

        listbox.set_filter_func ((row) => {
            var item = ((Layouts.ItemRow) row).item;
            bool return_value = true;

            if (Objects.Filters.Today.get_default ().filters.size <= 0) {
                return true;
            }

            return_value = false;
            foreach (Objects.Filters.FilterItem filter in Objects.Filters.Today.get_default ().filters.values) {
                if (filter.filter_type == FilterItemType.PRIORITY) {
                    return_value = return_value || item.priority == int.parse (filter.value);
                } else if (filter.filter_type == FilterItemType.LABEL) {
                    return_value = return_value || item.has_label (filter.value);
                }
            }

            return return_value;
        });

        overdue_listbox.set_filter_func ((row) => {
            var item = ((Layouts.ItemRow) row).item;
            bool return_value = true;

            if (Objects.Filters.Today.get_default ().filters.size <= 0) {
                return true;
            }

            return_value = false;
            foreach (Objects.Filters.FilterItem filter in Objects.Filters.Today.get_default ().filters.values) {
                if (filter.filter_type == FilterItemType.PRIORITY) {
                    return_value = return_value || item.priority == int.parse (filter.value);
                } else if (filter.filter_type == FilterItemType.LABEL) {
                    return_value = return_value || item.has_label (filter.value);
                }
            }

            return return_value;
        });

        signal_map[Objects.Filters.Today.get_default ().filter_added.connect (() => {
            listbox.invalidate_filter ();
            overdue_listbox.invalidate_filter ();
        })] = Objects.Filters.Today.get_default ();

        signal_map[Objects.Filters.Today.get_default ().filter_removed.connect (() => {
            listbox.invalidate_filter ();
            overdue_listbox.invalidate_filter ();
        })] = Objects.Filters.Today.get_default ();

        signal_map[Objects.Filters.Today.get_default ().filter_updated.connect (() => {
            listbox.invalidate_filter ();
            overdue_listbox.invalidate_filter ();
        })] = Objects.Filters.Today.get_default ();

        signal_map[reschedule_button.duedate_changed.connect (() => {
            foreach (unowned Gtk.Widget child in Util.get_default ().get_children (overdue_listbox)) {
                ((Layouts.ItemRow) child).update_due (reschedule_button.duedate);
            }
        })] = reschedule_button;

        signal_map[scrolled_window.vadjustment.value_changed.connect (() => {
            headerbar.revealer_title_box (scrolled_window.vadjustment.value >= Constants.HEADERBAR_TITLE_SCROLL_THRESHOLD);            
        })] = scrolled_window.vadjustment;
    }

    private void check_placeholder () {
        if (overdue_has_children || today_has_children) {
            listbox_placeholder_stack.visible_child_name = "listbox";
        } else {
            listbox_placeholder_stack.visible_child_name = "placeholder";
        }

        listbox.invalidate_sort ();
        overdue_listbox.invalidate_sort ();
    }

    private void add_today_items () {
        overdue_items.clear ();

        foreach (unowned Gtk.Widget child in Util.get_default ().get_children (overdue_listbox)) {
            overdue_listbox.remove (child);
        }

        foreach (Objects.Item item in Services.Store.instance ().get_items_by_overdeue_view (false)) {
            add_overdue_item (item);
        }

        items.clear ();

        foreach (unowned Gtk.Widget child in Util.get_default ().get_children (listbox)) {
            listbox.remove (child);
        }

        foreach (Objects.Item item in Services.Store.instance ().get_items_by_date (date, false)) {
            add_item (item);
        }

        update_headers ();
    }

    private void add_item (Objects.Item item) {
        items[item.id] = new Layouts.ItemRow (item);
        items[item.id].disable_drag_and_drop ();
        listbox.append (items[item.id]);
        update_headers ();
        check_placeholder ();
        listbox.invalidate_filter ();
        overdue_listbox.invalidate_filter ();
    }

    private void add_overdue_item (Objects.Item item) {
        overdue_items[item.id] = new Layouts.ItemRow (item);
        overdue_items[item.id].disable_drag_and_drop ();
        overdue_listbox.append (overdue_items[item.id]);
        update_headers ();
        check_placeholder ();
        listbox.invalidate_filter ();
        overdue_listbox.invalidate_filter ();
    }

    private void valid_add_item (Objects.Item item) {
        if (!items.has_key (item.id) &&
            Services.Store.instance ().valid_item_by_date (item, date, false)) {
            add_item (item);
        }

        if (!overdue_items.has_key (item.id) &&
            Services.Store.instance ().valid_item_by_overdue (item, date, false)) {
            add_overdue_item (item);
        }

        update_headers ();
        check_placeholder ();
        listbox.invalidate_filter ();
        overdue_listbox.invalidate_filter ();
    }

    private void valid_delete_item (Objects.Item item) {
        if (items.has_key (item.id)) {
            items[item.id].hide_destroy ();
            items.unset (item.id);
        }

        if (overdue_items.has_key (item.id)) {
            overdue_items[item.id].hide_destroy ();
            overdue_items.unset (item.id);
        }

        update_headers ();
        check_placeholder ();
        listbox.invalidate_filter ();
        overdue_listbox.invalidate_filter ();
    }

    private void valid_update_item (Objects.Item item) {
        if (items.has_key (item.id)) {
            items[item.id].update_request ();
        }

        if (overdue_items.has_key (item.id)) {
            overdue_items[item.id].update_request ();
        }

        if (items.has_key (item.id) && !item.has_due) {
            items[item.id].hide_destroy ();
            items.unset (item.id);
        }

        if (overdue_items.has_key (item.id) && !item.has_due) {
            overdue_items[item.id].hide_destroy ();
            overdue_items.unset (item.id);
        }

        if (items.has_key (item.id) && item.has_due) {
            if (!Services.Store.instance ().valid_item_by_date (item, date, false)) {
                items[item.id].hide_destroy ();
                items.unset (item.id);
            }
        }

        if (overdue_items.has_key (item.id) && item.has_due) {
            if (!Services.Store.instance ().valid_item_by_overdue (item, date, false)) {
                overdue_items[item.id].hide_destroy ();
                overdue_items.unset (item.id);
            }
        }

        if (item.has_due) {
            valid_add_item (item);
        }

        update_headers ();
        check_placeholder ();
        listbox.invalidate_filter ();
        overdue_listbox.invalidate_filter ();
    }

    public void prepare_new_item (string content = "") {
        var dialog = new Dialogs.QuickAdd ();
        dialog.update_content (content);
        dialog.set_due (Utils.Datetime.get_date_only (date));
        dialog.present (Planify._instance.main_window);
    }

    private void update_headers () {
        if (overdue_has_children) {
            overdue_revealer.reveal_child = true;
            today_revealer.reveal_child = today_has_children;
            listbox_grid.margin_top = 6;
        } else {
            overdue_revealer.reveal_child = false;
            today_revealer.reveal_child = false;
            listbox_grid.margin_top = 12;
        }
    }

    public void update_today_label () {
        var date_format = "%s %s".printf (
            new GLib.DateTime.now_local ().format ("%a"),
            date.format (Utils.Datetime.get_default_date_format (false, true, false))
        );

        date_label.label = date_format;
        headerbar.subtitle = date_format;
    }

    private Gtk.Popover build_view_setting_popover () {
        var sorted_by_item = new Widgets.ContextMenu.MenuPicker (_ ("Sorting"), "vertical-arrows-long-symbolic") {
            selected = Services.Settings.get_default ().settings.get_string ("today-sort-order")
        };
        sorted_by_item.add_item (_("Alphabetically"), SortedByType.NAME.to_string ());
        sorted_by_item.add_item (_("Due Date"), SortedByType.DUE_DATE.to_string ());
        sorted_by_item.add_item (_("Date Added"), SortedByType.ADDED_DATE.to_string ());
        sorted_by_item.add_item (_("Priority"), SortedByType.PRIORITY.to_string ());
        
        // Filters
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
        menu_box.append (sorted_by_item);
        menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
        menu_box.append (new Gtk.Label (_("Filter By")) {
            css_classes = { "heading", "h4" },
            margin_start = 6,
            margin_top = 6,
            margin_bottom = 6,
            halign = Gtk.Align.START
        });
        menu_box.append (priority_filter);
        menu_box.append (labels_filter);

        var popover = new Gtk.Popover () {
            has_arrow = false,
            position = Gtk.PositionType.BOTTOM,
            child = menu_box,
            width_request = 250
        };

        signal_map[sorted_by_item.notify["selected"].connect (() => {
            Services.Settings.get_default ().settings.set_string ("today-sort-order", sorted_by_item.selected);
        })] = sorted_by_item;

        signal_map[priority_filter.filter_change.connect ((filter, active) => {
            if (active) {
                Objects.Filters.Today.get_default ().add_filter (filter);
            } else {
                Objects.Filters.Today.get_default ().remove_filter (filter);
            }
        })] = priority_filter;

        signal_map[labels_filter.activate_item.connect (() => {
            Gee.ArrayList<Objects.Label> _labels = new Gee.ArrayList<Objects.Label> ();
            foreach (Objects.Filters.FilterItem filter in Objects.Filters.Today.get_default ().filters.values) {
                if (filter.filter_type == FilterItemType.LABEL) {
                    _labels.add (Services.Store.instance ().get_label (filter.value));
                }
            }

            Gee.HashMap<string, Objects.Label> labels_map = new Gee.HashMap<string, Objects.Label> ();
            Gee.ArrayList<Objects.Label> labels_list = new Gee.ArrayList<Objects.Label> ();
            foreach (Layouts.ItemRow item_row in items.values) {
                foreach (Objects.Label label in item_row.item.labels) {
                    if (!labels_map.has_key (label.id)) {
                        labels_map[label.id] = label;
                        labels_list.add (labels_map[label.id]);
                    }
                }
            }

            var dialog = new Dialogs.LabelPicker ();
            dialog.add_labels_list (labels_list);
            dialog.labels = _labels;

            signal_map[dialog.labels_changed.connect ((labels) => {
                foreach (Objects.Label label in labels.values) {
                    var filter = new Objects.Filters.FilterItem ();
                    filter.filter_type = FilterItemType.LABEL;
                    filter.name = label.name;
                    filter.value = label.id;

                    Objects.Filters.Today.get_default ().add_filter (filter);
                }

                Gee.ArrayList<Objects.Filters.FilterItem> to_remove = new Gee.ArrayList<Objects.Filters.FilterItem> ();
                foreach (Objects.Filters.FilterItem filter in Objects.Filters.Today.get_default ().filters.values) {
                    if (filter.filter_type == FilterItemType.LABEL) {
                        if (!labels.has_key (filter.value)) {
                            to_remove.add (filter);
                        }
                    }
                }

                foreach (Objects.Filters.FilterItem filter in to_remove) {
                    Objects.Filters.Today.get_default ().remove_filter (filter);
                }
            })] = dialog;
            
            dialog.present (Planify._instance.main_window);
        })] = labels_filter;

        return popover;
    }

    private int set_sort_func (Gtk.ListBoxRow lbrow, Gtk.ListBoxRow lbbefore) {
        Objects.Item item1 = ((Layouts.ItemRow) lbrow).item;
        Objects.Item item2 = ((Layouts.ItemRow) lbbefore).item;

        SortedByType sorted_by = SortedByType.parse (Services.Settings.get_default ().settings.get_string ("today-sort-order"));

        return Util.get_default ().set_item_sort_func (
            item1,
            item2,
            sorted_by,
            SortOrderType.ASC
        );
    }

    public void clean_up () {
        listbox.set_filter_func (null);
        listbox.set_sort_func (null);

        foreach (var row in Util.get_default ().get_children (listbox)) {
            ((Layouts.ItemRow) row).clean_up ();
        }

        overdue_listbox.set_filter_func (null);
        overdue_listbox.set_sort_func (null);

        foreach (var row in Util.get_default ().get_children (overdue_listbox)) {
            ((Layouts.ItemRow) row).clean_up ();
        }

        foreach (var entry in signal_map.entries) {
            entry.value.disconnect (entry.key);
        }

        signal_map.clear ();

        #if WITH_EVOLUTION
        event_list.clean_up ();
        #endif
    }
}
