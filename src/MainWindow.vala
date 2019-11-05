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
    private string visible_child_name = "";

    public signal void shift_press ();
    public signal void shift_release ();
    public bool shift_pressed { get; private set; default = false; }


    private uint timeout_id = 0;

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

        var stack = new Gtk.Stack ();
        stack.expand = true;
        stack.transition_type = Gtk.StackTransitionType.NONE;
        
        stack.add_named (welcome_view, "welcome-view");
        stack.add_named (inbox_view, "inbox-view");
        stack.add_named (today_view, "today-view");
        stack.add_named (upcoming_view, "upcoming-view");

        var toast = new Widgets.Toast ();
        var magic_button = new Widgets.MagicButton ();

        var overlay = new Gtk.Overlay ();
        overlay.expand = true;
        overlay.add_overlay (magic_button);
        overlay.add_overlay (toast);
        overlay.add (stack); 

        var paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
        paned.pack1 (pane, false, false);
        paned.pack2 (overlay, true, true);

        set_titlebar (header_paned);
        add (paned);

        // This must come after setting header_paned as the titlebar
        header_paned.get_style_context ().remove_class ("titlebar");
        get_style_context ().add_class ("rounded");
        Application.settings.bind ("pane-position", header_paned, "position", GLib.SettingsBindFlags.DEFAULT);
        Application.settings.bind ("pane-position", paned, "position", GLib.SettingsBindFlags.DEFAULT);

        timeout_id = Timeout.add (125, () => {
            if (Application.database.is_database_empty ()) {
                stack.visible_child_name = "welcome-view";
                pane.sensitive_ui = false;
                magic_button.reveal_child = false;
            } else {
                stack.visible_child_name = "inbox-view";
                pane.sensitive_ui = true;
                magic_button.reveal_child = true;
            }   
            
            Source.remove (timeout_id);
            
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

                // Set settings
                Application.settings.set_boolean ("inbox-project-sync", false);
                Application.settings.set_int64 ("inbox-project", inbox_project.id);
                
                stack.transition_type = Gtk.StackTransitionType.CROSSFADE;
                stack.visible_child_name = "inbox-view";
                pane.sensitive_ui = true;
                magic_button.reveal_child = true;
                stack.transition_type = Gtk.StackTransitionType.NONE;
            } else {
                var todoistOAuth = new Dialogs.TodoistOAuth ();
                todoistOAuth.show_all ();
            }
        });

        pane.activated.connect ((type, id) => {
            if (id == 0) {
                stack.visible_child_name = "inbox-view";
            } else if  (id == 1) {
                stack.visible_child_name = "today-view";
            } else {
                stack.visible_child_name = "upcoming-view";
            }
        });

        Application.utils.pane_project_selected.connect ((project_id, area_id) => {
            if (loaded_projects.has_key (project_id.to_string ())) {
                stack.visible_child_name = "project-view-%s".printf (project_id.to_string ());
            } else {
                loaded_projects.set (project_id.to_string (), true);
                var project_view = new Views.Project (Application.database.get_project_by_id (project_id));
                stack.add_named (project_view, "project-view-%s".printf (project_id.to_string ()));
                stack.visible_child_name = "project-view-%s".printf (project_id.to_string ());
            }
        });

        Application.todoist.first_sync_finished.connect (() => {
            stack.transition_type = Gtk.StackTransitionType.CROSSFADE;
            stack.visible_child_name = "inbox-view";
            pane.sensitive_ui = true;
            magic_button.reveal_child = true;
            stack.transition_type = Gtk.StackTransitionType.NONE;
        });
        
        Application.database.project_deleted.connect ((p) => {
            if ("project-view-%s".printf (p.id.to_string ()) == stack.visible_child_name) {
                stack.visible_child.destroy ();
                stack.visible_child_name = "inbox-view";
            }
        });

        magic_button.clicked.connect (() => {
            visible_child_name = stack.visible_child_name;
            
            if (visible_child_name == "inbox-view") {
                int is_todoist = 0;
                if (Application.settings.get_boolean ("inbox-project-sync")) {
                    is_todoist = 1;
                }

                Application.utils.magic_button_activated (
                    Application.settings.get_int64 ("inbox-project"),
                    0,
                    is_todoist,
                    true
                );
            } else if (visible_child_name == "today-view") {

            } else if (visible_child_name == "upcoming-view") {

            } else {
                var project = ((Views.Project) stack.get_child_by_name (visible_child_name)).project;
                Application.utils.magic_button_activated (
                    project.id,
                    0,
                    project.is_todoist,
                    true
                );
            }
        });

        // Label Controller
        var labels_controller = new Services.LabelsController ();

        Application.database.label_added.connect_after ((label) => {
            Idle.add (() => {
                labels_controller.add_label (label);

                return false;
            });
        });

        Application.database.label_updated.connect ((label) => {
            Idle.add (() => {
                labels_controller.update_label (label);

                return false;
            });
        });  

        Application.settings.changed.connect ((key) => {
            if (key == "prefer-dark-style") {
                Application.utils.apply_theme_changed ();
            }
        });

        this.key_press_event.connect ((event) => {
            if (event.keyval == Gdk.Key.Shift_L) {
                shift_pressed = true;
                shift_press ();
                print ("Se apreto\n");
            }
            return false;
        });

        this.key_release_event.connect ((event) => {
            if (event.keyval == Gdk.Key.Shift_L) {
                shift_pressed = false;
                shift_release ();
                print ("Se dejo de apretar\n");
            }
            return true;
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