//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

namespace Maya.Util {
    /* Iterator of DateRange objects */
    public class DateIterator : Object, Gee.Traversable<DateTime>, Gee.Iterator<DateTime> {
        DateTime current;
        DateRange range;

        public bool valid { get {return true;} }
        public bool read_only { get {return false;} }

        public DateIterator (DateRange range) {
            this.range = range;
            this.current = range.first_dt.add_days (-1);
        }

        public bool @foreach (Gee.ForallFunc<DateTime> f) {
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
            if (! has_next ())
                return false;
            current = this.current.add_days (1);
            return true;
        }

        public bool has_next() {
            return current.compare(range.last_dt) < 0;
        }

        public bool first () {
            current = range.first_dt;
            return true;
        }

        public new DateTime get () {
            return current;
        }

        public void remove() {
            assert_not_reached();
        }
    }

    /* Represents date range from 'first' to 'last' inclusive */
    public class DateRange : Object, Gee.Traversable<DateTime>, Gee.Iterable<DateTime> {
        public DateTime first_dt { get; private set; }
        public DateTime last_dt { get; private set; }
        public bool @foreach (Gee.ForallFunc<DateTime> f) {
            foreach (var date in this) {
                if (f (date) == false) {
                    return false;
                }
            }

            return true;
        }

        public int64 days {
            get { return last_dt.difference (first_dt) / GLib.TimeSpan.DAY; }
        }

        public DateRange (DateTime first, DateTime last) {
            this.first_dt = first;
            this.last_dt = last;
        }

        public DateRange.copy (DateRange date_range) {
            this (date_range.first_dt, date_range.last_dt);
        }

        public bool equals (DateRange other) {
            return (this.first_dt==other.first_dt && this.last_dt==other.last_dt);
        }

        public Type element_type {
            get { return typeof(DateTime); }
        }

        public Gee.Iterator<DateTime> iterator () {
            return new DateIterator (this);
        }

        public bool contains (DateTime time) {
            return (first_dt.compare (time) < 1) && (last_dt.compare (time) > -1);
        }

        public Gee.SortedSet<DateTime> to_set() {

            var @set = new Gee.TreeSet<DateTime> ((GLib.CompareDataFunc<GLib.DateTime>?) DateTime.compare);

            foreach (var date in this)
                set.add (date);

            return @set;
        }

        public Gee.List<DateTime> to_list () {
            var list = new Gee.ArrayList<DateTime> ((Gee.EqualDataFunc<GLib.DateTime>?) datetime_equal_func);
            foreach (var date in this)
                list.add (date);

            return list;
        }
    }
}
