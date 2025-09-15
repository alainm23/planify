/*
 * Copyright © 2023 Alain M. (https://github.com/alainm23/planify)
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

public class Widgets.EventRow : Gtk.ListBoxRow {
    public unowned ICal.Component component { get; construct; }
    public unowned E.SourceCalendar cal { get; construct; }
    public E.Source source { get; set; }

    public GLib.DateTime start_time { get; private set; }
    public GLib.DateTime ? end_time { get; private set; }
    public bool is_allday { get; private set; default = false; }

    private Gtk.Grid color_grid;
    private Gtk.Label time_label;

    private Gee.HashMap<ulong, weak GLib.Object> signal_map = new Gee.HashMap<ulong, weak GLib.Object> ();

    public EventRow (ICal.Component component, E.Source source) {
        Object (
            component : component,
            cal: (E.SourceCalendar ?) source.get_extension (E.SOURCE_EXTENSION_CALENDAR)
        );
    }

    ~EventRow () {
        debug ("Destroying - Widgets.EventRow\n");
    }

    construct {
        add_css_class ("no-selectable");
        add_css_class ("transition");

        var dt_start = component.get_dtstart ();
        end_time = CalendarEventsUtil.ical_to_date_time (component.get_dtend ());

        if (dt_start.is_date ()) {
            // Don't convert timezone for date with only day info, leave it at midnight UTC
            start_time = CalendarEventsUtil.ical_to_date_time (dt_start);
        } else {
            start_time = CalendarEventsUtil.ical_to_date_time (dt_start).to_local ();
        }

        var dt_end = component.get_dtend ();
        if (dt_end.is_date ()) {
            // Don't convert timezone for date with only day info, leave it at midnight UTC
            end_time = CalendarEventsUtil.ical_to_date_time (dt_end);
        } else {
            end_time = CalendarEventsUtil.ical_to_date_time (dt_end).to_local ();
        }

        if (end_time != null && CalendarEventsUtil.is_the_all_day (start_time, end_time)) {
            is_allday = true;
        }

        color_grid = new Gtk.Grid () {
            width_request = 3,
            height_request = 12,
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER,
            css_classes = { "event-bar" }
        };

        time_label = new Gtk.Label (null) {
            xalign = 0,
            valign = Gtk.Align.CENTER,
            css_classes = { "dimmed", "caption" }
        };

        var name_label = new Gtk.Label (component.get_summary ()) {
            valign = Gtk.Align.CENTER,
            ellipsize = Pango.EllipsizeMode.END,
            wrap = true,
            use_markup = true,
            wrap_mode = Pango.WrapMode.WORD_CHAR,
            margin_start = 3,
            css_classes = { "caption" }
        };

        var grid = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            margin_top = 3,
            margin_bottom = 3
        };

        if (!is_allday) {
            grid.append (time_label);
        }

        grid.append (color_grid);
        grid.append (name_label);

        child = grid;

        update_color ();
        signal_map[cal.notify["color"].connect (update_color)] = cal;
        update_timelabel ();

        signal_map[Services.Settings.get_default ().settings.changed["clock-format"].connect (update_timelabel)] = Services.Settings.get_default ();
    }

    private void update_timelabel () {
        string format = Utils.Datetime.is_clock_format_12h () ? "%I:%M %p" : "%H:%M";
        time_label.label = start_time.format (format);
    }

    private void update_color () {
        Util.get_default ().set_widget_color (cal.dup_color (), color_grid);
    }

    public void clean_up () {
        foreach (var entry in signal_map.entries) {
            entry.value.disconnect (entry.key);
        }

        signal_map.clear ();
    }
}
