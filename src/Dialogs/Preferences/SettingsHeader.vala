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

public class Dialogs.Preferences.SettingsHeader : Adw.Bin {
    public bool show_back_button { get; construct; }

    public string title {
        set {
            title_label.label = value;
        }
    }

    private Gtk.Label title_label;

    public signal void done_activated ();
    public signal void back_activated ();

    private Gee.HashMap<ulong, weak GLib.Object> signals_map = new Gee.HashMap<ulong, weak GLib.Object> ();

    public SettingsHeader (string title, bool show_back_button = true) {
        Object (
            title: title,
            show_back_button: show_back_button,
            hexpand: true
        );
    }

    ~SettingsHeader () {
        print ("Destroying Dialogs.Preferences.SettingsHeader\n");
    }

    construct {
        var back_button = new Gtk.Button.from_icon_name ("go-previous-symbolic") {
            valign = Gtk.Align.CENTER,
            tooltip_text = _("Back"),
            css_classes = { "flat" }
        };

        title_label = new Gtk.Label (null);
        title_label.add_css_class ("title");

        var headerbar = new Gtk.HeaderBar () {
            title_widget = title_label,
            show_title_buttons = true,
            hexpand = true
        };

        headerbar.add_css_class ("flat");

        if (show_back_button) {
            headerbar.pack_start (back_button);
        }

        child = headerbar;

        signals_map[back_button.clicked.connect (() => {
            back_activated ();
        })] = back_button;

        destroy.connect (() => {
            foreach (var entry in signals_map.entries) {
                if (SignalHandler.is_connected (entry.value, entry.key)) {
                    entry.value.disconnect (entry.key);
                }
            }

            signals_map.clear ();
        });
    }
}
