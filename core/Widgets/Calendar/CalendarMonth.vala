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

public class Widgets.Calendar.CalendarMonth : Gtk.Box {
    private Widgets.Calendar.CalendarWeek calendar_week;
    private Gtk.Grid days_grid;
    private Gee.ArrayList<Widgets.Calendar.CalendarDay> days_arraylist;
    private Widgets.ContextMenu.MenuItem date_item;

    private const int TOTAL_DAYS = 21; // 3 weeks

    private GLib.DateTime _current_date;
    public GLib.DateTime current_date {
        get {
            var today = new GLib.DateTime.now_local ();
            _current_date = new DateTime.local (
                today.get_year (),
                today.get_month (),
                today.get_day_of_month (),
                0, 0, 0
            );
            return _current_date;
        }
    }

    private GLib.DateTime _date;
    public GLib.DateTime? date {
        set {
            _date = value;
            if (_date != null) {
                select_date (_date);
            }
        }
        get {
            return _date;
        }
    }

    public signal void day_selected ();
    public signal void choose_date_clicked ();
    private Gee.HashMap<ulong, weak GLib.Object> signals_map = new Gee.HashMap<ulong, weak GLib.Object> ();

    public CalendarMonth () {
        Object (
            orientation: Gtk.Orientation.VERTICAL
        );
    }

    ~CalendarMonth () {
        debug ("Destroying - Widgets.Calendar.CalendarMonth\n");
    }

    construct {
        calendar_week = new Widgets.Calendar.CalendarWeek ();
        days_arraylist = new Gee.ArrayList<Widgets.Calendar.CalendarDay> ();

        days_grid = new Gtk.Grid () {
            column_homogeneous = true,
            row_homogeneous = true,
            margin_start = 6,
            margin_end = 6
        };

        date_item = new Widgets.ContextMenu.MenuItem (_("Choose a date"), "month-symbolic") {
            arrow = true,
            autohide_popover = false,
            margin_top = 3
        };

        append (calendar_week);
        append (days_grid);
        append (date_item);

        fill_days ();

        Services.EventBus.get_default ().day_changed.connect (() => {
            fill_days ();
            if (_date != null) {
                select_date (_date);
            }
        });

        Services.Settings.get_default ().settings.changed["start-week"].connect (() => {
            calendar_week.update ();
            fill_days ();
        });

        destroy.connect (() => {
            clean_up ();
        });

        date_item.clicked.connect (() => {
            choose_date_clicked ();
        });
    }

    private void fill_days () {
        for (int i = days_arraylist.size - 1; i >= 0; i--) {
            days_grid.remove (days_arraylist[i]);
            days_arraylist[i].clean_up ();
        }
        days_arraylist.clear ();

        var today = current_date;
        int start_week = Services.Settings.get_default ().settings.get_enum ("start-week");

        // Calculate starting column for today
        // get_day_of_week(): 1=Monday...7=Sunday
        // start_week: 0=Sunday, 1=Monday...6=Saturday
        int today_dow = today.get_day_of_week () % 7; // Sunday=0, Monday=1...Saturday=6
        int col = (today_dow - start_week + 7) % 7;
        int row = 0;

        for (int i = 0; i < TOTAL_DAYS; i++) {
            var day_datetime = today.add_days (i);

            var calendar_day = new Widgets.Calendar.CalendarDay ();
            calendar_day.day = day_datetime.get_day_of_month ();
            calendar_day.date = day_datetime;
            calendar_day.tooltip_text = Utils.Datetime.get_relative_date_from_date (day_datetime);

            if (i == 0) {
                calendar_day.child.add_css_class ("today");
            }

            // Show short month name on first day of next month
            if (day_datetime.get_day_of_month () == 1 && day_datetime.get_month () != today.get_month ()) {
                calendar_day.show_month = true;
                calendar_day.add_day_css_class ("caption");
            }

            signals_map[calendar_day.day_selected.connect (() => {
                day_selected_style (calendar_day);
            })] = calendar_day;

            days_grid.attach (calendar_day, col, row, 1, 1);
            days_arraylist.add (calendar_day);

            col++;
            if (col >= 7) {
                col = 0;
                row++;
            }
        }
    }

    private void day_selected_style (Widgets.Calendar.CalendarDay selected_day) {
        _date = selected_day.date;
        day_selected ();

        foreach (var day_item in days_arraylist) {
            day_item.child.remove_css_class ("selected");
        }

        selected_day.child.add_css_class ("selected");
    }

    private void select_date (GLib.DateTime date) {
        var today = current_date;
        var max_date = today.add_days (TOTAL_DAYS - 1);

        bool is_in_range = date.compare (today) >= 0 && date.compare (max_date) <= 0;

        if (is_in_range) {
            date_item.title = _("Choose a date");
            foreach (var day_item in days_arraylist) {
                day_item.child.remove_css_class ("selected");
                if (day_item.date.get_year () == date.get_year () &&
                    day_item.date.get_month () == date.get_month () &&
                    day_item.date.get_day_of_month () == date.get_day_of_month ()) {
                    day_item.child.add_css_class ("selected");
                }
            }
        } else {
            date_item.title = Utils.Datetime.get_default_date_format_from_date (date);
            foreach (var day_item in days_arraylist) {
                day_item.child.remove_css_class ("selected");
            }
        }
    }

    public void reset () {
        date_item.title = _("Choose a date");
        foreach (var day_item in days_arraylist) {
            day_item.child.remove_css_class ("selected");
        }
    }

    public void clean_up () {
        foreach (var item in days_arraylist) {
            item.clean_up ();
        }

        foreach (var entry in signals_map.entries) {
            if (SignalHandler.is_connected (entry.value, entry.key)) {
                entry.value.disconnect (entry.key);
            }
        }

        signals_map.clear ();
    }
}
