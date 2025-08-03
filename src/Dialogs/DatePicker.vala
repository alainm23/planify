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

public class Dialogs.DatePicker : Adw.Dialog {
    private Gtk.Revealer clear_revealer;
    private Widgets.Calendar.Calendar calendar_view;
    private Widgets.ContextMenu.MenuItem no_date_item;

    private GLib.DateTime _datetime = null;
    public GLib.DateTime datetime {
        get {
            return _datetime;
        }

        set {
            _datetime = value;
            calendar_view.date = _datetime;
        }
    }

    public bool clear {
        set {
            clear_revealer.reveal_child = value;
        }
    }

    public signal void date_changed ();

    private Gee.HashMap<ulong, weak GLib.Object> signal_map = new Gee.HashMap<ulong, weak GLib.Object> ();

    public DatePicker (string title) {
        Object (
            title: title,
            content_width: 320,
            content_height: 450
        );
    }

    ~DatePicker () {
        print ("Destroying Dialogs.DatePicker\n");
    }

    construct {
        var today_item = new Widgets.ContextMenu.MenuItem (_("Today"), "star-outline-thick-symbolic");
        today_item.secondary_text = new GLib.DateTime.now_local ().format ("%a");
        today_item.margin_top = 6;

        var tomorrow_item = new Widgets.ContextMenu.MenuItem (_("Tomorrow"), "today-calendar-symbolic");
        tomorrow_item.secondary_text = new GLib.DateTime.now_local ().add_days (1).format ("%a");

        var next_week_item = new Widgets.ContextMenu.MenuItem (_("Next Week"), "work-week-symbolic");
        next_week_item.secondary_text = Utils.Datetime.get_relative_date_from_date (
            Utils.Datetime.get_date_only (new GLib.DateTime.now_local ().add_days (7))
        );

        no_date_item = new Widgets.ContextMenu.MenuItem (_("No Date"), "cross-large-circle-filled-symbolic");
        no_date_item.margin_bottom = 6;

        clear_revealer = new Gtk.Revealer () {
            child = no_date_item
        };

        var items_card = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 12,
            css_classes = { "card" }
        };

        items_card.append (today_item);
        items_card.append (tomorrow_item);
        items_card.append (next_week_item);
        items_card.append (clear_revealer);

        calendar_view = new Widgets.Calendar.Calendar () {
            margin_top = 6,
            margin_bottom = 6
        };

        var calendar_card = new Adw.Bin () {
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 12,
            css_classes = { "card" },
            child = calendar_view
        };

        var done_button = new Widgets.LoadingButton (LoadingButtonType.LABEL, _("Done")) {
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 12,
            vexpand = true,
            valign = END
        };

        done_button.add_css_class ("suggested-action");

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            width_request = 225
        };

        content_box.append (items_card);
        content_box.append (calendar_card);
        content_box.append (done_button);

        var content_clamp = new Adw.Clamp () {
            maximum_size = 600,
            child = content_box
        };

        var toolbar_view = new Adw.ToolbarView () {
            content = content_clamp
        };

        toolbar_view.add_top_bar (new Adw.HeaderBar () {
            css_classes = { "flat" }
        });

        child = toolbar_view;
        Services.EventBus.get_default ().disconnect_typing_accel ();

        signal_map[today_item.activate_item.connect (() => {
            set_date (new DateTime.now_local ());
        })] = today_item;

        signal_map[tomorrow_item.activate_item.connect (() => {
            set_date (new DateTime.now_local ().add_days (1));
        })] = tomorrow_item;

        signal_map[next_week_item.activate_item.connect (() => {
            set_date (new DateTime.now_local ().add_days (7));
        })] = next_week_item;

        signal_map[no_date_item.activate_item.connect (() => {
            _datetime = null;
            date_changed ();
            close ();
        })] = no_date_item;

        signal_map[calendar_view.day_selected.connect (() => {
            _datetime = calendar_view.date;
        })] = calendar_view;

        signal_map[done_button.clicked.connect (() => {
            set_date (_datetime);
            date_changed ();
            close ();
        })] = done_button;

        closed.connect (() => {
            foreach (var entry in signal_map.entries) {
                entry.value.disconnect (entry.key);
            }

            signal_map.clear ();

            Services.EventBus.get_default ().connect_typing_accel ();
        });
    }

    private void set_date (DateTime ? date) {
        _datetime = Utils.Datetime.get_date_only (date);
        date_changed ();
        close ();
    }
}
