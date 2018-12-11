public class Widgets.Events : Gtk.Revealer {
    public signal void event_removed (E.CalComponent event);
    public signal void event_modified (E.CalComponent event);

    private Gtk.Label day_label;
    private DateTime selected_date;
    private Gtk.Label weekday_label;

    private Gtk.Button close_button;
    private Widgets.Weather weather_widget;
    private Gtk.Grid event_grid;

    private Gtk.ListBox selected_date_events_list;
    private HashTable<string, AgendaEventRow> row_table;

    public signal void on_signal_close ();

    public Events () {
        Object (
            transition_type: Gtk.RevealerTransitionType.SLIDE_LEFT,
            transition_duration: 300,
            reveal_child: false,
            margin: 6
        );
    }

    construct {
        selected_date = new GLib.DateTime.now_local ();
        row_table = new HashTable<string, AgendaEventRow> (str_hash, str_equal);

        day_label = new Gtk.Label ("");
        day_label.set_alignment (0, 0.5f);
        day_label.use_markup = true;
        day_label.get_style_context ().add_class ("h3");
        day_label.margin = 12;
        day_label.margin_top = 0;
        day_label.margin_bottom = 6;

        weekday_label = new Gtk.Label ("");
        weekday_label.set_alignment (0, 0.5f);
        weekday_label.use_markup = true;
        weekday_label.get_style_context ().add_class ("h2");
        weekday_label.margin = 12;
        weekday_label.margin_bottom = 0;

        close_button = new Gtk.Button.from_icon_name ("pan-end-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
        close_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
        close_button.get_style_context ().add_class ("no-padding");
        close_button.height_request = 64;
        close_button.can_focus = false;
        close_button.valign = Gtk.Align.CENTER;
        close_button.halign = Gtk.Align.START;

        weather_widget = new Widgets.Weather ();

        var events_label = new Granite.HeaderLabel (_("Up next"));
        events_label.margin_start = 6;

        selected_date_events_list = new Gtk.ListBox ();
        selected_date_events_list.selection_mode = Gtk.SelectionMode.SINGLE;

        var main_grid = new Gtk.Grid ();
        main_grid.width_request = 250;
        main_grid.get_style_context ().add_class ("popover");
        main_grid.get_style_context ().add_class ("planner-popover");
        main_grid.orientation = Gtk.Orientation.VERTICAL;

        main_grid.add (weather_widget);
        main_grid.add (events_label);
        main_grid.add (selected_date_events_list);

        var main_overlay = new Gtk.Overlay ();
        main_overlay.add_overlay (close_button);
        main_overlay.add (main_grid);

        add (main_overlay);

        close_button.clicked.connect (() => {
            on_signal_close ();
        });

        // Listen to changes for events
        var calmodel = Maya.Model.CalendarModel.get_default ();
        calmodel.events_added.connect (on_events_added);
        calmodel.events_removed.connect (on_events_removed);
        calmodel.events_updated.connect (on_events_updated);
        set_selected_date (Maya.Settings.SavedState.get_default ().get_selected ());
        show_all ();

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
                    Maya.Util.get_local_datetimes_from_icalcomponent (ical_event1, out start_date1, out end_date1);
                    unowned iCal.Component ical_event2 = row2.calevent.get_icalcomponent ();
                    DateTime start_date2, end_date2;
                    Maya.Util.get_local_datetimes_from_icalcomponent (ical_event2, out start_date2, out end_date2);
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
            var range = new Maya.Util.DateRange (stripped_time, stripped_time.add_days (1));
            Gee.Collection<Maya.Util.DateRange> event_ranges = Maya.Util.event_date_ranges (comp, range);

            foreach (Maya.Util.DateRange event_range in event_ranges) {
                if (Maya.Util.is_day_in_range (stripped_time, event_range)) {
                    return true;
                }
            }

            return false;
        });
    }

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

            /*
            if (!row_table2.contains (comp.get_uid ())) {
                var row2 = new AgendaEventRow (source, event, true);
                row2.modified.connect ((event) => (event_modified (event)));
                row2.removed.connect ((event) => (event_removed (event)));
                row2.show_all ();
                row_table2.set (comp.get_uid (), row2);
                upcoming_events_list.add (row2);
            }
            */
        }
    }

    void on_events_updated (E.Source source, Gee.Collection<E.CalComponent> events) {
        foreach (var event in events) {
            unowned iCal.Component comp = event.get_icalcomponent ();

            var row = (AgendaEventRow)row_table.get (comp.get_uid ());
            row.update (event);
            /*
            var row2 = (AgendaEventRow)row_table2.get (comp.get_uid ());
            row2.update (event);
            */
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

            /*
            var row2 = (AgendaEventRow)row_table2.get (comp.get_uid ());
            row_table2.remove (comp.get_uid ());
            if (row2 is Gtk.Widget) {
                row2.revealer.set_reveal_child (false);
                GLib.Timeout.add (row2.revealer.transition_duration, () => {
                    row2.destroy ();
                    return GLib.Source.REMOVE;
                });
            }
            */
        }
    }

    public void set_selected_date (DateTime date) {
        selected_date = date;
        string formated_weekday = date.format ("%A");
        string new_value = formated_weekday.substring (formated_weekday.index_of_nth_char (1));
        new_value = formated_weekday.get_char (0).totitle ().to_string () + new_value;
        weekday_label.label = new_value;
        day_label.label = date.format (Maya.Settings.DateFormat ());
        selected_date_events_list.invalidate_filter ();
    }
}
