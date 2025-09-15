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

public class Widgets.Calendar.CalendarWeek : Gtk.Box {
    private Gtk.Label[] day_labels;

    ~CalendarWeek () {
        debug ("Destroying - Widgets.Calendar.CalendarWeek\n");
    }

    construct {
        orientation = Gtk.Orientation.HORIZONTAL;
        homogeneous = true;
        valign = Gtk.Align.CENTER;
        margin_start = 6;
        margin_top = 6;
        margin_bottom = 6;
        margin_end = 6;

        day_labels = new Gtk.Label[] {
            new Gtk.Label (_("Su")),
            new Gtk.Label (_("Mo")),
            new Gtk.Label (_("Tu")),
            new Gtk.Label (_("We")),
            new Gtk.Label (_("Th")),
            new Gtk.Label (_("Fr")),
            new Gtk.Label (_("Sa"))
        };

        foreach (var label in day_labels) {
            label.add_css_class ("dimmed");
            append (label);
        }

        update ();
    }

    public void update () {
        for (Gtk.Widget ? child = get_first_child (); child != null; ) {
            Gtk.Widget ? next = child.get_next_sibling ();
            remove (child);
            child = next;
        }

        var start_week = Services.Settings.get_default ().settings.get_enum ("start-week");
        var rotated_labels = rotate_left (day_labels, start_week);

        foreach (var label in rotated_labels) {
            append (label);
        }
    }

    private Gtk.Label[] rotate_left (Gtk.Label[] array, int positions) {
        positions = (positions % array.length + array.length) % array.length;
        var rotated = new Gtk.Label[array.length];

        for (int i = 0; i < array.length; i++) {
            rotated[i] = array[(i + positions) % array.length];
        }

        return rotated;
    }
}
