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

public class Dialogs.DatePicker : Adw.Window {
    private Gtk.Revealer clear_revealer;
    
    private GLib.DateTime _datetime = null;
    public GLib.DateTime datetime {
        get {
            return _datetime;
        }

        set {
            _datetime = value;
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
            transient_for: (Gtk.Window) Planner.instance.main_window
        );
    }

    construct {
        var headerbar = new Adw.HeaderBar ();
        headerbar.add_css_class (Granite.STYLE_CLASS_FLAT);

        var today_item = new Widgets.ContextMenu.MenuItem (_("Today"), "planner-today");
        today_item.secondary_text = new GLib.DateTime.now_local ().format ("%a");
        today_item.margin_top = 6;

        var tomorrow_item = new Widgets.ContextMenu.MenuItem (_("Tomorrow"), "planner-scheduled");
        tomorrow_item.secondary_text = new GLib.DateTime.now_local ().add_days (1).format ("%a");

        var next_week_item = new Widgets.ContextMenu.MenuItem (_("Next week"), "planner-scheduled");
        next_week_item.secondary_text = Util.get_default ().get_relative_date_from_date (
            Util.get_default ().get_format_date (new GLib.DateTime.now_local ().add_days (7))
        );
        next_week_item.margin_bottom = 6;

        var items_card = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 12
        };

        items_card.append (today_item);
        items_card.append (tomorrow_item);
        items_card.append (next_week_item);
        items_card.add_css_class (Granite.STYLE_CLASS_CARD);

        var calendar_item = new Widgets.Calendar.Calendar (true) {
            margin_bottom = 12
        };

        var calendar_card = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 12
        };

        calendar_card.append (calendar_item);
        calendar_card.add_css_class (Granite.STYLE_CLASS_CARD);

        var clear_button = new Widgets.LoadingButton (LoadingButtonType.LABEL, _("Clear")) {
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 12
        };

        clear_button.add_css_class (Granite.STYLE_CLASS_DESTRUCTIVE_ACTION);

        clear_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };
        clear_revealer.child = clear_button;

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            width_request = 225
        };
        
        content_box.append (headerbar);
        content_box.append (items_card);
        content_box.append (calendar_card);
        content_box.append (clear_revealer);

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

        calendar_item.selection_changed.connect ((date) => {
            _datetime = date;
            date_changed ();

            Timeout.add (750, () => {
                hide_destroy ();
                return GLib.Source.REMOVE;
            });
        });

        clear_button.clicked.connect (() => {
            set_date (null);
        });
    }

    private void set_date (DateTime? date) {
        _datetime = date;
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