/*
 * Copyright (c) 2011-2016 elementary LLC. (https://elementary.io)
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA.
 */

/*
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

public class Event : GLib.Object {
    public GLib.DateTime date;
    Util.DateRange range;
    public string summary;
    public bool day_event = false;
    public bool alarm = false;
    public GLib.DateTime start_time;
    public GLib.DateTime end_time;

    public Event (GLib.DateTime date, Util.DateRange range, iCal.Component comp) {
        this.date = date;
        this.range = range;
        this.summary = comp.get_summary ();

        Util.get_local_datetimes_from_icalcomponent (comp, out start_time, out end_time);
        if (end_time == null) {
            alarm = true;
        } else if (Util.is_the_all_day (start_time, end_time)) {
            day_event = true;
            return;
        }
    }

    public string get_label () {
        if (day_event) {
            return summary;
        } else if (alarm) {
            return "%s - %s".printf (start_time.format (Util.TimeFormat ()), summary);
        } else if (range.days > 0 && date.compare (range.first_dt) != 0) {
            return summary;
        }
        return "%s - %s".printf (summary, start_time.format (Util.TimeFormat ()));
    }

    public string get_icon () {
        if (alarm) {
            return "alarm-symbolic";
        }
        return "office-calendar-symbolic";
    }
}

public class CalendarModel : Object {
    /* The data_range is the range of dates for which this model is storing
     * data. The month_range is a subset of this range corresponding to the
     * calendar month that is being focused on. In summary:
     *
     * data_range.first <= month_range.first < month_range.last <= data_range.last
     *
     * There is no way to set the ranges publicly. They can only be modified by
     * changing one of the following properties: month_start, num_weeks, and
     * week_starts_on.
     */
    public Util.DateRange data_range { get; private set; }
    public Util.DateRange month_range { get; private set; }
    public E.SourceRegistry registry { get; private set; }

    /* The first day of the month */
    public GLib.DateTime month_start { get; set; }

    /* The number of weeks to show in this model */
    public int num_weeks { get; private set; default = 6; }

    /* The start of week, ie. Monday=1 or Sunday=7 */
    public Weekday week_starts_on { get; set; }

    /* Notifies when events are added, updated, or removed */
    public signal void events_added (E.Source source, Gee.Collection<E.CalComponent> events);
    public signal void events_updated (E.Source source, Gee.Collection<E.CalComponent> events);
    public signal void events_removed (E.Source source, Gee.Collection<E.CalComponent> events);

    public signal void connecting (E.Source source, Cancellable cancellable);
    public signal void connected (E.Source source);
    public signal void error_received (string error);

    /* The month_start, num_weeks, or week_starts_on have been changed */
    public signal void parameters_changed ();

    HashTable<string, E.CalClient> source_client;
    HashTable<string, E.CalClientView> source_view;
    HashTable<E.Source, Gee.TreeMap<string, E.CalComponent> > source_events;

    private static CalendarModel? calendar_model = null;
        public enum Weekday {
            SUNDAY,
            MONDAY,
            TUESDAY,
            WEDNESDAY,
            THURSDAY,
            FRIDAY,
            SATURDAY
        }

    public static CalendarModel get_default () {
        lock (calendar_model) {
            if (calendar_model == null) {
                calendar_model = new CalendarModel ();
            }
        }

        return calendar_model;
    }

    construct {
        source_client = new HashTable<string, E.CalClient> (str_hash, str_equal);
        source_events = new HashTable<E.Source, Gee.TreeMap<string, E.CalComponent> > (Util.source_hash_func, Util.source_equal_func);
        source_view = new HashTable<string, E.CalClientView> (str_hash, str_equal);

        int week_start = Posix.NLTime.FIRST_WEEKDAY.to_string ().data[0];
        if (week_start >= 1 && week_start <= 7) {
            week_starts_on = (Weekday) (week_start - 1);
        }

        month_start = Util.get_start_of_month ();
        compute_ranges ();
        notify["month-start"].connect (on_parameter_changed);
    }

    private CalendarModel () {
        open.begin ();
    }

    public async void open () {
        try {
            registry = yield new E.SourceRegistry (null);
            registry.source_removed.connect (remove_source);
            registry.source_changed.connect (on_source_changed);
            registry.source_added.connect ((source) => add_source_async.begin (source));

            // Add sources
            registry.list_sources (E.SOURCE_EXTENSION_CALENDAR).foreach ((source) => {
                E.SourceCalendar cal = (E.SourceCalendar)source.get_extension (E.SOURCE_EXTENSION_CALENDAR);

                if (cal.selected == true && source.enabled == true) {
                    add_source_async.begin (source);
                }
            });

            load_all_sources ();
            parameters_changed ();
        } catch (GLib.Error error) {
            critical (error.message);
        }
    }

    /* --- Public Methods ---// */

    public Gee.ArrayList<Event> get_events (GLib.DateTime date) {
        var events_on_day = new Gee.TreeMap<string,Event> ();

        foreach (var entry in source_events.get_values ()) {
            foreach (var comp in entry.values) {
                unowned iCal.Component ical = comp.get_icalcomponent ();
                foreach (var dt_range in Util.event_date_ranges (ical, data_range)) {
                    if (dt_range.contains (date)) {
                        if (!events_on_day.has_key (ical.get_uid ())) {
                            events_on_day.set (ical.get_uid (), new Event (date, dt_range, ical));
                        }
                    }
                }
            }
        }

        var list = new Gee.ArrayList<Event>.wrap (events_on_day.values.to_array ());
        list.sort (sort_events);

        return list;
    }

    public int sort_events (Event e1, Event e2) {
        if (e1.start_time.compare (e2.start_time) != 0)
            return e1.start_time.compare(e2.start_time);

        // If they have the same date, sort them wholeday first
        if (e1.day_event)
            return -1;
        if (e2.day_event)
            return 1;
        return 0;
    }

    public bool calclient_is_readonly (E.Source source) {
        E.CalClient client;
        lock (source_client) {
            client = source_client.get (source.dup_uid ());
        }

        if (client != null) {
            return client.is_readonly ();
        } else {
            critical ("No calendar client was found");
        }

        return true;
    }

    public void load_all_sources () {
        lock (source_client) {
        foreach (var id in source_client.get_keys ()) {
            var source = registry.ref_source (id);
            E.SourceCalendar cal = (E.SourceCalendar)source.get_extension (E.SOURCE_EXTENSION_CALENDAR);

            if (cal.selected == true && source.enabled == true) {
                load_source (source);
            }
            }
        }
    }

    public void remove_source (E.Source source) {
        debug ("Removing source '%s'", source.dup_display_name ());
        /* Already out of the model, so do nothing */
        var uid = source.dup_uid ();

        if (!source_view.contains (uid)) {
            return;
        }

        var current_view = source_view.get (uid);
        try {
            current_view.stop ();
        } catch (Error e) {
            warning (e.message);
        }

        source_view.remove (uid);
        lock (source_client) {
            source_client.remove (uid);
        }

        var events = source_events.get (source).values.read_only_view;
        events_removed (source, events);
        source_events.remove (source);
    }

    public void change_month (int relative) {
        month_start = month_start.add_months (relative);
    }

    public void change_year (int relative) {
        month_start = month_start.add_years (relative);
    }

    /* --- Helper Methods ---// */

    private void compute_ranges () {
        var month_end = month_start.add_full (0, 1, -1);
        month_range = new Util.DateRange (month_start, month_end);

        int dow = month_start.get_day_of_week ();
        int wso = (int)week_starts_on;
        int offset = 0;

        if (wso < dow) {
            offset = dow - wso;
        } else if (wso > dow) {
            offset = 7 + dow - wso;
        }

        var data_range_first = month_start.add_days (-offset);

        dow = month_end.get_day_of_week ();
        wso = (int)(week_starts_on + 6);

        /* WSO must be between 1 and 7 */
        if (wso > 7) {
            wso = wso - 7;
        }

        offset = 0;

        if (wso < dow) {
            offset = 7 + wso - dow;
        } else if (wso > dow) {
            offset = wso - dow;
        }

        var data_range_last = month_end.add_days (offset);

        data_range = new Util.DateRange (data_range_first, data_range_last);
        num_weeks = data_range.to_list ().size / 7;

        debug (@"Date ranges: ($data_range_first <= $month_start < $month_end <= $data_range_last)");
    }

    private void load_source (E.Source source) {
        /* create empty source-event map */
        var events = new Gee.TreeMap<string, E.CalComponent> (
            (GLib.CompareDataFunc<E.CalComponent> ? )GLib.strcmp,
            (Gee.EqualDataFunc<E.CalComponent>? )Util.calcomponent_equal_func);
        source_events.set (source, events);
        /* query client view */
        var iso_first = E.Util.isodate_from_time_t ((time_t)data_range.first_dt.to_unix ());
        var iso_last = E.Util.isodate_from_time_t ((time_t)data_range.last_dt.add_days (1).to_unix ());
        var query = @"(occur-in-time-range? (make-time \"$iso_first\") (make-time \"$iso_last\"))";

        E.CalClient client;
        lock (source_client) {
            client = source_client.get (source.dup_uid ());
        }

        if (client == null) {
            return;
        }

        debug ("Getting client-view for source '%s'", source.dup_display_name ());
        client.get_view.begin (query, null, (obj, results) => {
            var view = on_client_view_received (results, source, client);
            view.objects_added.connect ((objects) => on_objects_added (source, client, objects));
            view.objects_removed.connect ((objects) => on_objects_removed (source, client, objects));
            view.objects_modified.connect ((objects) => on_objects_modified (source, client, objects));
            try {
                view.start ();
            } catch (Error e) {
                critical (e.message);
            }

            source_view.set (source.dup_uid (), view);
        });
    }

    private async void add_source_async (E.Source source) {
        debug ("Adding source '%s'", source.dup_display_name ());
        try {
            var cancellable = new GLib.Cancellable ();
            connecting (source, cancellable);
            var client = new E.CalClient.connect_sync (source, E.CalClientSourceType.EVENTS, -1, cancellable);
            source_client.insert (source.dup_uid (), client);
        } catch (Error e) {
            error_received (e.message);
        }

        Idle.add (() => {
            connected (source);
            load_source (source);
                return false;
        });
    }

    private void debug_event (E.Source source, E.CalComponent event) {
        unowned iCal.Component comp = event.get_icalcomponent ();
        debug (@"Event ['$(comp.get_summary())', $(source.dup_display_name()), $(comp.get_uid()))]");
    }

    /* --- Signal Handlers ---// */
    private void on_parameter_changed () {
        compute_ranges ();
        load_all_sources ();
        parameters_changed ();
    }

    private void on_source_changed (E.Source source) {
    }

    private E.CalClientView on_client_view_received (AsyncResult results, E.Source source, E.CalClient client) {
        E.CalClientView view;
        try {
            debug (@"Received client-view for source '%s'", source.dup_display_name ());
            bool status = client.get_view.end (results, out view);
            assert (status == true);
        } catch (Error e) {
            critical ("Error loading client-view from source '%s': %s", source.dup_display_name (), e.message);
        }

        return view;
    }

    private void on_objects_added (E.Source source, E.CalClient client, SList<unowned iCal.Component> objects) {
        debug (@"Received $(objects.length()) added event(s) for source '%s'", source.dup_display_name ());
        var events_from_source = source_events.get (source);
        var added_events = new Gee.ArrayList<E.CalComponent> ((Gee.EqualDataFunc<E.CalComponent>? )Util.calcomponent_equal_func);

        foreach (unowned iCal.Component comp in objects) {
            var event = new E.CalComponent ();
            event.set_icalcomponent (new iCal.Component.clone (comp));
            string uid = comp.get_uid ();
            debug_event (source, event);
            events_from_source.set (uid, event);
            added_events.add (event);
        }

        events_added (source, added_events.read_only_view);
    }

    private void on_objects_modified (E.Source source, E.CalClient client, SList<unowned iCal.Component> objects) {
        debug (@"Received $(objects.length()) modified event(s) for source '%s'", source.dup_display_name ());
        var updated_events = new Gee.ArrayList<E.CalComponent> ((Gee.EqualDataFunc<E.CalComponent>? )Util.calcomponent_equal_func);

        foreach (unowned iCal.Component comp in objects) {
            string uid = comp.get_uid ();
            E.CalComponent event = source_events.get (source).get (uid);
            event.set_icalcomponent (new iCal.Component.clone (comp));
            updated_events.add (event);
            debug_event (source, event);
        }

        events_updated (source, updated_events.read_only_view);
    }

    private void on_objects_removed (E.Source source, E.CalClient client, SList<unowned E.CalComponentId? > cids) {
        debug (@"Received $(cids.length()) removed event(s) for source '%s'", source.dup_display_name ());
        var events_from_source = source_events.get (source);
        var removed_events = new Gee.ArrayList<E.CalComponent> ((Gee.EqualDataFunc<E.CalComponent>? )Util.calcomponent_equal_func);

        foreach (unowned E.CalComponentId? cid in cids) {
            assert (cid != null);
            E.CalComponent event = events_from_source.get (cid.uid);
            removed_events.add (event);
            debug_event (source, event);
        }

        events_removed (source, removed_events.read_only_view);
    }
}
