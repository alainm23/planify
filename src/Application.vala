/*
* Copyright (c) 2017 Daniel Foré (http://danielfore.com)
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
*/

public class Planner : Gtk.Application {
    public MainWindow? main_window = null;

    public static GLib.Settings settings;
    public static Services.Database database;
    public static Services.EventBus event_bus;
    public static Services.Todoist todoist;

    public static Planner _instance = null;
    public static Planner instance {
        get {
            if (_instance == null) {
                _instance = new Planner ();
            }
            return _instance;
        }
    }

    construct {
        application_id = "com.github.alainm23.planner";
        flags |= ApplicationFlags.HANDLES_OPEN;

        create_dir_with_parents ("/com.github.alainm23.planner");

        settings = new Settings ("com.github.alainm23.planner");
        event_bus = new Services.EventBus ();
    }

    protected override void activate () {
        if (get_windows ().length () > 0) {
            get_windows ().data.present ();
            return;
        }

        main_window = new MainWindow (this);

        int window_x, window_y;
        int width, height;

        settings.get ("window-position", "(ii)", out window_x, out window_y);
        settings.get ("window-size", "(ii)", out width, out height);

        if (window_x != -1 || window_y != -1) {
            main_window.move (window_x, window_y);
        }

        if (width != -1 || height != -1) {
            var rect = Gtk.Allocation ();
            rect.height = height;
            rect.width = width;
            main_window.set_allocation (rect);
        }

        if (settings.get_boolean ("window-maximized")) {
            main_window.maximize ();
        }

        main_window.show_all ();
 
        var quit_action = new SimpleAction ("quit", null);

        add_action (quit_action);
        set_accels_for_action ("app.quit", {"<Control>q"});

        var granite_settings = Granite.Settings.get_default ();
        var gtk_settings = Gtk.Settings.get_default ();

        gtk_settings.gtk_application_prefer_dark_theme = (
            granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK
        );

        granite_settings.notify["prefers-color-scheme"].connect (() => {
            bool is_dark = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
            event_bus.prefers_color_scheme_changed (is_dark);
            gtk_settings.gtk_application_prefer_dark_theme = is_dark;
        });

        var provider_stylesheet = new Gtk.CssProvider ();
        provider_stylesheet.load_from_resource ("/com/github/alainm23/planner/stylesheet.css");
        Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider_stylesheet, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        
        var provider_animations = new Gtk.CssProvider ();
        provider_animations.load_from_resource ("/com/github/alainm23/planner/animations.css");
        Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider_animations, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        weak Gtk.IconTheme default_theme = Gtk.IconTheme.get_default ();
        default_theme.add_resource_path ("/com/github/alainm23/planner");
        
        quit_action.activate.connect (() => {
            if (main_window != null) {
                main_window.destroy ();
            }
        });
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
