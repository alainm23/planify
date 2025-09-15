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

public class Views.Scheduled.ScheduledDay : Gtk.ListBoxRow {
    public GLib.DateTime date { get; construct; }

    private Widgets.EventsList event_list;
    private Gtk.ListBox listbox;
    private Gtk.Revealer listbox_revealer;
    private Gtk.Revealer event_list_revealer;

    private Gee.HashMap<string, Layouts.ItemRow> items;

    private bool has_items {
        get {
            return items.size > 0;
        }
    }

    private Gee.HashMap<ulong, weak GLib.Object> signal_map = new Gee.HashMap<ulong, weak GLib.Object> ();

    public ScheduledDay (GLib.DateTime date) {
        Object (
            date: date
        );
    }

    ~ScheduledDay () {
        print ("Destroying - Views.Scheduled.ScheduledDay\n");
    }

    construct {
        add_css_class ("no-selectable");
        add_css_class ("transition");
        add_css_class ("no-padding");

        items = new Gee.HashMap<string, Layouts.ItemRow> ();

        var day_label = new Gtk.Label (date.get_day_of_month ().to_string ()) {
            halign = Gtk.Align.START
        };
        day_label.add_css_class ("font-bold");

        var date_format_label = new Gtk.Label (
            date.format ("%a")
                                ) {
            halign = Gtk.Align.START
        };

        date_format_label.add_css_class ("dimmed");

        var title_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            hexpand = true
        };

        title_box.append (day_label);
        title_box.append (date_format_label);

        event_list = new Widgets.EventsList.for_day (date) {
            hexpand = true,
            valign = Gtk.Align.START,
            margin_top = 6
        };

