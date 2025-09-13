/*
 * Copyright 2011-2018 elementary, Inc. (https://elementary.io)
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
 *
 * Authored by: Corentin Noël <corentin@elementaryos.org>
 */

#if WITH_EVOLUTION
public class CalendarEventsUtil.DateIterator : Object, Gee.Traversable<GLib.DateTime>, Gee.Iterator<GLib.DateTime> {
    public GLib.DateTime current { get; construct set; }
    public CalendarEventsUtil.DateRange range { get; construct; }

    // Required by Gee.Iterator
    public bool valid {
        get {
            return true;
        }
    }

    // Required by Gee.Iterator
    public bool read_only {
        get {
            return false;
        }
    }

    public DateIterator (CalendarEventsUtil.DateRange range) {
        Object (
            range: range,
            current: range.first_dt.add_days (-1)
        );
    }

    public bool @foreach (Gee.ForallFunc<GLib.DateTime> f) {
        var element = range.first_dt;

        while (element.compare (range.last_dt) < 0) {
            if (f (element) == false) {
                return false;
            }

            element = element.add_days (1);
        }

        return true;
    }

    public bool next () {
        if (!has_next ()) {
            return false;
        }

        current = this.current.add_days (1);

        return true;
    }

    public bool has_next () {
        return current.compare (range.last_dt) < 0;
    }

    public new GLib.DateTime get () {
        return current;
    }

    public void remove () {
        assert_not_reached ();
    }
#else
public class CalendarEventsUtil.DateIterator : Object {
#endif
}
