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

namespace ColorSchemeSettings {
    public class Settings : Object {
        public enum ColorScheme {
            NO_PREFERENCE,
            DARK,
            LIGHT
        }

        private ColorScheme? _prefers_color_scheme = null;

        public ColorScheme prefers_color_scheme {
            get {
                if (_prefers_color_scheme == null) {
                    setup_prefers_color_scheme ();
                }
                return _prefers_color_scheme;
            }
            private set {
                _prefers_color_scheme = value;
            }
        }

        private static GLib.Once<ColorSchemeSettings.Settings> instance;
        public static unowned ColorSchemeSettings.Settings get_default () {
            return instance.once (() => {
                return new ColorSchemeSettings.Settings ();
            });
        }

        private Settings () {}

        private void setup_prefers_color_scheme () {
            unowned Gtk.Settings? gtk_settings = Gtk.Settings.get_default ();
            if (gtk_settings == null) {
                prefers_color_scheme = ColorScheme.NO_PREFERENCE;
                return;
            }

            prefers_color_scheme = gtk_settings.gtk_application_prefer_dark_theme ?
                ColorScheme.DARK : ColorScheme.LIGHT;

            gtk_settings.notify["gtk-application-prefer-dark-theme"].connect (() => {
                prefers_color_scheme = gtk_settings.gtk_application_prefer_dark_theme ?
                    ColorScheme.DARK : ColorScheme.LIGHT;
            });
        }
    }
}
