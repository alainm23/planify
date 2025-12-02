/*
 * Copyright © 2025 Alain M. (https://github.com/alainm23/planify)
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

public class Views.Scheduled.ScheduledOverdue : Gtk.ListBoxRow {
    public GLib.DateTime date { get; set; default = new GLib.DateTime.now_local (); }

    private Gtk.ListBox listbox;
    private Gtk.Revealer main_revealer;

    private bool has_items {
        get {
            return item_map.size > 0;
        }
    }

    private Gee.HashMap<string, Layouts.ItemRow> item_map = new Gee.HashMap<string, Layouts.ItemRow> ();
    private Gee.HashMap<ulong, weak GLib.Object> signal_map = new Gee.HashMap<ulong, weak GLib.Object> ();

    ~ScheduledOverdue () {
        debug ("Destroying - Views.Scheduled.ScheduledOverdue\n");
    }

    construct {
        add_css_class ("no-selectable");
        add_css_class ("transition");
        add_css_class ("no-padding");

        var title_label = new Gtk.Label (_("Overdue")) {
            halign = Gtk.Align.START
        };
        title_label.add_css_class ("font-bold");

        var reschedule_button = new Widgets.ScheduleButton (_("Reschedule")) {
            visible_clear_button = false,
            visible_no_date = true,
            hexpand = true,
            halign = END
        };

        var title_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            hexpand = true,
            valign = CENTER,
            margin_start = 24,
            margin_end = 24
        };

        title_box.append (title_label);
        title_box.append (reschedule_button);

        listbox = new Gtk.ListBox () {
            valign = Gtk.Align.START,
            activate_on_single_click = true,
            selection_mode = Gtk.SelectionMode.SINGLE,
            hexpand = true
        };
        listbox.add_css_class ("listbox-background");
        listbox.set_sort_func (set_sort_func);

        var listbox_grid = new Adw.Bin () {
            margin_top = 6,
            margin_end = 24,
            child = listbox
        };

        var content = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            hexpand = true,
            valign = Gtk.Align.START,
            margin_bottom = 32,
        };

        content.append (title_box);
        content.append (new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
            margin_start = 24,
            margin_end = 24
        });
        content.append (listbox_grid);

        main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            reveal_child = has_items,
            child = content
        };

        child = main_revealer;
        add_items ();

        signal_map[Services.EventBus.get_default ().day_changed.connect (() => {
            date = new GLib.DateTime.now_local ();
            add_items ();
        })] = Services.EventBus.get_default ();
        
        signal_map[Services.Store.instance ().item_added.connect (valid_add_item)] = Services.Store.instance ();
        signal_map[Services.Store.instance ().item_deleted.connect (valid_delete_item)] = Services.Store.instance ();
        signal_map[Services.Store.instance ().item_updated.connect (valid_update_item)] = Services.Store.instance ();
        signal_map[Services.Store.instance ().item_archived.connect (valid_delete_item)] = Services.Store.instance ();
        signal_map[Services.Store.instance ().item_unarchived.connect (valid_add_item)] = Services.Store.instance ();

        signal_map[Services.EventBus.get_default ().item_moved.connect ((item, old_project_id, old_section_id, old_parent_id) => {
            if (item_map.has_key (item.id)) {
                if (!Services.Store.instance ().valid_item_by_overdue (item, date, false)) {
                    item_map[item.id].hide_destroy ();
                    item_map.unset (item.id);
                }
            }


            if (!item_map.has_key (item.id) &&
                Services.Store.instance ().valid_item_by_overdue (item, date, false)) {
                add_overdue_item (item);
            }

            listbox.invalidate_filter ();
            main_revealer.reveal_child = has_items;
        })] = Services.EventBus.get_default ();

        signal_map[reschedule_button.duedate_changed.connect (() => {
            foreach (unowned Gtk.Widget child in Util.get_default ().get_children (listbox)) {
                ((Layouts.ItemRow) child).update_due (reschedule_button.duedate);
            }
        })] = reschedule_button;

        signal_map[Services.EventBus.get_default ().dim_content.connect ((active, focused_item_id) => {
            title_box.sensitive = !active;
        })] = Services.EventBus.get_default ();
    }

    private void add_items () {
        item_map.clear ();

        foreach (unowned Gtk.Widget child in Util.get_default ().get_children (listbox)) {
            listbox.remove (child);
        }

        foreach (Objects.Item item in Services.Store.instance ().get_items_by_overdeue_view (false)) {
            add_overdue_item (item);
        }

        main_revealer.reveal_child = has_items;
    }

    private void add_overdue_item (Objects.Item item) {
        if (item_map.has_key (item.id)) {
            return;
        }

        item_map[item.id] = new Layouts.ItemRow (item);
        item_map[item.id].disable_drag_and_drop ();

        listbox.append (item_map[item.id]);
        listbox.invalidate_filter ();
    }

    private void valid_add_item (Objects.Item item) {
        if (!item_map.has_key (item.id) &&
            Services.Store.instance ().valid_item_by_overdue (item, date, false)) {
            add_overdue_item (item);
        }

        listbox.invalidate_filter ();
        main_revealer.reveal_child = has_items;
    }

    private void valid_delete_item (Objects.Item item) {
        if (item_map.has_key (item.id)) {
            item_map[item.id].hide_destroy ();
            item_map.unset (item.id);
        }

        listbox.invalidate_filter ();
        main_revealer.reveal_child = has_items;
    }

    private void valid_update_item (Objects.Item item, string update_id) {
        if (item_map.has_key (item.id)) {
            item_map[item.id].update_request ();
        }

        if (item_map.has_key (item.id) && !item.has_due) {
            item_map[item.id].hide_destroy ();
            item_map.unset (item.id);
        }

        if (item_map.has_key (item.id) && item.has_due) {
            if (!Services.Store.instance ().valid_item_by_overdue (item, date, false)) {
                item_map[item.id].hide_destroy ();
                item_map.unset (item.id);
            }
        }

        if (item.has_due) {
            valid_add_item (item);
        }

        listbox.invalidate_filter ();
        main_revealer.reveal_child = has_items;
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
        listbox.set_sort_func (null);

        foreach (var row in Util.get_default ().get_children (listbox)) {
            ((Layouts.ItemRow) row).clean_up ();
        }
        
        foreach (var entry in signal_map.entries) {
            entry.value.disconnect (entry.key);
        }

        signal_map.clear ();
    }
}