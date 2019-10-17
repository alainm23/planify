/*
* Copyright © 2019 Alain M. (https://github.com/alainm23/planner)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
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
* Authored by: Alain M. <alain23@protonmail.com>
*/

public class Application : Gtk.Application {
    public MainWindow main_window;
    public static GLib.Settings settings;
    public static Services.Database database;
    public static Services.Notifications notification;
    public static Services.Signals signals;
    public static Services.Github github;
    public static Services.Share share;

    public static string APP_VERSION;

    public static Utils utils;

    public const string CSS = """
        @define-color color_header %s;
        @define-color color_selected %s;
        @define-color color_text %s;
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
        utils.create_dir_with_parents ("/.local/share/com.github.alainm23.planner");
        utils.create_dir_with_parents ("/.local/share/com.github.alainm23.planner/profile");

        settings = new Settings ("com.github.alainm23.planner");
        database = new Services.Database ();

        notification = new Services.Notifications ();
        signals = new Services.Signals ();
        github = new Services.Github ();
        share = new Services.Share ();

        APP_VERSION =  "1.2.4";
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
        set_accels_for_action ("app.quick_find", {"<Control>f"});

        quick_find_action.activate.connect (() => {
            signals.on_signal_show_quick_find ();
        });

        var calendar_events_action = new SimpleAction ("calendar_events", null);
        set_accels_for_action ("app.calendar_events", {"<Control>e"});
        calendar_events_action.activate.connect (() => {
            signals.on_signal_show_events ();
        });

        var show_task = new SimpleAction ("show-task", VariantType.INT32);
        show_task.activate.connect ((parameter) => {
            var task = Application.database.get_task (parameter.get_int32 ());

            activate ();

            Timeout.add (200, () => {
                Application.signals.go_task_page (task.id, task.project_id);
                return false;
            });
        });

        var show_window = new SimpleAction ("show-window", null);
        show_window.activate.connect (() => {
            activate ();
        });

        add_action (quick_find_action);
        add_action (calendar_events_action);
        add_action (show_task);
        add_action (show_window);

        // Default Icon Theme
        weak Gtk.IconTheme default_theme = Gtk.IconTheme.get_default ();
        default_theme.add_resource_path ("/com/github/alainm23/planner");

        // Stylesheet
        var provider = new Gtk.CssProvider ();
        provider.load_from_resource ("/com/github/alainm23/planner/stylesheet.css");
        Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        // Window Theme
        var theme_provider = new Gtk.CssProvider ();
        var colored_css = "";

        if (settings.get_boolean ("prefer-dark-style")) {
            colored_css = CSS.printf (
                "@base_color",
                "@selected_bg_color",
                "@text_color"
            );
        } else {
            colored_css = CSS.printf (
                Application.utils.get_theme (Application.settings.get_enum ("theme")),
                Application.utils.get_theme (Application.settings.get_enum ("theme")),
                Application.utils.convert_invert ( Application.utils.get_theme (Application.settings.get_enum ("theme")))
            );
        }

        try {
            theme_provider.load_from_data (colored_css, colored_css.length);
            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), theme_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (GLib.Error e) {
            debug ("Theme error");
        }
    }
    public static int main (string[] args) {
        Application app = Application.instance;
        return app.run (args);
    }
}
