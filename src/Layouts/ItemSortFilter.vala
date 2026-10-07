/*
 * Copyright © 2026 Alain M. (https://github.com/alainm23/planify)
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
 */

/**
 * Sort and filter menu shared by All Tasks and the Label view, persisted under "<prefix>-*" keys.
 */
public class Layouts.ItemSortFilter : GLib.Object {
    // Default sort: group by project. Not in SortedByType, as it only applies across projects.
    public const string SORT_BY_PROJECT = "project";

    public Objects.BaseObject target { get; construct; }
    public string key_prefix { get; construct; }

    public signal void changed ();

    private string sort_order_key;
    private string sort_ascending_key;
    private string filters_key;

    private Widgets.ContextMenu.MenuPicker due_date_item;
    private Widgets.ContextMenu.MenuCheckPicker priority_filter;

    private Gee.HashMap<ulong, weak GLib.Object> signal_map = new Gee.HashMap<ulong, weak GLib.Object> ();

    public ItemSortFilter (Objects.BaseObject target, string key_prefix) {
        Object (
            target: target,
            key_prefix: key_prefix
        );
    }

    construct {
        sort_order_key = key_prefix + "-sort-order";
        sort_ascending_key = key_prefix + "-sort-ascending";
        filters_key = key_prefix + "-filters";

        signal_map[Services.Settings.get_default ().settings.changed[sort_order_key].connect (() => {
            changed ();
        })] = Services.Settings.get_default ().settings;

        signal_map[Services.Settings.get_default ().settings.changed[sort_ascending_key].connect (() => {
            changed ();
        })] = Services.Settings.get_default ().settings;
    }

