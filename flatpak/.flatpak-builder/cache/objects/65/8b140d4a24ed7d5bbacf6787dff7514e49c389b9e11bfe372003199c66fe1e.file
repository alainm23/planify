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
 *              Niels Avonds <niels.avonds@gmail.com>
 *              Corentin Noël <corentin@elementaryos.org>
 */

public class Maya.View.AgendaView : Gtk.Grid {
    public signal void event_removed (E.CalComponent event);
    public signal void event_modified (E.CalComponent event);

    private Gtk.Label day_label;
    private Gtk.Label weekday_label;
    private Gtk.ListBox selected_date_events_list;
    private Gtk.ListBox upcoming_events_list;
    private DateTime selected_date;
    private HashTable<string, AgendaEventRow> row_table;
    private HashTable<string, AgendaEventRow> row_table2;

    public AgendaView () {
        orientation = Gtk.Orientation.VERTICAL;
        column_spacing = 0;
        row_spacing = 0;

        weekday_label = new Gtk.Label ("");
        weekday_label.set_alignment (0, 0.5f);
        weekday_label.use_markup = true;
        weekday_label.get_style_context ().add_class ("h2");
        weekday_label.margin = 12;
        weekday_label.margin_bottom = 0;

        day_label = new Gtk.Label ("");
        day_label.set_alignment (0, 0.5f);
        day_label.use_markup = true;
        day_label.get_style_context ().add_class ("h3");
        day_label.margin = 12;
        day_label.margin_top = 0;
        day_label.margin_bottom = 6;

        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator.hexpand = true;

        var selected_data_grid = new Gtk.Grid ();
        selected_data_grid.row_spacing = 6;
        selected_data_grid.orientation = Gtk.Orientation.VERTICAL;
        selected_data_grid.add (weekday_label);
        selected_data_grid.add (day_label);
        selected_data_grid.add (separator);

        var placeholder_label = new Gtk.Label (_("Your upcoming events will be displayed here when you select a date with events."));
        placeholder_label.wrap = true;
        placeholder_label.wrap_mode = Pango.WrapMode.WORD;
        placeholder_label.margin_start = 12;
        placeholder_label.margin_end = 12;
        placeholder_label.justify = Gtk.Justification.CENTER;
        placeholder_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
        placeholder_label.show_all ();

        selected_date_events_list = new Gtk.ListBox ();
        selected_date_events_list.selection_mode = Gtk.SelectionMode.SINGLE;
        selected_date_events_list.set_header_func (header_update_func);
        selected_date_events_list.set_placeholder (placeholder_label);
        selected_date_events_list.set_sort_func ((child1, child2) => {
            var row1 = (AgendaEventRow) child1;
            var row2 = (AgendaEventRow) child2;
            if (row1.is_allday) {
                if (row2.is_allday) {
                    return row1.summary.collate (row2.summary);
                } else {
                    return -1;
                }
            } else {
                if (row2.is_allday) {
                    return 1;
                } else {
                    unowned iCal.Component ical_event1 = row1.calevent.get_icalcomponent ();
                    DateTime start_date1, end_date1;
                    Util.get_local_datetimes_from_icalcomponent (ical_event1, out start_date1, out end_date1);
                    unowned iCal.Component ical_event2 = row2.calevent.get_icalcomponent ();
                    DateTime start_date2, end_date2;
                    Util.get_local_datetimes_from_icalcomponent (ical_event2, out start_date2, out end_date2);
                    var comp = start_date1.compare (start_date2);
                    if (comp != 0) {
                        return comp;
                    } else {
                        comp = end_date1.compare (end_date2);
                        if (comp != 0) {
                            return comp;
                        }
                    }

                    return row1.summary.collate (row2.summary);
                }
            }
        });

        selected_date_events_list.set_filter_func ((row) => {
            if (selected_date == null) {
                return false;
            }

            var event_row = (AgendaEventRow) row;
            unowned iCal.Component comp = event_row.calevent.get_icalcomponent ();

            var stripped_time = new DateTime.local (selected_date.get_year (), selected_date.get_month (), selected_date.get_day_of_month (), 0, 0, 0);
            var range = new Util.DateRange (stripped_time, stripped_time.add_days (1));
            Gee.Collection<Util.DateRange> event_ranges = Util.event_date_ranges (comp, range);

            foreach (Util.DateRange event_range in event_ranges) {
                if (Util.is_day_in_range (stripped_time, event_range)) {
                    return true;
                }
            }

            return false;
        });

        var selected_scrolled = new Gtk.ScrolledWindow (null, null);
        selected_scrolled.expand = true;
        selected_scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        selected_scrolled.add (selected_date_events_list);

        var upcoming_events_label = new Gtk.Label (_("Upcoming Events"));

        var upcoming_events_separatorTop = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        upcoming_events_separatorTop.hexpand = true;

        var upcoming_events_separatorBottom = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        upcoming_events_separatorBottom.hexpand = true;

        var upcoming_events_grid = new Gtk.Grid ();
        upcoming_events_grid.row_spacing = 6;
        upcoming_events_grid.orientation = Gtk.Orientation.VERTICAL;
        upcoming_events_grid.attach (upcoming_events_separatorTop, 0, 0, 1, 1);
        upcoming_events_grid.attach (upcoming_events_label, 0, 1, 1, 1);
        upcoming_events_grid.attach (upcoming_events_separatorBottom, 0, 2, 1, 1);

        upcoming_events_list = new Gtk.ListBox ();
        upcoming_events_list.selection_mode = Gtk.SelectionMode.SINGLE;
        upcoming_events_list.set_header_func (upcoming_header_update_func);
        upcoming_events_list.set_sort_func ((child1, child2) => {
            var row1 = (AgendaEventRow) child1;
            var row2 = (AgendaEventRow) child2;

            unowned iCal.Component ical_event1 = row1.calevent.get_icalcomponent ();
            DateTime start_date1, end_date1;
            Util.get_local_datetimes_from_icalcomponent (ical_event1, out start_date1, out end_date1);
            unowned iCal.Component ical_event2 = row2.calevent.get_icalcomponent ();
            DateTime start_date2, end_date2;
            Util.get_local_datetimes_from_icalcomponent (ical_event2, out start_date2, out end_date2);
            var comp = start_date1.compare (start_date2);
            if (comp != 0) {
                return comp;
            } else {
                comp = end_date1.compare (end_date2);
                if (comp != 0) {
                    return comp;
                }
            }

            return row1.summary.collate (row2.summary);
        });

        upcoming_events_list.set_filter_func ((row) => {
            var event_row = (AgendaEventRow) row;

            DateTime now = new DateTime.now_local ();
            unowned iCal.Component comp = event_row.calevent.get_icalcomponent ();
            var stripped_time = new DateTime.local (now.get_year (), now.get_month (), now.get_day_of_month (), 0, 0, 0);
            stripped_time = stripped_time.add_days (1);
            var stripped_time_end = new DateTime.local (now.get_year (), now.get_month (), 1, 0, 0, 0);
            stripped_time_end = stripped_time_end.add_months (2);

            var range = new Util.DateRange (stripped_time, stripped_time_end);

            return Util.is_event_in_range (comp, range);
        });

        var upcoming_scrolled = new Gtk.ScrolledWindow (null, null);
        upcoming_scrolled.expand = true;
        upcoming_scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        upcoming_scrolled.add (upcoming_events_list);

        attach (selected_data_grid, 0, 0, 1, 1);
        attach (selected_scrolled, 0, 1, 1, 1);
        attach (upcoming_events_grid, 0, 2, 1, 1);
        attach (upcoming_scrolled, 0, 3, 1, 2);

        row_table = new HashTable<string, AgendaEventRow> (str_hash, str_equal);
        row_table2 = new HashTable<string, AgendaEventRow> (str_hash, str_equal);

        // Listen to changes for events
        var calmodel = Model.CalendarModel.get_default ();
        calmodel.events_added.connect (on_events_added);
        calmodel.events_removed.connect (on_events_removed);
        calmodel.events_updated.connect (on_events_updated);
        set_selected_date (Settings.SavedState.get_default ().get_selected ());
        show_all ();
    }

