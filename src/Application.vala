public class Application : Gtk.Application {
    public MainWindow main_window;
    public static GLib.Settings settings;
    public static Services.Database database;
    public static Services.Notifications notification;
    public static Services.Signals signals;
    public static Utils utils;

    public const string CSS = """
        @define-color headerbar_color %s;
        @define-color textColorPrimary %s;
    """;
    public Application () {
        Object (
            application_id: "com.github.alainm23.planner",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    static construct {
        // Dir to Database
        utils = new Utils ();
        utils.create_dir_with_parents ("/.cache/com.github.alainm23.planner");

        settings = new Settings ("com.github.alainm23.planner");
        database = new Services.Database ();

        notification = new Services.Notifications ();
        signals = new Services.Signals ();
    }

    public static Application _instance = null;

    public static Application instance {
        get {
            if (_instance == null) {
                _instance = new Application ();
            }
            return _instance;
        }
    }

    protected override void activate () {
        if (get_windows ().length () > 0) {
            get_windows ().data.present ();
            return;
        }

        var window_size = settings.get_value ("window-size");
        var rect = Gtk.Allocation ();
        rect.height = (int32) window_size.get_child_value (0);
        rect.width =  (int32) window_size.get_child_value (1);

        var window_position = settings.get_value ("window-position");
        var window_x = (int32) window_position.get_child_value (0);
        var window_y = (int32) window_position.get_child_value (1);

        main_window = new MainWindow (this);
        if (window_x != -1 ||  window_y != -1) {
            main_window.move (window_x, window_y);
        }

        main_window.set_allocation (rect);
        main_window.show_all ();


        // Actions
        var quit_action = new SimpleAction ("quit", null);

        add_action (quit_action);
        set_accels_for_action ("app.quit", {"<Control>q"});

        quit_action.activate.connect (() => {
            if (main_window != null) {
                main_window.destroy ();
            }
        });

        var quick_find_action = new SimpleAction ("quick_find", null);
        add_action (quick_find_action);
        set_accels_for_action ("app.quick_find", {"<Control>f"});

        quick_find_action.activate.connect (() => {
            signals.on_signal_show_quick_find ();
        });

        var calendar_events_action = new SimpleAction ("calendar_events", null);
        add_action (calendar_events_action);
        set_accels_for_action ("app.calendar_events", {"<Control>e"});

        calendar_events_action.activate.connect (() => {
            signals.on_signal_show_events ();
        });

        // Default Icon Theme
        weak Gtk.IconTheme default_theme = Gtk.IconTheme.get_default ();
        default_theme.add_resource_path ("/com/github/alainm23/planner");

        // Stylesheet
        var provider = new Gtk.CssProvider ();
        provider.load_from_resource ("/com/github/alainm23/planner/stylesheet.css");
        Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        // Window Theme
        /*
        var theme_provider = new Gtk.CssProvider ();
        var colored_css = "";

        if (settings.get_boolean ("prefer-dark-style")) {
            colored_css = CSS.printf ("@base_color", "@text_color");
            stdout.printf ("true");
        } else {
            colored_css = CSS.printf ("#ffe16b", "#1a1a1a");
            stdout.printf ("true");
        }

        try {
            theme_provider.load_from_data (colored_css, colored_css.length);

            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), theme_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (GLib.Error e) {
            debug ("Theme error");
        }
        */
    }
    public static int main (string[] args) {
        Application app = Application.instance;
        return app.run (args);
    }
}
