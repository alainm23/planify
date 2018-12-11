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

    public int compare_events (E.CalComponent comp1, E.CalComponent comp2) {

        var date1 = Util.ical_to_date_time (comp1.get_icalcomponent ().get_dtstart ());
        var date2 = Util.ical_to_date_time (comp2.get_icalcomponent ().get_dtstart ());

        if (date1.compare (date2) != 0)
            return date1.compare(date2);

        // If they have the same date, sort them alphabetically
        var summary1 = comp1.get_summary ();
        var summary2 = comp2.get_summary ();

        if (summary1.value < summary2.value)
            return -1;
        if (summary1.value > summary2.value)
            return 1;
        return 0;
    }

    //--- Date and Time ---//


    /**
     * Converts two datetimes to one TimeType. The first contains the date,
     * its time settings are ignored. The second one contains the time itself.
     * XXX: We need to convert to UTC because of some bugs with the Google backend…
     */
    public iCal.TimeType date_time_to_ical (DateTime date, DateTime? time_local, string? timezone = E.Util.get_system_timezone_location ()) {
        var result = iCal.TimeType.from_day_of_year (date.get_day_of_year (), date.get_year ());
        if (time_local != null) {
            unowned iCal.Array<unowned iCal.TimeZone> tzs = iCal.TimeZone.get_builtin_timezones ();
            for (int i = 0; i<tzs.num_elements; i++) {
                unowned iCal.TimeZone tz = tzs.element_at (i);
                if (tz.get_display_name () == timezone) {
                    result.zone = tz;
                    break;
                }
            }

            result.is_date = 0;
            result.hour = time_local.get_hour ();
            result.minute = time_local.get_minute ();
            result.second = time_local.get_second ();
        } else {
            result.is_date = 1;
            result.hour = 0;
            result.minute = 0;
            result.second = 0;
        }

        return result;
    }

    /**
     * Converts the given TimeType to a DateTime.
     */
    private TimeZone timezone_from_ical (iCal.TimeType date) {
        var interval = date.zone.get_utc_offset (date, date.is_daylight);
        var hours = (interval / 3600);
        string hour_string = "-";
        if (hours >= 0) {
            hour_string = "+";
        }

        hours = hours.abs();
        if (hours > 9) {
            hour_string = "%s%d".printf (hour_string, hours);
        } else {
            hour_string = "%s0%d".printf (hour_string, hours);
        }

        var minutes = (interval.abs () % 3600)/60;
        if (minutes > 9) {
            hour_string = "%s:%d".printf (hour_string, minutes);
        } else {
            hour_string = "%s:0%d".printf (hour_string, minutes);
        }

        return new TimeZone (hour_string);
    }

    /**
     * Converts the given TimeType to a DateTime.
     * XXX : Track next versions of evolution in order to convert iCal.Timezone to GLib.TimeZone with a dedicated function…
     */
    public DateTime ical_to_date_time (iCal.TimeType date) {
        return new DateTime (timezone_from_ical (date), date.year, date.month,
            date.day, date.hour, date.minute, date.second);
    }

    public void get_local_datetimes_from_icalcomponent (iCal.Component comp, out DateTime start_date, out DateTime end_date) {
        iCal.TimeType dt_start = comp.get_dtstart ();
        iCal.TimeType dt_end = comp.get_dtend ();
        start_date = Util.ical_to_date_time (dt_start);

        if (dt_end.is_null_time () == 0) {
            end_date = Util.ical_to_date_time (dt_end);
        } else if (dt_start.is_it_date () == 0) {
            end_date = start_date;
        } else if (comp.get_duration ().is_null_duration () == 0) {
            end_date = Util.ical_to_date_time (dt_start.add (comp.get_duration ()));
        } else {
            end_date = start_date.add_days (1);
        }

        if (is_all_day (start_date, end_date)) {
            end_date = end_date.add_days (-1);
        }
    }

    public bool is_event_in_range (iCal.Component comp, Util.DateRange view_range) {
        DateTime start, end;
        get_local_datetimes_from_icalcomponent (comp, out start, out end);

        int c1 = start.compare (view_range.first_dt);
        int c2 = start.compare (view_range.last_dt);
        int c3 = end.compare (view_range.first_dt);
        int c4 = end.compare (view_range.last_dt);

        if (c1 <= 0 && c3 > 0) {
            return true;
        }
        if (c2 < 0 && c4 > 0) {
            return true;
        }
        if (c1 >= 0 && c2 < 0) {
            return true;
        }
        if (c3 > 0 && c4 < 0) {
            return true;
        }

        return false;
    }

    public bool is_day_in_range (DateTime day, Util.DateRange range) {
        var date = day.get_day_of_year ();

        foreach (var dt in range) {
            if (dt.get_day_of_year () == date && dt.get_year () == day.get_year ()) {
                return true;
            }
        }
        return false;
    }

    public Gee.Collection<DateRange> event_date_ranges (iCal.Component comp, Util.DateRange view_range) {
        var dateranges = new Gee.LinkedList<DateRange> ();

        DateTime start, end;
        get_local_datetimes_from_icalcomponent (comp, out start, out end);

        start = strip_time (start);
        end = strip_time (end);
        dateranges.add (new Util.DateRange (start, end));

        // Search for recursive events.
        unowned iCal.Property property = comp.get_first_property (iCal.PropertyKind.RRULE);
        if (property != null) {
            var rrule = property.get_rrule ();
            switch (rrule.freq) {
                case (iCal.RecurrenceTypeFrequency.WEEKLY):
                    generate_week_reccurence (dateranges, view_range, rrule, start, end);
                    break;
                case (iCal.RecurrenceTypeFrequency.MONTHLY):
                    generate_month_reccurence (dateranges, view_range, rrule, start, end);
                    break;
                case (iCal.RecurrenceTypeFrequency.YEARLY):
                    generate_year_reccurence (dateranges, view_range, rrule, start, end);
                    break;
                default:
                    generate_day_reccurence (dateranges, view_range, rrule, start, end);
                    break;
            }
        }

        // EXDATEs elements are exceptions dates that should not appear.
        property = comp.get_first_property (iCal.PropertyKind.EXDATE);
        while (property != null) {
            var exdate = property.get_exdate ();
            var date = ical_to_date_time (exdate);
            dateranges.@foreach ((daterange) => {
                var first = daterange.first_dt;
                var last = daterange.last_dt;
                if (first.get_year () <= date.get_year () && last.get_year () >= date.get_year ()) {
                    if (first.get_day_of_year () <= date.get_day_of_year () && last.get_day_of_year () >= date.get_day_of_year ()) {
                        dateranges.remove (daterange);
                        return false;
                    }
                }

                return true;
            });

            property = comp.get_next_property (iCal.PropertyKind.EXDATE);
        }

        return dateranges;
    }

    private void generate_day_reccurence (Gee.LinkedList<DateRange> dateranges, Util.DateRange view_range,
                                           iCal.RecurrenceType rrule, DateTime start, DateTime end) {
        if (rrule.until.is_null_time () == 0) {
            for (int i = 1; i <= (int)(rrule.until.day/rrule.interval); i++) {
                int n = i*rrule.interval;
                if (view_range.contains (start.add_days (n)) || view_range.contains (end.add_days (n)))
                    dateranges.add (new Util.DateRange (start.add_days (n), end.add_days (n)));
            }
        } else if (rrule.count > 0) {
            for (int i = 1; i<=rrule.count; i++) {
                int n = i*rrule.interval;
                if (view_range.contains (start.add_days (n)) || view_range.contains (end.add_days (n)))
                    dateranges.add (new Util.DateRange (start.add_days (n), end.add_days (n)));
            }
        } else {
            int i = 1;
            int n = i*rrule.interval;
            while (view_range.last_dt.compare (start.add_days (n)) > 0) {
                dateranges.add (new Util.DateRange (start.add_days (n), end.add_days (n)));
                i++;
                n = i*rrule.interval;
            }
        }
    }

    private void generate_year_reccurence (Gee.LinkedList<DateRange> dateranges, Util.DateRange view_range,
                                           iCal.RecurrenceType rrule, DateTime start, DateTime end) {
        if (rrule.until.is_null_time () == 0) {
            /*for (int i = 0; i <= rrule.until.year; i++) {
                int n = i*rrule.interval;
                if (view_range.contains (start.add_years (n)) || view_range.contains (end.add_years (n)))
                    dateranges.add (new Util.DateRange (start.add_years (n), end.add_years (n)));
            }*/
        } else if (rrule.count > 0) {
            for (int i = 1; i<=rrule.count; i++) {
                int n = i*rrule.interval;
                if (view_range.contains (start.add_years (n)) || view_range.contains (end.add_years (n)))
                    dateranges.add (new Util.DateRange (start.add_years (n), end.add_years (n)));
            }
        } else {
            int i = 1;
            int n = i*rrule.interval;
            bool is_null_time = rrule.until.is_null_time () == 1;
            var temp_start = start.add_years (n);
            while (view_range.last_dt.compare (temp_start) > 0) {
                if (is_null_time == false) {
                    if (temp_start.get_year () > rrule.until.year)
                        break;
                    else if (temp_start.get_year () == rrule.until.year && temp_start.get_month () > rrule.until.month)
                        break;
                    else if (temp_start.get_year () == rrule.until.year && temp_start.get_month () == rrule.until.month &&temp_start.get_day_of_month () > rrule.until.day)
                        break;

                }
                dateranges.add (new Util.DateRange (temp_start, end.add_years (n)));
                i++;
                n = i*rrule.interval;
                temp_start = start.add_years (n);
            }
        }
    }

    private void generate_month_reccurence (Gee.LinkedList<DateRange> dateranges, Util.DateRange view_range,
                                           iCal.RecurrenceType rrule, DateTime start, DateTime end) {
        // Computes month recurrences by day (for example: third friday of the month).
        for (int k = 0; k <= iCal.Size.BY_DAY; k++) {
            if (rrule.by_day[k] < iCal.Size.BY_DAY) {
                if (rrule.count > 0) {
                    for (int i = 1; i<=rrule.count; i++) {
                        int n = i*rrule.interval;
                        var start_ical_day = get_date_from_ical_day (start.add_months (n), rrule.by_day[k]);
                        int interval = start_ical_day.get_day_of_month () - start.get_day_of_month ();
                        dateranges.add (new Util.DateRange (start_ical_day, end.add_months (n).add_days (interval)));
                    }
                } else {
                    int i = 1;
                    bool is_null_time = rrule.until.is_null_time () == 1;
                    bool is_last = (rrule.by_day[k] < 0);
                    var start_ical_day = start;
                    var end_ical_day = end;
                    var days = end.get_day_of_month () - start.get_day_of_month ();
                    int start_week = (int)GLib.Math.ceil ((double)start.get_day_of_month () / 7);

                    // Loop through each individual month from the start and test to see if our event is in the month or not
                    while (view_range.last_dt.compare (start_ical_day) > 0) {
                        if (is_null_time == false) {
                            if (start_ical_day.get_year () > rrule.until.year)
                                break;
                            else if (start_ical_day.get_year () == rrule.until.year && start_ical_day.get_month () > rrule.until.month)
                                break;
                            else if (start_ical_day.get_year () == rrule.until.year && start_ical_day.get_month () == rrule.until.month && start_ical_day.get_day_of_month () > rrule.until.day)
                                break;
                        }

                        var start_ical_day_new = get_date_from_ical_day (start.add_months (i), rrule.by_day[k]);
                        int month = start.add_months (i).get_month ();
                        int week = start_week;

                        // If event repeats on a last day of the month, take us back a week if we move into a new month
                        if (is_last && start_ical_day_new.get_month () != month) {
                            start_ical_day_new = start_ical_day_new.add_weeks (-1);
                        }

                        else if (!is_last) {
                            if (start_ical_day_new.get_day_of_month () <= 7 && start_ical_day_new.add_weeks (-1).get_month () == month) {
                                week = 2;
                            }
                            else {
                                week =  (int)GLib.Math.ceil ((double)start_ical_day_new.get_day_of_month () / 7);
                            }
                        }

                        start_ical_day_new = start_ical_day_new.add_weeks (start_week - week);
                        if (start_ical_day_new.get_month () != month) {
                            start_ical_day = start.add_months (i);
                        }
                        else {
                            start_ical_day = start_ical_day_new;
                            end_ical_day = start_ical_day.add_days (days);
                            dateranges.add (new Util.DateRange (start_ical_day, end_ical_day));
                        }

                        i++;
                    }
                }
            } else {
                break;
            }
        }

        // Computes month recurrences by month day (for example: 4th of the month).
        if (rrule.by_month_day[0] < iCal.Size.BY_MONTHDAY) {
            if (rrule.count > 0) {
                for (int i = 1; i<=rrule.count; i++) {
                    int n = i*rrule.interval;
                    dateranges.add (new Util.DateRange (start.add_months (n), end.add_months (n)));
                }
            } else {
                int i = 1;
                int n = i*rrule.interval;
                bool is_null_time = rrule.until.is_null_time () == 1;
                var temp_start = start.add_months (n);
                while (view_range.last_dt.compare (temp_start) > 0) {
                    if (is_null_time == false) {
                        if (temp_start.get_year () > rrule.until.year)
                            break;
                        else if (temp_start.get_year () == rrule.until.year && temp_start.get_month () > rrule.until.month)
                            break;
                        else if (temp_start.get_year () == rrule.until.year && temp_start.get_month () == rrule.until.month && temp_start.get_day_of_month () > rrule.until.day)
                            break;

                    }

                    dateranges.add (new Util.DateRange (temp_start, end.add_months (n)));
                    i++;
                    n = i*rrule.interval;
                    temp_start = start.add_months (n);
                }
            }
        }
    }

    private void generate_week_reccurence (Gee.LinkedList<DateRange> dateranges, Util.DateRange view_range,
                                           iCal.RecurrenceType rrule, DateTime start_, DateTime end_) {
        DateTime start = start_;
        DateTime end = end_;
        for (int k = 0; k <= iCal.Size.BY_DAY; k++) {
            if (rrule.by_day[k] > 7)
                break;

            int day_to_add = 0;
            switch (rrule.by_day[k]) {
                case 1:
                    day_to_add = 7 - start.get_day_of_week ();
                    break;
                case 2:
                    day_to_add = 1 - start.get_day_of_week ();
                    break;
                case 3:
                    day_to_add = 2 - start.get_day_of_week ();
                    break;
                case 4:
                    day_to_add = 3 - start.get_day_of_week ();
                    break;
                case 5:
                    day_to_add = 4 - start.get_day_of_week ();
                    break;
                case 6:
                    day_to_add = 5 - start.get_day_of_week ();
                    break;
                default:
                    day_to_add = 6 - start.get_day_of_week ();
                    break;
            }

            start = start.add_days (day_to_add);
            end = end.add_days (day_to_add);

            if (rrule.count > 0) {
                if (day_to_add > 0 && day_to_add + start_.get_day_of_week () < 7 ) {
                    dateranges.add (new Util.DateRange (start, end));
                }
                for (int i = 1; i<=rrule.count; i++) {
                    int n = i*rrule.interval*7;
                    if (view_range.contains (start.add_days (n)) || view_range.contains (end.add_days (n)))
                        dateranges.add (new Util.DateRange (start.add_days (n), end.add_days (n)));
                }
            } else {
                int i = 1;
                int n = rrule.interval;
                if (day_to_add > 0 && day_to_add + start_.get_day_of_week () < 7) {
                    dateranges.add (new Util.DateRange (start, end));
                }
                n *= 7;
                bool is_null_time = rrule.until.is_null_time () == 1;
                var temp_start = start.add_days (n);
                while (view_range.last_dt.compare (temp_start) > 0) {
                    if (is_null_time == false) {
                        if (temp_start.get_year () > rrule.until.year)
                            break;
                        else if (temp_start.get_year () == rrule.until.year) {
                            if (temp_start.get_month () > rrule.until.month)
                                break;
                            else if (temp_start.get_month () == rrule.until.month && temp_start.get_day_of_month () > rrule.until.day)
                                break;
                        }
                    }

                    dateranges.add (new Util.DateRange (temp_start, end.add_days (n)));
                    i++;
                    n = i*rrule.interval*7;
                    temp_start = start.add_days (n);
                }
            }
        }
    }

    public bool is_multiday_event (iCal.Component comp) {
        DateTime start, end;
        get_local_datetimes_from_icalcomponent (comp, out start, out end);

        if (start.get_year () != end.get_year () || start.get_day_of_year () != end.get_day_of_year ())
            return true;

        return false;
    }

    /**
     * Say if an event lasts all day.
     */
    public bool is_all_day (DateTime dtstart, DateTime dtend) {
        var UTC_start = dtstart.to_timezone (new TimeZone.utc ());
        var timespan = dtend.difference (dtstart);
        if (timespan % GLib.TimeSpan.DAY == 0 && UTC_start.get_hour() == 0) {
            return true;
        } else {
            return false;
        }
    }

    private DateTime get_date_from_ical_day (DateTime date, short day) {
        int day_to_add = 0;
        switch (iCal.RecurrenceType.day_day_of_week (day)) {
            case iCal.RecurrenceTypeWeekday.SUNDAY:
                day_to_add = 7 - date.get_day_of_week ();
                break;
            case iCal.RecurrenceTypeWeekday.MONDAY:
                day_to_add = 1 - date.get_day_of_week ();
                break;
            case iCal.RecurrenceTypeWeekday.TUESDAY:
                day_to_add = 2 - date.get_day_of_week ();
                break;
            case iCal.RecurrenceTypeWeekday.WEDNESDAY:
                day_to_add = 3 - date.get_day_of_week ();
                break;
            case iCal.RecurrenceTypeWeekday.THURSDAY:
                day_to_add = 4 - date.get_day_of_week ();
                break;
            case iCal.RecurrenceTypeWeekday.FRIDAY:
                day_to_add = 5 - date.get_day_of_week ();
                break;
            default:
                day_to_add = 6 - date.get_day_of_week ();
                break;
        }

        return date.add_days (day_to_add);
    }

    public DateTime get_start_of_month (owned DateTime? date = null) {

        if (date == null)
            date = new DateTime.now_local ();

        return new DateTime.local (date.get_year (), date.get_month (), 1, 0, 0, 0);
    }

    public DateTime strip_time (DateTime datetime) {
        return datetime.add_full (0, 0, 0, -datetime.get_hour (), -datetime.get_minute (), -datetime.get_second ());
    }

    /*
     * Gee Utility Functions
     */

    /* Computes hash value for E.Source */
    private uint source_hash_func (E.Source key) {
        return key.dup_uid (). hash ();
    }

    /* Returns true if 'a' and 'b' are the same GLib.DateTime */
    private bool datetime_equal_func (DateTime a, DateTime b) {
        return a.equal (b);
    }

    /* Returns true if 'a' and 'b' are the same E.CalComponent */
    private bool calcomponent_equal_func (E.CalComponent a, E.CalComponent b) {
        unowned iCal.Component comp_a = a.get_icalcomponent ();
        unowned iCal.Component comp_b = b.get_icalcomponent ();
        return comp_a.get_uid () == comp_b.get_uid ();
    }

    /* Returns true if 'a' and 'b' are the same E.Source */
    private bool source_equal_func (E.Source a, E.Source b) {
        return a.dup_uid () == b.dup_uid ();
    }

    /*
     * Gtk Miscellaneous
     */

    public class Css {
        private static Gtk.CssProvider? _css_provider;
        // Retrieve global css provider
        public static unowned Gtk.CssProvider get_css_provider () {
            if (_css_provider == null) {
                _css_provider = new Gtk.CssProvider ();
                _css_provider.load_from_resource ("/io/elementary/calendar/default.css");
            }

            return _css_provider;
        }
    }

    /*
     * E.Source Utils
     */
    public string get_source_location (E.Source source) {
        var registry = Maya.Model.CalendarModel.get_default ().registry;
        string parent_uid = source.parent;
        E.Source parent_source = source;
        while (parent_source != null) {
            parent_uid = parent_source.parent;

            if (parent_source.has_extension (E.SOURCE_EXTENSION_AUTHENTICATION)) {
                var collection = (E.SourceAuthentication)parent_source.get_extension (E.SOURCE_EXTENSION_AUTHENTICATION);
                if (collection.user != null) {
                    return collection.user;
                }
            }

            if (parent_source.has_extension (E.SOURCE_EXTENSION_COLLECTION)) {
                var collection = (E.SourceCollection)parent_source.get_extension (E.SOURCE_EXTENSION_COLLECTION);
                if (collection.identity != null) {
                    return collection.identity;
                }
            }

            if (parent_uid == null)
                break;

            parent_source = registry.ref_source (parent_uid);
        }

        return _("On this computer");
    }

    /*
     * ical Exportation
     */

    public void save_temp_selected_calendars () {
        var calmodel = Model.CalendarModel.get_default ();
        var events = calmodel.get_events ();
        var builder = new StringBuilder ();
        builder.append ("BEGIN:VCALENDAR\n");
        builder.append ("VERSION:2.0\n");
        foreach (E.CalComponent event in events) {
            builder.append (event.get_as_string ());
        }
        builder.append ("END:VCALENDAR");

        string file_path = GLib.Environment.get_tmp_dir () + "/calendar.ics";
        try {
            var file = File.new_for_path (file_path);
            file.replace_contents (builder.data, null, false, FileCreateFlags.REPLACE_DESTINATION, null);
        } catch (Error e) {
            warning ("%s\n", e.message);
        }
    }

    public const string SHOW_WEEKS_SCHEMA = "io.elementary.desktop.wingpanel.datetime";

    public bool show_weeks () {
        if (GLib.SettingsSchemaSource.get_default ().lookup (SHOW_WEEKS_SCHEMA, false) != null) {
            GLib.Settings weeks = new GLib.Settings (SHOW_WEEKS_SCHEMA);
            return weeks.get_boolean ("show-weeks");
        } else {
            return Settings.SavedState.get_default ().show_weeks;
        }
    }

    public void toggle_show_weeks () {
        if (GLib.SettingsSchemaSource.get_default ().lookup (SHOW_WEEKS_SCHEMA, false)!= null) {
            GLib.Settings weeks = new GLib.Settings (SHOW_WEEKS_SCHEMA);
            weeks.set_boolean ("show-weeks", !weeks.get_boolean ("show-weeks"));
        } else {
            Settings.SavedState.get_default ().show_weeks = !Settings.SavedState.get_default ().show_weeks;
        }
    }

    public void style_calendar_color (Gtk.Widget widget, string color, bool background = false) {
        string style = ".cal_color { %s: %s }";

        var style_context = widget.get_style_context ();
        style_context.add_class ("cal_color");
        var css_color = style.printf(background ? "background-color" : "color", color);
        var style_provider = new Gtk.CssProvider ();

        try {
            style_provider.load_from_data (css_color, css_color.length);
            style_context.add_provider (style_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (Error e) {
            warning ("Could not create CSS Provider: %s\nStylesheet:\n%s", e.message, css_color);
        }
    }

}