    private void header_update_func (Gtk.ListBoxRow lbrow, Gtk.ListBoxRow? lbbefore) {
        var row = (AgendaEventRow) lbrow;
        if (lbbefore != null) {
            var before = (AgendaEventRow) lbbefore;
            if (row.is_allday == before.is_allday) {
                row.set_header (null);
                return;
            }

            if (row.is_allday != before.is_allday) {
                row.set_header (header_with_label (_("During the day")));
                return;
            }
        } else {
            if (row.is_allday) {
                var allday_header = header_with_label (_("All day"));
                row.set_header (allday_header);
            }
            return;
        }
    }

    private static int get_event_type (AgendaEventRow row) {
        unowned iCal.Component comp = row.calevent.get_icalcomponent ();
        DateTime now = new DateTime.now_local ();

        var stripped_time = new DateTime.local (now.get_year (), now.get_month (), now.get_day_of_month (), 0, 0, 0);
        stripped_time = stripped_time.add_days (1);
        var stripped_time_end = stripped_time.add_days (1);
        var range = new Util.DateRange (stripped_time, stripped_time_end);
        if (Util.is_event_in_range (comp, range)) {
            return 1; // Tomorrow
        }

        stripped_time_end = stripped_time_end.add_days (7 - stripped_time.get_day_of_week ());
        range = new Util.DateRange (stripped_time, stripped_time_end);
        if (Util.is_event_in_range (comp, range)) {
            return 2; // This Week
        }

        stripped_time = new DateTime.local (now.get_year (), now.get_month (), now.get_day_of_month (), 0, 0, 0);
        stripped_time = stripped_time.add_days (8 - stripped_time.get_day_of_week ());
        stripped_time_end = stripped_time.add_days (7);
        range = new Util.DateRange (stripped_time, stripped_time_end);
        if (Util.is_event_in_range (comp, range)) {
            return 3; // Next Week
        }

        stripped_time = new DateTime.local (now.get_year (), now.get_month (), now.get_day_of_month (), 0, 0, 0);
        stripped_time_end = new DateTime.local (now.get_year (), now.get_month (), 1, 0, 0, 0);
        stripped_time_end = stripped_time_end.add_months (1);
        range = new Util.DateRange (stripped_time, stripped_time_end);
        if (Util.is_event_in_range (comp, range)) {
            return 4; // This Month
        }

        stripped_time = new DateTime.local (now.get_year (), now.get_month (), 1, 0, 0, 0);
        stripped_time = stripped_time.add_months (1);
        stripped_time_end = stripped_time.add_months (1);
        range = new Util.DateRange (stripped_time, stripped_time_end);
        if (Util.is_event_in_range (comp, range)) {
            return 5; // Next Month
        }
        return -1;
    }

