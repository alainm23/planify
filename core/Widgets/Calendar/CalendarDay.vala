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

public class Widgets.Calendar.CalendarDay : Adw.Bin {
    private Gtk.Label day_label;
    private Gtk.Label month_label;
    private Gtk.Button button;
    private ulong button_clicked_id = 0;

    int _day;
    public int day {
        set {
            _day = value;
            day_label.label = _day.to_string ();
            update_accessible_label ();
        }
        get {
            return _day;
        }
    }

    private GLib.DateTime _date;
    public GLib.DateTime date {
        set {
            _date = value;
            update_accessible_label ();
        }
        get {
            return _date;
        }
    }

    public bool show_month {
        set {
            month_label.visible = value;
            if (value && _date != null) {
                month_label.label = _date.format ("%b");
            }
        }
    }

    public signal void day_selected ();

    public CalendarDay () {
        Object (
            halign: Gtk.Align.CENTER,
            valign: Gtk.Align.CENTER
        );
    }

    construct {
        month_label = new Gtk.Label (null) {
            css_classes = { "caption", "dimmed" },
            visible = false
        };

        day_label = new Gtk.Label (null);

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            halign = CENTER,
            valign = CENTER
        };
        box.append (month_label);
        box.append (day_label);

        button = new Gtk.Button () {
            child = box,
            css_classes = { "flat", "calendar-day" }
        };

        child = button;

        button_clicked_id = button.clicked.connect (() => {
            day_selected ();
            button.add_css_class ("selected");
        });
    }

    public void add_day_css_class (string css_class) {
        day_label.add_css_class (css_class);
    }

    private void update_accessible_label () {
        if (_date != null && _day > 0) {
            var accessible_text = _date.format (_("%A, %B %e, %Y"));
            button.update_property (Gtk.AccessibleProperty.LABEL, accessible_text, -1);
        }
    }

    public void clean_up () {
        if (button_clicked_id != 0) {
            button.disconnect (button_clicked_id);
            button_clicked_id = 0;
        }
    }
}
