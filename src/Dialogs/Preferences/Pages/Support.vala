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

public class Dialogs.Preferences.Pages.Support : Dialogs.Preferences.Pages.BasePage {
    private Layouts.HeaderItem views_group;

    public Support (Adw.PreferencesDialog preferences_dialog) {
        Object (
            preferences_dialog: preferences_dialog,
            title: _("Supporting Us")
        );
    }

    ~Support () {
        print ("Destroying - Dialogs.Preferences.Pages.Support\n");
    }

    construct {
        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12) {
            vexpand = true,
            hexpand = true
        };

        content_box.append (
            new Gtk.Label (_("Our mission is to provide the best open source task management application for users all over the world. Your donations support this work. Want to donate today?")) {
            wrap = true,
            xalign = 0
        });

        var patreon_row = new Adw.ActionRow ();
        patreon_row.activatable = true;
        patreon_row.add_suffix (new Gtk.Image.from_icon_name ("go-next-symbolic"));
        patreon_row.title = _("Patreon");

        signal_map[patreon_row.activated.connect (() => {
            try {
                AppInfo.launch_default_for_uri (Constants.PATREON_URL, null);
            } catch (Error e) {
                warning ("%s\n", e.message);
            }
        })] = patreon_row;

        var paypal_row = new Adw.ActionRow ();
        paypal_row.activatable = true;
        paypal_row.add_suffix (new Gtk.Image.from_icon_name ("go-next-symbolic"));
        paypal_row.title = _("PayPal");

        signal_map[paypal_row.activated.connect (() => {
            try {
                AppInfo.launch_default_for_uri (Constants.PAYPAL_ME_URL, null);
            } catch (Error e) {
                warning ("%s\n", e.message);
            }
        })] = paypal_row;

        var liberapay_row = new Adw.ActionRow ();
        liberapay_row.activatable = true;
        liberapay_row.add_suffix (new Gtk.Image.from_icon_name ("go-next-symbolic"));
        liberapay_row.title = _("Liberapay");

        signal_map[liberapay_row.activated.connect (() => {
            try {
                AppInfo.launch_default_for_uri (Constants.LIBERAPAY_URL, null);
            } catch (Error e) {
                warning ("%s\n", e.message);
            }
        })] = liberapay_row;

        var kofi_row = new Adw.ActionRow ();
        kofi_row.activatable = true;
        kofi_row.add_suffix (new Gtk.Image.from_icon_name ("go-next-symbolic"));
        kofi_row.title = _("Ko-fi");

        signal_map[kofi_row.activated.connect (() => {
            try {
                AppInfo.launch_default_for_uri (Constants.KOFI_URL, null);
            } catch (Error e) {
                warning ("%s\n", e.message);
            }
        })] = kofi_row;

        var group = new Adw.PreferencesGroup () {
            margin_top = 12
        };
        group.add (patreon_row);
        group.add (paypal_row);
        group.add (liberapay_row);
        group.add (kofi_row);

        content_box.append (group);

        var content_clamp = new Adw.Clamp () {
            maximum_size = 400,
            margin_start = 24,
            margin_end = 24,
            margin_top = 12
        };

        content_clamp.child = content_box;

        var scrolled_window = new Gtk.ScrolledWindow () {
            hexpand = true,
            vexpand = true,
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            child = content_clamp
        };

        var toolbar_view = new Adw.ToolbarView ();
        toolbar_view.add_top_bar (new Adw.HeaderBar ());
        toolbar_view.content = scrolled_window;

        child = toolbar_view;

        destroy.connect (() => {
            clean_up ();
        });
    }

    public override void clean_up () {
        foreach (var entry in signal_map.entries) {
            entry.value.disconnect (entry.key);
        }

        signal_map.clear ();
    }
}