    private void upcoming_header_update_func (Gtk.ListBoxRow lbrow, Gtk.ListBoxRow? lbbefore) {
        var row = (AgendaEventRow) lbrow;
        int rowType = get_event_type (row);

        if (lbbefore != null) {
            var before = (AgendaEventRow) lbbefore;
            int beforeType = get_event_type (before);

            if (rowType == beforeType) {
                row.set_header (null);
                return;
            }

            switch (rowType) {
                case 1: row.set_header (header_with_label (_("Tomorrow")));
                        break;
                case 2: row.set_header (header_with_label (_("This Week")));
                        break;
                case 3: row.set_header (header_with_label (_("Next Week")));
                        break;
                case 4: row.set_header (header_with_label (_("This Month")));
                        break;
                case 5: row.set_header (header_with_label (_("Next Month")));
                        break;
                default: break;
            }
        } else {
            switch (rowType) {
                case 1: row.set_header (header_with_label (_("Tomorrow")));
                        break;
                case 2: row.set_header (header_with_label (_("This Week")));
                        break;
                case 3: row.set_header (header_with_label (_("Next Week")));
                        break;
                case 4: row.set_header (header_with_label (_("This Month")));
                        break;
                case 5: row.set_header (header_with_label (_("Next Month")));
                        break;
                default: break;
            }
        }
    }

    private Gtk.Widget header_with_label (string text) {
        var label = new Gtk.Label (text);
        label.get_style_context ().add_class ("h4");
        label.hexpand = true;
        label.margin_start = 6;
        label.margin_top = 6;
        label.use_markup = true;
        label.set_alignment (0, 0.5f);
        return label;
    }

