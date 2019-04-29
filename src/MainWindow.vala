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

public class MainWindow : Gtk.Window {
    public weak Application app { get; construct; }
    public Widgets.HeaderBar headerbar;
    
    public Gtk.Stack stack;

    public Views.Main main_view;
    public Views.Welcome welcome_view;
    public Views.TodoistAccess todoist_access_view;
    
    public Unity.LauncherEntry launcher;
    //public Widgets.QuickFind quick_find;
    //public Widgets.CalendarEvents events_widget;
    public const string CSS = """
        @define-color color_header %s;
        @define-color color_selected %s;
        @define-color color_text %s;
    """;

    public MainWindow (Application application) {
        Object (
            application: application,
            app: application,
            icon_name: "com.github.alainm23.planner",
            title: "Planner",
            height_request: 700,
            width_request: 1024
        );
    }

    construct {
        get_style_context ().add_class ("rounded");

        headerbar = new Widgets.HeaderBar ();
        set_titlebar (headerbar);

        stack = new Gtk.Stack ();
        stack.expand = true;
        stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;

        main_view = new Views.Main ();
        welcome_view = new Views.Welcome ();
        todoist_access_view = new Views.TodoistAccess ();
        
        stack.add_named (main_view, "main_view");
        stack.add_named (welcome_view, "welcome_view");
        stack.add_named (todoist_access_view, "todoist_access_view");
        
        add (stack);

        Timeout.add (150, () => {
            if (Application.database_v2.user_exists ()) {
                stack.visible_child_name = "main_view";
                headerbar.visible_ui = true;
                Application.database_v2.start_create_projects ();
            } else {
                stack.visible_child_name = "welcome_view";
                headerbar.visible_ui = false;
            }
             
            return false;
        }); 

        launcher = Unity.LauncherEntry.get_for_desktop_file (GLib.Application.get_default ().application_id + ".desktop");

        delete_event.connect (() => {
            Application.settings.set_int ("project-sidebar-width", main_view.position);

            if (Application.settings.get_boolean ("run-background")) {
                return hide_on_delete ();
            } else {
                return false;
            }
        });

        Application.settings.changed.connect (key => {
            if (key == "badge-count") {
                //check_badge_count ();
            } else if (key == "theme") {
                var provider = new Gtk.CssProvider ();
                var colored_css = "";

                colored_css = CSS.printf (
                    Application.utils.get_theme (Application.settings.get_enum ("theme")),
                    Application.utils.get_selected_theme (Application.settings.get_enum ("theme")),
                    Application.utils.convert_invert ( Application.utils.get_selected_theme (Application.settings.get_enum ("theme")))
                );

                try {
                    provider.load_from_data (colored_css, colored_css.length);

                    Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
                } catch (GLib.Error e) {
                    return;
                }
            }
        });
        
        todoist_access_view.back.connect (() => {
            stack.visible_child_name = "welcome_view";
        });

        welcome_view.activated.connect ((index) => {
            if (index == 0) {
                // Create User
                var user = new Objects.User ();
                user.id = (int64) Application.utils.generate_id ();
                user.inbox_project = (int64) Application.utils.generate_id ();
                user.full_name = GLib.Environment.get_real_name ();

                // Create Avatar
                var avatar_file = GLib.File.new_for_path ("/var/lib/AccountsService/icons/" + GLib.Environment.get_user_name ());

                var image_path = GLib.Path.build_filename (Application.utils.PROFILE_FOLDER, ("avatar-%s.jpg").printf (user.id.to_string ()));
                var file_path = File.new_for_path (image_path);

                try {
                    avatar_file.copy (file_path, 0, null, (current_num_bytes, total_num_bytes) => {
                        print ("%" + int64.FORMAT + " bytes of %" + int64.FORMAT + " bytes copied.\n",
                            current_num_bytes, total_num_bytes);
                    });
                } catch (Error e) {
                    print ("Error: %s\n", e.message);
                }
                
                // Create Inbox project
                var inbox_project = new Objects.Project ();
                inbox_project.inbox_project = true; 
                inbox_project.id = user.inbox_project;
                inbox_project.name = "Inbox";
                
                if (Application.database_v2.create_user (user)) {
                    Application.user = user;
                    stack.visible_child_name = "main_view";
                    headerbar.visible_ui = true;
                }
            } else if (index == 1) {

            } else {
                stack.visible_child_name = "todoist_access_view";
                todoist_access_view.init ();
            }
        });

        Application.todoist.sync_finished.connect (() => {
            stack.visible_child_name = "main_view";
            headerbar.visible_ui = true;
        });
    }

    public override bool configure_event (Gdk.EventConfigure event) {
        Gtk.Allocation rect;
        get_allocation (out rect);
        Application.settings.set_value ("window-size",  new int[] { rect.height, rect.width });

        int root_x, root_y;
        get_position (out root_x, out root_y);
        Application.settings.set_value ("window-position",  new int[] { root_x, root_y });

        return base.configure_event (event);
    }
}
