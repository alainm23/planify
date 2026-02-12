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

public class Widgets.Calendar.CalendarScroll : Adw.Bin {
    private Gtk.ScrolledWindow scrolled_window;
    private Gtk.Box content_box;
    private Gee.ArrayList<MonthSection> month_sections;
    private int loaded_months = 0;

    private GLib.DateTime _date;
    public GLib.DateTime ? date {
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

    construct {
        month_sections = new Gee.ArrayList<MonthSection> ();

        content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12);

        scrolled_window = new Gtk.ScrolledWindow () {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            vscrollbar_policy = Gtk.PolicyType.AUTOMATIC,
            child = content_box,
            height_request = 300
        };

        child = scrolled_window;

        load_initial_months ();

        scrolled_window.vadjustment.value_changed.connect (() => {
            if (scrolled_window.vadjustment.value + scrolled_window.vadjustment.page_size >= scrolled_window.vadjustment.upper - 100) {
                load_more_months ();
            }
        });
    }

    private void load_initial_months () {
        var today = new GLib.DateTime.now_local ();

        add_month_section (today, true);

        for (int i = 1; i <= 2; i++) {
            var next_month = today.add_months (i);
            add_month_section (next_month, false);
        }

        loaded_months = 3;
    }

    private void load_more_months () {
        var today = new GLib.DateTime.now_local ();

        for (int i = 0; i < 2; i++) {
            var next_month = today.add_months (loaded_months);
            add_month_section (next_month, false);
            loaded_months++;
        }
    }

    private void add_month_section (GLib.DateTime month_date, bool from_today) {
        var section = new MonthSection (month_date, from_today);
        section.day_selected.connect ((date) => {
            _date = date;
            update_selection ();
            day_selected ();
        });

        content_box.append (section);
        month_sections.add (section);
    }

    private void select_date (GLib.DateTime date) {
        update_selection ();
    }

    private void update_selection () {
        foreach (var section in month_sections) {
            section.update_selection (_date);
        }
    }

    public void reset () {
        _date = null;
        update_selection ();
    }

    private class MonthSection : Adw.Bin {
        public GLib.DateTime month_date { get; construct; }
        public bool from_today { get; construct; }

        private Gtk.Label month_label;
        private Widgets.Calendar.CalendarWeek calendar_week;
        private Gtk.Grid days_grid;
        private Gee.ArrayList<DayItem> day_items;

        public signal void day_selected (GLib.DateTime date);

        public MonthSection (GLib.DateTime month_date, bool from_today) {
            Object (
                month_date: month_date,
                from_today: from_today
            );
        }

        construct {
            day_items = new Gee.ArrayList<DayItem> ();

            month_label = new Gtk.Label (null) {
                halign = Gtk.Align.START,
                css_classes = { "font-bold" },
                margin_start = 6
            };

            calendar_week = new Widgets.Calendar.CalendarWeek () {
                margin_horizontal = 0,
                margin_top = 3,
                margin_bottom = 0
            };

            days_grid = new Gtk.Grid () {
                column_homogeneous = true,
                row_homogeneous = true
            };

            var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
                margin_start = 6,
                margin_end = 6
            };
            main_box.append (month_label);
            main_box.append (calendar_week);
            main_box.append (days_grid);

            child = main_box;

            fill_days ();
        }

        private void fill_days () {
            var today = new GLib.DateTime.now_local ();
            var current_year = today.get_year ();
            var month_year = month_date.get_year ();

            if (current_year == month_year) {
                month_label.label = month_date.format ("%B");
            } else {
                month_label.label = month_date.format ("%B %Y");
            }
            int start_day = from_today ? today.get_day_of_month () : 1;
            int max_days = Utils.Datetime.get_days_of_month (month_date.get_month (), month_date.get_year ());

            int start_week = Services.Settings.get_default ().settings.get_enum ("start-week");
            var first_day_date = new DateTime.local (
                month_date.get_year (),
                month_date.get_month (),
                start_day,
                0, 0, 0
            );

            int day_of_week = first_day_date.get_day_of_week () - start_week;
            if (day_of_week < 0) {
                day_of_week += 7;
            }
            day_of_week = (day_of_week + 7) % 7;

            int col = day_of_week;
            int row = 0;

            for (int day = start_day; day <= max_days; day++) {
                var day_datetime = new DateTime.local (
                    month_date.get_year (),
                    month_date.get_month (),
                    day,
                    0, 0, 0
                );

                var day_item = new DayItem (day, day_datetime);
                day_item.clicked.connect (() => {
                    day_selected (day_item.date);
                });

                days_grid.attach (day_item, col, row, 1, 1);
                day_items.add (day_item);

                col++;
                if (col >= 7) {
                    col = 0;
                    row++;
                }
            }
        }

        public void update_selection (GLib.DateTime ? selected_date) {
            foreach (var item in day_items) {
                item.update_selection (selected_date);
            }
        }
    }

    private class DayItem : Adw.Bin {
        public int day { get; construct; }
        public GLib.DateTime date { get; construct; }

        private Gtk.Button button;

        public signal void clicked ();

        public DayItem (int day, GLib.DateTime date) {
            Object (
                day: day,
                date: date,
                halign: Gtk.Align.CENTER,
                valign: Gtk.Align.CENTER
            );
        }

        construct {
            button = new Gtk.Button.with_label (day.to_string ()) {
                css_classes = { "flat", "calendar-day" }
            };

            child = button;

            var today = new GLib.DateTime.now_local ();
            if (date.get_year () == today.get_year () &&
                date.get_month () == today.get_month () &&
                date.get_day_of_month () == today.get_day_of_month ()) {
                button.add_css_class ("today");
            }

            button.clicked.connect (() => {
                clicked ();
            });
        }

        public void update_selection (GLib.DateTime ? selected_date) {
            button.remove_css_class ("selected");

            if (selected_date != null &&
                date.get_year () == selected_date.get_year () &&
                date.get_month () == selected_date.get_month () &&
                date.get_day_of_month () == selected_date.get_day_of_month ()) {
                button.add_css_class ("selected");
            }
        }
    }
}
