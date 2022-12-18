public class Layouts.Sidebar : Gtk.Grid {
    private Gtk.Grid filters_grid;

    private Layouts.FilterPaneRow inbox_filter;
    private Layouts.FilterPaneRow today_filter;
    private Layouts.FilterPaneRow scheduled_filter;
    private Layouts.FilterPaneRow pinboard_filter;
    
    private Layouts.HeaderItem favorites_header;
    private Layouts.HeaderItem local_projects_header;
    private Layouts.HeaderItem todoist_projects_header;

    public Gee.HashMap <string, Layouts.ProjectRow> local_hashmap;
    public Gee.HashMap <string, Layouts.ProjectRow> todoist_hashmap;
    public Gee.HashMap <string, Layouts.ProjectRow> favorites_hashmap;

    public Sidebar () {
        Object();
    }

    construct {
        local_hashmap = new Gee.HashMap <string, Layouts.ProjectRow> ();
        todoist_hashmap = new Gee.HashMap <string, Layouts.ProjectRow> ();
        favorites_hashmap = new Gee.HashMap <string, Layouts.ProjectRow> ();

        filters_grid= new Gtk.Grid () {
            row_spacing = 9,
            column_spacing = 9,
            margin_start = 3,
            margin_end = 3
        };

        inbox_filter = new Layouts.FilterPaneRow (FilterType.INBOX);
        today_filter = new Layouts.FilterPaneRow (FilterType.TODAY);
        scheduled_filter = new Layouts.FilterPaneRow (FilterType.SCHEDULED);
        pinboard_filter = new Layouts.FilterPaneRow (FilterType.PINBOARD);

        filters_grid.attach (inbox_filter, 0, 0);
        filters_grid.attach (today_filter, 1, 0);
        filters_grid.attach (scheduled_filter, 0, 1);
        filters_grid.attach (pinboard_filter, 1, 1);

        favorites_header = new Layouts.HeaderItem (PaneType.FAVORITE);
        favorites_header.margin_top = 6;
        favorites_header.show_action = false;

        local_projects_header = new Layouts.HeaderItem (PaneType.PROJECT);
        local_projects_header.margin_top = 6;

        todoist_projects_header = new Layouts.HeaderItem (PaneType.PROJECT);
        todoist_projects_header.margin_top = 6;

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            margin_start = 16,
            margin_end = 16,
            margin_bottom = 16,
            margin_top = 24
        };
        
        content_box.append (filters_grid);
        content_box.append (favorites_header);
        content_box.append (local_projects_header);
        content_box.append (todoist_projects_header);

        var scrolled_window = new Gtk.ScrolledWindow () {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            hexpand = true,
            vexpand = true
        };

        scrolled_window.child = content_box;

        attach (scrolled_window, 0, 0);

        local_projects_header.add_activated.connect (() => {
            prepare_new_project ();
        });

        todoist_projects_header.add_activated.connect (() => {
            bool is_logged_in = Services.Todoist.get_default ().is_logged_in ();
            
            if (is_logged_in) {
                prepare_new_project (true);
            } else {
                Services.Todoist.get_default ().init ();
            }
        });

        //  filters_grid.child_activated.connect ((child) => {
        //      select_filter (((Layouts.FilterPaneRow) child).filter_type);
        //  });
        
        //  local_projects_header.row_selected.connect ((row) => {
        //      select_project (((Layouts.ProjectRow) row).project);
        //  });

        //  todoist_projects_header.row_selected.connect ((row) => {
        //      select_project (((Layouts.ProjectRow) row).project);
        //  });
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

        Planner.event_bus.favorite_toggled.connect ((project) => {
            if (favorites_hashmap.has_key (project.id_string)) {
                favorites_hashmap [project.id_string].hide_destroy ();
                favorites_hashmap.unset (project.id_string);
            } else {
                add_row_favorite (project);
            }

            favorites_header.check_visibility ();
        });

        inbox_filter.init ();
        today_filter.init ();
        scheduled_filter.init ();
        pinboard_filter.init ();
                
        add_all_projects ();
        add_all_favorites ();

        verify_todoist_account ();
    }

    private void add_all_projects () {
        foreach (Objects.Project project in Services.Database.get_default ().projects) {
            add_row_project (project);
        }

        // projects_header.init_update_position_project ();
    }

    private void add_all_favorites () {
        foreach (Objects.Project project in Services.Database.get_default ().projects) {
            add_row_favorite (project);
        }

        favorites_header.check_visibility ();
    }

    private void add_row_favorite (Objects.Project project) {
        if (project.is_favorite) {
            if (!favorites_hashmap.has_key (project.id_string)) {
                favorites_hashmap [project.id_string] = new Layouts.ProjectRow (project, false);
                favorites_header.add_child (favorites_hashmap [project.id_string]);
            }
        }
    }

    private void add_row_project (Objects.Project project) {
        if (!project.inbox_project && project.parent_id == Constants.INACTIVE) {
            if (project.todoist) {
                if (!todoist_hashmap.has_key (project.id_string)) {
                    todoist_hashmap [project.id_string] = new Layouts.ProjectRow (project);
                    todoist_projects_header.add_child (todoist_hashmap [project.id_string]);
                }
            } else {
                if (!local_hashmap.has_key (project.id_string)) {
                    local_hashmap [project.id_string] = new Layouts.ProjectRow (project);
                    local_projects_header.add_child (local_hashmap [project.id_string]);
                }
            }
        }
    }

    private void prepare_new_project (bool todoist = false) {
        var dialog = new Dialogs.Project.new (todoist);
        dialog.show ();
    }
}