    /**
     * Events have been added to the given source.
     */
    void on_events_added (E.Source source, Gee.Collection<E.CalComponent> events) {
        foreach (var event in events) {
            unowned iCal.Component comp = event.get_icalcomponent ();

            if (!row_table.contains (comp.get_uid ())) {
                var row = new AgendaEventRow (source, event, false);
                row.modified.connect ((event) => (event_modified (event)));
                row.removed.connect ((event) => (event_removed (event)));
                row.show_all ();
                row_table.set (comp.get_uid (), row);
                selected_date_events_list.add (row);
            }

            if (!row_table2.contains (comp.get_uid ())) {
                var row2 = new AgendaEventRow (source, event, true);
                row2.modified.connect ((event) => (event_modified (event)));
                row2.removed.connect ((event) => (event_removed (event)));
                row2.show_all ();
                row_table2.set (comp.get_uid (), row2);
                upcoming_events_list.add (row2);
            }
        }
    }

    /**
     * Events for the given source have been updated.
     */
    void on_events_updated (E.Source source, Gee.Collection<E.CalComponent> events) {
        foreach (var event in events) {
            unowned iCal.Component comp = event.get_icalcomponent ();

            var row = (AgendaEventRow)row_table.get (comp.get_uid ());
            row.update (event);

            var row2 = (AgendaEventRow)row_table2.get (comp.get_uid ());
            row2.update (event);
        }
    }

    /**
     * Events for the given source have been removed.
     */
    void on_events_removed (E.Source source, Gee.Collection<E.CalComponent> events) {
        foreach (var event in events) {
            unowned iCal.Component comp = event.get_icalcomponent ();

            var row = (AgendaEventRow)row_table.get (comp.get_uid ());
            row_table.remove (comp.get_uid ());
            if (row is Gtk.Widget) {
                row.revealer.set_reveal_child (false);
                GLib.Timeout.add (row.revealer.transition_duration, () => {
                    row.destroy ();
                    return GLib.Source.REMOVE;
                });
            }

            var row2 = (AgendaEventRow)row_table2.get (comp.get_uid ());
            row_table2.remove (comp.get_uid ());
            if (row2 is Gtk.Widget) {
                row2.revealer.set_reveal_child (false);
                GLib.Timeout.add (row2.revealer.transition_duration, () => {
                    row2.destroy ();
                    return GLib.Source.REMOVE;
                });
            }
        }
    }

    /**
     * Called when the user searches for the given text.
     */
    public void set_search_text (string text) {
        /*search_text = text;
        foreach (var widget in source_widgets.get_values ()) {
            widget.set_search_text (text);
        }*/
    }

    /**
     * The given date has been selected.
     */
    public void set_selected_date (DateTime date) {
        selected_date = date;
        string formated_weekday = date.format ("%A");
        string new_value = formated_weekday.substring (formated_weekday.index_of_nth_char (1));
        new_value = formated_weekday.get_char (0).totitle ().to_string () + new_value;
        weekday_label.label = new_value;
        day_label.label = date.format (Settings.DateFormat ());
        selected_date_events_list.invalidate_filter ();
    }

    public class AgendaEventRow : Gtk.ListBoxRow {
        public signal void removed (E.CalComponent event);
        public signal void modified (E.CalComponent event);

        public string uid { public get; private set; }
        public string summary { public get; private set; }
        public E.CalComponent calevent { public get; private set; }
        public bool is_allday { public get; private set; default=false; }
        public bool is_multiday { public get; private set; default=false; }
        public Gtk.Revealer revealer { public get; private set; }

        private Gtk.Image event_image;
        private Gtk.Label name_label;
        private Gtk.Label datatime_label;
        private Gtk.Label location_label;

        private bool isUpcoming;

