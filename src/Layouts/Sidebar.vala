public class Layouts.Sidebar : Gtk.Grid {
    private Gtk.FlowBox filters_flowBox;

    private Layouts.FilterPaneRow inbox_filter;
    private Layouts.FilterPaneRow today_filter;
    private Layouts.FilterPaneRow scheduled_filter;
    private Layouts.FilterPaneRow pinboard_filter;
    
    private Layouts.HeaderItem favorites_header;
    private Layouts.HeaderItem local_projects_header;
    private Layouts.HeaderItem todoist_projects_header;

    public Gee.HashMap <string, Layouts.ProjectRow> projects_hashmap;

    public Sidebar () {
        Object();
    }

    construct {
        projects_hashmap = new Gee.HashMap <string, Layouts.ProjectRow> ();

        filters_flowBox= new Gtk.FlowBox () {
            column_spacing = 9,
            row_spacing = 9,
            margin_start = 3,
            margin_end = 3,
            homogeneous = true,
            hexpand = true,
            max_children_per_line = 2,
            min_children_per_line = 2
        };

        inbox_filter = new Layouts.FilterPaneRow (FilterType.INBOX);
        today_filter = new Layouts.FilterPaneRow (FilterType.TODAY);
        scheduled_filter = new Layouts.FilterPaneRow (FilterType.SCHEDULED);
        pinboard_filter = new Layouts.FilterPaneRow (FilterType.PINBOARD);

        filters_flowBox.append (inbox_filter);
        filters_flowBox.append (today_filter);
        filters_flowBox.append (scheduled_filter);
        filters_flowBox.append (pinboard_filter);

        favorites_header = new Layouts.HeaderItem (PaneType.FAVORITE);
        favorites_header.margin_top = 6;

        local_projects_header = new Layouts.HeaderItem (PaneType.PROJECT);
        local_projects_header.margin_top = 6;

        todoist_projects_header = new Layouts.HeaderItem (PaneType.PROJECT);
        todoist_projects_header.margin_top = 6;

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            margin_start = 9,
            margin_end = 9
        };
        content_box.append(filters_flowBox);
        content_box.append(favorites_header);
        content_box.append(local_projects_header);
        content_box.append(todoist_projects_header);

        var scrolled_window = new Gtk.ScrolledWindow () {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            hexpand = true,
            vexpand = true
        };

        scrolled_window.child = content_box;

        attach(scrolled_window, 0, 0);

        local_projects_header.add_activated.connect (() => {
            prepare_new_project ();
        });

        todoist_projects_header.add_activated.connect (() => {
            bool is_logged_in = Services.Todoist.get_default ().is_logged_in ();
            
            if (is_logged_in) {
                
            } else {
                Services.Todoist.get_default ().init ();
            }
        });

        filters_flowBox.child_activated.connect ((child) => {
            select_filter (((Layouts.FilterPaneRow) child).filter_type);
        });
        
        local_projects_header.row_selected.connect ((row) => {
            select_project (((Layouts.ProjectRow) row).project);
        });

        todoist_projects_header.row_selected.connect ((row) => {
            select_project (((Layouts.ProjectRow) row).project);
        });
    }

    public void verify_todoist_account () {
        bool is_logged_in = Services.Todoist.get_default ().is_logged_in ();
        
        if (is_logged_in) {
            todoist_projects_header.header_title = Planner.settings.get_string ("todoist-user-email");
            todoist_projects_header.placeholder_message = _("No project available. Create one by clicking on the '+' button");
        } else {
            todoist_projects_header.header_title = _("Todoist");
            todoist_projects_header.placeholder_message = _("No account available, Sync one by clicking the '+' button");
        }
    }


    public void select_project (Objects.Project project) {
        Planner.event_bus.pane_selected (PaneType.PROJECT, project.id_string);
    }

    public void select_filter (FilterType filter_type) {
        Planner.event_bus.pane_selected (PaneType.FILTER, filter_type.to_string ());
    }

    public void init () {
        Services.Database.get_default().project_added.connect (add_row_project);
        // Planner.database.project_updated.connect (update_projects_sort);
        //  Planner.database.label_added.connect (add_row_label);
        //  Planner.event_bus.project_parent_changed.connect ((project, old_parent_id) => {
        //      if (old_parent_id == Constants.INACTIVE) {
        //          if (projects_hashmap.has_key (project.id_string)) {
        //              projects_hashmap [project.id_string].hide_destroy ();
        //              projects_hashmap.unset (project.id_string);
        //          }
        //      }

        //      if (project.parent_id == Constants.INACTIVE) {
        //          add_row_project (project);
        //      }
        //  });

        //  Planner.event_bus.favorite_toggled.connect ((project) => {
        //      if (favorites_hashmap.has_key (project.id_string)) {
        //          favorites_hashmap [project.id_string].hide_destroy ();
        //          favorites_hashmap.unset (project.id_string);
        //      } else {
        //          add_row_favorite (project);
        //      }
        //  });

        add_all_projects ();
        verify_todoist_account ();
    }

    private void add_all_projects () {
        foreach (Objects.Project project in Services.Database.get_default().projects) {
            add_row_project (project);
        }

        // projects_header.init_update_position_project ();
    }

    private void add_row_project (Objects.Project project) {
        if (!project.inbox_project && project.parent_id == Constants.INACTIVE) {
            if (!projects_hashmap.has_key (project.id_string)) {
                projects_hashmap [project.id_string] = new Layouts.ProjectRow (project);

                if (project.todoist) {
                    todoist_projects_header.add_child (projects_hashmap [project.id_string]);
                } else {
                    local_projects_header.add_child (projects_hashmap [project.id_string]);
                }
            }
        }
    }

    private void prepare_new_project () {
        var dialog = new Dialogs.Project.new ();
        dialog.show ();
    }
}