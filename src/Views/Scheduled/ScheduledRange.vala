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

public class Views.Scheduled.ScheduledRange : Views.Scheduled.ScheduledSection {
    public GLib.DateTime start_date { get; construct; }
    public GLib.DateTime end_date { get; construct; }

    private Gtk.Box header_content;

    public ScheduledRange (GLib.DateTime start_date, GLib.DateTime end_date) {
        Object (
            start_date: start_date,
            end_date: end_date
        );
    }

    ~ScheduledRange () {
        debug ("Destroying - Views.Scheduled.ScheduledRange\n");
    }

    construct {
        add_css_class ("no-selectable");
        add_css_class ("transition");
        add_css_class ("no-padding");

        var month_label = new Gtk.Label (start_date.format ("%B")) {
            halign = Gtk.Align.START
        };
        month_label.add_css_class ("font-bold");

        var date_range_label = new Gtk.Label ("%s - %s".printf (start_date.format ("%d"), end_date.format ("%d"))) {
            halign = Gtk.Align.START
        };
        date_range_label.add_css_class ("dimmed");

        var title_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            hexpand = true
        };

        title_box.append (month_label);
        title_box.append (date_range_label);

        header_content = create_header (title_box);
        #if WITH_EVOLUTION
        setup_events (header_content);
        #endif

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
            reveal_child = has_items,
            child = listbox_grid
        };

        var content = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            hexpand = true,
            valign = Gtk.Align.START,
            margin_bottom = 32
        };

        content.append (header_content);
        content.append (listbox_revealer);

        child = content;

        Timeout.add (listbox_revealer.transition_duration, () => {
            listbox_revealer.reveal_child = has_items;
            return GLib.Source.REMOVE;
        });

        setup_listbox ();
        setup_item_signals ();
        add_items ();

        signal_map[Services.EventBus.get_default ().item_moved.connect ((item) => {
            if (items.has_key (item.id)) {
                items[item.id].update_request ();
            }
        })] = Services.EventBus.get_default ();

        signal_map[Services.EventBus.get_default ().dim_content.connect ((active, focused_item_id) => {
            header_content.sensitive = !active;
        })] = Services.EventBus.get_default ();

    }

    protected override void add_items () {
        foreach (Objects.Item item in Services.Store.instance ().get_items_by_date_range (start_date, end_date, false)) {
            add_item (item);
        }
    }

    protected override bool valid_item_predicate (Objects.Item item) {
        return Services.Store.instance ().valid_item_by_date_range (item, start_date, end_date, false);
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
            if (!Services.Store.instance ().valid_item_by_date_range (item, start_date, end_date, false)) {
                items[item.id].hide_destroy ();
                items.unset (item.id);
                Services.EventBus.get_default ().unfocus_item ();
            }
        }

        if (item.has_due) {
            valid_add_item (item);
        }

        listbox_revealer.reveal_child = has_items;
    }
}
