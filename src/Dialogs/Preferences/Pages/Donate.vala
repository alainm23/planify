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

public class Dialogs.Preferences.Pages.Donate : Dialogs.Preferences.Pages.BasePage {
    public Donate (Adw.PreferencesDialog preferences_dialog) {
        Object (
            preferences_dialog: preferences_dialog,
            title: _("Donate")
        );
    }

    ~Donate () {
        debug ("Destroying - Dialogs.Preferences.Pages.Donate\n");
    }

    construct {
        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 18) {
            vexpand = true,
            hexpand = true,
            margin_start = 24,
            margin_end = 24,
            margin_bottom = 24,
            margin_top = 24
        };

        var hero_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12) {
            halign = Gtk.Align.CENTER,
            margin_bottom = 24
        };

        var emoji_label = new Gtk.Label ("💝") {
            css_classes = { "title-1" }
        };

        var hero_title = new Gtk.Label (_("Support Planify Development")) {
            css_classes = { "title-2" },
            halign = Gtk.Align.CENTER
        };

        var hero_description = new Gtk.Label (_("Help keep Planify free and open source! Your donations directly support development, new features, and maintenance. Every contribution, no matter the size, makes a difference.")) {
            wrap = true,
            justify = Gtk.Justification.CENTER,
            css_classes = { "body" },
            margin_start = 12,
            margin_end = 12
        };

        hero_box.append (emoji_label);
        hero_box.append (hero_title);
        hero_box.append (hero_description);
        content_box.append (hero_box);

        var patreon_row = new Adw.ActionRow ();
        patreon_row.activatable = true;
        patreon_row.add_suffix (new Gtk.Image.from_icon_name ("go-next-symbolic"));
        patreon_row.title = _("Patreon");
        patreon_row.subtitle = _("Monthly recurring support");

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
        paypal_row.subtitle = _("One-time donation");

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
        liberapay_row.subtitle = _("Weekly recurring donations");

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
        kofi_row.subtitle = _("Buy me a coffee ☕");

        signal_map[kofi_row.activated.connect (() => {
            try {
                AppInfo.launch_default_for_uri (Constants.KOFI_URL, null);
            } catch (Error e) {
                warning ("%s\n", e.message);
            }
        })] = kofi_row;

        var group = new Adw.PreferencesGroup () {
            title = _("Choose Your Preferred Platform"),
            margin_top = 12
        };
        group.add (patreon_row);
        group.add (paypal_row);
        group.add (liberapay_row);
        group.add (kofi_row);

        content_box.append (group);

        var thanks_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            css_classes = { "card" }
        };

        var thanks_label = new Gtk.Label (_("Thank you for your support! 🙏")) {
            css_classes = { "title-4" },
            halign = Gtk.Align.CENTER,
            margin_top = 12,
            margin_bottom = 6
        };

        var thanks_description = new Gtk.Label (_("Your contribution helps keep Planify alive and growing.")) {
            css_classes = { "caption" },
            halign = Gtk.Align.CENTER,
            margin_bottom = 12
        };

        thanks_box.append (thanks_label);
        thanks_box.append (thanks_description);
        content_box.append (thanks_box);

        var scrolled_window = new Gtk.ScrolledWindow () {
            hexpand = true,
            vexpand = true,
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            child = content_box
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