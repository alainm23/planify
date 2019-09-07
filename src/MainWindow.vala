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
    private Widgets.Pane pane;
    public MainWindow (Application application) {
        Object (
            application: application,
            icon_name: "com.github.alainm23.planner",
            title: _("Planner")
        );
    }

    construct {
        var sidebar_header = new Gtk.HeaderBar ();
        sidebar_header.decoration_layout = "close:";
        sidebar_header.has_subtitle = false;
        sidebar_header.show_close_button = true;
        sidebar_header.get_style_context ().add_class ("sidebar-header");
        sidebar_header.get_style_context ().add_class ("titlebar");
        sidebar_header.get_style_context ().add_class ("default-decoration");
        sidebar_header.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var projectview_header = new Gtk.HeaderBar ();
        projectview_header.has_subtitle = false;
        projectview_header.decoration_layout = ":";
        projectview_header.show_close_button = true;
        projectview_header.get_style_context ().add_class ("projectview_header");
        projectview_header.get_style_context ().add_class ("titlebar");
        projectview_header.get_style_context ().add_class ("default-decoration");
        projectview_header.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var header_paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
        header_paned.pack1 (sidebar_header, false, false);
        header_paned.pack2 (projectview_header, true, false);

        var listbox = new Gtk.ListBox ();
        listbox.get_style_context ().add_class ("sidebar");

        var scrolledwindow = new Gtk.ScrolledWindow (null, null);
        scrolledwindow.expand = true;
        scrolledwindow.add (listbox);
        
        pane = new Widgets.Pane ();
        
        var welcome_view = new Views.Welcome ();
        var inbox_view = new Views.Inbox ();
        var today_view = new Views.Today ();
        var upcoming_view = new Views.Upcoming ();
        var project_view = new Views.Project ();

        var stack = new Gtk.Stack ();
        stack.expand = true;
        stack.transition_type = Gtk.StackTransitionType.NONE;
        
        stack.add_named (welcome_view, "welcome_view");
        stack.add_named (inbox_view, "inbox_view");
        stack.add_named (today_view, "today_view");
        stack.add_named (upcoming_view, "upcoming_view");
        stack.add_named (project_view, "project_view");

        var paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
        paned.pack1 (pane, false, false);
        paned.pack2 (stack, true, false);

        set_titlebar (header_paned);
        add (paned);

        // This must come after setting header_paned as the titlebar
        header_paned.get_style_context ().remove_class ("titlebar");
        get_style_context ().add_class ("rounded");
        Application.settings.bind ("pane-position", header_paned, "position", GLib.SettingsBindFlags.DEFAULT);
        Application.settings.bind ("pane-position", paned, "position", GLib.SettingsBindFlags.DEFAULT);

        welcome_view.activated.connect ((index) => {
            if (index == 0) {
                // Save user name
                Application.settings.set_string ("user-name", GLib.Environment.get_real_name ());

                // Create Inbox Project
                var inbox_project = Application.database.create_inbox_project ();
                Application.settings.set_int ("inbox-project", inbox_project.id);

                //stack.transition_type = Gtk.StackTransitionType.SLIDE_UP_DOWN;
                stack.visible_child_name = "inbox_view";
                pane.sensitive_ui = true;
            } else {
                var todoistOAuth = new Dialogs.TodoistOAuth ();
                todoistOAuth.show_all ();
            }
        });

        pane.activated.connect ((type, id) => {
            if (type == "action") {
                if (id == 0) {
                    stack.visible_child_name = "inbox_view";
                } else if  (id == 1) {
                    stack.visible_child_name = "today_view";
                } else {
                    stack.visible_child_name = "upcoming_view";
                }
            } else {
                stack.visible_child_name = "project_view";
                project_view.project = Application.database.get_project_by_id (id);
            }
        });

        Timeout.add (125, () => {
            if (Application.database.is_database_empty ()) {
                stack.visible_child_name = "welcome_view";
                pane.sensitive_ui = false;
            } else {
                stack.visible_child_name = "inbox_view";
                pane.sensitive_ui = true;
            }
             
            return false;
        });

        Application.todoist.first_sync_finished.connect (() => {
            stack.visible_child_name = "inbox_view";
            pane.sensitive_ui = true;
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