// From Clipped: https://github.com/davidmhewitt/clipped/blob/edac68890c2a78357910f05bf44060c2aba5958e/src/Settings/CustomShortcutSettings.vala

public class Services.CustomShortcutSettings : Object {
    const string SCHEMA = "org.gnome.settings-daemon.plugins.media-keys";
    const string KEY = "custom-keybinding";

    const string RELOCATABLE_SCHEMA_PATH_TEMLPATE =
    "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom%d/";

    const int MAX_SHORTCUTS = 100;

    static GLib.Settings settings;

    public static bool available = false;

    public struct CustomShortcut {
        string shortcut;
        string command;
        string relocatable_schema;
    }

    public static void init () {
        var schema_source = GLib.SettingsSchemaSource.get_default ();

        var schema = schema_source.lookup (SCHEMA, true);

        if (schema == null) {
            warning ("Schema \"%s\" is not installed on your system.", SCHEMA);
            return;
        }

        settings = new GLib.Settings.full (schema, null, null);

        available = true;
    }

    static string[] get_relocatable_schemas () {
        return settings.get_strv (KEY + "s");
    }

    static string get_relocatable_schema_path (int i) {
        return RELOCATABLE_SCHEMA_PATH_TEMLPATE.printf (i);
    }

    static GLib.Settings? get_relocatable_schema_settings (string relocatable_schema) {
        return new GLib.Settings.with_path (SCHEMA + "." + KEY, relocatable_schema);
    }

    public static string? create_shortcut () requires (available) {
        for (int i = 0; i < MAX_SHORTCUTS; i++) {
            var new_relocatable_schema = get_relocatable_schema_path (i);

            if (relocatable_schema_is_used (new_relocatable_schema) == false) {
                reset_relocatable_schema (new_relocatable_schema);
                add_relocatable_schema (new_relocatable_schema);
                return new_relocatable_schema;
            }
        }

        return (string) null;
    }

    static bool relocatable_schema_is_used (string new_relocatable_schema) {
        var relocatable_schemas = get_relocatable_schemas ();

        foreach (var relocatable_schema in relocatable_schemas)
            if (relocatable_schema == new_relocatable_schema)
                return true;

        return false;
    }

    static void add_relocatable_schema (string new_relocatable_schema) {
        var relocatable_schemas = get_relocatable_schemas ();
        relocatable_schemas += new_relocatable_schema;
        settings.set_strv (KEY + "s", relocatable_schemas);
        apply_settings (settings);
    }

    static void reset_relocatable_schema (string relocatable_schema) {
        var relocatable_settings = get_relocatable_schema_settings (relocatable_schema);
        relocatable_settings.reset ("name");
        relocatable_settings.reset ("command");
        relocatable_settings.reset ("binding");
        apply_settings (relocatable_settings);
    }

    public static bool edit_shortcut (string relocatable_schema, string shortcut)
        requires (available) {

        var relocatable_settings = get_relocatable_schema_settings (relocatable_schema);
        relocatable_settings.set_string ("binding", shortcut);
        apply_settings (relocatable_settings);
        return true;
    }

    public static bool edit_command (string relocatable_schema, string command)
        requires (available) {

        var relocatable_settings = get_relocatable_schema_settings (relocatable_schema);
        relocatable_settings.set_string ("command", command);
        relocatable_settings.set_string ("name", command);
        apply_settings (relocatable_settings);
        return true;
    }

    public static GLib.List <CustomShortcut?> list_custom_shortcuts ()
        requires (available) {

        var list = new GLib.List <CustomShortcut?> ();
        foreach (var relocatable_schema in get_relocatable_schemas ())
            list.append (create_custom_shortcut_object (relocatable_schema));
        return list;
    }

    static CustomShortcut? create_custom_shortcut_object (string relocatable_schema) {
        var relocatable_settings = get_relocatable_schema_settings (relocatable_schema);

        return {
            relocatable_settings.get_string ("binding"),
            relocatable_settings.get_string ("command"),
            relocatable_schema
        };
    }

    private static void apply_settings (GLib.Settings asettings) {
        asettings.apply ();
        GLib.Settings.sync ();
    }
}
