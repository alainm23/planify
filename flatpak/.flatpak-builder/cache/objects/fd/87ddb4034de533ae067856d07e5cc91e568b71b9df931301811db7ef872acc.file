// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2014-2015 Maya Developers (http://launchpad.net/maya)
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
 * Authored by: Corentin Noël <corentin@elementaryos.org>
 */

// TODO: deprecate this in favor of the build-in Gtk 3.14 functions.
namespace Maya.GesturesUtils {

    static bool has_scrolled = false;
    const uint interval = 500;

    public bool on_scroll_event (Gdk.EventScroll event) {
        double delta_x;
        double delta_y;
        event.get_scroll_deltas (out delta_x, out delta_y);

        double choice = delta_x;
        if (((int)delta_x).abs () < ((int)delta_y).abs ()) {
            choice = delta_y;
        }

        // It's mouse scroll !
        if (choice == 1 || choice == -1) {
            Model.CalendarModel.get_default ().change_month ((int) choice);
            return true;
        }

        if (has_scrolled == true) {
            return true;
        }

        if (choice > 0.3) {
            reset_timer.begin ();
            Model.CalendarModel.get_default ().change_month (1);
            return true;
        }

        if (choice < -0.3) {
            reset_timer.begin ();
            Model.CalendarModel.get_default ().change_month (-1);
            return true;
        }

        return false;
    }

    public async void reset_timer () {
        has_scrolled = true;
        Timeout.add (interval, () => {
            has_scrolled = false;
            return false;
        });
    }
}
