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

public class Views.Scheduled.ScheduledOverdue : Views.Scheduled.ScheduledSection {
    public GLib.DateTime date { get; set; default = new GLib.DateTime.now_local (); }

    private Gtk.Box header_content;
    private Gtk.Revealer main_revealer;
    private Widgets.ScheduleButton reschedule_button;

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

        reschedule_button = new Widgets.ScheduleButton (_("Reschedule")) {
            visible_clear_button = false,
            visible_no_date = true,
            hexpand = true,
            halign = END
        };

        var title_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            hexpand = true
        };
        title_box.append (title_label);
        title_box.append (reschedule_button);

        header_content = create_header (title_box);
        #if WITH_EVOLUTION
        setup_events (header_content);
        #endif

        listbox = new Gtk.ListBox () {
            valign = Gtk.Align.START,
            activate_on_single_click = true,
            selection_mode = Gtk.SelectionMode.SINGLE,
            hexpand = true
        };
        listbox.add_css_class ("listbox-background");

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

        content.append (header_content);
        content.append (listbox_grid);

        main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            reveal_child = has_items,
            child = content
        };

        child = main_revealer;

        setup_listbox ();
        setup_item_signals ();
        add_items ();

        signal_map[Services.EventBus.get_default ().day_changed.connect (() => {
            date = new GLib.DateTime.now_local ();
            add_items ();
        })] = Services.EventBus.get_default ();

        signal_map[Services.EventBus.get_default ().item_moved.connect ((item, old_project_id, old_section_id, old_parent_id) => {
            if (items.has_key (item.id)) {
                if (!Services.Store.instance ().valid_item_by_overdue (item, date, false)) {
                    items[item.id].hide_destroy ();
                    items.unset (item.id);
                    Services.EventBus.get_default ().unfocus_item ();
                }
            }

            if (!items.has_key (item.id) &&
            Services.Store.instance ().valid_item_by_overdue (item, date, false)) {
                add_item (item);
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
            header_content.sensitive = !active;
        })] = Services.EventBus.get_default ();
    }

    protected override void add_items () {
        items.clear ();

        foreach (unowned Gtk.Widget child in Util.get_default ().get_children (listbox)) {
            listbox.remove (child);
        }

        foreach (Objects.Item item in Services.Store.instance ().get_items_by_overdeue_view (false)) {
            add_item (item);
        }

        main_revealer.reveal_child = has_items;
    }

    protected override bool valid_item_predicate (Objects.Item item) {
        return Services.Store.instance ().valid_item_by_overdue (item, date, false);
    }

    protected override void valid_add_item (Objects.Item item) {
        if (!items.has_key (item.id) && valid_item_predicate (item)) {
            add_item (item);
        }

        listbox.invalidate_filter ();
        main_revealer.reveal_child = has_items;
    }

    protected override void valid_delete_item (Objects.Item item) {
        if (items.has_key (item.id)) {
            items[item.id].hide_destroy ();
            items.unset (item.id);
        }

        listbox.invalidate_filter ();
        main_revealer.reveal_child = has_items;
    }

    protected override void valid_update_item (Objects.Item item, string? update_id = null) {
        if (items.has_key (item.id)) {
            items[item.id].update_request ();
        }

        if (items.has_key (item.id) && !item.has_due) {
            items[item.id].hide_destroy ();
            items.unset (item.id);
            Services.EventBus.get_default ().unfocus_item ();
        }

        if (items.has_key (item.id) && item.has_due) {
            if (!Services.Store.instance ().valid_item_by_overdue (item, date, false)) {
                items[item.id].hide_destroy ();
                items.unset (item.id);
                Services.EventBus.get_default ().unfocus_item ();
            }
        }

        if (item.has_due) {
            valid_add_item (item);
        }

        listbox.invalidate_filter ();
        main_revealer.reveal_child = has_items;
    }
}