        public AgendaEventRow (E.Source source, E.CalComponent calevent, bool isUpcoming) {
            this.calevent = calevent;
            this.isUpcoming = isUpcoming;
            unowned iCal.Component ical_event = calevent.get_icalcomponent ();
            uid = ical_event.get_uid ();

            var main_grid = new Gtk.Grid ();
            main_grid.column_spacing = 6;
            main_grid.row_spacing = 6;
            main_grid.margin = 6;

            E.SourceCalendar cal = (E.SourceCalendar)source.get_extension (E.SOURCE_EXTENSION_CALENDAR);

            event_image = new Gtk.Image.from_icon_name ("office-calendar-symbolic", Gtk.IconSize.MENU);
            event_image.margin_start = 6;
            Util.style_calendar_color (event_image, cal.dup_color ());

            cal.notify["color"].connect (() => {
                Util.style_calendar_color (event_image, cal.dup_color ());
            });

            name_label = new Gtk.Label ("");
            name_label.hexpand = true;
            name_label.wrap = true;
            name_label.wrap_mode = Pango.WrapMode.WORD_CHAR;
            name_label.xalign = 0;

            datatime_label = new Gtk.Label ("");
            datatime_label.ellipsize = Pango.EllipsizeMode.END;
            datatime_label.xalign = 0;
            datatime_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

            location_label = new Gtk.Label ("");
            location_label.no_show_all = true;
            location_label.wrap = true;
            location_label.xalign = 0;
            location_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

            main_grid.attach (event_image, 0, 0, 1, 1);
            main_grid.attach (name_label, 1, 0, 1, 1);
            main_grid.attach (datatime_label, 1, 1, 1, 1);
            main_grid.attach (location_label, 1, 2, 1, 1);

            var event_box = new Gtk.EventBox ();
            event_box.add (main_grid);

            revealer = new Gtk.Revealer ();
            revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
            revealer.add (event_box);
            add (revealer);

            show.connect (() => {
                revealer.set_reveal_child (true);
            });

            hide.connect (() => {
                revealer.set_reveal_child (false);
            });

            add_events (Gdk.EventMask.BUTTON_PRESS_MASK);
            button_press_event.connect (on_button_press);

            // Fill in the information
            update (calevent);
        }

        private bool on_button_press (Gdk.EventButton event) {
            if (event.type == Gdk.EventType.@2BUTTON_PRESS) {
                 modified (calevent);
            } else if (event.type == Gdk.EventType.BUTTON_PRESS && event.button == Gdk.BUTTON_SECONDARY) {
                Gtk.Menu menu = new Gtk.Menu ();
                menu.attach_to_widget (this, null);
                var edit_item = new Gtk.MenuItem.with_label (_("Edit…"));
                var remove_item = new Gtk.MenuItem.with_label (_("Remove"));
                edit_item.activate.connect (() => { modified (calevent); });
                remove_item.activate.connect (() => { removed (calevent); });

                E.Source src = calevent.get_data ("source");
                if (src.writable != true && Model.CalendarModel.get_default ().calclient_is_readonly (src) != false) {
                    edit_item.sensitive = false;
                    remove_item.sensitive = false;
                }

                menu.append (edit_item);
                menu.append (remove_item);

                menu.popup_at_pointer (event);
                menu.show_all ();
            }

            return true;
        }

        /**
         * Updates the event to match the given event.
         */
        public void update (E.CalComponent event) {
            unowned iCal.Component ical_event = event.get_icalcomponent ();
            summary = ical_event.get_summary ();
            name_label.set_markup (Markup.escape_text (summary));

            DateTime start_date, end_date;
            Util.get_local_datetimes_from_icalcomponent (ical_event, out start_date, out end_date);

            is_allday = Util.is_all_day (start_date, end_date);
            is_multiday = Util.is_multiday_event (ical_event);

            string start_date_string = start_date.format (Settings.DateFormat_Complete ());
            string end_date_string = end_date.format (Settings.DateFormat_Complete ());
            string start_time_string = start_date.format (Settings.TimeFormat ());
            string end_time_string = end_date.format (Settings.TimeFormat ());

            datatime_label.show ();
            datatime_label.no_show_all = false;
            if (is_multiday) {
                if (is_allday) {
                    datatime_label.label = _("%s - %s").printf (start_date_string, end_date_string);
                } else {
                    datatime_label.label = _("%s, %s - %s, %s").printf (start_date_string, start_time_string, end_date_string, end_time_string);
                }
            } else {
                if (!isUpcoming) {
                    if (is_allday) {
                        datatime_label.hide ();
                        datatime_label.no_show_all = true;
                    } else {
                        datatime_label.label = _("%s - %s").printf (start_time_string, end_time_string);
                    }
                } else {
                    if (is_allday) {
                        datatime_label.label = _("%s").printf (start_date_string);
                    } else {
                        datatime_label.label = _("%s, %s - %s").printf (start_date_string, start_time_string, end_time_string);
                    }
                }
            }

            string location = ical_event.get_location ();
            if (location != null && location != "") {
                location_label.label = location;
                location_label.show ();
            } else {
                location_label.hide ();
                location_label.no_show_all = true;
            }
        }
    }
}
