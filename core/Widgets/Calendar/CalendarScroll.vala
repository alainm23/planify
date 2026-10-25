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
    private Gtk.Revealer today_button_revealer;
    private Gee.ArrayList<MonthSection> month_sections;
    private const int MAX_MONTHS = 12;
    private GLib.DateTime first_month;
    private uint scroll_idle_id = 0;

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

        var today_button = new Gtk.Button.with_label (_("Today")) {
            halign = END,
            valign = END,
            margin_bottom = 12,
            margin_end = 12
        };
        today_button.add_css_class ("pill");
        today_button.add_css_class ("suggested-action");

        today_button_revealer = new Gtk.Revealer () {
            child = today_button,
            transition_type = Gtk.RevealerTransitionType.SLIDE_UP,
            reveal_child = false,
            valign = END
        };

        var overlay = new Gtk.Overlay () {
            child = scrolled_window
        };
        overlay.add_overlay (today_button_revealer);

        child = overlay;

        load_initial_months ();

        scrolled_window.edge_reached.connect ((edge) => {
            if (scroll_idle_id == 0 && (edge == Gtk.PositionType.TOP || edge == Gtk.PositionType.BOTTOM)) {
                load_more_months (edge == Gtk.PositionType.TOP);
            }
        });

        scrolled_window.vadjustment.value_changed.connect (() => {
            int today_index = month_index (new GLib.DateTime.now_local ());
            double current_month_y = 0;
            for (int i = 0; i < int.min (int.max (today_index, 0), month_sections.size); i++) {
                current_month_y += month_sections[i].get_allocated_height () + 12;
            }
            bool away_from_today = today_index < 0 || today_index >= month_sections.size;
            if (!away_from_today) {
                double threshold = month_sections[today_index].get_allocated_height ();
                away_from_today = scrolled_window.vadjustment.value < current_month_y - threshold ||
                                  scrolled_window.vadjustment.value > current_month_y + threshold;
            }
            today_button_revealer.reveal_child = away_from_today;
        });

        today_button.clicked.connect (() => {
            scroll_to_date (new GLib.DateTime.now_local ());
        });
    }

    private int month_index (GLib.DateTime target) {
        return (target.get_year () - first_month.get_year ()) * 12 +
               target.get_month () - first_month.get_month ();
    }

    private void load_initial_months () {
        rebuild_months (new GLib.DateTime.now_local ());
        scroll_to_date (new GLib.DateTime.now_local ());
    }

    private void rebuild_months (GLib.DateTime target) {
        foreach (var section in month_sections) {
            content_box.remove (section);
        }
        month_sections.clear ();
        first_month = new GLib.DateTime.local (target.get_year (), target.get_month (), 1, 0, 0, 0);
        first_month = first_month.add_months (-3);
        for (int i = 0; i < 6; i++) {
            add_month_section (first_month.add_months (i));
        }
        update_selection ();
    }

    private void load_more_months (bool past) {
        double offset = scrolled_window.vadjustment.value;
        if (past) {
            for (int i = 0; i < 2; i++) {
                first_month = first_month.add_months (-1);
                var section = create_month_section (first_month);
                content_box.prepend (section);
                month_sections.insert (0, section);
            }
            while (month_sections.size > MAX_MONTHS) {
                var section = month_sections[month_sections.size - 1];
                content_box.remove (section);
                month_sections.remove (section);
            }
        } else {
            for (int i = 0; i < 2; i++) {
                add_month_section (first_month.add_months (month_sections.size));
            }
            while (month_sections.size > MAX_MONTHS) {
                var section = month_sections[0];
                offset -= section.get_allocated_height () + 12;
                content_box.remove (section);
                month_sections.remove (section);
                first_month = first_month.add_months (1);
            }
        }
        update_selection ();
        if (scroll_idle_id != 0) {
            GLib.Source.remove (scroll_idle_id);
        }
        scroll_idle_id = Idle.add (() => {
            scroll_idle_id = 0;
            if (past) {
                offset += month_sections[0].get_allocated_height () + month_sections[1].get_allocated_height () + 24;
            }
            scrolled_window.vadjustment.value = double.max (0, offset);
            return Source.REMOVE;
        });
    }

    private MonthSection create_month_section (GLib.DateTime month_date) {
        var section = new MonthSection (month_date);
        section.day_selected.connect ((date) => {
            _date = date;
            update_selection ();
            day_selected ();
        });
        return section;
    }

    private void add_month_section (GLib.DateTime month_date) {
        var section = create_month_section (month_date);
        content_box.append (section);
        month_sections.add (section);
    }

    private void select_date (GLib.DateTime date) {
        ensure_month_loaded (date);
        update_selection ();
        scroll_to_date (date);
    }

    private void ensure_month_loaded (GLib.DateTime target_date) {
        int index = month_index (target_date);
        if (index < 0 || index >= month_sections.size) {
            rebuild_months (target_date);
        }
    }

    private void scroll_to_month_index (int index) {
        if (index < 0 || index >= month_sections.size) return;
        var target_section = month_sections[index];
        double target_y = 0;
        for (int i = 0; i < index; i++) {
            target_y += month_sections[i].get_allocated_height () + 12;
        }
        double center_offset = (scrolled_window.vadjustment.page_size - target_section.get_allocated_height ()) / 2;
        scrolled_window.vadjustment.value = double.max (0, target_y - center_offset);
    }

    private void scroll_to_date (GLib.DateTime target_date) {
        ensure_month_loaded (target_date);
        if (scroll_idle_id != 0) {
            GLib.Source.remove (scroll_idle_id);
        }
        scroll_idle_id = Idle.add (() => {
            scroll_idle_id = 0;
            scroll_to_month_index (month_index (target_date));
            return Source.REMOVE;
        });
    }

    public override void dispose () {
        if (scroll_idle_id != 0) {
            GLib.Source.remove (scroll_idle_id);
            scroll_idle_id = 0;
        }
        base.dispose ();
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

    public void scroll_to_selected_date () {
        if (_date != null) {
            scroll_to_date (_date);
        } else {
            scroll_to_date (new GLib.DateTime.now_local ());
        }
    }

    private class MonthSection : Adw.Bin {
        public GLib.DateTime month_date { get; construct; }

        private Gtk.Label month_label;
        private Widgets.Calendar.CalendarWeek calendar_week;
        private Gtk.Grid days_grid;
        private Gee.ArrayList<DayItem> day_items;

        public signal void day_selected (GLib.DateTime date);

        public MonthSection (GLib.DateTime month_date) {
            Object (
                month_date: month_date
            );
        }

        construct {
            day_items = new Gee.ArrayList<DayItem> ();

            month_label = new Gtk.Label (null) {
                halign = Gtk.Align.START,
                css_classes = { "font-bold" },
                margin_start = 9
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
            main_box.append (new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
                margin_start = 6,
                margin_end = 6
            });

            child = main_box;

            fill_days ();
        }

        private void fill_days () {
            var today = new GLib.DateTime.now_local ();
            var today_date = new DateTime.local (today.get_year (), today.get_month (), today.get_day_of_month (), 0, 0, 0);

            if (month_date.get_year () == today.get_year ()) {
                month_label.label = month_date.format ("%B");
            } else {
                month_label.label = month_date.format ("%B %Y");
            }

            int max_days = Utils.Datetime.get_days_of_month (month_date.get_month (), month_date.get_year ());
            int start_week = Services.Settings.get_default ().settings.get_enum ("start-week");

            var first_day_date = new DateTime.local (month_date.get_year (), month_date.get_month (), 1, 0, 0, 0);
            int day_of_week = first_day_date.get_day_of_week () % 7;
            int col = (day_of_week - start_week + 7) % 7;
            int row = 0;

            for (int i = 0; i < col; i++) {
                days_grid.attach (new Gtk.Label (null), i, 0, 1, 1);
            }

            for (int day = 1; day <= max_days; day++) {
                var day_datetime = new DateTime.local (
                    month_date.get_year (), month_date.get_month (), day, 0, 0, 0
                );

                bool is_today = day_datetime.compare (today_date) == 0;
                bool is_past = day_datetime.compare (today_date) < 0;

                var day_item = new DayItem (day, day_datetime, is_today, is_past);
                day_item.clicked.connect ((date) => {
                    day_selected (date);
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
        public bool is_today { get; construct; }
        public bool is_past { get; construct; }

        private Gtk.Button button;

        public signal void clicked (GLib.DateTime date);

        public DayItem (int day, GLib.DateTime date, bool is_today, bool is_past) {
            Object (
                day: day,
                date: date,
                is_today: is_today,
                is_past: is_past,
                halign: Gtk.Align.CENTER,
                valign: Gtk.Align.CENTER
            );
        }

        construct {
            button = new Gtk.Button.with_label (day.to_string ()) {
                css_classes = { "flat", "calendar-day" }
            };

            button.update_property (Gtk.AccessibleProperty.LABEL, date.format (_("%A, %B %e, %Y")), -1);

            if (is_today) {
                button.add_css_class ("today");
            } else if (is_past) {
                button.add_css_class ("dimmed");
            }

            child = button;

            button.clicked.connect (() => {
                clicked (date);
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
