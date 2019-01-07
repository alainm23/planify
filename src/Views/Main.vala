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

public class Views.Main : Gtk.Paned {
    public weak MainWindow parent_window { get; construct; }

    public Widgets.ProjectsList projects_list;
    public Gtk.Stack stack;

    private Views.Inbox inbox_view;
    private Views.Today today_view;
    private Views.Upcoming upcoming_view;
    private Views.AllTasks all_tasks_view;
    private Views.CompletedTasks completed_tasks_view;
    public Main (MainWindow parent) {
        Object (
            parent_window: parent,
            orientation: Gtk.Orientation.HORIZONTAL,
            position: Application.settings.get_int ("project-sidebar-width")
        );
    }

    construct {
        get_style_context ().add_class ("view");

        projects_list = new Widgets.ProjectsList ();

        inbox_view = new Views.Inbox ();
        today_view = new Views.Today ();
        upcoming_view = new Views.Upcoming ();
        all_tasks_view = new Views.AllTasks ();
        completed_tasks_view = new Views.CompletedTasks ();

        stack = new Gtk.Stack ();
        stack.expand = true;
        stack.transition_type = Gtk.StackTransitionType.SLIDE_UP_DOWN;

        stack.add_named (inbox_view, "inbox_view");
        stack.add_named (today_view, "today_view");
        stack.add_named (upcoming_view, "upcoming_view");
        stack.add_named (all_tasks_view, "all_tasks_view");
        stack.add_named (completed_tasks_view, "completed_tasks_view");

        update_views ();

        var start_page = Application.settings.get_enum ("start-page");
        var start_page_name = "";

        if (start_page == 0) {
            start_page_name = "inbox_view";
        } else if (start_page == 1) {
            start_page_name = "today_view";
        } else {
            start_page_name = "upcoming_view";
        }

        Timeout.add (200, () => {
            stack.visible_child_name = start_page_name;
            return false;
        });

        pack1 (projects_list, false, false);
        pack2 (stack, true, true);

        projects_list.on_selected_item.connect ((type, index) => {
            if (type == "item") {
                if (index == 0) {
                    stack.visible_child_name = "inbox_view";
                } else if (index == 1) {
                    stack.visible_child_name = "today_view";
                } else if (index == 2) {
                    stack.visible_child_name = "upcoming_view";
                } else if (index == 3) {
                    stack.visible_child_name = "all_tasks_view";
                } else {
                    stack.visible_child_name = "completed_tasks_view";
                }
            } else {
                stack.visible_child_name = "project_view-" + index.to_string ();
                var project_view = stack.get_child_by_name ("project_view-" + index.to_string ()) as Views.Project;
                //project_view.apply_remove ();
            }
        });

        Application.database.on_add_project_signal.connect (() => {
            var project = Application.database.get_last_project ();

            var project_view = new Views.Project (project, parent_window);
            stack.add_named (project_view, "project_view-%i".printf (project.id));

            stack.show_all ();
        });

        Application.notification.on_signal_highlight_task.connect ((task) => {
            stack.visible_child_name = "inbox_view";
            destroy ();
        });

        Application.signals.go_action_page.connect ((index) => {
            if (index == 0) {
                stack.visible_child_name = "inbox_view";
            } else if (index == 1) {
                stack.visible_child_name = "today_view";
            } else if (index == 2) {
                stack.visible_child_name = "upcoming_view";
            } else if (index == 3) {
                stack.visible_child_name = "all_tasks_view";
            } else if (index == 4) {
                stack.visible_child_name = "completed_tasks_view";
            }
        });

        Application.signals.go_project_page.connect ((project_id) => {
            stack.visible_child_name = "project_view-%i".printf (project_id);
        });

        Application.signals.go_task_page.connect ((task_id, project_id) => {
            stack.visible_child_name = "project_view-%i".printf (project_id);
        });
    }

    public void update_views () {
        var all_projects = new Gee.ArrayList<Objects.Project?> ();
        all_projects = Application.database.get_all_projects ();

        foreach (var project in all_projects) {
            var project_view = new Views.Project (project, parent_window);
            stack.add_named (project_view, "project_view-%i".printf (project.id));
        }
    }
}
