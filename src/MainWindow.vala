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

    public Gee.HashMap<string, bool> loaded_projects;
    public MainWindow (Application application) {
        Object (
            application: application,
            icon_name: "com.github.alainm23.planner",
            title: _("Planner")
        );
    }

    construct {
        loaded_projects = new Gee.HashMap<string, bool> ();

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
        projectview_header.get_style_context ().add_class ("projectview-header");
        projectview_header.get_style_context ().add_class ("titlebar");
        projectview_header.get_style_context ().add_class ("default-decoration");
        projectview_header.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var tag_1_button = new Gtk.Button.with_label ("All");
        
        tag_1_button.get_style_context ().add_class ("preview");
        tag_1_button.valign = Gtk.Align.CENTER;

        var tag_2_button = new Gtk.Button.with_label ("CSS");
        tag_2_button.get_style_context ().add_class ("preview");
        tag_2_button.valign = Gtk.Align.CENTER;

        var tag_3_button = new Gtk.Button.with_label ("Alain");
        tag_3_button.get_style_context ().add_class ("preview");
        tag_3_button.valign = Gtk.Align.CENTER;

        var tag_4_button = new Gtk.Button.with_label ("Juan Carlos");
        tag_4_button.get_style_context ().add_class ("preview");
        tag_4_button.valign = Gtk.Align.CENTER;

        var tag_grid = new Gtk.Grid ();
        tag_grid.valign = Gtk.Align.CENTER;
        tag_grid.margin_start = 35;
        tag_grid.margin_top = 6;
        tag_grid.column_spacing = 6;
        tag_grid.add (tag_1_button);
        tag_grid.add (tag_2_button);
        tag_grid.add (tag_3_button);
        tag_grid.add (tag_4_button);

        //projectview_header.pack_start (tag_grid);

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
        //var project_view = new Views.Project ();

        var stack = new Gtk.Stack ();
        stack.expand = true;
        stack.transition_type = Gtk.StackTransitionType.NONE;
        
        stack.add_named (welcome_view, "welcome-view");
        stack.add_named (inbox_view, "inbox-view");
        stack.add_named (today_view, "today-view");
        stack.add_named (upcoming_view, "upcoming-view");
        //stack.add_named (project_view, "project_view");

        var toast = new Widgets.Toast ();

        var paned_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        paned_box.pack_start (stack, true, true, 0);
        paned_box.pack_start (toast, false, false, 0);

        var paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
        paned.pack1 (pane, false, false);
        paned.pack2 (paned_box, true, true);

        set_titlebar (header_paned);
        add (paned);

        // This must come after setting header_paned as the titlebar
        header_paned.get_style_context ().remove_class ("titlebar");
        get_style_context ().add_class ("rounded");
        Application.settings.bind ("pane-position", header_paned, "position", GLib.SettingsBindFlags.DEFAULT);
        Application.settings.bind ("pane-position", paned, "position", GLib.SettingsBindFlags.DEFAULT);

        Timeout.add (125, () => {
            if (Application.database.is_database_empty ()) {
                stack.visible_child_name = "welcome-view";
                pane.sensitive_ui = false;
            } else {
                stack.visible_child_name = "inbox-view";
                pane.sensitive_ui = true;
            }
             
            return false;
        });

        welcome_view.activated.connect ((index) => {
            if (index == 0) {
                // Save user name
                Application.settings.set_string ("user-name", GLib.Environment.get_real_name ());

                // To do: Save user photo
                // To do: Create a tutorial project

                // Create Inbox Project
                var inbox_project = Application.database.create_inbox_project ();
                Application.settings.set_int64 ("inbox-project", inbox_project.id);
                Application.settings.set_boolean ("inbox-project-sync", false);
                
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
                    stack.visible_child_name = "inbox-view";
                } else if  (id == 1) {
                    stack.visible_child_name = "today-view";
                } else {
                    stack.visible_child_name = "upcoming-view";
                }
            } else {
                if (loaded_projects.has_key (id.to_string ())) {
                    stack.visible_child_name = "project-view-%s".printf (id.to_string ());
                } else {
                    loaded_projects.set (id.to_string (), true);
                    var project_view = new Views.Project (Application.database.get_project_by_id (id));
                    stack.add_named (project_view, "project-view-%s".printf (id.to_string ()));
                    stack.visible_child_name = "project-view-%s".printf (id.to_string ());
                }
            }
        });

        Application.todoist.first_sync_finished.connect (() => {
            stack.visible_child_name = "inbox_view";
            pane.sensitive_ui = true;
        });

        Application.database.show_toast_delete.connect ((count) => {
            string t = _("task");

            if (count > 1) {
                t = _("tasks");
            }

            toast.title = _("(%i) %s deleted".printf (count, t));
            toast.send_notification ();
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