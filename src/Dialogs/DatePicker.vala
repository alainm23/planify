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

public class Dialogs.DatePicker : Adw.Window {
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
            // calendar_item.select_day (_datetime);
            no_date_item.visible = true;
        }
    }

    public bool clear {
        set {
            clear_revealer.reveal_child = value;
        }
    }

    public signal void date_changed ();

    public DatePicker (string title) {
        Object (
            deletable: true,
            resizable: true,
            modal: true,
            title: title,
            width_request: 320,
            height_request: 450,
            transient_for: (Gtk.Window) Planify.instance.main_window
        );
    }

    construct {
        var headerbar = new Adw.HeaderBar ();
        headerbar.add_css_class (Granite.STYLE_CLASS_FLAT);

        var today_item = new Widgets.ContextMenu.MenuItem (_("Today"), "star-outline-thick-symbolic");
        today_item.secondary_text = new GLib.DateTime.now_local ().format ("%a");
        today_item.margin_top = 6;

        var tomorrow_item = new Widgets.ContextMenu.MenuItem (_("Tomorrow"), "today-calendar-symbolic");
        tomorrow_item.secondary_text = new GLib.DateTime.now_local ().add_days (1).format ("%a");

        var next_week_item = new Widgets.ContextMenu.MenuItem (_("Next Week"), "work-week-symbolic");
        next_week_item.secondary_text = Utils.Datetime.get_relative_date_from_date (
            Utils.Datetime.get_format_date (new GLib.DateTime.now_local ().add_days (7))
        );
        next_week_item.margin_bottom = 6;

        no_date_item = new Widgets.ContextMenu.MenuItem (_("No Date"), "cross-large-circle-filled-symbolic");
        no_date_item.visible = false;

        var items_card = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 12
        };

        items_card.append (today_item);
        items_card.append (tomorrow_item);
        items_card.append (next_week_item);
        items_card.append (no_date_item);
        items_card.add_css_class (Granite.STYLE_CLASS_CARD);

        calendar_view = new Widgets.Calendar.Calendar (true) {
            margin_top = 6,
            margin_bottom = 6
        };

        var calendar_card = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 12
        };

        calendar_card.append (calendar_view);
        calendar_card.add_css_class (Granite.STYLE_CLASS_CARD);

        var done_button = new Widgets.LoadingButton (LoadingButtonType.LABEL, _("Done")) {
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 12
        };

        done_button.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            width_request = 225
        };
        
        content_box.append (headerbar);
        content_box.append (items_card);
        content_box.append (calendar_card);
        content_box.append (done_button);

        content = content_box;

        today_item.activate_item.connect (() => {
            set_date (new DateTime.now_local ());
        });

        tomorrow_item.activate_item.connect (() => {
            set_date (new DateTime.now_local ().add_days (1));
        });

        next_week_item.activate_item.connect (() => {
            set_date (new DateTime.now_local ().add_days (7));
        });

        no_date_item.activate_item.connect (() => {
            _datetime = null;
            date_changed ();
            hide_destroy ();
        });

        calendar_view.day_selected.connect (() => {
            _datetime = calendar_view.date;
        });

        done_button.clicked.connect (() => {
            set_date (_datetime);
            date_changed ();
            hide_destroy ();
        });
    }

    private void set_date (DateTime? date) {
        _datetime = Utils.Datetime.get_format_date (date);
        date_changed ();
        hide_destroy ();
    }

    public void hide_destroy () {
        hide ();

        Timeout.add (500, () => {
            destroy ();
            return GLib.Source.REMOVE;
        });
    }
}
