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

public class Widgets.SourceItem : Gtk.ListBoxRow {
    public signal void remove_request (E.Source source);
    public signal void edit_request (E.Source source);

    public string location { public get; private set; }
    public string label { public get; private set; }
    public E.Source source { public get; private set; }

    private Gtk.Label calendar_name_label;
    //private Gtk.Label calendar_color_label;
    private Gtk.CheckButton visible_checkbutton;

    public SourceItem (E.Source source) {
        this.source = source;

        // Source widget
        E.SourceCalendar cal = (E.SourceCalendar)source.get_extension (E.SOURCE_EXTENSION_CALENDAR);

        calendar_name_label = new Gtk.Label (source.dup_display_name ());
        calendar_name_label.xalign = 0;
        calendar_name_label.hexpand = true;

        label = source.dup_display_name ();
        location = Maya.Util.get_source_location (source);

        visible_checkbutton = new Gtk.CheckButton ();
        visible_checkbutton.active = cal.selected;
        visible_checkbutton.toggled.connect (() => {
            var calmodel = Maya.Model.CalendarModel.get_default ();
            if (visible_checkbutton.active == true) {
                calmodel.add_source (source);
            } else {
                calmodel.remove_source (source);
            }

            cal.set_selected (visible_checkbutton.active);
            try {
                source.write_sync ();
            } catch (GLib.Error error) {
                critical (error.message);
            }
        });

        style_calendar_color (cal.dup_color ());

        var calendar_grid = new Gtk.Grid ();
        calendar_grid.column_spacing = 6;
        calendar_grid.margin = 6;
        calendar_grid.attach (visible_checkbutton, 0, 0, 1, 1);
        //calendar_grid.attach (calendar_color_label, 1, 0, 1, 1);
        calendar_grid.attach (calendar_name_label, 2, 0, 1, 1);

        add (calendar_grid);

        source.changed.connect (source_has_changed);
    }

    private void style_calendar_color (string color) {
        var css_color = "@define-color colorAccent %s;".printf (color);

        var style_provider = new Gtk.CssProvider ();

        try {
            style_provider.load_from_data (css_color, css_color.length);
            visible_checkbutton.get_style_context ().add_provider (style_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (Error e) {
            warning ("Could not create CSS Provider: %s\nStylesheet:\n%s", e.message, css_color);
        }
    }

    public void source_has_changed () {
        calendar_name_label.label = source.dup_display_name ();

        E.SourceCalendar cal = (E.SourceCalendar)source.get_extension (E.SOURCE_EXTENSION_CALENDAR);

        style_calendar_color (cal.dup_color ());

        visible_checkbutton.active = cal.selected;
    }
}

public class Widgets.SourceItemHeader : Gtk.ListBoxRow {
    public string label { public get; private set; }
    public uint children = 1;
    public SourceItemHeader (string label) {
        this.label = label;
        var header_label = new Gtk.Label (label);
        header_label.get_style_context ().add_class ("h4");
        header_label.xalign = 0.0f;
        header_label.hexpand = true;
        add (header_label);
    }
}
