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
    public MainWindow? main_window = null;

    public static Utils utils;
    public static GLib.Settings settings;
    public static Services.Database database;
    public static Services.Todoist todoist;
    public static Services.Notifications notifications;
    public static Services.Calendar.CalendarModel calendar_model;
    
    public signal void go_view (string type, int64 id, int64 id_2);

    private bool silence = false;

    public Application () {
        Object (
            application_id: "com.github.alainm23.planner",
            flags: ApplicationFlags.HANDLES_COMMAND_LINE
        ); 

        // Dir to Database
        utils = new Utils ();
        utils.create_dir_with_parents ("/.local/share/com.github.alainm23.planner");
        utils.create_dir_with_parents ("/.local/share/com.github.alainm23.planner/avatars");

        // Services
        settings = new Settings ("com.github.alainm23.planner2");
        database = new Services.Database ();
        todoist = new Services.Todoist ();
        notifications = new Services.Notifications ();
        calendar_model = new Services.Calendar.CalendarModel ();
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
        if (main_window != null) {
            main_window.present ();
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

        if (silence == false) {
            main_window.show_all ();
            main_window.present ();
        }

        // Actions
        var quit_action = new SimpleAction ("quit", null);
        set_accels_for_action ("app.quit", {"<Control>q"});

        quit_action.activate.connect (() => {
            if (main_window != null) {
                main_window.destroy ();
            }
        });

        var show_item = new SimpleAction ("show-item", VariantType.INT64);
        show_item.activate.connect ((parameter) => {
            //var item = Application.database.get_item_by_id (parameter.get_int64 ());
            activate ();
        });

        var quick_find_action = new SimpleAction ("quick-find", null);
        set_accels_for_action ("app.quick-find", {"<Control>f"});

        quick_find_action.activate.connect (() => {
            main_window.show_quick_find ();
        });
        
        add_action (quit_action);
        add_action (show_item);
        add_action (quick_find_action);

        // Stylesheet
        var provider = new Gtk.CssProvider ();
        provider.load_from_resource ("/com/github/alainm23/planner/stylesheet.css");
        Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        // Default Icon Theme
        weak Gtk.IconTheme default_theme = Gtk.IconTheme.get_default ();
        default_theme.add_resource_path ("/com/github/alainm23/planner");

        utils.apply_theme_changed ();
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
        for(int i = 0; i < args.length; i++) {
            _args[i] = args[i];
        }

        try {
            var ctx = new OptionContext ();
            ctx.set_help_enabled (true);
            ctx.add_main_entries (options, null);
            unowned string[] tmp = _args;
            ctx.parse (ref tmp);
        } catch(OptionError e) {
            command_line.print ("error: %s\n", e.message);
            return 0;
        }

        silence = silence_mode;
        activate ();

        return 0;
    }
    
    public static int main (string[] args) {
        Application app = Application.instance;

        if (args.length > 1 && args[1] == "--s") {
            app.silence = true;
        }

        return app.run (args);
    }
}
