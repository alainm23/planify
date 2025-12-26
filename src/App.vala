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

public class Planify : Adw.Application {
    public MainWindow main_window;

    public static Planify _instance = null;
    public static Planify instance {
        get {
            if (_instance == null) {
                _instance = new Planify ();
            }
            return _instance;
        }
    }

    private static bool run_in_background = false;
    private static bool n_version = false;
    private static bool clear_database = false;
    private static string lang = "";

    
    #if WITH_LIBPORTAL
    private Xdp.Portal ? portal = null;
    #endif

    private const OptionEntry[] OPTIONS = {
        { "version", 'v', 0, OptionArg.NONE, ref n_version, "Display version number", null },
        { "reset", 'r', 0, OptionArg.NONE, ref clear_database, "Reset Planify", null },
        { "background", 'b', 0, OptionArg.NONE, out run_in_background, "Run the Application in background", null },
        { "lang", 'l', 0, OptionArg.STRING, ref lang, "Open Planify in a specific language", "LANG" },
        { null }
    };

    public Planify () {
        Object (
            application_id : Build.APPLICATION_ID,
            flags: ApplicationFlags.HANDLES_OPEN
        );
    }

    ~Planify () {
        debug ("Destroying Planify\n");
    }

    construct {
        Intl.setlocale (LocaleCategory.ALL, "");
        string langpack_dir = Path.build_filename (Build.INSTALL_PREFIX, "share", "locale");
        Intl.bindtextdomain (Build.GETTEXT_PACKAGE, langpack_dir);
        Intl.bind_textdomain_codeset (Build.GETTEXT_PACKAGE, "UTF-8");
        Intl.textdomain (Build.GETTEXT_PACKAGE);

        add_main_option_entries (OPTIONS);
        create_dir_with_parents ("/io.github.alainm23.planify");
        create_dir_with_parents ("/io.github.alainm23.planify/backups");
    }

    protected override void activate () {
        if (lang != "") {
            GLib.Environment.set_variable ("LANGUAGE", lang, true);
        }

        if (n_version) {
            debug ("%s\n".printf (Build.VERSION));
            return;
        }

        if (clear_database) {
            stdout.printf ("Are you sure you want to reset all? (y/n): ");
            string ? option = stdin.read_line ();

            if (option.down () == "y" || option.down () == "yes") {
                Services.Database.get_default ().clear_database ();
                Services.Settings.get_default ().reset_settings ();
                return;
            }
        }

        if (main_window != null) {
            main_window.present ();
            return;
        }

        main_window = new MainWindow (this);

        Services.Settings.get_default ().settings.bind ("window-height", main_window, "default-height", SettingsBindFlags.DEFAULT);
        Services.Settings.get_default ().settings.bind ("window-width", main_window, "default-width", SettingsBindFlags.DEFAULT);

        if (Services.Settings.get_default ().settings.get_boolean ("window-maximized")) {
            main_window.maximize ();
        }

        if (!run_in_background) {
            main_window.show ();
        }

        Services.Settings.get_default ().settings.bind ("window-maximized", main_window, "maximized", SettingsBindFlags.SET);

        var provider = new Gtk.CssProvider ();
        provider.load_from_resource ("/io/github/alainm23/planify/index.css");

        Gtk.StyleContext.add_provider_for_display (
            Gdk.Display.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );

        Util.get_default ().update_theme ();
        Util.get_default ().update_font_scale ();

        if (Services.Settings.get_default ().settings.get_string ("dismissed-update-version") != Build.VERSION) {
            Services.Settings.get_default ().settings.set_boolean ("show-support-banner", true);
        }

        // Actions
        build_shortcuts ();
    }

