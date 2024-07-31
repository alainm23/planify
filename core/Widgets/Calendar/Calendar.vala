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

public class Widgets.Calendar.Calendar : Gtk.Box {
    private Widgets.Calendar.CalendarHeader calendar_header;
    private Widgets.Calendar.CalendarWeek calendar_week;
    private Widgets.Calendar.CalendarView calendar_view;

    public bool block_past_days { get; construct; }

    private int month_nav;
    private int year_nav;
    private int day_nav;

    GLib.DateTime _current_date;
    public GLib.DateTime current_date {
        get {
            _current_date = new GLib.DateTime.now_local ();
            return _current_date;
        }
    }

    GLib.DateTime _date;
    public GLib.DateTime date {
        set {
            _date = value;
            view_date (_date);
        }

        get {
            return _date;
        }
    }

    public signal void day_selected ();

    private Gee.HashMap<ulong, GLib.Object> signal_map = new Gee.HashMap<ulong, GLib.Object> ();

    public Calendar (bool block_past_days = Constants.BLOCK_PAST_DAYS) {
        Object (
            block_past_days: block_past_days,
            orientation: Gtk.Orientation.VERTICAL
        );
    }

    ~Calendar() {
        print ("Destroying Widgets.Calendar.Calendar\n");
    }

    construct {
        calendar_header = new Widgets.Calendar.CalendarHeader ();
        calendar_week = new Widgets.Calendar.CalendarWeek ();
        calendar_view = new Widgets.Calendar.CalendarView ();

        append (calendar_header);
        append (calendar_week);
        append (calendar_view);

        today ();

        signal_map[calendar_header.left_clicked.connect (() => {
            previous_month ();
        })] = calendar_header;

        signal_map[calendar_header.center_clicked.connect (() => {
            today ();
        })] = calendar_header;

        signal_map[calendar_header.right_clicked.connect (() => {
            next_month ();
        })] = calendar_header;

        signal_map[calendar_view.day_selected.connect ((day) => {
            day_nav = day;
            _date = new DateTime.local (year_nav, month_nav, day_nav, 0, 0, 0);
            day_selected ();
        })] = calendar_view;

        Services.Settings.get_default ().settings.changed["start-week"].connect (() => {
            calendar_week.update ();
            today ();
        });

        destroy.connect (() => {
            print ("Before Destroying Widgets.Calendar.Calendar\n");
        });
    }

    public void next_month () {
        month_nav = month_nav + 1;

        if (month_nav > 12) {
            year_nav = year_nav + 1;
            month_nav = 1;
        }

        var date = new GLib.DateTime.local (year_nav, month_nav, 1, 0, 0, 0);
        fill_days (date);
    }

    public void previous_month () {
        month_nav = month_nav - 1;

        if (month_nav < 1) {
            year_nav = year_nav - 1;
            month_nav = 12;
        }

        var date = new GLib.DateTime.local (year_nav, month_nav, 1, 0, 0, 0);
        fill_days (date);
    }

    private void today () {
        year_nav = current_date.get_year ();
        month_nav = current_date.get_month ();
        day_nav = current_date.get_day_of_month ();

        fill_days (current_date);
    }

    private void view_date (GLib.DateTime date) {
        if (date == null) {
            return;
        }

        year_nav = date.get_year ();
        month_nav = date.get_month ();
        day_nav = date.get_day_of_month ();

        fill_days (date, true);
    }

    private void fill_days (GLib.DateTime date, bool show_day = false) {
        var firts_week = new DateTime.local (year_nav, month_nav, 1, 0, 0, 0);
        int start_day = firts_week.get_day_of_week () - Services.Settings.get_default ().settings.get_enum ("start-week");
        if (start_day < 0) {
            start_day += 7;
        }
        start_day = (start_day + 7) % 7;

        int max_days = Utils.Datetime.get_days_of_month (date.get_month (), year_nav);
        calendar_view.fill_grid_days (start_day, max_days, date, show_day, block_past_days);
        calendar_header.date = date;
    }

    public void reset () {
        calendar_view.clear_style ();
    }
}
