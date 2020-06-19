/*
* Copyright © 2019 Alain M. (https://github.com/alainm23/planner)
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

public class Planner : Gtk.Application {
    public MainWindow? main_window = null;

    public static Utils utils;
    public static GLib.Settings settings;
    public static Services.Database database;
    public static Services.Todoist todoist;
    public static Services.Notifications notifications;
    public static Services.EventBus event_bus;
    public static Services.Calendar.CalendarModel calendar_model;

    public signal void go_view (string type, int64 id, int64 id_2);

    private bool silence = false;

    public Planner () {
        Object (
            application_id: "com.github.alainm23.planner",
            flags: ApplicationFlags.HANDLES_COMMAND_LINE
        );

        // Init internationalization support
        Intl.setlocale (LocaleCategory.ALL, "");
        string langpack_dir = Path.build_filename (Constants.INSTALL_PREFIX, "share", "locale");
        Intl.bindtextdomain (Constants.GETTEXT_PACKAGE, langpack_dir);
        Intl.bind_textdomain_codeset (Constants.GETTEXT_PACKAGE, "UTF-8");
        Intl.textdomain (Constants.GETTEXT_PACKAGE);

        // Dir to Database
        utils = new Utils ();
        utils.create_dir_with_parents ("/com.github.alainm23.planner");
        utils.create_dir_with_parents ("/com.github.alainm23.planner/avatars");

        // Services
        settings = new Settings ("com.github.alainm23.planner");
        database = new Services.Database ();
        todoist = new Services.Todoist ();
        notifications = new Services.Notifications ();
        calendar_model = new Services.Calendar.CalendarModel ();
        event_bus = new Services.EventBus ();
    }

    public static Planner _instance = null;
    public static Planner instance {
        get {
            if (_instance == null) {
                _instance = new Planner ();
            }
            return _instance;
        }
    }

    protected override void activate () {
        if (get_windows ().length () > 0) {
            get_windows ().data.present ();
            get_windows ().data.show_all ();

            int x, y;
            settings.get ("window-position", "(ii)", out x, out y);
            if (x != -1 || y != -1) {
                get_windows ().data.move (x, y);
            }

            return;
        }

        main_window = new MainWindow (this);

        int window_x, window_y;
        var rect = Gtk.Allocation ();

        settings.get ("window-position", "(ii)", out window_x, out window_y);
        settings.get ("window-size", "(ii)", out rect.width, out rect.height);

        if (window_x != -1 || window_y != -1) {
            main_window.move (window_x, window_y);
        }

        main_window.set_allocation (rect);

        if (settings.get_boolean ("window-maximized")) {
            main_window.maximize ();
        }

        if (silence == false) {
            main_window.show_all ();
            main_window.present ();
        }

        // Actions
        build_shortcuts ();

        // Stylesheet
        var provider = new Gtk.CssProvider ();
        provider.load_from_resource ("/com/github/alainm23/planner/stylesheet.css");
        Gtk.StyleContext.add_provider_for_screen (
            Gdk.Screen.get_default (),
            provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );

        // Default Icon Theme
        weak Gtk.IconTheme default_theme = Gtk.IconTheme.get_default ();
        default_theme.add_resource_path ("/com/github/alainm23/planner");

        utils.apply_theme_changed ();

        // Set Theme and Icon
        Gtk.Settings.get_default ().set_property ("gtk-icon-theme-name", "elementary");
        Gtk.Settings.get_default ().set_property ("gtk-theme-name", "elementary");

        // Path Theme
        //  if (get_os_info ("PRETTY_NAME") == null || get_os_info ("PRETTY_NAME").index_of ("elementary") == -1) {
        //      string CSS = """
        //          window decoration {
        //              box-shadow: none;
        //              margin: 1px;
        //          }
        //      """;

        //      var _provider = new Gtk.CssProvider ();
        //      _provider.load_from_data (CSS, CSS.length);

        //      Gtk.StyleContext.add_provider_for_screen (
        //          Gdk.Screen.get_default (), _provider,
        //          Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        //      );
        //  }

        // Set shortcut
        string quick_add_shortcut = settings.get_string ("quick-add-shortcut");
        if (quick_add_shortcut == "") {
            quick_add_shortcut = "<Primary>Tab";
            settings.set_string ("quick-add-shortcut", quick_add_shortcut);
        }

        utils.set_quick_add_shortcut (quick_add_shortcut);
        database.open_database ();

        if (settings.get_string ("version") != Constants.VERSION) {
            var dialog = new Dialogs.ReleaseDialog ();
            dialog.show_all ();
            dialog.present ();

            // Update the settings so we don't show the same dialog again.
            settings.set_string ("version", Constants.VERSION);
        }
    }

    public override int command_line (ApplicationCommandLine command_line) {
        bool silence_mode = false;
        OptionEntry[] options = new OptionEntry [1];
        options[0] = {
            "s", 0, 0, OptionArg.NONE,
            ref silence_mode, "Run without window", null
        };

        string[] args = command_line.get_arguments ();
        string[] _args = new string[args.length];
        for (int i = 0; i < args.length; i++) {
            _args[i] = args[i];
        }

        try {
            var ctx = new OptionContext ();
            ctx.set_help_enabled (true);
            ctx.add_main_entries (options, null);
            unowned string[] tmp = _args;
            ctx.parse (ref tmp);
        } catch (OptionError e) {
            command_line.print ("error: %s\n", e.message);
            return 0;
        }

        silence = silence_mode;
        activate ();

        return 0;
    }

    private void build_shortcuts () {
        var show_item = new SimpleAction ("show-item", VariantType.INT64);
        show_item.activate.connect ((parameter) => {
            Planner.instance.main_window.go_item (parameter.get_int64 ());
            activate ();
        });
    }

    public static int main (string[] args) {
        Planner app = Planner.instance;

        if (args.length > 1 && args[1] == "--s") {
            app.silence = true;
        }

        return app.run (args);
    }
}
