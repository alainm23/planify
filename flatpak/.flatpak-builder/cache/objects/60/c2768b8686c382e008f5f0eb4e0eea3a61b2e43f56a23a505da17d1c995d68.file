/*
 * Copyright 2011-2018 elementary, Inc. (https://elementary.io)
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

public class AgendaEventRow : Gtk.ListBoxRow {
    public signal void removed (E.CalComponent event);
    public signal void modified (E.CalComponent event);

    public string uid { public get; private set; }
    public string summary { public get; private set; }
    public E.CalComponent calevent { public get; private set; }
    public bool is_allday { public get; private set; default=false; }
    public bool is_multiday { public get; private set; default=false; }
    public Gtk.Revealer revealer { public get; private set; }

    private Gtk.Label event_label;
    private Gtk.Label name_label;
    private Gtk.Label source_label;
    private Gtk.Label datatime_label;
    private Gtk.Label location_label;

    private bool isUpcoming;

    public AgendaEventRow (E.Source source, E.CalComponent calevent, bool isUpcoming) {
        margin_start = 3;

        this.calevent = calevent;
        this.isUpcoming = isUpcoming;
        unowned iCal.Component ical_event = calevent.get_icalcomponent ();
        uid = ical_event.get_uid ();

        E.SourceCalendar cal = (E.SourceCalendar)source.get_extension (E.SOURCE_EXTENSION_CALENDAR);

        //event_label = new Gtk.Image.from_icon_name ("mail-unread-symbolic", Gtk.IconSize.MENU);
        event_label = new Gtk.Label (null);
        event_label.width_request = 3;
        Maya.Util.style_calendar_color (event_label, cal.dup_color (), true);

        cal.notify["color"].connect (() => {
            Maya.Util.style_calendar_color (event_label, cal.dup_color (), true);
        });

        name_label = new Gtk.Label ("");
        name_label.margin_bottom = 1;
        name_label.hexpand = true;
        name_label.wrap = true;
        name_label.wrap_mode = Pango.WrapMode.WORD_CHAR;
        name_label.xalign = 0;

        source_label = new Gtk.Label (Maya.Util.get_source_location (source));
        source_label.wrap = true;
        source_label.wrap_mode = Pango.WrapMode.WORD_CHAR;
        source_label.xalign = 0;

        var source_revealer = new Gtk.Revealer ();
        source_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
        source_revealer.add (source_label);
        source_revealer.reveal_child = false;

        datatime_label = new Gtk.Label (null);
        datatime_label.use_markup = true;
        datatime_label.ellipsize = Pango.EllipsizeMode.END;
        datatime_label.xalign = 0;
        datatime_label.valign = Gtk.Align.START;
        datatime_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        location_label = new Gtk.Label ("");
        location_label.no_show_all = true;
        location_label.wrap = true;
        location_label.xalign = 0;
        //location_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        var location_revealer = new Gtk.Revealer ();
        location_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        location_revealer.add (location_label);
        location_revealer.reveal_child = true;

        var main_grid = new Gtk.Grid ();
        main_grid.column_spacing = 6;
        main_grid.margin = 6;

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        box.pack_start (name_label, false, false, 0);
        box.pack_start (location_revealer, false, false, 0);
        box.pack_start (source_revealer, false, false, 0);

        main_grid.add (datatime_label);
        main_grid.add (event_label);
        main_grid.add (box);

        var event_box = new Gtk.EventBox ();
        event_box.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
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

        event_box.enter_notify_event.connect ((event) => {
            location_revealer.reveal_child = false;
            source_revealer.reveal_child = true;

            return false;
        });

        event_box.leave_notify_event.connect ((event) => {
            if (event.detail == Gdk.NotifyType.INFERIOR) {
                return false;
            }

            location_revealer.reveal_child = true;
            source_revealer.reveal_child = false;

            return false;
        });

        // Fill in the information
        update (calevent);
    }
    /**
     * Updates the event to match the given event.
     */
    public void update (E.CalComponent event) {
        unowned iCal.Component ical_event = event.get_icalcomponent ();
        summary = ical_event.get_summary ();
        name_label.set_markup (Markup.escape_text (summary));

        DateTime start_date, end_date;
        Maya.Util.get_local_datetimes_from_icalcomponent (ical_event, out start_date, out end_date);

        is_allday = Maya.Util.is_all_day (start_date, end_date);
        is_multiday = Maya.Util.is_multiday_event (ical_event);

        string start_date_string = start_date.format (Maya.Settings.DateFormat_Complete ());
        string end_date_string = end_date.format (Maya.Settings.DateFormat_Complete ());
        string start_time_string = start_date.format (Maya.Settings.TimeFormat ());
        string end_time_string = end_date.format (Maya.Settings.TimeFormat ());

        datatime_label.show ();
        datatime_label.no_show_all = false;
        if (is_multiday) {
            if (is_allday) {
                datatime_label.label = _("%s\n%s").printf (start_date_string, end_date_string);
            } else {
                datatime_label.label = _("%s, %s\n%s, %s").printf (start_date_string, start_time_string, end_date_string, end_time_string);
            }
        } else {
            if (!isUpcoming) {
                if (is_allday) {
                    datatime_label.hide ();
                    datatime_label.no_show_all = true;
                } else {
                    datatime_label.label = _("%s\n%s").printf (start_time_string, end_time_string);
                }
            } else {
                if (is_allday) {
                    datatime_label.label = _("%s").printf (start_date_string);
                } else {
                    datatime_label.label = _("%s, %s\n%s").printf (start_date_string, start_time_string, end_time_string);
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
