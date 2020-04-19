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

public class Widgets.Calendar.Calendar : Gtk.Box {
    private Widgets.Calendar.CalendarHeader calendar_header;
    private Widgets.Calendar.CalendarWeek calendar_week;
    private Widgets.Calendar.CalendarView calendar_view;

    public bool block_past_days { get; construct; }

    private int month_nav;
    private int year_nav;
    private int day_nav;

    private GLib.DateTime current_date;

    private GLib.DateTime _date;
    public GLib.DateTime date {
        get {
            _date = new DateTime.local (year_nav, month_nav, day_nav, 0, 0, 0);
            return _date;
        }
    }

    public signal void selection_changed (GLib.DateTime date);

    public Calendar (bool block_past_days = false) {
        Object (
            block_past_days: block_past_days
        );
    }

    construct {
        orientation = Gtk.Orientation.VERTICAL;
        margin = 6;
        margin_start = 9;
        margin_end = 6;
        height_request = 200;

        current_date = new GLib.DateTime.now_local ();

        calendar_header = new Widgets.Calendar.CalendarHeader ();
        calendar_week = new Widgets.Calendar.CalendarWeek ();
        calendar_view = new Widgets.Calendar.CalendarView ();

        pack_start (calendar_header);
        pack_start (calendar_week);
        pack_start (calendar_view);

        today ();

        calendar_header.left_clicked.connect (() => {
            previous_month ();
        });

        calendar_header.center_clicked.connect (() => {
            today ();
        });

        calendar_header.right_clicked.connect (() => {
            next_month ();
        });

        calendar_view.day_selected.connect ((day) => {
            day_nav = day;
            selection_changed (new DateTime.local (year_nav, month_nav, day_nav, 0, 0, 0));
        });
    }

    public void next_month () {
        month_nav = month_nav + 1;

        if (month_nav > 12) {
            year_nav = year_nav + 1;
            month_nav = 1;
        }

        var date = new GLib.DateTime.local (year_nav, month_nav, 1, 0, 0, 0);

        var firts_week = new DateTime.local (date.get_year (), date.get_month (), 1, 0, 0, 0);
        int start_day = firts_week.get_day_of_week () - 1;

        int max_days = Planner.utils.get_days_of_month (date.get_month (), year_nav);

        calendar_view.fill_grid_days (start_day,
                                      max_days,
                                      date.get_day_of_month (),
                                      Planner.utils.is_current_month (date),
                                      block_past_days,
                                      date);

        calendar_header.date = date;
    }

    public void previous_month () {
        month_nav = month_nav - 1;

        if (month_nav < 1) {
            year_nav = year_nav - 1;
            month_nav = 12;
        }

        var date = new GLib.DateTime.local (year_nav, month_nav, 1, 0, 0, 0);

        var firts_week = new DateTime.local (date.get_year (), date.get_month (), 1, 0, 0, 0);
        int start_day = firts_week.get_day_of_week () - 1;

        int max_days = Planner.utils.get_days_of_month (date.get_month (), year_nav);

        calendar_view.fill_grid_days (start_day,
                                      max_days,
                                      date.get_day_of_month (),
                                      Planner.utils.is_current_month (date),
                                      block_past_days,
                                      date);

        calendar_header.date = date;
    }

    private void today () {
        int year = current_date.get_year ();
        int month = current_date.get_month ();
        int day = current_date.get_day_of_month ();

        month_nav = month;
        year_nav = year;
        day_nav = day;

        var firts_week = new DateTime.local (year, month, 1, 0, 0, 0);
        int start_day = firts_week.get_day_of_week () - 1;

        int max_days = Planner.utils.get_days_of_month (current_date.get_month (), year_nav);

        calendar_view.fill_grid_days (
            start_day,
            max_days,
            day,
            true,
            block_past_days,
            current_date
        );

        calendar_header.date = current_date;

        selection_changed (new GLib.DateTime.now_local ());
    }
}