        event_list_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            reveal_child = event_list.has_items,
            child = event_list
        };

        var header_content = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            hexpand = true,
            valign = Gtk.Align.START,
            margin_start = 24,
            margin_end = 24
        };

        header_content.append (title_box);
        header_content.append (new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
            margin_top = 6,
            margin_bottom = 3
        });
        header_content.append (event_list_revealer);

        listbox = new Gtk.ListBox () {
            valign = Gtk.Align.START,
            activate_on_single_click = true,
            selection_mode = Gtk.SelectionMode.SINGLE,
            hexpand = true,
            css_classes = { "listbox-background" }
        };

        var listbox_grid = new Gtk.Grid () {
            margin_top = 6,
            margin_end = 24
        };
        listbox_grid.attach (listbox, 0, 0);

        listbox_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            reveal_child = has_items
        };

        listbox_revealer.child = listbox_grid;

        var content = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            hexpand = true,
            valign = Gtk.Align.START,
            margin_bottom = 32,
        };

        content.append (header_content);
        content.append (listbox_revealer);

        child = content;

        add_items ();

        Timeout.add (listbox_revealer.transition_duration, () => {
            listbox_revealer.reveal_child = has_items;
            return GLib.Source.REMOVE;
        });

        signal_map[Services.Store.instance ().item_added.connect (valid_add_item)] = Services.Store.instance ();
        signal_map[Services.Store.instance ().item_deleted.connect (valid_delete_item)] = Services.Store.instance ();
        signal_map[Services.Store.instance ().item_updated.connect (valid_update_item)] = Services.Store.instance ();
        signal_map[Services.Store.instance ().item_archived.connect (valid_delete_item)] = Services.Store.instance ();
        signal_map[Services.Store.instance ().item_unarchived.connect (valid_add_item)] = Services.Store.instance ();

        signal_map[Services.EventBus.get_default ().item_moved.connect ((item) => {
            if (items.has_key (item.id)) {
                items[item.id].update_request ();
            }

            listbox.invalidate_filter ();
        })] = Services.EventBus.get_default ();

        signal_map[Services.Settings.get_default ().settings.changed["scheduled-sort-order"].connect (() => {
            listbox.invalidate_sort ();
        })] = Services.Settings.get_default ();

        listbox.set_sort_func ((lbrow, lbbefore) => {
            Objects.Item item1 = ((Layouts.ItemRow) lbrow).item;
            Objects.Item item2 = ((Layouts.ItemRow) lbbefore).item;

            SortedByType sorted_by = SortedByType.parse (Services.Settings.get_default ().settings.get_string ("scheduled-sort-order"));

            return Util.get_default ().set_item_sort_func (
                item1,
                item2,
                sorted_by,
                SortOrderType.ASC
            );
        });

        listbox.set_filter_func ((row) => {
            var item = ((Layouts.ItemRow) row).item;
            bool return_value = true;

            if (Objects.Filters.Scheduled.get_default ().filters.size <= 0) {
                return true;
            }

            return_value = false;
            foreach (Objects.Filters.FilterItem filter in Objects.Filters.Scheduled.get_default ().filters.values) {
                if (filter.filter_type == FilterItemType.PRIORITY) {
                    return_value = return_value || item.priority == int.parse (filter.value);
                } else if (filter.filter_type == FilterItemType.LABEL) {
                    return_value = return_value || item.has_label (filter.value);
                }
            }

            return return_value;
        });

        signal_map[Objects.Filters.Scheduled.get_default ().filter_added.connect (() => {
            listbox.invalidate_filter ();
        })] = Objects.Filters.Scheduled.get_default ();

        signal_map[Objects.Filters.Scheduled.get_default ().filter_removed.connect (() => {
            listbox.invalidate_filter ();
        })] = Objects.Filters.Scheduled.get_default ();

        signal_map[Objects.Filters.Scheduled.get_default ().filter_updated.connect (() => {
            listbox.invalidate_filter ();
        })] = Objects.Filters.Scheduled.get_default ();

        signal_map[event_list.change.connect (() => {
            event_list_revealer.reveal_child = event_list.has_items;
        })] = event_list;
    }

    private void add_items () {
        foreach (Objects.Item item in Services.Store.instance ().get_items_by_date (date, false)) {
            add_item (item);
        }
    }

    private void add_item (Objects.Item item) {
        if (!items.has_key (item.id)) {
            items[item.id] = new Layouts.ItemRow (item);
            items[item.id].disable_drag_and_drop ();
            listbox.append (items[item.id]);
        }
    }

    private void valid_add_item (Objects.Item item) {
        if (!items.has_key (item.id) &&
            Services.Store.instance ().valid_item_by_date (item, date, false)) {
            items[item.id] = new Layouts.ItemRow (item);
            items[item.id].disable_drag_and_drop ();
            listbox.append (items[item.id]);
        }

        listbox_revealer.reveal_child = has_items;
        listbox.invalidate_filter ();
    }

    private void valid_delete_item (Objects.Item item) {
        if (items.has_key (item.id)) {
            items[item.id].hide_destroy ();
            items.unset (item.id);
        }

        listbox_revealer.reveal_child = has_items;
    }

    private void valid_update_item (Objects.Item item) {
        if (items.has_key (item.id)) {
            items[item.id].update_request ();
        }

        if (items.has_key (item.id) && !item.has_due) {
            items[item.id].hide_destroy ();
            items.unset (item.id);
        }


        if (items.has_key (item.id) && item.has_due) {
            if (!Services.Store.instance ().valid_item_by_date (item, date, false)) {
                items[item.id].hide_destroy ();
                items.unset (item.id);
            }
        }

        if (item.has_due) {
            valid_add_item (item);
        }

        listbox_revealer.reveal_child = has_items;
        listbox.invalidate_filter ();
    }

    public void clean_up () {
        listbox.set_filter_func (null);
        listbox.set_sort_func (null);

        foreach (var row in Util.get_default ().get_children (listbox)) {
            ((Layouts.ItemRow) row).clean_up ();
        }
        
        foreach (var entry in signal_map.entries) {
            entry.value.disconnect (entry.key);
        }

        signal_map.clear ();

        event_list.clean_up ();
    }
}
