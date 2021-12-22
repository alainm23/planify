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

public class Dialogs.DateTimePicker.DateTimePicker : Hdy.Window {
    public Objects.Item item { get; construct; }

    public signal void date_changed (GLib.DateTime? date);
    
    public DateTimePicker (Objects.Item item) {
        Object (
            item: item,
            transient_for: (Gtk.Window) Planner.instance.main_window.get_toplevel (),
            destroy_with_parent: true,
            window_position: Gtk.WindowPosition.MOUSE,
            resizable: false
        );
    }

    construct {
        var today_item = new Dialogs.ContextMenu.MenuItem (_("Today"), "planner-today");
        today_item.secondary_text = new GLib.DateTime.now_local ().format ("%a");

        var tomorrow_item = new Dialogs.ContextMenu.MenuItem (_("Tomorrow"), "planner-scheduled");
        tomorrow_item.secondary_text = new GLib.DateTime.now_local ().add_days (1).format ("%a");

        var no_date_item = new Dialogs.ContextMenu.MenuItem (_("No Date"), "planner-close-circle");

        var next_week_item = new Dialogs.ContextMenu.MenuItem (_("Next week"), "planner-scheduled");
        next_week_item.secondary_text = Util.get_default ().get_relative_date_from_date (
            new GLib.DateTime.now_local ().add_days (7)
        );

        var calendar_item = new Dialogs.ContextMenu.MenuCalendarPicker (_("Pick Date"));

        var content_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            width_request = 215
        };

        unowned Gtk.StyleContext content_grid_context = content_grid.get_style_context ();
        content_grid_context.add_class ("view");
        content_grid_context.add_class ("menu");

        content_grid.add (today_item);
        content_grid.add (tomorrow_item);
        content_grid.add (next_week_item);
        if (item.has_due) {
            content_grid.add (no_date_item);
        }
        content_grid.add (calendar_item);

        add (content_grid);

        focus_out_event.connect (() => {
            hide_destroy ();
            return false;
        });

         key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                hide_destroy ();
            }

            return false;
        });

        today_item.activate_item.connect (() => {
            update_date (new DateTime.now_local ());
        });

        tomorrow_item.activate_item.connect (() => {
            update_date (new DateTime.now_local ().add_days (1));
        });

        next_week_item.activate_item.connect (() => {
            update_date (new DateTime.now_local ().add_days (7));
        });

        no_date_item.activate_item.connect (() => {
            update_date (null);
        });

        calendar_item.selection_changed.connect ((date) => {
            update_date (date);
        });
    }

    private void update_date (GLib.DateTime? date) {
        date_changed (date == null ? null : Util.get_default ().get_format_date (date));
        hide_destroy ();
    }

    private void hide_destroy () {
        hide ();

        Timeout.add (500, () => {
            destroy ();
            return GLib.Source.REMOVE;
        });
    }

    public void popup () {
        show_all ();

        // Gdk.Rectangle rect;
        // get_allocation (out rect);

        // int root_x, root_y;
        // get_position (out root_x, out root_y);

        // move (root_x + (rect.width / 3), root_y + (rect.height / 3) + 24);
    }
}