    public Gtk.Popover build_popover () {
        var sorted_by_item = new Widgets.ContextMenu.MenuPicker (_("Sorting"), "vertical-arrows-long-symbolic") {
            selected = Services.Settings.get_default ().settings.get_string (sort_order_key)
        };

        sorted_by_item.add_item (_("Project"), SORT_BY_PROJECT);
        sorted_by_item.add_item (_("Alphabetically"), SortedByType.NAME.to_string ());
        sorted_by_item.add_item (_("Due Date"), SortedByType.DUE_DATE.to_string ());
        sorted_by_item.add_item (_("Date Added"), SortedByType.ADDED_DATE.to_string ());
        sorted_by_item.add_item (_("Date Modified"), SortedByType.UPDATED_DATE.to_string ());
        sorted_by_item.add_item (_("Priority"), SortedByType.PRIORITY.to_string ());

        var sort_order_item = new Widgets.ContextMenu.MenuSwitch (_("Ascending Order"), "vertical-arrows-long-symbolic") {
            active = Services.Settings.get_default ().settings.get_boolean (sort_ascending_key)
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

        // Before connecting the signals below, so restoring isn't saved back as a change.
        restore_filters ();

        signal_map[sorted_by_item.notify["selected"].connect (() => {
            Services.Settings.get_default ().settings.set_string (sort_order_key, sorted_by_item.selected);
        })] = sorted_by_item;

        signal_map[sort_order_item.activate_item.connect (() => {
            Services.Settings.get_default ().settings.set_boolean (sort_ascending_key, sort_order_item.active);
        })] = sort_order_item;

        signal_map[due_date_item.notify["selected"].connect (() => {
            update_due_date_filter (int.parse (due_date_item.selected));
        })] = due_date_item;

        signal_map[priority_filter.filter_change.connect ((filter_item, active) => {
            if (active) {
                target.add_filter (filter_item);
            } else {
                target.remove_filter (filter_item);
            }
        })] = priority_filter;

        signal_map[labels_filter.activate_item.connect (() => {
            show_labels_filter_dialog ();
        })] = labels_filter;

        signal_map[target.filter_added.connect (() => {
            filters_changed ();
        })] = target;

        signal_map[target.filter_removed.connect ((filter_item) => {
            // A chip removed the filter; bring the menu back in line with it.
            if (filter_item.filter_type == FilterItemType.PRIORITY) {
                priority_filter.unchecked (filter_item);
            } else if (filter_item.filter_type == FilterItemType.DUE_DATE) {
                due_date_item.update_selected ("0");
            }

            filters_changed ();
        })] = target;

        signal_map[target.filter_updated.connect (() => {
            filters_changed ();
        })] = target;

        return popover;
    }

    public bool matches (Objects.Item item) {
        return Utils.TaskUtils.items_filter_func (item, target.filters);
    }

    public int compare (Objects.Item item1, Objects.Item item2) {
        if (sorted_by_project ()) {
            return Util.get_default ().set_item_project_sort_func (item1, item2, get_sort_order ());
        }

        return Util.get_default ().set_item_sort_func (
            item1,
            item2,
            SortedByType.parse (Services.Settings.get_default ().settings.get_string (sort_order_key)),
            get_sort_order ()
        );
    }

    public bool sorted_by_project () {
        return Services.Settings.get_default ().settings.get_string (sort_order_key) == SORT_BY_PROJECT;
    }

    public bool is_default () {
        return target.filters.size == 0 && sorted_by_project () &&
               Services.Settings.get_default ().settings.get_boolean (sort_ascending_key);
    }

    private SortOrderType get_sort_order () {
        return Services.Settings.get_default ().settings.get_boolean (sort_ascending_key)
            ? SortOrderType.ASC : SortOrderType.DESC;
    }

    private void filters_changed () {
        save_filters ();
        changed ();
    }

    private void update_due_date_filter (int selected) {
        Objects.Filters.FilterItem ? due_filter = target.get_filter (FilterItemType.DUE_DATE.to_string ());

        if (selected <= 0) {
            if (due_filter != null) {
                target.remove_filter (due_filter);
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
            target.add_filter (due_filter);
        } else {
            target.update_filter (due_filter);
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
        foreach (Objects.Filters.FilterItem filter_item in target.filters.values) {
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

        // Not in signal_map: handler ids are per instance and would collide with the view's.
        ulong labels_handler = dialog.labels_changed.connect ((labels) => {
            foreach (Objects.Label label in labels.values) {
                var label_filter = new Objects.Filters.FilterItem ();
                label_filter.filter_type = FilterItemType.LABEL;
                label_filter.name = label.name;
                label_filter.value = label.id;

                target.add_filter (label_filter);
            }

            var to_remove = new Gee.ArrayList<Objects.Filters.FilterItem> ();
            foreach (Objects.Filters.FilterItem filter_item in target.filters.values) {
                if (filter_item.filter_type == FilterItemType.LABEL && !labels.has_key (filter_item.value)) {
                    to_remove.add (filter_item);
                }
            }

            foreach (Objects.Filters.FilterItem filter_item in to_remove) {
                target.remove_filter (filter_item);
            }
        });

        dialog.closed.connect (() => {
            if (GLib.SignalHandler.is_connected (dialog, labels_handler)) {
                dialog.disconnect (labels_handler);
            }
        });

        dialog.present (Planify._instance.main_window);
    }

    // Entries are "filter-type:value"; names are looked up again, so renamed labels stay current.
    private void restore_filters () {
        string[] stored = Services.Settings.get_default ().settings.get_strv (filters_key);

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

            target.add_filter (filter_item);
        }

        sync_menu_to_filters ();
    }

    private void sync_menu_to_filters () {
        foreach (Objects.Filters.FilterItem filter_item in target.filters.values) {
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
        // Not Gee's to_array (): its unowned strings are freed before set_strv () reads them.
        string[] stored = {};

        foreach (Objects.Filters.FilterItem filter_item in target.filters.values) {
            stored += "%s:%s".printf (filter_item.filter_type.to_string (), filter_item.value);
        }

        Services.Settings.get_default ().settings.set_strv (filters_key, stored);
    }

    public static void project_header_func (Gtk.ListBoxRow lbrow, Gtk.ListBoxRow ? lbbefore) {
        if (!(lbrow is Layouts.ItemRow)) {
            return;
        }

        var row = (Layouts.ItemRow) lbrow;
        if (lbbefore != null && lbbefore is Layouts.ItemRow) {
            var before = (Layouts.ItemRow) lbbefore;
            // The item's project, not ItemRow.project_id, which goes stale when a task is moved.
            if (row.item.project_id == before.item.project_id) {
                row.set_header (null);
                return;
            }
        }

        Objects.Project ? project = row.item.project;
        row.set_header (header_box (project == null ? "" : project.name));
    }

    public static Gtk.Widget header_box (string title) {
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

    public void clean_up () {
        foreach (var entry in signal_map.entries) {
            if (entry.value != null && GLib.SignalHandler.is_connected (entry.value, entry.key)) {
                entry.value.disconnect (entry.key);
            }
        }

        signal_map.clear ();
    }
}
