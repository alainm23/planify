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
    private Chrono.Core chrono;
    private uint search_timeout_id = 0;
    private GLib.DateTime _last_parsed = null;

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
        debug ("Destroying - Dialogs.DatePicker\n");
    }

    construct {
        chrono = new Chrono.Core ();

        var search_entry = new Gtk.SearchEntry () {
            placeholder_text = _("Type a date\u2026"),
            margin_start = 12,
            margin_end = 12,
            margin_top = 6,
            margin_bottom = 6
        };

        var suggested_date_box = new Adw.WrapBox () {
            child_spacing = 6,
            line_spacing = 6,
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 12,
            margin_top = 6
        };

        no_date_item = new Widgets.ContextMenu.MenuItem (_("No Date"), "cross-large-circle-filled-symbolic");
        no_date_item.margin_bottom = 6;

        clear_revealer = new Gtk.Revealer () {
            child = no_date_item,
            margin_start = 12,
            margin_end = 12
        };

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

        content_box.append (suggested_date_box);
        content_box.append (clear_revealer);
        content_box.append (calendar_card);
        content_box.append (done_button);

        var content_clamp = new Adw.Clamp () {
            maximum_size = 600,
            child = content_box
        };

        var toolbar_view = new Adw.ToolbarView () {
            content = content_clamp
        };

        var search_bar = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        search_bar.append (search_entry);

        toolbar_view.add_top_bar (new Adw.HeaderBar () {
            css_classes = { "flat" }
        });
        toolbar_view.add_top_bar (search_bar);

        child = toolbar_view;
        Services.EventBus.get_default ().disconnect_typing_accel ();

        add_default_suggestions (suggested_date_box);

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

        search_entry.activate.connect (() => {
            if (_last_parsed != null) {
                set_date (_last_parsed);
            }
        });

        search_entry.search_changed.connect (() => {
            if (search_timeout_id != 0) {
                GLib.Source.remove (search_timeout_id);
            }

            search_timeout_id = Timeout.add (300, () => {
                search_timeout_id = 0;

                while (suggested_date_box.get_first_child () != null) {
                    suggested_date_box.remove (suggested_date_box.get_first_child ());
                }

                var text = search_entry.text.strip ();
                if (text.length == 0) {
                    _last_parsed = null;
                    add_default_suggestions (suggested_date_box);
                    return GLib.Source.REMOVE;
                }

                var result = chrono.parse (text);
                if (result != null && result.date != null) {
                    _last_parsed = Utils.Datetime.get_date_only (result.date);
                    calendar_view.date = _last_parsed;
                    var chip = build_suggestion_chip (_last_parsed);
                    suggested_date_box.append (chip);
                } else {
                    _last_parsed = null;
                }

                return GLib.Source.REMOVE;
            });
        });

        closed.connect (() => {
            clean_up ();
            Services.EventBus.get_default ().connect_typing_accel ();
        });
    }

    private void add_default_suggestions (Adw.WrapBox box) {
        add_suggestion (box, _("Today"), "star-outline-thick-symbolic", new GLib.DateTime.now_local ());
        add_suggestion (box, _("Tomorrow"), "today-calendar-symbolic", new GLib.DateTime.now_local ().add_days (1));
        add_suggestion (box, _("Next Week"), "work-week-symbolic", new GLib.DateTime.now_local ().add_days (7));
    }

    private void add_suggestion (Adw.WrapBox box, string label, string icon, GLib.DateTime date) {
        var chip = build_suggestion_chip (date, label, icon);
        box.append (chip);
    }

    private Gtk.Button build_suggestion_chip (GLib.DateTime date, string? label = null, string? icon = null) {
        var icon_widget = new Gtk.Image.from_icon_name (icon ?? "month-symbolic");

        var label_widget = new Gtk.Label (label ?? Utils.Datetime.get_relative_date_from_date (date)) {
            ellipsize = END
        };

        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            margin_start = 9,
            margin_end = 9,
            margin_top = 6,
            margin_bottom = 6
        };
        box.append (icon_widget);
        box.append (label_widget);

        var chip = new Gtk.Button () {
            child = box,
            css_classes = { "suggestion-chip" }
        };

        chip.clicked.connect (() => {
            set_date (date);
        });

        return chip;
    }

    private void set_date (DateTime ? date) {
        _datetime = Utils.Datetime.get_date_only (date);
        date_changed ();
        close ();
    }

    public void clean_up () {
        foreach (var entry in signal_map.entries) {
            entry.value.disconnect (entry.key);
        }

        signal_map.clear ();

        if (calendar_view != null) {
            calendar_view.clean_up ();
        }
    }
}
