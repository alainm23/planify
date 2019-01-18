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

/**
 * Represents the entire calendar, including the headers, the week labels and the grid.
 */
public class Maya.View.CalendarView : Gtk.Grid {
    /*
     * Event emitted when the day is double clicked or the ENTER key is pressed.
     */
    public signal void on_event_add (DateTime date);
    public signal void edition_request (E.CalComponent comp);
    public signal void selection_changed (DateTime new_date);

    public DateTime? selected_date { get; private set; }

    private WeekLabels weeks { get; private set; }
    private Header header { get; private set; }
    private Grid grid { get; private set; }
    private Gtk.Stack stack { get; private set; }
    private Gtk.Grid big_grid { get; private set; }
    private Gtk.Label spacer { get; private set; }
    private GLib.Settings show_weeks;

    public CalendarView () {
        selected_date = Settings.SavedState.get_default ().get_selected ();
        big_grid = create_big_grid ();

        stack = new Gtk.Stack ();
        stack.add (big_grid);
        stack.show_all ();
        stack.expand = true;

        sync_with_model ();

        var model = Model.CalendarModel.get_default ();
        model.parameters_changed.connect (on_model_parameters_changed);

        model.events_added.connect (on_events_added);
        model.events_updated.connect (on_events_updated);
        model.events_removed.connect (on_events_removed);

        stack.notify["transition-running"].connect (() => {
            if (stack.transition_running == false) {
                stack.get_children ().foreach ((child) => {
                    if (child != stack.visible_child) {
                        child.destroy ();
                    }
                });
            }
        });

        if (GLib.SettingsSchemaSource.get_default ().lookup (Util.SHOW_WEEKS_SCHEMA, false) != null) {
            show_weeks = new GLib.Settings (Util.SHOW_WEEKS_SCHEMA);
            show_weeks.changed["show-weeks"].connect (on_show_weeks_changed);
            show_weeks.get_value ("show-weeks");
        } else {
            Settings.SavedState.get_default ().changed["show-weeks"].connect (on_show_weeks_changed);
        }

        events |= Gdk.EventMask.BUTTON_PRESS_MASK;
        events |= Gdk.EventMask.KEY_PRESS_MASK;
        events |= Gdk.EventMask.SCROLL_MASK;
        events |= Gdk.EventMask.SMOOTH_SCROLL_MASK;
        add (stack);
    }

    public Gtk.Grid create_big_grid () {
        var style_provider = Util.Css.get_css_provider ();

        spacer = new Gtk.Label ("");
        spacer.no_show_all = true;
        spacer.get_style_context().add_provider (style_provider, 600);
        spacer.get_style_context().add_class ("weeks");

        weeks = new WeekLabels ();

        header = new Header ();
        grid = new Grid ();
        grid.focus_date (selected_date);
        grid.on_event_add.connect ((date) => on_event_add (date));
        grid.edition_request.connect ((comp) => edition_request (comp));
        grid.selection_changed.connect ((date) => {
            selected_date = date;
            selection_changed (date);
        });

        // Grid properties
        var new_big_grid = new Gtk.Grid ();
        new_big_grid.attach (spacer, 0, 0, 1, 1);
        new_big_grid.attach (header, 1, 0, 1, 1);
        new_big_grid.attach (grid, 1, 1, 1, 1);
        new_big_grid.attach (weeks, 0, 1, 1, 1);
        new_big_grid.show_all ();
        new_big_grid.expand = true;

        if (!Util.show_weeks ())  {
            spacer.hide ();
        } else {
            spacer.show ();
        }

        return new_big_grid;
    }

    public override bool scroll_event (Gdk.EventScroll event) {
        return GesturesUtils.on_scroll_event (event);
    }

    //--- Public Methods ---//

    public void today () {
        var today = Util.strip_time (new DateTime.now_local ());
        var calmodel = Model.CalendarModel.get_default ();
        var start = Util.get_start_of_month (today);
        if (!start.equal (calmodel.month_start))
            calmodel.month_start = start;
        sync_with_model ();
        grid.focus_date (today);
    }

    //--- Signal Handlers ---//

    void on_show_weeks_changed () {
        var model = Model.CalendarModel.get_default ();
        weeks.update (model.data_range.first_dt, model.num_weeks);
        if (Util.show_weeks ()) {
            spacer.show ();
        } else {
            spacer.hide ();
        }
    }

    void on_events_added (E.Source source, Gee.Collection<E.CalComponent> events) {
        Idle.add ( () => {
            foreach (var event in events)
                add_event (source, event);

            return false;
        });
    }

    void on_events_updated (E.Source source, Gee.Collection<E.CalComponent> events) {
        Idle.add ( () => {
            foreach (var event in events)
                update_event (source, event);

            return false;
        });
    }

    void on_events_removed (E.Source source, Gee.Collection<E.CalComponent> events) {
        Idle.add ( () => {
            foreach (var event in events)
                remove_event (source, event);

            return false;
        });
    }

    /* Indicates the month has changed */
    void on_model_parameters_changed () {
        var model = Model.CalendarModel.get_default ();
        if (grid.grid_range != null && model.data_range.equals (grid.grid_range))
            return; // nothing to do

        Idle.add ( () => {
            remove_all_events ();
            sync_with_model ();
            return false;
        });
    }

    //--- Helper Methods ---//

    /* Sets the calendar widgets to the date range of the model */
    void sync_with_model () {
        var model = Model.CalendarModel.get_default ();
        if (grid.grid_range != null && (model.data_range.equals (grid.grid_range) || grid.grid_range.first_dt.compare (model.data_range.first_dt) == 0))
            return; // nothing to do

        DateTime previous_first = null;
        if (grid.grid_range != null)
            previous_first = grid.grid_range.first_dt;

        big_grid = create_big_grid ();
        stack.add (big_grid);

        header.update_columns (model.week_starts_on);
        weeks.update (model.data_range.first_dt, model.num_weeks);
        grid.set_range (model.data_range, model.month_start);

        // keep focus date on the same day of the month
        if (selected_date != null) {
            var bumpdate = model.month_start.add_days (selected_date.get_day_of_month() - 1);
            grid.focus_date (bumpdate);
        }

        if (previous_first != null) {
            if (previous_first.compare (grid.grid_range.first_dt) == -1) {
                stack.transition_type = Gtk.StackTransitionType.SLIDE_UP;
            } else {
                stack.transition_type = Gtk.StackTransitionType.SLIDE_DOWN;
            }
        }

        stack.set_visible_child (big_grid);
    }

    /* Render new event on the grid */
    void add_event (E.Source source, E.CalComponent event) {
        event.set_data("source", source);
        grid.add_event (event);
    }

    /* Update the event on the grid */
    void update_event (E.Source source, E.CalComponent event) {
        grid.update_event (event);
    }

    /* Remove event from the grid */
    void remove_event (E.Source source, E.CalComponent event) {
        grid.remove_event (event);
    }

    /* Remove all events from the grid */
    void remove_all_events () {
        grid.remove_all_events ();
    }
}
