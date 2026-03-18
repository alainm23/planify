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

public abstract class Views.Scheduled.ScheduledSection : Gtk.ListBoxRow {
    protected Gtk.ListBox listbox;
    protected Gtk.Revealer listbox_revealer;
    protected Gee.HashMap<string, Layouts.ItemRow> items = new Gee.HashMap<string, Layouts.ItemRow> ();
    protected Gee.HashMap<ulong, weak GLib.Object> signal_map = new Gee.HashMap<ulong, weak GLib.Object> ();

    protected bool has_items {
        get {
            return items.size > 0;
        }
    }

    protected abstract void add_items ();
    protected abstract bool valid_item_predicate (Objects.Item item);

    protected void setup_listbox () {
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

        signal_map[Services.Settings.get_default ().settings.changed["scheduled-sort-order"].connect (() => {
            listbox.invalidate_sort ();
        })] = Services.Settings.get_default ();
    }

#if WITH_EVOLUTION
    protected Widgets.EventsList? event_list;
    protected Gtk.Revealer? event_list_revealer;

    protected virtual Widgets.EventsList? create_events_list () {
        return null;
    }

    protected void setup_events (Gtk.Box header_content) {
        event_list = create_events_list ();
        if (event_list == null) {
            return;
        }

        event_list_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            reveal_child = event_list.has_items,
            child = event_list
        };

        header_content.append (event_list_revealer);

        signal_map[event_list.change.connect (() => {
            event_list_revealer.reveal_child = event_list.has_items;
        })] = event_list;
    }
#endif


    protected Gtk.Box create_header (Gtk.Widget title_widget) {
        var header = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            hexpand = true,
            valign = Gtk.Align.START,
            margin_start = 30,
            margin_end = 24
        };

        header.append (title_widget);
        header.append (new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
            margin_top = 6,
            margin_bottom = 3
        });

        return header;
    }

    protected void add_item (Objects.Item item) {
        if (!items.has_key (item.id)) {
            items[item.id] = new Layouts.ItemRow (item);
            items[item.id].disable_drag_and_drop ();
            listbox.append (items[item.id]);
        }
    }

    protected virtual void valid_add_item (Objects.Item item) {
        if (!items.has_key (item.id) && valid_item_predicate (item)) {
            add_item (item);
        }

        listbox_revealer.reveal_child = has_items;
    }

    protected virtual void valid_delete_item (Objects.Item item) {
        if (items.has_key (item.id)) {
            items[item.id].hide_destroy ();
            items.unset (item.id);
        }

        listbox_revealer.reveal_child = has_items;
    }

    protected virtual void valid_update_item (Objects.Item item, string? update_id = null) {
        if (items.has_key (item.id)) {
            items[item.id].update_request ();
        }

        listbox_revealer.reveal_child = has_items;
    }

    protected void setup_item_signals () {
        signal_map[Services.Store.instance ().item_added.connect (valid_add_item)] = Services.Store.instance ();
        signal_map[Services.Store.instance ().item_deleted.connect (valid_delete_item)] = Services.Store.instance ();
        signal_map[Services.Store.instance ().item_updated.connect (valid_update_item)] = Services.Store.instance ();
        signal_map[Services.Store.instance ().item_archived.connect (valid_delete_item)] = Services.Store.instance ();
        signal_map[Services.Store.instance ().item_unarchived.connect (valid_add_item)] = Services.Store.instance ();
    }

    protected virtual void cleanup_signals () {
        foreach (var entry in signal_map.entries) {
            if (entry.value != null && GLib.SignalHandler.is_connected (entry.value, entry.key)) {
                entry.value.disconnect (entry.key);
            }
        }

        signal_map.clear ();
    }

    public virtual void clean_up () {
        listbox.set_filter_func (null);
        listbox.set_sort_func (null);

        foreach (var row in Util.get_default ().get_children (listbox)) {
            ((Layouts.ItemRow) row).clean_up ();
        }

        cleanup_signals ();

#if WITH_EVOLUTION
        if (event_list != null) {
            event_list.clean_up ();
        }
#endif
    }
}