    #if WITH_LIBPORTAL
    public async bool ask_for_background (Xdp.BackgroundFlags flags = Xdp.BackgroundFlags.AUTOSTART) {
        const string[] DAEMON_COMMAND = { "io.github.alainm23.planify", "--background" };
        if (portal == null) {
            portal = new Xdp.Portal ();
        }

        string reason = _(
            "Planify will automatically start when this device turns on " + "and run when its window is closed so that it can send to-do notifications.");
        var command = new GenericArray<unowned string> (2);
        foreach (unowned var arg in DAEMON_COMMAND) {
            command.add (arg);
        }

        var window = Xdp.parent_new_gtk (active_window);

        try {
            return yield portal.request_background (window, reason, command, flags, null);
        } catch (Error e) {
            debug ("Error during portal request: %s".printf (e.message));
            return e is IOError.FAILED;
        }
    }
    #endif

    public void create_dir_with_parents (string dir) {
        string path = Environment.get_user_data_dir () + dir;
        File tmp = File.new_for_path (path);
        if (tmp.query_file_type (0) != FileType.DIRECTORY) {
            GLib.DirUtils.create_with_parents (path, 0775);
        }
    }

    public void recreate_main_window () {
        if (main_window != null) {
            main_window.destroy ();
            main_window = null;
        }
        
        activate ();
    }

    private void snooze_item (string item_id, int minutes) {
        var item = Services.Store.instance ().get_item (item_id);
        if (item != null) {
            var datetime = new GLib.DateTime.now_local ().add_minutes (minutes);
            var reminder = new Objects.Reminder ();
            reminder.due.date = Utils.Datetime.get_todoist_datetime_format (
                Utils.Datetime.get_datetime_no_seconds (datetime, datetime)
            );
            item.add_reminder (reminder);
        }
    }

    private void build_shortcuts () {
        var show_item = new SimpleAction ("show-item", VariantType.STRING);
        show_item.activate.connect ((parameter) => {
            Planify.instance.main_window.view_item (parameter.get_string ());
            activate ();
        });

        var complete = new SimpleAction ("complete", VariantType.STRING);
        complete.activate.connect ((parameter) => {
            var item = Services.Store.instance ().get_item (parameter.get_string ());
            if (item != null) {
                item.checked = true;
                item.completed_at = new GLib.DateTime.now_local ().to_string ();
                Services.Store.instance ().complete_item (item, false);
            }
        });

        var snooze_10 = new SimpleAction ("snooze-10", VariantType.STRING);
        snooze_10.activate.connect ((parameter) => snooze_item (parameter.get_string (), 10));

        var snooze_30 = new SimpleAction ("snooze-30", VariantType.STRING);
        snooze_30.activate.connect ((parameter) => snooze_item (parameter.get_string (), 30));

        var snooze_60 = new SimpleAction ("snooze-60", VariantType.STRING);
        snooze_60.activate.connect ((parameter) => snooze_item (parameter.get_string (), 60));

        add_action (show_item);
        add_action (complete);
        add_action (snooze_10);
        add_action (snooze_30);
        add_action (snooze_60);
    }

    private static void ensure_schema_dir () {
        var current = GLib.Environment.get_variable ("GSETTINGS_SCHEMA_DIR");
        if (current != null && current != "") {
            return;
        }

        // Prefer a locally built schema (for in-tree runs), then fall back to the system install dir.
        string[] candidates = {
            Path.build_filename (GLib.Environment.get_current_dir (), "data"),
            Path.build_filename (Build.DATADIR, "glib-2.0", "schemas")
        };

        foreach (var dir in candidates) {
            var compiled = Path.build_filename (dir, "gschemas.compiled");
            if (FileUtils.test (compiled, FileTest.IS_REGULAR)) {
                GLib.Environment.set_variable ("GSETTINGS_SCHEMA_DIR", dir, true);
                break;
            }
        }
    }

    public static int main (string[] args) {
        // NOTE: Workaround for https://github.com/alainm23/planify/issues/1069
        GLib.Environment.set_variable ("WEBKIT_DISABLE_COMPOSITING_MODE", "1", true);
        // NOTE: Workaround for https://github.com/alainm23/planify/issues/1120
        GLib.Environment.set_variable ("WEBKIT_DISABLE_DMABUF_RENDERER", "1", true);

        ensure_schema_dir ();

        Planify app = Planify.instance;
        return app.run (args);
    }
}
