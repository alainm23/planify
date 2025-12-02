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
        debug ("Destroying Widgets.EventsList\n");
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
        signal_map[event_model.components_updated.connect (update_event_model)] = event_model;
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
            } else if (is_range) {
                if (event_overlaps_range (component)) {
                    add_row_event (component, source);
                }
            }
        }
    }

    private void add_row_event (ECal.Component component, E.Source source) {
        unowned ICal.Component ical = component.get_icalcomponent ();
        var event_uid = ical.get_uid ();
        if (!event_hashmap.has_key (event_uid)) {
            bool show_date = is_month || is_range;
            event_hashmap[event_uid] = new Widgets.EventRow (ical, source, show_date);
            listbox.append (event_hashmap[event_uid]);
        }

        change ();
    }

    private void update_event_model (E.Source source, Gee.Collection<ECal.Component> components) {
        foreach (var component in components) {
            unowned ICal.Component ical = component.get_icalcomponent ();
            var event_uid = ical.get_uid ();
            bool in_range = false;

            if (is_day) {
                in_range = CalendarEventsUtil.calcomp_is_on_day (component, start_date);
            } else if (is_month) {
                in_range = CalendarEventsUtil.calcomp_is_on_month (component, start_date);
            } else if (is_range) {
                in_range = event_overlaps_range (component);
            }

            if (event_hashmap.has_key (event_uid)) {
                if (in_range) {
                    event_hashmap[event_uid].update (ical);
                } else {
                    event_hashmap[event_uid].destroy ();
                    listbox.remove (event_hashmap[event_uid]);
                    event_hashmap.unset (event_uid);
                }
            } else if (in_range) {
                add_row_event (component, source);
            }
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

    private bool event_overlaps_range (ECal.Component component) {
        unowned ICal.Component ical = component.get_icalcomponent ();
        ICal.Time ? start_time = ical.get_dtstart ();
        ICal.Time ? end_time = ical.get_dtend ();
        ICal.Time ? due_time = ical.get_due ();
        
        if (due_time != null && !due_time.is_null_time ()) {
            end_time = due_time;
            if (start_time == null || start_time.is_null_time ()) {
                start_time = due_time;
            }
        }
        
        if (start_time == null || end_time == null) {
            return false;
        }
        
        var event_start = CalendarEventsUtil.ical_to_date_time (start_time);
        var event_end = CalendarEventsUtil.ical_to_date_time (end_time);
        
        // Check if event overlaps with our date range
        return !(event_end.compare (start_date) < 0 || event_start.compare (end_date.add_days (1)) >= 0);
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
