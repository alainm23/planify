/*
* Copyright © 2019 Alain M. (https://github.com/alainm23/planner)
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

public class Widgets.EventsList : Gtk.EventBox {
    public GLib.DateTime date { get; set; }
    public bool is_today_view { get; construct; }

    private Gtk.ListBox listbox;
    private Gtk.Revealer main_revealer;

    private Gee.HashMap<string, Widgets.EventRow> event_hashmap;
    private uint update_events_idle_source = 0;

    public EventsList (bool is_today_view = false) {
        Object (
            is_today_view: is_today_view
        );
    }

    construct {
        listbox = new Gtk.ListBox () {
            valign = Gtk.Align.START,
            activate_on_single_click = true,
            selection_mode = Gtk.SelectionMode.SINGLE
        };

        listbox.set_sort_func (sort_event_function);

        unowned Gtk.StyleContext listbox_context = listbox.get_style_context ();
        listbox_context.add_class ("listbox-background");

        var listbox_grid = new Gtk.Grid () {
            valign = Gtk.Align.START
        };
        listbox_grid.add (listbox);

        var main_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            hexpand = true,
            margin_start = 6,
            margin_bottom = 6
        };

        main_grid.add (listbox_grid);

        main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };
        main_revealer.add (main_grid);
        
        add (main_revealer);

        Timeout.add (main_revealer.transition_duration, () => {
            main_revealer.reveal_child = Planner.settings.get_boolean ("calendar-enabled");
            return GLib.Source.REMOVE;
        });

        event_hashmap = new Gee.HashMap<string, Widgets.EventRow> ();
        Services.CalendarEvents.get_default ().components_added.connect (add_event_model);
        Services.CalendarEvents.get_default ().components_removed.connect (remove_event_model);

        if (is_today_view) {
            date = new GLib.DateTime.now_local ();
        }

        Planner.settings.changed.connect ((key) => {
            if (key == "calendar-enabled") {
                main_revealer.reveal_child = Planner.settings.get_boolean ("calendar-enabled");
            }
        });

        notify ["date"].connect (() => {
            if (date != null) {
                if (!is_today_view) {
                    main_revealer.reveal_child = Planner.settings.get_boolean ("calendar-enabled");
                    event_hashmap.clear ();

                    foreach (unowned Gtk.Widget child in listbox.get_children ()) {
                        child.destroy ();
                    }
                }

                Services.CalendarEvents.get_default ().month_start = CalendarEventsUtil.get_start_of_month (date);
                idle_update_events ();

                Timeout.add (main_revealer.transition_duration, () => {
                    main_revealer.reveal_child = Planner.settings.get_boolean ("calendar-enabled");
                    return GLib.Source.REMOVE;
                });
            }
        });
    }

    private void add_event_model (E.Source source, Gee.Collection<ECal.Component> events) {
        foreach (var component in events) {
            if (CalendarEventsUtil.calcomp_is_on_day (component, date)) {
                unowned ICal.Component ical = component.get_icalcomponent ();

                var event_uid = ical.get_uid ();
                if (!event_hashmap.has_key (event_uid)) {
                    event_hashmap[event_uid] = new Widgets.EventRow (date, ical, source);
                    listbox.add (event_hashmap[event_uid]);
                }
            }
        }

        listbox.show_all ();
    }

    private void idle_update_events () {
        if (update_events_idle_source > 0) {
            GLib.Source.remove (update_events_idle_source);
        }

        update_events_idle_source = GLib.Idle.add (update_events);
    }

    private void remove_event_model (E.Source source, Gee.Collection<ECal.Component> events) {
        foreach (var component in events) {
            unowned ICal.Component ical = component.get_icalcomponent ();
            var event_uid = ical.get_uid ();
            var event_row = event_hashmap[event_uid];
            if (event_row != null) {
                event_row.destroy ();
                event_hashmap.unset (event_uid);
            }
        }
    }

    private bool update_events () {
        Services.CalendarEvents.get_default ().source_components.@foreach ((source, component_map) => {
            foreach (var comp in component_map.get_values ()) {
                if (CalendarEventsUtil.calcomp_is_on_day (comp, date)) {
                    unowned ICal.Component ical = comp.get_icalcomponent ();
                    var event_uid = ical.get_uid ();
                    if (!event_hashmap.has_key (event_uid)) {
                        event_hashmap[event_uid] = new Widgets.EventRow (date, ical, source);
                        listbox.add (event_hashmap[event_uid]);
                    }
                }
            }
        });

        listbox.show_all ();
        update_events_idle_source = 0;
        return GLib.Source.REMOVE;
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
}