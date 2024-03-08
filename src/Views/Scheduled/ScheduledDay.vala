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

    private Gee.HashMap <string, Layouts.ItemRow> items;

    private bool has_items {
        get {
            return items.size > 0;
        }
    }

    public ScheduledDay (GLib.DateTime date) {
        Object (
            date: date
        );
    }

    construct {
        add_css_class ("no-selectable");
        add_css_class ("transition");

        items = new Gee.HashMap <string, Layouts.ItemRow> ();

        var day_label = new Gtk.Label (date.format ("%a").up (1) + date.format ("%a").substring (1)) {
            halign = Gtk.Align.START
        };
        day_label.add_css_class ("font-bold");

        var date_format_label = new Gtk.Label (
            Util.get_default ().get_default_date_format_from_date (date)
        ) {
            halign = Gtk.Align.START
        };

        date_format_label.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);

        var title_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            hexpand = true,
            margin_start = 24
        };

        title_box.append (day_label);
        title_box.append (date_format_label);

        event_list = new Widgets.EventsList.for_day (date) {
            hexpand = true,
            valign = Gtk.Align.START,
            margin_top = 6,
            margin_start = 24
        };

        event_list_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            reveal_child = event_list.has_items,
            child = event_list
        };
        
        event_list.change.connect (() => {
            event_list_revealer.reveal_child = event_list.has_items;
        });

        listbox = new Gtk.ListBox () {
            valign = Gtk.Align.START,
            activate_on_single_click = true,
            selection_mode = Gtk.SelectionMode.SINGLE,
            hexpand = true
        };

        listbox.add_css_class ("listbox-background");

        var listbox_grid = new Gtk.Grid () {
            margin_top = 6
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
            margin_bottom = 32
        };

        content.append (title_box);
        content.append (new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
            margin_top = 6,
            margin_bottom = 3,
            margin_start = 24
        });
        
        content.append (event_list_revealer);
        content.append (listbox_revealer);

        child = content;

        add_items ();

        Timeout.add (listbox_revealer.transition_duration, () => {
            listbox_revealer.reveal_child = has_items;
            return GLib.Source.REMOVE;
        });

        Services.Database.get_default ().item_added.connect (valid_add_item);
        Services.Database.get_default ().item_deleted.connect (valid_delete_item);
        Services.Database.get_default ().item_updated.connect (valid_update_item);

        Services.EventBus.get_default ().item_moved.connect ((item) => {
            if (items.has_key (item.id)) {
                items[item.id].update_request ();
            }
        });
    }

    private void add_items () {
        foreach (Objects.Item item in Services.Database.get_default ().get_items_by_date (date, false)) {
            add_item (item);
        }
    }

    private void add_item (Objects.Item item) {
        if (!items.has_key (item.id)) {
            items [item.id] = new Layouts.ItemRow (item) {
                show_project_label = true
            };
            items [item.id].disable_drag_and_drop ();
            listbox.append (items [item.id]);
        }
    }

    private void valid_add_item (Objects.Item item) {
        if (!items.has_key (item.id) &&
            Services.Database.get_default ().valid_item_by_date (item, date, false)) {
            items [item.id] = new Layouts.ItemRow (item) {
                show_project_label = true
            };
            items [item.id].disable_drag_and_drop ();
            listbox.append (items [item.id]);
        }

        listbox_revealer.reveal_child = has_items;
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
            if (!Services.Database.get_default ().valid_item_by_date (item, date, false)) {
                items[item.id].hide_destroy ();
                items.unset (item.id);
            }
        }

        if (item.has_due) {
            valid_add_item (item);
        }

        listbox_revealer.reveal_child = has_items;
    }
}
