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

public class Widgets.SourceItem : Gtk.ListBoxRow {
    public signal void remove_request (E.Source source);
    public signal void edit_request (E.Source source);

    public string location { public get; private set; }
    public string label { public get; private set; }
    public bool source_enabled {
        get {
            return visible_checkbutton.active;
        }
    }
    public E.Source source { public get; private set; }

    private Gtk.Label calendar_name_label;
    private Gtk.CheckButton visible_checkbutton;

    public signal void visible_changed ();

    public SourceItem (E.Source source) {
        this.source = source;

        E.SourceCalendar cal = (E.SourceCalendar)source.get_extension (E.SOURCE_EXTENSION_CALENDAR);

        calendar_name_label = new Gtk.Label (source.dup_display_name ());
        calendar_name_label.get_style_context ().add_class ("font-weight-600");
        calendar_name_label.xalign = 0;
        calendar_name_label.hexpand = true;

        label = source.dup_display_name ();
        location = Util.get_source_location (source);

        visible_checkbutton = new Gtk.CheckButton ();
        visible_checkbutton.can_focus = false;
        visible_checkbutton.get_style_context ().add_class ("checklist-radio");
        visible_checkbutton.active = !get_source_visible ();

        var location_label = new Gtk.Label ("<small>%s</small>".printf (location));
        location_label.xalign = 0;
        location_label.hexpand = true;
        location_label.use_markup = true;

        var color_grid = new Gtk.Grid ();
        color_grid.height_request = 24;
        color_grid.width_request = 3;
        color_grid.valign = Gtk.Align.CENTER;
        color_grid.get_style_context ().add_class ("source-%s".printf (source.dup_uid ()));

        var grid = new Gtk.Grid ();
        grid.column_spacing = 6;
        grid.margin_start = 12;
        grid.margin_end = 12;
        grid.margin_top = 3;
        grid.margin_bottom = 3;

        grid.attach (visible_checkbutton, 0, 0, 1, 2);
        grid.attach (color_grid, 1, 0, 1, 2);
        grid.attach (calendar_name_label, 2, 0, 1, 1);
        grid.attach (location_label, 2, 1, 1, 1);

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.get_style_context ().add_class ("view");
        main_box.hexpand = true;
        main_box.pack_start (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), false, true, 0);
        main_box.pack_start (grid, false, true, 0);

        add (main_box);

        style_calendar_color (cal.dup_color ());
        visible_checkbutton.toggled.connect (() => {
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
        string css = """
            .source-%s {
                background-color: %s;
                border-radius: 4px;
            }
        """;

        var provider = new Gtk.CssProvider ();

        try {
            var colored_css = css.printf (
                source.dup_uid (),
                color
            );

            provider.load_from_data (colored_css, colored_css.length);

            Gtk.StyleContext.add_provider_for_screen (
                Gdk.Screen.get_default (), provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            );
        } catch (GLib.Error e) {
            return;
        }
    }
}
