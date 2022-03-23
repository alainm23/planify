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
    public MainWindow? main_window = null;
    public static GLib.Settings settings;


    public static PlannerQuickAdd _instance = null;
    public static PlannerQuickAdd instance {
        get {
            if (_instance == null) {
                _instance = new PlannerQuickAdd ();
            }
            return _instance;
        }
    }

    public PlannerQuickAdd () {
        Object (
            application_id: "com.github.alainm23.planner.quick-add",
            flags: ApplicationFlags.FLAGS_NONE
        );

        settings = new Settings ("com.github.alainm23.planner3");
        // database = new Database ();
    }

    protected override void activate () {
        unowned List<Gtk.Window> windows = get_windows ();
        if (windows.length () > 0 && !windows.data.visible) {
            windows.data.destroy ();
            return;
        }

        main_window = new MainWindow (this);
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

        var provider = new Gtk.CssProvider ();
        provider.load_from_resource ("/com/github/alainm23/planner/index.css");
        Gtk.StyleContext.add_provider_for_screen (
            Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );
        
        // Set Theme and Icon
        Gtk.Settings.get_default ().set_property ("gtk-icon-theme-name", "elementary");
        Gtk.Settings.get_default ().set_property ("gtk-theme-name", "io.elementary.stylesheet.blueberry");
        QuickAddUtil.update_theme ();
    }
}

public static int main (string[] args) {
    var application = PlannerQuickAdd.instance;
    return application.run (args);
}