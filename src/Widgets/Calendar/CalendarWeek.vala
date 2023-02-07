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

public class Widgets.Calendar.CalendarWeek : Gtk.Box {
    private Gtk.Label label_monday;
    private Gtk.Label label_tuesday;
    private Gtk.Label label_wednesday;
    private Gtk.Label label_thursday;
    private Gtk.Label label_friday;
    private Gtk.Label label_saturday;
    private Gtk.Label label_sunday;

    public CalendarWeek () {
        orientation = Gtk.Orientation.HORIZONTAL;
        homogeneous = true;
        valign = Gtk.Align.CENTER;
        margin_start = 6;
        margin_top = 6;
        margin_bottom = 6;
        margin_end = 6;
        
        label_monday = new Gtk.Label (_("Mo"));
        label_monday.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);

        label_tuesday = new Gtk.Label (_("Tu"));
        label_tuesday.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);

        label_wednesday = new Gtk.Label (_("We"));
        label_wednesday.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);

        label_thursday = new Gtk.Label (_("Th"));
        label_thursday.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);

        label_friday = new Gtk.Label (_("Fr"));
        label_friday.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);

        label_saturday = new Gtk.Label (_("Sa"));
        label_saturday.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);

        label_sunday = new Gtk.Label (_("Su"));
        label_sunday.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);

        update ();
    }

    public void update () {
        for (Gtk.Widget child = get_first_child (); child != null; child = get_next_sibling ()) {
            remove (child);
        }

        var start_week = Planner.settings.get_enum ("start-week");
        if (start_week == 0) {
            append (label_sunday);
            append (label_monday);
            append (label_tuesday);
            append (label_wednesday);
            append (label_thursday);
            append (label_friday);
            append (label_saturday);
        } else if (start_week == 1) {
            append (label_monday);
            append (label_tuesday);
            append (label_wednesday);
            append (label_thursday);
            append (label_friday);
            append (label_saturday);
            append (label_sunday);
        } else if (start_week == 2) {
            append (label_tuesday);
            append (label_wednesday);
            append (label_thursday);
            append (label_friday);
            append (label_saturday);
            append (label_sunday);
            append (label_monday);
        } else if (start_week == 3) {
            append (label_wednesday);
            append (label_thursday);
            append (label_friday);
            append (label_saturday);
            append (label_sunday);
            append (label_monday);
            append (label_tuesday);
        } else if (start_week == 4) {
            append (label_thursday);
            append (label_friday);
            append (label_saturday);
            append (label_sunday);
            append (label_monday);
            append (label_tuesday);
            append (label_wednesday);
        } else if (start_week == 5) {
            append (label_friday);
            append (label_saturday);
            append (label_sunday);
            append (label_monday);
            append (label_tuesday);
            append (label_wednesday);
            append (label_thursday);
        } else if (start_week == 6) {
            append (label_saturday);
            append (label_sunday);
            append (label_monday);
            append (label_tuesday);
            append (label_wednesday);
            append (label_thursday);
            append (label_friday);
        }
    }
}