// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2011-2015 Maya Developers (http://launchpad.net/maya)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored by: Maxwell Barvian
 *              Corentin Noël <corentin@elementaryos.org>
 */

namespace Maya.View {

/**
 * Represent the week labels at the left side of the grid.
 */
public class WeekLabels : Gtk.Revealer {

    private Gtk.Grid day_grid;
    private Gtk.Label[] labels;
    private int nr_of_weeks;

    public WeekLabels () {
        events |= Gdk.EventMask.BUTTON_PRESS_MASK;
        vexpand = true;

        day_grid = new Gtk.Grid ();
        set_nr_of_weeks (5);
        day_grid.insert_row (1);
        day_grid.set_column_homogeneous (true);
        day_grid.set_row_homogeneous (true);
        day_grid.row_spacing = 0;
        day_grid.show ();

        var style_provider = Util.Css.get_css_provider ();

        // EventBox properties
        day_grid.get_style_context().add_provider (style_provider, 600);
        day_grid.get_style_context().add_class ("weeks");

        button_press_event.connect ((event) => {
            if (event.type == Gdk.EventType.BUTTON_PRESS && event.button == Gdk.BUTTON_SECONDARY) {
                var menu = new Gtk.Menu ();
                menu.attach_to_widget (this, null);
                var show_weeks_menuitem = new Gtk.MenuItem ();
                if (Util.show_weeks ()) {
                    show_weeks_menuitem.label = _("Hide Week Numbers");
                } else {
                    show_weeks_menuitem.label = _("Show Week Numbers");
                }

                show_weeks_menuitem.activate.connect (() => {
                    Util.toggle_show_weeks ();
                });
                menu.add (show_weeks_menuitem);
                menu.show_all ();
                menu.popup_at_pointer (event);
            }

            return false;
        });

        add (day_grid);
    }

    public void update (DateTime date, int nr_of_weeks) {

        update_nr_of_labels (nr_of_weeks);

        if (Util.show_weeks ()) {
            transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT;
            set_reveal_child (true);

            var next = date;
            // Find the beginning of the week which is apparently always a monday
            int days_to_add = (8 - next.get_day_of_week()) % 7;
            next = next.add_days(days_to_add);
            foreach (var label in labels) {
                label.label = next.get_week_of_year ().to_string();
                next = next.add_weeks (1);
            }
        } else {
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
            set_reveal_child (false);
        }
    }

    public void set_nr_of_weeks (int new_number) {
        day_grid.insert_row (new_number);
        nr_of_weeks = new_number;
    }

    public int get_nr_of_weeks () {
        return nr_of_weeks;
    }

    void update_nr_of_labels (int nr_of_weeks) {
        // Destroy all the old ones

        if (labels != null)
            foreach (var label in labels)
                label.destroy ();

        // Create new labels
        labels = new Gtk.Label[nr_of_weeks];
        var style_provider = Util.Css.get_css_provider ();
        for (int c = 0; c < nr_of_weeks; c++) {
            labels[c] = new Gtk.Label ("");
            labels[c].valign = Gtk.Align.START;
            labels[c].width_chars = 2;
            labels[c].get_style_context().add_provider (style_provider, 600);
            labels[c].get_style_context().add_class ("weeklabel");
            day_grid.attach (labels[c], 0, c, 1, 1);
            labels[c].show ();
        }
    }
}

}
