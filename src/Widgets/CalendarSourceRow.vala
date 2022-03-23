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

public class Widgets.CalendarSourceRow : Gtk.ListBoxRow {
    public E.Source source { get; construct; }

    public bool source_enabled {
        get {
            return checked_button.active;
        }
    }

    private Gtk.CheckButton checked_button;

    public signal void visible_changed ();

    public CalendarSourceRow (E.Source source) {
        Object (source: source);
    }

    construct {
        E.SourceCalendar cal = (E.SourceCalendar)source.get_extension (E.SOURCE_EXTENSION_CALENDAR);

        checked_button = new Gtk.CheckButton.with_label (source.dup_display_name ());
        checked_button.can_focus = false;
        checked_button.active = !get_source_visible ();
        checked_button.get_style_context ().add_class ("default_check");

        var source_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);

        source_box.pack_start (checked_button, false, false, 0);

        add (source_box);

        style_calendar_color (cal.dup_color ());
        checked_button.toggled.connect (() => {
            visible_changed ();
        });
    }

    private bool get_source_visible () {
        bool returned = false;

        foreach (var uid in Planner.settings.get_strv ("calendar-sources-disabled")) {
            if (source.dup_uid () == uid) {
                return true;
            }
        }

        return returned;
    }

    private void style_calendar_color (string color) {
        string style = """
                @define-color colorAccent %s;
                @define-color accent_color %s;
            """.printf (color.slice (0, 7), color.slice (0, 7));

        var style_provider = new Gtk.CssProvider ();

        try {
            style_provider.load_from_data (style, style.length);
            checked_button.get_style_context ().add_provider (style_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (Error e) {
            warning ("Could not create CSS Provider: %s\nStylesheet:\n%s", e.message, style);
        }
    }
}