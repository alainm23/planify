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
    int _day;
    public int day {
        set {
            _day = value;
            button.label = _day.to_string ();
        }
        get {
            return _day;
        }
    }

    private Gtk.Button button;
    private ulong button_clicked_id = 0;

    public signal void day_selected ();

    public CalendarDay () {
        Object (
            halign: Gtk.Align.CENTER,
            valign: Gtk.Align.CENTER
        );
    }

    construct {
        button = new Gtk.Button () {
            css_classes = { "flat", "calendar-day" }
        };

        child = button;

        button_clicked_id = button.clicked.connect (() => {
            day_selected ();
            button.add_css_class ("selected");
        });
    }

    public void clean_up () {
        if (button_clicked_id != 0) {
            button.disconnect (button_clicked_id);
            button_clicked_id = 0;
        }
    }
}
