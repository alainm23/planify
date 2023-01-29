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

public class Widgets.EventRow : Gtk.ListBoxRow {
    public unowned ICal.Component component { get; construct; }
    public unowned E.SourceCalendar cal { get; construct; }
    public E.Source source { get; set; }

    public GLib.DateTime start_time { get; private set; }
    public GLib.DateTime? end_time { get; private set; }
    public bool is_allday { get; private set; default = false; }

    private Gtk.Revealer main_revealer;

    private Gtk.Grid color_grid;
    private Gtk.Label time_label;

    public EventRow (ICal.Component component, E.Source source) {
        Object (
            component: component,
            cal: (E.SourceCalendar?) source.get_extension (E.SOURCE_EXTENSION_CALENDAR)
        );
    }

    construct {
        add_css_class ("selectable-item");
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

        color_grid = new Gtk.Grid ();
        color_grid.width_request = 3;
        color_grid.height_request = 12;
        color_grid.valign = Gtk.Align.CENTER;
        color_grid.halign = Gtk.Align.CENTER;
        color_grid.get_style_context ().add_class ("event-%s".printf (component.get_uid ()));

        time_label = new Gtk.Label (null) {
            xalign = 0,
            valign = Gtk.Align.CENTER,
            width_chars = 7
        };
        time_label.get_style_context ().add_class (Granite.STYLE_CLASS_DIM_LABEL);
        time_label.get_style_context ().add_class (Granite.STYLE_CLASS_SMALL_LABEL);

        var name_label = new Gtk.Label (component.get_summary ()) {
            valign = Gtk.Align.CENTER,
            ellipsize = Pango.EllipsizeMode.END,
            wrap = true,
            use_markup = true,
            wrap_mode = Pango.WrapMode.WORD_CHAR,
            margin_start = 3
        };
        name_label.get_style_context ().add_class (Granite.STYLE_CLASS_SMALL_LABEL);

        var grid = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            margin_top = 3,
            margin_bottom = 3
        };

        if (!is_allday) {
            grid.append (time_label);
        }
        
        grid.append (color_grid);
        grid.append (name_label);

        main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };
        main_revealer.child = grid;

        child = main_revealer;

        set_color ();
        cal.notify["color"].connect (set_color);

        update_timelabel ();
    }

    private void update_timelabel () {
        // var time_format = Granite.DateTime.get_default_time_format (true, false);
        time_label.label = "%s".printf (
            start_time.format ("%I:%M %p")
        );
    }

    private void set_color () {
        var color = cal.dup_color ();
        string color_css = """
            .event-%s {
                background-color: %s;
                border-radius: 1px;
            }
        """;

        var provider = new Gtk.CssProvider ();

        var colored_css = color_css.printf (
            component.get_uid (),
            color
        );

        provider.load_from_data (colored_css.data);

        Gtk.StyleContext.add_provider_for_display (
            Gdk.Display.get_default (), provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );
    }
}