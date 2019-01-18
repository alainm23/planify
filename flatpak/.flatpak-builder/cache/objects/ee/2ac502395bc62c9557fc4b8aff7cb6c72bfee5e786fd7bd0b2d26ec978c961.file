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
 * Represents the entire date grid as a table.
 */
public class Grid : Gtk.Grid {

    Gee.HashMap<uint, GridDay> data;

    public Util.DateRange grid_range { get; private set; }

    /*
     * Event emitted when the day is double clicked or the ENTER key is pressed.
     */
    public signal void on_event_add (DateTime date);
    public signal void edition_request (E.CalComponent comp);

    public signal void selection_changed (DateTime new_date);
    private GridDay selected_gridday;

    public Grid () {

        // Gtk.Grid properties
        insert_column (7);
        set_column_homogeneous (true);
        set_row_homogeneous (true);
        column_spacing = 0;
        row_spacing = 0;

        data = new Gee.HashMap<uint, GridDay> ();
        events |= Gdk.EventMask.SCROLL_MASK;
        events |= Gdk.EventMask.SMOOTH_SCROLL_MASK;
    }

    void on_day_focus_in (GridDay day) {
        if (selected_gridday != null)
            selected_gridday.set_selected (false);
        var selected_date = day.date;
        selected_gridday = day;
        day.set_selected (true);
        day.set_state_flags (Gtk.StateFlags.FOCUSED, false);
        selection_changed (selected_date);
        Settings.SavedState.get_default ().selected_day = selected_date.format ("%Y-%j");
        var calmodel = Maya.Model.CalendarModel.get_default ();
        var date_month = selected_date.get_month () - calmodel.month_start.get_month ();
        var date_year = selected_date.get_year () - calmodel.month_start.get_year ();
        if (date_month != 0 || date_year != 0) {
            calmodel.change_month (date_month);
            calmodel.change_year (date_year);
        }
    }

    public void focus_date (DateTime date) {
        debug (@"Setting focus to @ $(date)");
        var date_hash = day_hash (date);
        if (data.has_key (date_hash) == true) {
            var day_widget = data.get (date_hash);
            day_widget.grab_focus ();
            on_day_focus_in (day_widget);
        }
    }

    /**
     * Sets the given range to be displayed in the grid. Note that the number of days
     * must remain the same.
     */
    public void set_range (Util.DateRange new_range, DateTime month_start) {
        var today = new DateTime.now_local ();

        Gee.List<DateTime> old_dates;
        if (grid_range == null)
            old_dates = new Gee.ArrayList<DateTime> ();
        else
            old_dates = grid_range.to_list();

        var new_dates = new_range.to_list();

        var data_new = new Gee.HashMap<uint, GridDay> ();

        // Assert that a valid number of weeks should be displayed
        assert (new_dates.size % 7 == 0);

        // Create new widgets for the new range

        int i=0;
        int col = 0, row = 0;

        var style_provider = Util.Css.get_css_provider ();

        for (i=0; i<new_dates.size; i++) {
            var new_date = new_dates [i];
            GridDay day;
            if (i < old_dates.size) {
                // A widget already exists for this date, just change it

                var old_date = old_dates [i];
                day = update_day (data[day_hash (old_date)], new_date, today, month_start);

            } else {
                // Still update_day to get the color of etc. right
                day = update_day (new GridDay (new_date), new_date, today, month_start);
                day.on_event_add.connect ((date) => on_event_add (date));
                day.scroll_event.connect ((event) => {scroll_event (event); return false;});
                day.focus_in_event.connect ((event) => {
                    on_day_focus_in (day);
                    return false;
                });

                if (col == 0) {
                    day.get_style_context().add_provider (style_provider, 600);
                    day.get_style_context().add_class ("firstcol");
                }

                attach (day, col, row, 1, 1);
                day.show_all ();
            }

            col = (col+1) % 7;
            row = (col==0) ? row+1 : row;
            data_new.set (day_hash (new_date), day);
        }

        // Destroy the widgets that are no longer used
        while (i < old_dates.size) {
            // There are widgets remaining that are no longer used, destroy them
            var old_date = old_dates [i];
            var old_day = data.get (day_hash (old_date));

            old_day.destroy ();
            i++;
        }

        data.clear ();
        data.set_all (data_new);

        grid_range = new_range;
    }

    /**
     * Updates the given GridDay so that it shows the given date. Changes to its style etc.
     */
    GridDay update_day (GridDay day, DateTime new_date, DateTime today, DateTime month_start) {
        if (new_date.get_day_of_year () == today.get_day_of_year () && new_date.get_year () == today.get_year ()) {
            day.name = "today";
        }

        day.in_current_month = new_date.get_month () == month_start.get_month ();

        day.update_date (new_date);
        return day;
    }

    /**
     * Puts the given event on the grid.
     */
    public void add_event (E.CalComponent event) {
        unowned iCal.Component comp = event.get_icalcomponent ();
        foreach (var dt_range in Util.event_date_ranges (comp, grid_range)) {
            add_buttons_for_range (dt_range, event);
        }
    }

    /**
     * Adds an eventbutton to the grid for the given event at each day of the given range.
     */
    void add_buttons_for_range (Util.DateRange dt_range, E.CalComponent event) {
        foreach (var date in dt_range) {
            EventButton button = new EventButton (event, date);
            add_button_for_day (date, button);
            button.edition_request.connect (() => {
                edition_request (event);
            });
        }
    }

    void add_button_for_day (DateTime date, EventButton button) {
        var hash = day_hash (date);
        if (data.has_key (hash) == false)
            return;
        GridDay grid_day = data.get (hash);
        grid_day.add_event_button (button);
    }

    uint day_hash (DateTime date) {
        return date.get_year () * 10000 + date.get_month () * 100 + date.get_day_of_month ();
    }

    /**
     * Removes the given event from the grid.
     */
    public void remove_event (E.CalComponent event) {
        foreach(var grid_day in data.values) {
            grid_day.remove_event (event);
        }
    }

    public void update_event (E.CalComponent event) {
        Gee.Collection<Util.DateRange> event_ranges = Util.event_date_ranges (event.get_icalcomponent (), grid_range);

        foreach (var grid_day in data.values) {
            bool contains = false;

            foreach (Util.DateRange event_range in event_ranges) {
                if (Util.is_day_in_range (grid_day.date, event_range)) {
                    contains = true;
                }
            }

            if (contains) {
                if (!grid_day.update_event (event)) {
                    EventButton button = new EventButton (event, grid_day.date);
                    add_button_for_day (grid_day.date, button);

                    button.edition_request.connect (() => {
                        edition_request (event);
                    });
                }
            } else {
                grid_day.remove_event (event);
            }
        }
    }

    /**
     * Removes all events from the grid.
     */
    public void remove_all_events () {
        foreach(var grid_day in data.values) {
            grid_day.clear_events ();
        }
    }
}

}
