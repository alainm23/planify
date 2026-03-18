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
        int current_day = today.get_day_of_month ();
        int max_days = Utils.Datetime.get_days_of_month (today.get_month (), today.get_year ());
        
        int start_week = Services.Settings.get_default ().settings.get_enum ("start-week");
        int day_of_week = today.get_day_of_week () - start_week;
        if (day_of_week < 0) {
            day_of_week += 7;
        }
        day_of_week = (day_of_week + 7) % 7;

        int col = day_of_week;
        int row = 0;

        for (int day = current_day; day <= max_days; day++) {
            var calendar_day = new Widgets.Calendar.CalendarDay ();
            var day_datetime = new DateTime.local (
                today.get_year (),
                today.get_month (),
                day,
                0, 0, 0
            );

            calendar_day.day = day;
            calendar_day.date = day_datetime;
            calendar_day.tooltip_text = Utils.Datetime.get_relative_date_from_date (day_datetime);

            if (day_datetime.compare (current_date) == 0) {
                calendar_day.child.add_css_class ("today");
            }

            signals_map[calendar_day.day_selected.connect (() => {
                day_selected_style (calendar_day.day, day_datetime);
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

    private void day_selected_style (int day, GLib.DateTime date) {
        _date = date;
        day_selected ();

        foreach (var day_item in days_arraylist) {
            day_item.child.remove_css_class ("selected");
        }
        
        foreach (var day_item in days_arraylist) {
            if (day_item.day == day) {
                day_item.child.add_css_class ("selected");
                break;
            }
        }
    }

    private void select_date (GLib.DateTime date) {
        var today = current_date;
        bool is_in_range = false;
        
        if (date.get_year () == today.get_year () && date.get_month () == today.get_month ()) {
            if (date.get_day_of_month () >= today.get_day_of_month ()) {
                is_in_range = true;
            }
        }

        if (is_in_range) {
            date_item.title = _("Choose a date");
            foreach (var day_item in days_arraylist) {
                day_item.child.remove_css_class ("selected");
                if (day_item.day == date.get_day_of_month ()) {
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
