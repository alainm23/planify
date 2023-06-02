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

    private static bool silent = false;
    private static bool version = false;
    private static bool clear_database = false;
    private static string lang = "";

    private const OptionEntry[] PLANNER_OPTIONS = {
        { "version", 'v', 0, OptionArg.NONE, ref version,
        "Display version number", null },
        { "reset", 'r', 0, OptionArg.NONE, ref clear_database,
        "Reset Planner", null },
        { "silent", 's', 0, OptionArg.NONE, out silent,
        "Run the Application in background", null },
        { "lang", 'l', 0, OptionArg.STRING, ref lang,
        "Open Planner in a specific language", "LANG" },
        { null }
    };
    
    static construct {
        settings = new Settings ("io.github.alainm23.planify");
    }

    construct {
        application_id = "io.github.alainm23.planify";
        flags |= ApplicationFlags.HANDLES_OPEN;

        Intl.setlocale (LocaleCategory.ALL, "");
        string langpack_dir = Path.build_filename (Constants.INSTALL_PREFIX, "share", "locale");
        Intl.bindtextdomain (Constants.GETTEXT_PACKAGE, langpack_dir);
        Intl.bind_textdomain_codeset (Constants.GETTEXT_PACKAGE, "UTF-8");
        Intl.textdomain (Constants.GETTEXT_PACKAGE);

        add_main_option_entries (PLANNER_OPTIONS);

        create_dir_with_parents ("/io.github.alainm23.planify");

        event_bus = new Services.EventBus ();
    }

    protected override void activate () {
        if (lang != "") {
            GLib.Environment.set_variable ("LANGUAGE", lang, true);
        }

        if (version) {
            print ("%s\n".printf (Constants.VERSION));
            return;
        }

        if (main_window != null) {
            main_window.show ();
            return;
        }

        main_window = new MainWindow (this);

        Planner.settings.bind ("window-height", main_window, "default-height", SettingsBindFlags.DEFAULT);
        Planner.settings.bind ("window-width", main_window, "default-width", SettingsBindFlags.DEFAULT);

        if (Planner.settings.get_boolean ("window-maximized")) {
            main_window.maximize ();
        }

        if (!silent) {
            main_window.show ();
        }

        Planner.settings.bind ("window-maximized", main_window, "maximized", SettingsBindFlags.SET);

        var provider = new Gtk.CssProvider ();
        provider.load_from_resource ("/io/github/alainm23/planify/index.css");
        Gtk.StyleContext.add_provider_for_display (
            Gdk.Display.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );

        Util.get_default ().update_theme ();

        if (settings.get_string ("version") != Constants.VERSION) {
            settings.set_string ("version", Constants.VERSION);
        }

        if (clear_database) {
            Util.get_default ().clear_database (_("Are you sure you want to reset all?"),
                _("The process removes all stored information without the possibility of undoing it."));
        }
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