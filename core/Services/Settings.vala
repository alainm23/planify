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

public class Services.Settings : GLib.Object {
    public GLib.Settings settings;

    private static Settings ? _instance;
    public static Settings get_default () {
        if (_instance == null) {
            _instance = new Settings ();
        }

        return _instance;
    }

    public Settings () {
        settings = new GLib.Settings ("io.github.alainm23.planify");
    }

    public void reset_settings () {
        var schema_source = GLib.SettingsSchemaSource.get_default ();
        SettingsSchema schema = schema_source.lookup ("io.github.alainm23.planify", true);

        foreach (string key in schema.list_keys ()) {
            Services.Settings.get_default ().settings.reset (key);
        }
    }

    public NewTaskPosition get_new_task_position () {
        var value = Services.Settings.get_default ().settings.get_enum ("new-tasks-position");
        return value == 0 ? NewTaskPosition.TOP : NewTaskPosition.BOTTOM;
    }

    public bool get_boolean (string key) {
        return settings.get_boolean (key);
    }

    public double get_double (string key) {
        return settings.get_double (key);
    }
}
