public class Planner : Adw.Application {
    public MainWindow main_window;

    public static GLib.Settings settings;
    public static Services.EventBus event_bus;

    public static Planner _instance = null;
    public static Planner instance {
        get {
            if (_instance == null) {
                _instance = new Planner ();
            }
            return _instance;
        }
    }
    
    static construct {
        settings = new Settings ("com.github.alainm23.planner");
    }

    construct {
        application_id = "com.github.alainm23.planner";
        flags |= ApplicationFlags.HANDLES_OPEN;

        Intl.setlocale (LocaleCategory.ALL, "");
        string langpack_dir = Path.build_filename (Constants.INSTALL_PREFIX, "share", "locale");
        Intl.bindtextdomain (Constants.GETTEXT_PACKAGE, langpack_dir);
        Intl.bind_textdomain_codeset (Constants.GETTEXT_PACKAGE, "UTF-8");
        Intl.textdomain (Constants.GETTEXT_PACKAGE);

        // add_main_option_entries (PLANNER_OPTIONS);

        create_dir_with_parents ("/com.github.alainm23.planner");

        event_bus = new Services.EventBus ();
    }

    protected override void activate () {
        main_window = new MainWindow (this);
        main_window.show ();

        Planner.settings.bind ("window-height", main_window, "default-height", SettingsBindFlags.DEFAULT);
        Planner.settings.bind ("window-width", main_window, "default-width", SettingsBindFlags.DEFAULT);

        if (Planner.settings.get_boolean ("window-maximized")) {
            main_window.maximize ();
        }

        Planner.settings.bind ("window-maximized", main_window, "maximized", SettingsBindFlags.SET);

        var provider = new Gtk.CssProvider ();
        provider.load_from_resource ("/com/github/alainm23/planner/index.css");
        Gtk.StyleContext.add_provider_for_display (
            Gdk.Display.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );

        Util.get_default ().update_theme ();
    }

    public void create_dir_with_parents (string dir) {
        string path = Environment.get_user_data_dir () + dir;
        File tmp = File.new_for_path (path);
        if (tmp.query_file_type (0) != FileType.DIRECTORY) {
            GLib.DirUtils.create_with_parents (path, 0775);
        }
    }

    public static int main (string[] args) {
        Planner app = Planner.instance;
        return app.run (args);
    }
}