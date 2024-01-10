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

public class Views.Scheduled.ScheduledRange : Gtk.ListBoxRow {
    public GLib.DateTime start_date { get; construct; }
    public GLib.DateTime end_date { get; construct; }

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

    public ScheduledRange (GLib.DateTime start_date, GLib.DateTime end_date) {
        Object (
            start_date: start_date,
            end_date: end_date
        );
    }

    construct {
        add_css_class ("selectable-item");
        add_css_class ("transition");

        items = new Gee.HashMap <string, Layouts.ItemRow> ();

        var month_label = new Gtk.Label (start_date.format ("%B").up (1) + start_date.format ("%B").substring (1)) {
            halign = Gtk.Align.START
        };

        month_label.add_css_class ("font-bold");

        var date_range_label = new Gtk.Label ("%s - %s".printf (start_date.format ("%d"), end_date.format ("%d"))) {
            halign = Gtk.Align.START
        };

        date_range_label.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);

        var title_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            hexpand = true,
            margin_start = 24
        };

        title_box.append (month_label);
        title_box.append (date_range_label);

        event_list = new Widgets.EventsList.for_range (start_date, end_date) {
            hexpand = true,
            valign = Gtk.Align.START,
            margin_top = 6,
            margin_start = 24
        };

        event_list_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            reveal_child = event_list.has_items
        };

        event_list_revealer.child = event_list;
        
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
        content.append (listbox_grid);

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
            if (items.has_key (item.id_string)) {
                items[item.id_string].update_request ();
            }
        });
    }

    private void add_items () {
        foreach (Objects.Item item in Services.Database.get_default ().get_items_by_date_range (start_date, end_date, false)) {
            add_item (item);
        }
    }

    private void add_item (Objects.Item item) {
        items [item.id_string] = new Layouts.ItemRow (item) {
            show_project_label = true
        };
        listbox.append (items [item.id_string]);
    }

    private void valid_add_item (Objects.Item item) {
        if (!items.has_key (item.id_string) &&
            Services.Database.get_default ().valid_item_by_date_range (item, start_date, end_date, false)) {
            items [item.id_string] = new Layouts.ItemRow (item) {
                show_project_label = true
            };
            listbox.append (items [item.id_string]);
        }

        listbox_revealer.reveal_child = has_items;
    }

    private void valid_delete_item (Objects.Item item) {
        if (items.has_key (item.id_string)) {
            items[item.id_string].hide_destroy ();
            items.unset (item.id_string);
        }

        listbox_revealer.reveal_child = has_items;
    }

    private void valid_update_item (Objects.Item item) {
        if (items.has_key (item.id_string)) {
            items[item.id_string].update_request ();
        }

        if (items.has_key (item.id_string) && !item.has_due) {
            items[item.id_string].hide_destroy ();
            items.unset (item.id_string);
        }


        if (items.has_key (item.id_string) && item.has_due) {
            if (!Services.Database.get_default ().valid_item_by_date_range (item, start_date, end_date, false)) {
                items[item.id_string].hide_destroy ();
                items.unset (item.id_string);
            }
        }

        if (item.has_due) {
            valid_add_item (item);
        }

        listbox_revealer.reveal_child = has_items;
    }
}