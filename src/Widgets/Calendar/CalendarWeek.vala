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

public class Widgets.Calendar.CalendarWeek : Gtk.Grid {
    private Gtk.Label label_monday;
    private Gtk.Label label_tuesday;
    private Gtk.Label label_wednesday;
    private Gtk.Label label_thursday;
    private Gtk.Label label_friday;
    private Gtk.Label label_saturday;
    private Gtk.Label label_sunday;

    public CalendarWeek () {
        margin_end = 3;
        column_homogeneous = true;
        valign = Gtk.Align.CENTER;

        label_monday = new Gtk.Label (_("Mon"));
        label_monday.get_style_context ().add_class ("font-weight-600");

        label_tuesday = new Gtk.Label (_("Tue"));
        label_tuesday.get_style_context ().add_class ("font-weight-600");

        label_wednesday = new Gtk.Label (_("Wed"));
        label_wednesday.get_style_context ().add_class ("font-weight-600");

        label_thursday = new Gtk.Label (_("Thu"));
        label_thursday.get_style_context ().add_class ("font-weight-600");

        label_friday = new Gtk.Label (_("Fri"));
        label_friday.get_style_context ().add_class ("font-weight-600");

        label_saturday = new Gtk.Label (_("Sat"));
        label_saturday.get_style_context ().add_class ("font-weight-600");

        label_sunday = new Gtk.Label (_("Sun"));
        label_sunday.get_style_context ().add_class ("font-weight-600");

        update ();
    }

    public void update () {
        foreach (unowned Gtk.Widget child in get_children ()) {
            child.destroy ();
        }

        var start_week = Planner.settings.get_enum ("start-week");
        if (start_week == 0) {
            add (label_sunday);
            add (label_monday);
            add (label_tuesday);
            add (label_wednesday);
            add (label_thursday);
            add (label_friday);
            add (label_saturday);
        } else if (start_week == 1) {
            add (label_monday);
            add (label_tuesday);
            add (label_wednesday);
            add (label_thursday);
            add (label_friday);
            add (label_saturday);
            add (label_sunday);
        } else if (start_week == 2) {
            add (label_tuesday);
            add (label_wednesday);
            add (label_thursday);
            add (label_friday);
            add (label_saturday);
            add (label_sunday);
            add (label_monday);
        } else if (start_week == 3) {
            add (label_wednesday);
            add (label_thursday);
            add (label_friday);
            add (label_saturday);
            add (label_sunday);
            add (label_monday);
            add (label_tuesday);
        } else if (start_week == 4) {
            add (label_thursday);
            add (label_friday);
            add (label_saturday);
            add (label_sunday);
            add (label_monday);
            add (label_tuesday);
            add (label_wednesday);
        } else if (start_week == 5) {
            add (label_friday);
            add (label_saturday);
            add (label_sunday);
            add (label_monday);
            add (label_tuesday);
            add (label_wednesday);
            add (label_thursday);
        } else if (start_week == 6) {
            add (label_saturday);
            add (label_sunday);
            add (label_monday);
            add (label_tuesday);
            add (label_wednesday);
            add (label_thursday);
            add (label_friday);
        }

        show_all ();
    }
}
