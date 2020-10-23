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

public enum NotificationStyle {
    NORMAL,
    ERROR
}

public class Planner : Gtk.Application {
    public MainWindow? main_window = null;

    public static Utils utils;
    public static GLib.Settings settings;
    public static Services.Database database;
    public static Services.Todoist todoist;
    public static Services.Notifications notifications;
    public static Services.EventBus event_bus;
    public static Services.Calendar.CalendarModel calendar_model;
    // public static Services.Tasks.Store task_store;

    public signal void go_view (string type, int64 id, int64 id_2);

    private static bool silent = false;
    private static int64 load_project = 0;
    private static bool version = false;
    private static bool clear_database = false;

    public const OptionEntry[] PLANNER_OPTIONS = {
        { "version", 'v', 0, OptionArg.NONE, ref version,
        "Display version number", null },
        { "reset-database", 'r', 0, OptionArg.NONE, ref clear_database,
        "Reset Planner database", null },
        { "silent", 's', 0, OptionArg.NONE, out silent,
        "Run the Application in background", null },
        { "load-project", 'l', 0, OptionArg.INT64, ref load_project,
        "Open project in separate window", "PROJECT_ID" },
        { null }
    };

    construct {
        application_id = "com.github.alainm23.planner";
        flags |= ApplicationFlags.HANDLES_OPEN;

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
        // task_store = new Services.Tasks.Store ();

        add_main_option_entries (PLANNER_OPTIONS);
        
        // Set lang
        // GLib.Environment.set_variable ("LANGUAGE", "es", true);
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

        if (version) {
            print ("%s\n".printf (Constants.VERSION));
            return;
        }

        if (clear_database) {
            print ("%s\n".printf (_("Are you sure you want to reset all?")));
            print (_("It process removes all stored information without the possibility of undoing it. (y/n): "));
            string input = stdin.read_line ();
            
            if (input == _("y") || input == _("yes") ) {
                var db_path = Planner.settings.get_string ("database-location-path");
                if (settings.get_boolean ("database-location-use-default")) {
                    db_path = Environment.get_user_data_dir () + "/com.github.alainm23.planner/database.db";
                }

                File db_file = File.new_for_path (db_path);
                try {
                    db_file.delete ();
                } catch (Error err) {
                    warning (err.message);
                }

                // Log out Todoist
                settings.set_string ("todoist-sync-token", "");
                settings.set_string ("todoist-access-token", "");
                settings.set_string ("todoist-last-sync", "");
                settings.set_string ("todoist-user-email", "");
                settings.set_string ("todoist-user-join-date", "");
                settings.set_string ("todoist-user-avatar", "");
                settings.set_string ("todoist-user-image-id", "");
                settings.set_boolean ("todoist-sync-server", false);
                settings.set_boolean ("todoist-account", false);
                settings.set_boolean ("todoist-user-is-premium", false);
                settings.set_int ("todoist-user-id", 0);
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

        // Open database
        database.open_database ();

        if (load_project != 0) {
            var dialog = new Dialogs.Project (database.get_project_by_id (load_project), true);
            dialog.destroy.connect (Gtk.main_quit);
            dialog.show_all ();
        }

        if (silent == false && load_project == 0) {
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
        utils.update_font_scale ();

        // Set Theme and Icon
        Gtk.Settings.get_default ().set_property ("gtk-icon-theme-name", "elementary");
        Gtk.Settings.get_default ().set_property ("gtk-theme-name", "elementary");

        // Path Theme
        //  if (utils.is_flatpak ()) {
        //      string CSS = """
        //          window decoration {
        //              box-shadow: none;
        //              border: 1px solid @decoration_border_color;
        //              border-radius: 4px;
        //              margin: 0px;
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
            quick_add_shortcut = "<Super>n";
            settings.set_string ("quick-add-shortcut", quick_add_shortcut);
        }

        utils.set_quick_add_shortcut (quick_add_shortcut, Planner.settings.get_boolean ("quick-add-enabled"));

        if (settings.get_string ("version") != Constants.VERSION) {
            var dialog = new Widgets.WhatsNew ("com.github.alainm23.planner", _("Planner %s is here, with many design improvements, new features, and more.".printf (Constants.VERSION)));

            List<string> list = new List<string> ();
            list.append (_("Github #575 - Homepage was fixed."));
            list.append (_("Github #336 - The option to change the text size was added."));
            list.append (_("Updated translations."));
            
            dialog.append_notes (_("Bug fixes and performance improvement"), list, 30);

            dialog.show_all ();
            dialog.present ();

            // Update the settings so we don't show the same dialog again.
            settings.set_string ("version", Constants.VERSION);
        }
    }
    
    private void build_shortcuts () {
        var show_item = new SimpleAction ("show-item", VariantType.INT64);
        show_item.activate.connect ((parameter) => {
            Planner.instance.main_window.go_item (parameter.get_int64 ());
            activate ();
        });

        add_action (show_item);
    }

    public static int main (string[] args) {
        Planner app = Planner.instance;
        return app.run (args);
    }
}
