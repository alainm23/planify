/*
* Copyright © 2019 Alain M. (https://github.com/alainm23/planner)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
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
* Authored by: Alain M. <alain23@protonmail.com>
*/

public class Widgets.CalendarEvents : Gtk.Revealer {
    public signal void event_removed (E.CalComponent event);
    public signal void event_modified (E.CalComponent event);

    private Gtk.Revealer box_revealer;
    private Gtk.Stack main_stack;

    private Gtk.Label day_label;
    private DateTime selected_date;
    private Gtk.Label weekday_label;

    private Widgets.Weather weather_widget;

    private Gtk.ListBox selected_date_events_list;
    private HashTable<string, AgendaEventRow> row_table;

    public signal void on_signal_close ();

    public CalendarEvents () {
        Object (
            transition_type: Gtk.RevealerTransitionType.SLIDE_LEFT,
            transition_duration: 300,
            reveal_child: false,
            margin_end: 3
        );
    }

    construct {
        weekday_label = new Gtk.Label ("");
        weekday_label.hexpand = true;
        weekday_label.halign = Gtk.Align.END;
        weekday_label.xalign = 0;
        weekday_label.use_markup = true;
        weekday_label.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);

        day_label = new Gtk.Label ("");
        day_label.hexpand = true;
        day_label.halign = Gtk.Align.END;
        day_label.xalign = 0;
        day_label.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);

        var selected_data_grid = new Gtk.Grid ();
        selected_data_grid.margin = 6;
        selected_data_grid.margin_start = selected_data_grid.margin_end = 12;
        selected_data_grid.row_spacing = 3;
        selected_data_grid.orientation = Gtk.Orientation.VERTICAL;
        selected_data_grid.add (weekday_label);
        selected_data_grid.add (day_label);

        var mode_button = new Granite.Widgets.ModeButton ();
        mode_button.hexpand = true;
        mode_button.margin = 6;

        mode_button.append_text (_("Events"));
        mode_button.append_text (_("Notifications"));
        mode_button.selected = 0;

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        box.add (selected_data_grid);
        //box.add (mode_button);

        box_revealer = new Gtk.Revealer ();
        box_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        box_revealer.add (box);
        box_revealer.reveal_child = true;

        main_stack = new Gtk.Stack ();
        main_stack.expand = true;
        main_stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;

        main_stack.add_named (get_calendar_event_widget (), "calendar_event");
        main_stack.add_named (get_notifications_widget (), "notifications");

        var content_grid = new Gtk.Grid ();
        content_grid.orientation = Gtk.Orientation.VERTICAL;
        content_grid.add (box_revealer);
        content_grid.add (main_stack);

        var scrolled_window = new Gtk.ScrolledWindow (null, null);
        scrolled_window.width_request = 275;
        scrolled_window.hscrollbar_policy = Gtk.PolicyType.NEVER;
        scrolled_window.get_style_context ().add_class ("popover");
        scrolled_window.get_style_context ().add_class ("planner-popover");
        scrolled_window.expand = true;
        scrolled_window.add (content_grid);

        mode_button.mode_changed.connect ((widget) => {
            if (mode_button.selected == 0) {
                main_stack.visible_child_name = "calendar_event";
            } else if (mode_button.selected == 1){
                main_stack.visible_child_name = "notifications";
            }
        });

        add (scrolled_window);
    }

    private Gtk.Widget get_calendar_event_widget () {
        row_table = new HashTable<string, AgendaEventRow> (str_hash, str_equal);

        weather_widget = new Widgets.Weather ();

        var weather_revealer = new Gtk.Revealer ();
        weather_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        weather_revealer.add (weather_widget);
        weather_revealer.reveal_child = true;

        var calendar = new Widgets.Calendar.Calendar ();

        var calendar_revealer = new Gtk.Revealer ();
        calendar_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        calendar_revealer.add (calendar);
        calendar_revealer.reveal_child = false;

        var events_label = new Granite.HeaderLabel (_("Today"));
        events_label.margin_start = 9;

        selected_date_events_list = new Gtk.ListBox ();
        selected_date_events_list.selection_mode = Gtk.SelectionMode.NONE;

        var events_grid = new Gtk.Grid ();
        events_grid.orientation = Gtk.Orientation.VERTICAL;
        events_grid.add (events_label);
        events_grid.add (selected_date_events_list);

        var events_list_revealer = new Gtk.Revealer ();
        events_list_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        events_list_revealer.margin_top = 6;
        events_list_revealer.add (events_grid);
        events_list_revealer.reveal_child = true;

        var show_calendar_button = new Gtk.Button.from_icon_name ("window-close-symbolic", Gtk.IconSize.MENU);
        show_calendar_button.can_focus = false;
        show_calendar_button.focus_on_click = false;
        show_calendar_button.valign = Gtk.Align.CENTER;
        show_calendar_button.halign = Gtk.Align.CENTER;

        var show_hide_calendar_button = new Gtk.Button.from_icon_name ("pan-up-symbolic", Gtk.IconSize.MENU);
        show_hide_calendar_button.can_focus = false;
        show_hide_calendar_button.margin = 3;
        show_hide_calendar_button.focus_on_click = false;
        show_hide_calendar_button.valign = Gtk.Align.CENTER;
        show_hide_calendar_button.halign = Gtk.Align.CENTER;
        show_hide_calendar_button.get_style_context ().add_class ("planner-button-ani");

        var calendar_button = new Gtk.Button.with_label (_("Calendar"));
        calendar_button.margin = 3;
        calendar_button.can_focus = false;
        calendar_button.valign = Gtk.Align.CENTER;
        calendar_button.hexpand = true;
        calendar_button.halign = Gtk.Align.CENTER;
        calendar_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        calendar_button.get_style_context ().add_class ("no-padding");

        var add_event_button = new Gtk.Button.from_icon_name ("list-add-symbolic", Gtk.IconSize.MENU);
        add_event_button.can_focus = false;
        add_event_button.margin_end = 3;
        add_event_button.valign = Gtk.Align.CENTER;
        add_event_button.halign = Gtk.Align.CENTER;
        add_event_button.tooltip_text = _("Add new project");

        var action_bar = new Gtk.ActionBar ();
        action_bar.get_style_context ().add_class (Gtk.STYLE_CLASS_INLINE_TOOLBAR);
        action_bar.get_style_context ().add_class ("planner-actionbar");
        action_bar.pack_start (show_hide_calendar_button);
        action_bar.set_center_widget (calendar_button);
        //action_bar.pack_end (add_event_button);

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

        main_box.pack_start (weather_revealer, false, false, 0);
        main_box.pack_start (events_label, false, false, 0);
        main_box.pack_start (events_list_revealer, false, false, 0);
        main_box.pack_end (calendar_revealer, false, false, 0);
        main_box.pack_end (action_bar, false, false, 0);

        calendar.selection_changed.connect ((date) => {
            set_selected_date (date);

            events_label.label = Application.utils.get_relative_default_date_format_from_date (date);
        });

        calendar_button.clicked.connect (() => {
            if (calendar_revealer.reveal_child) {
                calendar_revealer.reveal_child = false;

                weather_revealer.reveal_child = true;
                box_revealer.reveal_child = true;

                Timeout.add (300, () => {
				    show_hide_calendar_button.get_style_context ().remove_class ("closed");
				    return false;
			    });

                var now = new GLib.DateTime.now_local ();
                set_selected_date (now);
                events_label.label = Application.utils.get_relative_default_date_format_from_date (now);
            } else {
                calendar_revealer.reveal_child = true;

                weather_revealer.reveal_child  = false;
                box_revealer.reveal_child = false;

                Timeout.add (300, () => {
				    show_hide_calendar_button.get_style_context ().add_class ("closed");
				    return false;
			    });
            }
        });

        show_hide_calendar_button.clicked.connect (() => {
            if (calendar_revealer.reveal_child) {
                calendar_revealer.reveal_child = false;

                weather_revealer.reveal_child = true;
                box_revealer.reveal_child = true;

                Timeout.add (300, () => {
				    show_hide_calendar_button.get_style_context ().remove_class ("closed");
				    return false;
			    });
            } else {
                calendar_revealer.reveal_child = true;

                weather_revealer.reveal_child  = false;
                box_revealer.reveal_child = false;

                Timeout.add (300, () => {
				    show_hide_calendar_button.get_style_context ().add_class ("closed");
				    return false;
			    });
            }
        });

        Application.settings.changed.connect ((key) => {
            if (key == "show-calendar-events") {
                events_list_revealer.reveal_child = Application.settings.get_boolean ("show-calendar-events");
            }
        });

        // Listen to changes for events
        var calmodel = Maya.Model.CalendarModel.get_default ();
        calmodel.events_added.connect (on_events_added);
        calmodel.events_removed.connect (on_events_removed);
        calmodel.events_updated.connect (on_events_updated);

        set_selected_date (new GLib.DateTime.now_local ());
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

        return main_box;
    }

    private Gtk.Widget get_notifications_widget () {
        var main_grid = new Gtk.Grid ();
        main_grid.valign = Gtk.Align.CENTER;
        main_grid.halign = Gtk.Align.CENTER;
        main_grid.expand = true;

        return main_grid;
    }

    private void on_events_added (E.Source source, Gee.Collection<E.CalComponent> events) {
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
        }

        selected_date_events_list.invalidate_sort ();
    }

    private void on_events_updated (E.Source source, Gee.Collection<E.CalComponent> events) {
        foreach (var event in events) {
            unowned iCal.Component comp = event.get_icalcomponent ();

            var row = (AgendaEventRow)row_table.get (comp.get_uid ());
            row.update (event);
        }

        selected_date_events_list.invalidate_sort ();
    }

    private void on_events_removed (E.Source source, Gee.Collection<E.CalComponent> events) {
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
        }

        selected_date_events_list.invalidate_sort ();
    }

    public void set_selected_date (DateTime date) {
        selected_date = date;

        string formated_weekday = date.format ("%A");
        string new_value = formated_weekday.substring (formated_weekday.index_of_nth_char (1));

        new_value = formated_weekday.get_char (0).totitle ().to_string () + new_value;
        weekday_label.label = "<b>%s</b>".printf (new_value);
        day_label.label = date.format (Maya.Settings.DateFormat ());

        selected_date_events_list.invalidate_filter ();
    }
}
