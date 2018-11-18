public class Views.Main : Gtk.Paned {
    public weak MainWindow parent_window { get; construct; }

    public Widgets.ProjectsList projects_list;
    public Gtk.Stack stack;

    private Views.Inbox inbox_view;
    private Views.Today today_view;
    private Views.Tomorrow tomorrow_view;
    private Views.Project project_view;

    public Main (MainWindow parent) {
        Object (
            parent_window: parent,
            orientation: Gtk.Orientation.HORIZONTAL,
            position: Planner.settings.get_int ("project-sidebar-width")
        );
    }

    construct {
        get_style_context ().add_class ("view");

        projects_list = new Widgets.ProjectsList ();

        inbox_view = new Views.Inbox ();
        today_view = new Views.Today ();
        tomorrow_view = new Views.Tomorrow ();


        stack = new Gtk.Stack ();
        stack.expand = true;
        stack.transition_type = Gtk.StackTransitionType.SLIDE_UP_DOWN;

        stack.add_named (inbox_view, "inbox_view");
        stack.add_named (today_view, "today_view");
        stack.add_named (tomorrow_view, "tomorrow_view");
        stack.add_named (project_view, "project_view");

        update_views ();

        var start_page = Planner.settings.get_enum ("start-page");
        var start_page_name = "";

        if (start_page == 0) {
            start_page_name = "inbox_view";
        } else if (start_page == 1) {
            start_page_name = "today_view";
        } else {
            start_page_name = "tomorrow_view";
            start_page_name = "tomorrow_view";
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
                    stack.visible_child = inbox_view;

                    inbox_view.infobar_apply_remove ();
                } else if (index == 1) {
                    stack.visible_child = today_view;

                    today_view.infobar_apply_remove ();
                } else {
                    stack.visible_child = tomorrow_view;
                }
            } else {
                stack.visible_child_name = "project_view-" + index.to_string ();
            }
        });

        projects_list.on_add_project_signal.connect (() => {
            var project = Planner.database.get_last_project ();

            var project_view = new Views.Project (project, parent_window);
            stack.add_named (project_view, "project_view-" + project.id.to_string ());

            stack.show_all ();
        });

        Planner.notification.on_signal_highlight_task.connect ((task) => {
            stack.visible_child = inbox_view;
            destroy ();
        });
    }

    public void update_views () {
        var all_projects = new Gee.ArrayList<Objects.Project?> ();
        all_projects = Planner.database.get_all_projects ();

        foreach (var project in all_projects) {
            var project_view = new Views.Project (project, parent_window);
            stack.add_named (project_view, "project_view-" + project.id.to_string ());
        }
    }
}
