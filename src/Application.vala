public class Planner : Gtk.Application {
    private MainWindow main_window;
    public static GLib.Settings settings;
    public static Services.Database database;
    public static Services.Notifications notification;
    public static Utils utils;
    public static Unity.LauncherEntry launcher;

    public const string CSS = """
        @define-color headerbar_color %s;
    """;

    public Planner () {
        Object (
            application_id: "com.github.artegeek.planner",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    static construct {
        // Dir to Database
        utils = new Utils ();
        utils.create_dir_with_parents ("/.cache/com.github.artegeek.planner");

        settings = new Settings ("com.github.artegeek.planner");
        database = new Services.Database ();

        notification = new Services.Notifications ();

        launcher = Unity.LauncherEntry.get_for_desktop_file (GLib.Application.get_default ().application_id + ".desktop");
        launcher.count = 2;
        launcher.count_visible = 2 != 0U;
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

        var quit_action = new SimpleAction ("quit", null);

        add_action (quit_action);
        set_accels_for_action ("app.quit", {"<Control>q"});

        weak Gtk.IconTheme default_theme = Gtk.IconTheme.get_default ();
        default_theme.add_resource_path ("/com/github/artegeek/planner");

        var provider = new Gtk.CssProvider ();
        provider.load_from_resource ("/com/github/artegeek/planner/stylesheet.css");
        Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);


        // Theme
        var theme_provider = new Gtk.CssProvider ();
        var colored_css = "";

        if (settings.get_boolean ("prefer-dark-style")) {
            colored_css = CSS.printf ("@base_color");
            stdout.printf ("true");
        } else {
            colored_css = CSS.printf ("#ffe16b");
            stdout.printf ("true");
        }

        try {
            theme_provider.load_from_data (colored_css, colored_css.length);

            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), theme_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (GLib.Error e) {
            debug ("Theme error");
        }

        quit_action.activate.connect (() => {
            if (main_window != null) {
                main_window.destroy ();
            }
        });

    }
    public static int main (string[] args) {
        var app = new Planner ();
        return app.run (args);
    }
}
