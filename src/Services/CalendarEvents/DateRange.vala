/*
 * Copyright 2011-2019 elementary, Inc. (https://elementary.io)
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

/* Represents date range from 'first' to 'last' inclusive */

#if WITH_EVOLUTION
public class CalendarEventsUtil.DateRange : Object, Gee.Traversable<GLib.DateTime>, Gee.Iterable<GLib.DateTime> {
    public GLib.DateTime first_dt { get; construct; }
    public GLib.DateTime last_dt { get; construct; }

    public bool @foreach (Gee.ForallFunc<GLib.DateTime> f) {
        foreach (var date in this) {
            if (f (date) == false) {
                return false;
            }
        }

        return true;
    }

    public DateRange (GLib.DateTime first, GLib.DateTime last) {
        Object (
            first_dt: first,
            last_dt: last
        );
    }

    public bool equals (DateRange other) {
        return (first_dt == other.first_dt && last_dt == other.last_dt);
    }

    public Gee.Iterator<GLib.DateTime> iterator () {
        return new DateIterator (this);
        
    }

    public Gee.List<GLib.DateTime> to_list () {
        var list = new Gee.ArrayList<GLib.DateTime> ((Gee.EqualDataFunc<GLib.DateTime> ?) datetime_equal_func);

        foreach (var date in this) {
            list.add (date);
        }

        return list;
    }

    /* Returns true if 'a' and 'b' are the same GLib.DateTime */
    private bool datetime_equal_func (GLib.DateTime a, GLib.DateTime b) {
        return a.equal (b);
    }
#else
public class CalendarEventsUtil.DateRange : Object {
#endif
}
