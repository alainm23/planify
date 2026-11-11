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
    public SettingsSchema settings_schema;

    private static Settings ? _instance;
    public static Settings get_default () {
        if (_instance == null) {
            _instance = new Settings ();
        }

        return _instance;
    }

    public const string ID = "io.github.alainm23.planify";

    public Settings () {
        settings = new GLib.Settings (ID);
        settings_schema = GLib.SettingsSchemaSource.get_default ().lookup (ID, true);
    }

    public void reset_settings () {
        foreach (string key in settings_schema.list_keys ()) {
            Services.Settings.get_default ().settings.reset (key);
        }
    }

    // Keys that are not carried in backups: they describe this machine or
    // app state rather than user preferences. local-inbox-project-id is
    // stored separately in the backup.
    private const string[] BACKUP_EXCLUDED_KEYS = {
        "local-inbox-project-id",
        "window-maximized",
        "window-height",
        "window-width",
        "pane-position",
        "mobile-mode",
        "run-on-startup",
        "quick-add-project-selected",
        "quick-add-section-selected",
        "dismissed-update-version",
        "calendar-sources-disabled",
        "backup-extra-folders",
        "backup-last-date"
    };

    private bool is_backup_key (string key) {
        return !(key in BACKUP_EXCLUDED_KEYS);
    }

    // Write the user preferences as "key": "<GVariant text>" members.
    public void export_preferences (Json.Builder builder) {
        builder.begin_object ();
        foreach (string key in settings_schema.list_keys ()) {
            if (!is_backup_key (key)) {
                continue;
            }

            builder.set_member_name (key);
            builder.add_string_value (settings.get_value (key).print (false));
        }
        builder.end_object ();
    }

    // Apply preferences read from a backup. Unknown keys and values that no
    // longer match the schema are skipped, so older or newer backups still work.
    public void import_preferences (Gee.HashMap<string, string> preferences) {
        foreach (var entry in preferences.entries) {
            if (!has_key (entry.key) || !is_backup_key (entry.key)) {
                continue;
            }

            var schema_key = settings_schema.get_key (entry.key);
            try {
                var value = GLib.Variant.parse (schema_key.get_value_type (), entry.value);
                if (schema_key.range_check (value)) {
                    settings.set_value (entry.key, value);
                }
            } catch (Error e) {
                warning ("Skipping preference %s: %s", entry.key, e.message);
            }
        }
    }

    public bool has_key (string key) {
        foreach (string schema_key in settings_schema.list_keys ()) {
            if (schema_key == key) {
                return true;
            }
        }

        return false;
    }

    public NewTaskPosition get_new_task_position () {
        var value = Services.Settings.get_default ().settings.get_enum ("new-tasks-position");
        return value == 0 ? NewTaskPosition.START : NewTaskPosition.END;
    }

    public bool get_boolean (string key) {
        return settings.get_boolean (key);
    }

    public double get_double (string key) {
        return settings.get_double (key);
    }

    public string get_string (string key) {
        return settings.get_string (key);
    }
}
