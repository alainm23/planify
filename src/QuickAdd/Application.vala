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

public class PlannerQuickAdd : Gtk.Application {
    private const string CSS = """
        @define-color base_color %s;    

        decoration {
            box-shadow:
                0 0 0 1px alpha(@theme_bg_color, 0),
                0 14px 28px alpha(@theme_bg_color, 0),
                0 10px 10px alpha(@theme_bg_color, 0);
        }

        .quick-add {
            background: alpha(@theme_bg_color, 0);
        }

        .titlebar {
            background: alpha(@theme_bg_color, 0);
            border: none;
            color: alpha(@theme_bg_color, 0);
            font-size: 0.001px;
            margin: 0;
            opacity: 0;
            padding: 0;
        }

        entry {
            caret-color: #3689e6;
        }

        button {
            border-radius: 4px;
        }

        .titlebar {
            padding: 0px;
            background-color: @base_color;
        }

        .checklist-button check {
            border-radius: 4px;
        }

        .active-switch slider {
            min-height: 16px;
            min-width: 16px;
        }

        .content-entry {
            border-width: 0 0 1px;
            border-radius: 0;
            background-color: transparent;
            background-image: none;
            box-shadow: none;
            border-bottom: none;
        }

        .content-entry:focus {
            border-color: transparent;
            box-shadow: none;
        }

        .quick-add-combobox {
            background-color: @base_color;
        }

        .quick-add-combobox button {
            padding-left: 6px;
            padding-right: 6px;
            border-radius: 4px;
        }

        .textview text {
            background: alpha (#3689e6, 0.24);
        }

        .check-grid {
            background-color: alpha (#3689e6, 0.25);
            border-radius: 4px;
            border: 1px solid alpha (#3689e6, 0.45);
        }

        .fake-window {
            background: @theme_bg_color;
            border-radius: 4px;
            box-shadow:
              0 0 0 1px @decoration_border_color,
              0 14px 28px alpha(black, 0.35),
              0 10px 10px alpha(black, 0.22);
        }

        .priority-4 check {
            border-radius: 4px;
            border-color: #ff7066;
            background: rgba (255, 112, 102, 0.1);
        }
        
        .priority-3 check {
            border-radius: 4px;
            border-color: #ff9a14;
            background: rgba (255, 154, 20, 0.1);
        }
        
        .priority-2 check {
            border-radius: 4px;
            border-color: #5297ff;
            background: rgba (82, 151, 255, 0.1);
        }
        
        .priority-1 check {
            border-radius: 4px;
            border-color: @border_color;
            background: transparent;
        }

        .overdue-label {
            color: #fa1955;
        }

        .today {
            color: #ffaa00;
        }

        .upcoming {
            color: #692fc2;
        }

        .today-icon {
            background-color: #ffaa00;
            color: #ffffff;
            border-radius: 4px;
            padding: 2px;
        }

        .upcoming-icon {
            background-color: #692fc2;
            color: #fff;
            border-radius: 4px;
            padding: 2px;
        }

        .due-clear {
            background-color: #333333;
            color: #fff;
            border-radius: 4px;
            padding: 2px;
        }
    """;

    public static Database database;
    public static GLib.Settings settings;

    public PlannerQuickAdd () {
        Object (
            application_id: "com.github.alainm23.planner.quick-add",
            flags: ApplicationFlags.FLAGS_NONE
        );

        settings = new Settings ("com.github.alainm23.planner");
        database = new Database ();
    }

    protected override void activate () {
        unowned List<Gtk.Window> windows = get_windows ();
        if (windows.length () > 0 && !windows.data.visible) {
            windows.data.destroy ();
            return;
        }

        var main_window = new MainWindow (this);
        main_window.show_all ();

        var quit_action = new SimpleAction ("quit", null);

        add_action (quit_action);
        set_accels_for_action ("app.quit", {"Escape"});

        quit_action.activate.connect (() => {
            if (main_window != null) {
                main_window.hide ();

                Timeout.add (500, () => {
                    main_window.destroy ();
                    return GLib.Source.REMOVE;
                });
            }
        });

        // Default Icon Theme
        weak Gtk.IconTheme default_theme = Gtk.IconTheme.get_default ();
        default_theme.add_resource_path ("/com/github/alainm23/planner");
        
        // Set Theme and Icon
        Gtk.Settings.get_default ().set_property ("gtk-icon-theme-name", "elementary");
        Gtk.Settings.get_default ().set_property ("gtk-theme-name", "elementary");
        
        // Dark Mode
        int appearance_mode = settings.get_enum ("appearance");
        string base_color = "white";
        if (appearance_mode == 0) {
            base_color = "white";
            Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = false;
        } else if (appearance_mode == 1) {
            base_color = "#282828";
            Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
        } else if (appearance_mode == 2) {
            base_color = "#15151B";
            Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
        } else if (appearance_mode == 3) {
            base_color = "#353945";
            Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
        }

        // CSS provider
        var provider = new Gtk.CssProvider ();
        try {
            provider.load_from_data (CSS.printf (base_color), CSS.length);
            Gtk.StyleContext.add_provider_for_screen (
                Gdk.Screen.get_default (), provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            );
        } catch (Error e) {
            debug (e.message);
        }
    }
}

public static int main (string[] args) {
    GLib.Environment.set_variable ("GTK_CSD", "1", true);

    Gtk.init (ref args);
    
    var application = new PlannerQuickAdd ();
    return application.run (args);
}
