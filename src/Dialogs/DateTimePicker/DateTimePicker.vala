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
    private Dialogs.DateTimePicker.TimePicker time_picker;
    private Gtk.Button cancel_clear_button;

    private GLib.DateTime _datetime = null;
    public GLib.DateTime datetime {
        get {
            if (time_picker.has_time) {
                if (_datetime == null) {
                    _datetime = time_picker.time;
                } else {
                    _datetime = add_date_time (_datetime, time_picker.time);
                }
            } else {
                if (_datetime != null) {
                    _datetime = Util.get_default ().get_format_date (_datetime);
                }
            }

            return _datetime;
        }

        set {
            _datetime = value;
            cancel_clear_button.label = _("Clear");
            if (Util.get_default ().has_time (_datetime)) {
                time_picker.time = _datetime;
                time_picker.has_time = true;
            }
        }
    }

    public signal void date_changed ();
    
    public DateTimePicker () {
        Object (
            transient_for: (Gtk.Window) Planner.instance.main_window.get_toplevel (),
            destroy_with_parent: true,
            window_position: Gtk.WindowPosition.MOUSE,
            resizable: false
        );
    }

    construct {
        var headerbar = new Hdy.HeaderBar () {
            has_subtitle = false,
            show_close_button = false,
            hexpand = true
        };
        headerbar.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        headerbar.get_style_context ().add_class ("default-decoration");

        var done_button = new Gtk.Button.with_label (_("Done")) {
            halign = Gtk.Align.CENTER,
            valign = Gtk.Align.CENTER,
            can_focus = false
        };
        done_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        done_button.get_style_context ().add_class ("primary-color");
        done_button.get_style_context ().add_class (Granite.STYLE_CLASS_SMALL_LABEL);

        cancel_clear_button = new Gtk.Button.with_label (_("Cancel")) {
            halign = Gtk.Align.CENTER,
            valign = Gtk.Align.CENTER,
            can_focus = false
        };
        cancel_clear_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        cancel_clear_button.get_style_context ().add_class (Granite.STYLE_CLASS_SMALL_LABEL);

        var title_label = new Gtk.Label (_("Schedule"));
        title_label.get_style_context ().add_class ("h4");

        var header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            hexpand = true,
            margin_start = 3,
            margin_end = 3
        };
        header_box.pack_start (cancel_clear_button, false, false, 0);
        header_box.set_center_widget (title_label);
        header_box.pack_end (done_button, false, false, 0);

        headerbar.set_custom_title (header_box);

        var today_item = new Dialogs.ContextMenu.MenuItem (_("Today"), "planner-today");
        today_item.secondary_text = new GLib.DateTime.now_local ().format ("%a");

        var tomorrow_item = new Dialogs.ContextMenu.MenuItem (_("Tomorrow"), "planner-scheduled");
        tomorrow_item.secondary_text = new GLib.DateTime.now_local ().add_days (1).format ("%a");

        var no_date_item = new Dialogs.ContextMenu.MenuItem (_("No Date"), "planner-close-circle");

        var next_week_item = new Dialogs.ContextMenu.MenuItem (_("Next week"), "planner-scheduled");
        next_week_item.secondary_text = Util.get_default ().get_relative_date_from_date (
            Util.get_default ().get_format_date (new GLib.DateTime.now_local ().add_days (7))
        );

        var calendar_item = new Dialogs.ContextMenu.MenuCalendarPicker (_("Pick Date"));

        var date_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            hexpand = true,
            margin = 9,
            margin_top = 0,
            margin_bottom = 12
        };

        unowned Gtk.StyleContext date_grid_context = date_grid.get_style_context ();
        date_grid_context.add_class ("picker-content");

        date_grid.add (today_item);
        date_grid.add (tomorrow_item);
        date_grid.add (next_week_item);
        date_grid.add (calendar_item);

        var time_icon = new Widgets.DynamicIcon () {
            margin_start = 3
        };
        time_icon.size = 19;
        time_icon.update_icon_name ("planner-clock");

        var time_label = new Gtk.Label (_("Time")) {
            margin_start = 6
        };
        time_label.get_style_context ().add_class ("font-weight-500");

        time_picker = new Dialogs.DateTimePicker.TimePicker ();

        var time_picker_grid = new Gtk.Grid () {
            margin = 9,
            margin_top = 0
        };
        time_picker_grid.add (time_icon);
        time_picker_grid.add (time_label);
        time_picker_grid.add (time_picker);

        unowned Gtk.StyleContext time_picker_grid_context = time_picker_grid.get_style_context ();
        time_picker_grid_context.add_class ("picker-content");

        var main_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            width_request = 225
        };
        main_grid.add (headerbar);
        main_grid.add (date_grid);
        main_grid.add (time_picker_grid);

        unowned Gtk.StyleContext main_grid_context = main_grid.get_style_context ();
        main_grid_context.add_class ("picker");

        add (main_grid);

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
            set_date (new DateTime.now_local ());
        });

        tomorrow_item.activate_item.connect (() => {
            set_date (new DateTime.now_local ().add_days (1));
        });

        next_week_item.activate_item.connect (() => {
            set_date (new DateTime.now_local ().add_days (7));
        });

        cancel_clear_button.clicked.connect (() => {
            _datetime = null;
            time_picker.has_time = false;
            
            date_changed ();
            hide_destroy ();
        });

        calendar_item.selection_changed.connect ((date) => {
            set_date (date);
        });

        done_button.clicked.connect (() => {
            date_changed ();
            hide_destroy ();
        });
    }

    private void set_date (DateTime date) {
        _datetime = Util.get_default ().get_format_date (date);
        date_changed ();
        hide_destroy ();
    }

    private GLib.DateTime add_date_time (GLib.DateTime date, GLib.DateTime time) {
        return new GLib.DateTime.local (
            date.get_year (),
            date.get_month (),
            date.get_day_of_month (),
            time.get_hour (),
            time.get_minute (),
            time.get_second ()
        );
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
