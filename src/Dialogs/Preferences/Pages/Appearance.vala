/*
 * Copyright © 2025 Alain M. (https://github.com/alainm23/planify)
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

public class Dialogs.Preferences.Pages.Appearance : Adw.Bin {
    private Gtk.Switch system_appearance_switch;
    private Adw.ActionRow light_row;
    private Adw.ActionRow dark_row;
    private Adw.ActionRow blue_row;
    private Gtk.CheckButton light_radio;
    private Gtk.CheckButton dark_radio;
    private Gtk.CheckButton blue_radio;
    private Adw.PreferencesGroup theme_group;
    private Gtk.Revealer placeholder_revealer;

    public signal void pop_subpage ();

    ~Appearance () {
        print ("Destroying Dialogs.Preferences.Pages.Appearance\n");
    }

    construct {
        var settings_header = new Dialogs.Preferences.SettingsHeader (_("Appearance"));

        system_appearance_switch = new Gtk.Switch () {
            valign = Gtk.Align.CENTER,
            active = Services.Settings.get_default ().settings.get_boolean ("system-appearance")
        };

        var system_appearance_row = new Adw.ActionRow () {
            title = _("Use System Settings")
        };
        system_appearance_row.add_prefix (new Gtk.Image.from_icon_name ("computer-symbolic") {
            pixel_size = 16
        });
        system_appearance_row.set_activatable_widget (system_appearance_switch);
        system_appearance_row.add_suffix (system_appearance_switch);

        var system_appearance_group = new Adw.PreferencesGroup ();
        system_appearance_group.add (system_appearance_row);

        light_radio = new Gtk.CheckButton () {
            valign = CENTER
        };

        var light_row = new Adw.ActionRow () {
            title = _("Light Style"),
            subtitle = _("Clean light theme"),
            activatable_widget = light_radio
        };

        light_row.add_prefix (new Adw.Avatar (32, null, true) {
            custom_image = new Gtk.Image.from_resource ("/io/github/alainm23/planify/light-mode.svg").get_paintable (),
            css_classes = { "theme-mode-image" }
        });
        light_row.add_suffix (light_radio);

        dark_radio = new Gtk.CheckButton () {
            group = light_radio,
            valign = CENTER
        };

        var dark_row = new Adw.ActionRow () {
            title = _("Dark Style"),
            subtitle = _("Elegant dark theme"),
            activatable_widget = dark_radio
        };

        dark_row.add_prefix (new Adw.Avatar (32, null, true) {
            custom_image = new Gtk.Image.from_resource ("/io/github/alainm23/planify/dark-mode.svg").get_paintable (),
            css_classes = { "theme-mode-image" }
        });
        dark_row.add_suffix (dark_radio);

        blue_radio = new Gtk.CheckButton () {
            group = light_radio,
            valign = CENTER
        };

        blue_row = new Adw.ActionRow () {
            title = _("Dark Blue Style"),
            subtitle = _("Professional blue theme"),
            activatable_widget = blue_radio
        };

        blue_row.add_prefix (new Adw.Avatar (32, null, true) {
            custom_image = new Gtk.Image.from_resource ("/io/github/alainm23/planify/blue-mode.svg").get_paintable (),
            css_classes = { "theme-mode-image" }
        });
        blue_row.add_suffix (blue_radio);

        placeholder_revealer = new Gtk.Revealer () {
            child = new Gtk.Label (_("Custom themes are not available when using the system light theme")) {
                wrap = true,
                halign = CENTER,
                justify = CENTER,
                margin_top = 12
            }
        };

        theme_group = new Adw.PreferencesGroup () {
            title = _("Select theme")
        };
        theme_group.add (light_row);
        theme_group.add (dark_row);
        theme_group.add (blue_row);

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12);
        content_box.append (system_appearance_group);
        content_box.append (theme_group);
        content_box.append (placeholder_revealer);

        var content_clamp = new Adw.Clamp () {
            maximum_size = 600,
            margin_start = 24,
            margin_end = 24,
            margin_top = 12,
            child = content_box
        };

        var toolbar_view = new Adw.ToolbarView () {
            content = content_clamp
        };
        toolbar_view.add_top_bar (settings_header);

        child = toolbar_view;
        verify ();

        system_appearance_switch.notify["active"].connect (() => {
            Services.Settings.get_default ().settings.set_boolean ("system-appearance",
                                                                   system_appearance_switch.active);
        });

        light_radio.activate.connect (() => {
            Services.Settings.get_default ().settings.set_boolean ("dark-mode", false);
            Services.Settings.get_default ().settings.set_enum ("appearance", 0);
        });

        dark_radio.activate.connect (() => {
            Services.Settings.get_default ().settings.set_boolean ("dark-mode", true);
            Services.Settings.get_default ().settings.set_enum ("appearance", 1);
        });

        blue_radio.activate.connect (() => {
            Services.Settings.get_default ().settings.set_boolean ("dark-mode", true);
            Services.Settings.get_default ().settings.set_enum ("appearance", 2);
        });

        Services.Settings.get_default ().settings.changed.connect ((key) => {
            if (key == "system-appearance" || key == "dark-mode") {
                system_appearance_switch.active =
                    Services.Settings.get_default ().settings.get_boolean ("system-appearance");
                light_row.visible = is_light_visible ();
                theme_group.visible = is_dark_modes_visible ();
                placeholder_revealer.reveal_child = !is_dark_modes_visible ();
            }
        });

        settings_header.back_activated.connect (() => {
            pop_subpage ();
        });
    }

    private void verify () {
        system_appearance_switch.active =
            Services.Settings.get_default ().settings.get_boolean ("system-appearance");
        light_row.visible = is_light_visible ();
        theme_group.visible = is_dark_modes_visible ();
        placeholder_revealer.reveal_child = !is_dark_modes_visible ();

        int appearance = Services.Settings.get_default ().settings.get_enum ("appearance");
        if (appearance == 0) {
            light_radio.active = true;
        } else if (appearance == 1) {
            dark_radio.active = true;
        } else if (appearance == 2) {
            blue_radio.active = true;
        }
    }

    public bool is_dark_theme () {
        var dark_mode = Services.Settings.get_default ().settings.get_boolean ("dark-mode");

        if (Services.Settings.get_default ().settings.get_boolean ("system-appearance")) {
            dark_mode = Granite.Settings.get_default ().prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
        }

        return dark_mode;
    }

    public bool is_light_visible () {
        bool system_appearance = Services.Settings.get_default ().settings.get_boolean ("system-appearance");

        if (system_appearance) {
            return !is_dark_theme ();
        }

        return true;
    }

    public bool is_dark_modes_visible () {
        bool system_appearance = Services.Settings.get_default ().settings.get_boolean ("system-appearance");

        if (system_appearance) {
            return is_dark_theme ();
        }

        return true;
    }
}