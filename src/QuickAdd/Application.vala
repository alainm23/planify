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
        entry {
            caret-color: #3689e6;
        }

        button {
            border-radius: 4px;
        }

        textview {
            caret-color: #3689e6;
        }

        .titlebar {
            padding: 0px;
            background-color: @base_color;
        }

        .checklist-button check {
            border-radius: 4px;
        }

        .content-entry {
            color: @text_color;
            font-weight: 600;
            border-width: 0px 0px 0px 0px;
            background-color: @base_color;
        }

        .content-entry:focus {
            border-color: transparent;
            box-shadow: none;
        }

        .label {
            font-size: 14px;
        }

        .quick-add-combobox {
            background-color: @base_color;
        }

        .quick-add-combobox button {
            border-radius: 4px;
        }
    """;

    public static Database database;
    public static GLib.Settings settings;

    public PlannerQuickAdd () {
        Object (
            application_id: "planner-quick-add",
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
                    return false;
                });
            }
        });

        // CSS provider
        var provider = new Gtk.CssProvider ();

        try {
            provider.load_from_data (CSS, CSS.length);
            Gtk.StyleContext.add_provider_for_screen (
                Gdk.Screen.get_default (), provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            );
        } catch (Error e) {
            debug (e.message);
        }

        // Default Icon Theme
        weak Gtk.IconTheme default_theme = Gtk.IconTheme.get_default ();
        default_theme.add_resource_path ("/com/github/alainm23/planner");

        // Dark Mode
        Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = settings.get_boolean ("prefer-dark-style");
    }
}

public static int main (string[] args) {
    var application = new PlannerQuickAdd ();
    return application.run (args);
}
