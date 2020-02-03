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

public class Planner : Gtk.Application {
    public MainWindow? main_window = null;

    public static Utils utils;
    public static GLib.Settings settings;
    public static Services.Database database;
    public static Services.Todoist todoist;
    public static Services.Notifications notifications;
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

        // Path database
        database.patch_database ();
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
        Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        // Default Icon Theme
        weak Gtk.IconTheme default_theme = Gtk.IconTheme.get_default ();
        default_theme.add_resource_path ("/com/github/alainm23/planner");

        utils.apply_theme_changed ();

        Gtk.Settings.get_default ().set_property ("gtk-icon-theme-name", "elementary");
        Gtk.Settings.get_default ().set_property ("gtk-theme-name", "elementary");
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

    private void build_shortcuts () {
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

        var add_task = new SimpleAction ("add-task", null);
        set_accels_for_action ("app.add-task", {"<Control>n"});
        add_task.activate.connect (() => {
            main_window.add_task_action (true);
        });

        var add_task_first = new SimpleAction ("add-task-first", null);
        set_accels_for_action ("app.add-task-first", {"<Control><Shift>n"});
        add_task_first.activate.connect (() => {
            main_window.add_task_action (false);
        });

        var sync_manually = new SimpleAction ("sync-manually", null);
        set_accels_for_action ("app.sync-manually", {"<Control>s"});
        sync_manually.activate.connect (() => {
            todoist.sync ();
        });

        var new_project = new SimpleAction ("new-project", null);
        set_accels_for_action ("app.new-project", {"<Control><Shift>p"});
        new_project.activate.connect (() => {
            main_window.new_project ();
        });

        var new_area = new SimpleAction ("new-area", null);
        set_accels_for_action ("app.new-area", {"<Control><Shift>a"});
        new_area.activate.connect (() => {
            var area = new Objects.Area ();
            area.name = _("New area");
            database.insert_area (area);
        });

        var new_section = new SimpleAction ("new-section", null);
        set_accels_for_action ("app.new-section", {"<Control><Shift>s"});
        new_section.activate.connect (() => {
            main_window.new_section_action ();
        });

        var view_inbox = new SimpleAction ("view-inbox", null);
        set_accels_for_action ("app.view-inbox", {"<Control>1"});
        view_inbox.activate.connect (() => {
            main_window.go_view (0);
        });

        var view_today = new SimpleAction ("view-today", null);
        set_accels_for_action ("app.view-today", {"<Control>2"});
        view_today.activate.connect (() => {
            main_window.go_view (1);
        });

        var view_upcoming = new SimpleAction ("view-upcoming", null);
        set_accels_for_action ("app.view-upcoming", {"<Control>3"});
        view_upcoming.activate.connect (() => {
            main_window.go_view (2);
        });

        //  var open_settings = new SimpleAction ("open-settings", null);
        //  set_accels_for_action ("app.open-settings", {"<Control>,"});
        //  open_settings.activate.connect (() => {
        //      var dialog = new Dialogs.Preferences ();
        //      dialog.destroy.connect (Gtk.main_quit);
        //      dialog.show_all ();
        //  });
        
        add_action (quit_action);
        add_action (show_item);
        add_action (quick_find_action);
        add_action (add_task);
        add_action (add_task_first);
        add_action (sync_manually);
        add_action (new_project);
        add_action (new_area);
        add_action (new_section);
        add_action (view_inbox);
        add_action (view_today);
        add_action (view_upcoming);
        //add_action (open_settings);
    }
    
    public static int main (string[] args) {
        Planner app = Planner.instance;

        if (args.length > 1 && args[1] == "--s") {
            app.silence = true;
        }

        return app.run (args);
    }
}
