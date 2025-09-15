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

public class Widgets.EventsList : Adw.Bin {
    public GLib.DateTime start_date { get; construct; }
    public GLib.DateTime end_date { get; construct; }

    public bool is_day { get; construct; }
    public bool is_month { get; construct; }
    public bool is_range { get; construct; }

    private Gtk.ListBox listbox;
    private Gtk.Revealer main_revealer;

    private Gee.HashMap<string, Widgets.EventRow> event_hashmap;
    private Services.CalendarEvents event_model;

    public signal void change ();

    public bool has_items {
        get {
            return event_hashmap.size > 0;
        }
    }

    private Gee.HashMap<ulong, weak GLib.Object> signal_map = new Gee.HashMap<ulong, weak GLib.Object> ();

    public EventsList.for_day (GLib.DateTime start_date) {
        Object (
            start_date: start_date,
            end_date: start_date,
            is_day: true,
            is_range: false,
            is_month: false
        );
    }

    public EventsList.for_range (GLib.DateTime start_date, GLib.DateTime end_date) {
        Object (
            start_date: start_date,
            end_date: end_date,
            is_day: false,
            is_range: true,
            is_month: false
        );
    }

    public EventsList.for_month (GLib.DateTime start_date) {
        Object (
            start_date: start_date,
            end_date: start_date,
            is_day: false,
            is_range: false,
            is_month: true
        );
    }

    ~EventsList () {
        print ("Destroying Widgets.EventsList\n");
    }

    construct {
        event_model = new Services.CalendarEvents (start_date);
        event_hashmap = new Gee.HashMap<string, Widgets.EventRow> ();

        listbox = new Gtk.ListBox () {
            valign = Gtk.Align.START,
            selection_mode = Gtk.SelectionMode.NONE
        };

        listbox.set_sort_func (sort_event_function);
        listbox.add_css_class ("listbox-background");

        var listbox_grid = new Gtk.Grid () {
            valign = Gtk.Align.START
        };

        listbox_grid.attach (listbox, 0, 0);

        var main_grid = new Gtk.Grid () {
            hexpand = true
        };

        main_grid.add_css_class ("description-box");
        main_grid.attach (listbox_grid, 0, 0);

        main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            reveal_child = Services.Settings.get_default ().settings.get_boolean ("calendar-enabled"),
            child = main_grid
        };

        child = main_revealer;
        add_events ();

        signal_map[Services.Settings.get_default ().settings.changed["calendar-enabled"].connect (() => {
            main_revealer.reveal_child = Services.Settings.get_default ().settings.get_boolean ("calendar-enabled");
        })] = Services.Settings.get_default ();
    }

    private void add_events () {
        signal_map[event_model.components_added.connect (add_event_model)] = event_model;
        signal_map[event_model.components_removed.connect (remove_event_model)] = event_model;
    }

    private void add_event_model (E.Source source, Gee.Collection<ECal.Component> components) {
        foreach (ECal.Component ? component in components) {
            if (is_day) {
                if (CalendarEventsUtil.calcomp_is_on_day (component, start_date)) {
                    add_row_event (component, source);
                }
            } else if (is_month) {
                if (CalendarEventsUtil.calcomp_is_on_month (component, start_date)) {
                    add_row_event (component, source);
                }
            }
        }
    }

    private void add_row_event (ECal.Component component, E.Source source) {
        unowned ICal.Component ical = component.get_icalcomponent ();
        var event_uid = ical.get_uid ();
        if (!event_hashmap.has_key (event_uid)) {
            event_hashmap[event_uid] = new Widgets.EventRow (ical, source);
            listbox.append (event_hashmap[event_uid]);
        }

        change ();
    }

    private void remove_event_model (E.Source source, Gee.Collection<ECal.Component> events) {
        foreach (var component in events) {
            unowned ICal.Component ical = component.get_icalcomponent ();
            var event_uid = ical.get_uid ();
            var event_row = event_hashmap[event_uid];
            if (event_row != null) {
                event_row.destroy ();
                event_hashmap.unset (event_uid);
                listbox.remove (event_row);
            }
        }

        change ();
    }

    private int sort_event_function (Gtk.ListBoxRow child1, Gtk.ListBoxRow child2) {
        var e1 = (Widgets.EventRow) child1;
        var e2 = (Widgets.EventRow) child2;

        if (e1.start_time.compare (e2.start_time) != 0) {
            return e1.start_time.compare (e2.start_time);
        }

        // If they have the same date, sort them wholeday first
        if (e1.is_allday) {
            return -1;
        } else if (e2.is_allday) {
            return 1;
        }

        return 0;
    }

    public void clean_up () {
        foreach (var row in Util.get_default ().get_children (listbox)) {
            ((Widgets.EventRow) row).clean_up ();
        }

        foreach (var entry in signal_map.entries) {
            entry.value.disconnect (entry.key);
        }

        signal_map.clear ();
    }
}
