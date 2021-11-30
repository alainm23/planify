public class Layouts.Sidebar : Gtk.EventBox {
    private Gtk.FlowBox listbox;

    private Layouts.FilterPaneRow inbox;
    private Layouts.FilterPaneRow today;
    private Layouts.FilterPaneRow upcoming;
    private Layouts.FilterPaneRow pinboard;

    private Widgets.TodoistSync todoist_button;
    private Layouts.HeaderItem favorites_header;
    private Layouts.HeaderItem projects_header;
    private Layouts.HeaderItem labels_header;
    private Gtk.Grid main_grid;
    
    public Gee.HashMap <string, Layouts.ProjectRow> projects_hashmap;
    public Gee.HashMap <string, Layouts.ProjectRow> favorites_hashmap;

    construct {
        projects_hashmap = new Gee.HashMap <string, Layouts.ProjectRow> ();
        favorites_hashmap = new Gee.HashMap <string, Layouts.ProjectRow> ();

        todoist_button = new Widgets.TodoistSync ();

        listbox = new Gtk.FlowBox () {
            column_spacing = 9,
            row_spacing = 9,
            homogeneous = true,
            hexpand = true,
            max_children_per_line = 2,
            min_children_per_line = 2
        };
        
        unowned Gtk.StyleContext listbox_context = listbox.get_style_context ();
        listbox_context.add_class ("padding-3");

        var listbox_grid = new Gtk.Grid () {
            margin = 6,
            margin_bottom = 3,
            margin_top = 0
        };
        listbox_grid.add (listbox);

        inbox = new Layouts.FilterPaneRow (FilterType.INBOX);
        today = new Layouts.FilterPaneRow (FilterType.TODAY);
        upcoming = new Layouts.FilterPaneRow (FilterType.SCHEDULED);
        pinboard = new Layouts.FilterPaneRow (FilterType.PINBOARD);

        favorites_header = new Layouts.HeaderItem (PaneType.FAVORITE);
        projects_header = new Layouts.HeaderItem (PaneType.PROJECT);
        labels_header = new Layouts.HeaderItem (PaneType.LABEL);

        main_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL
        };
        
        main_grid.add (todoist_button);
        main_grid.add (listbox_grid);
        main_grid.add (favorites_header);
        main_grid.add (projects_header);
        main_grid.add (labels_header);

        var scrolled_window = new Gtk.ScrolledWindow (null, null) {
            hscrollbar_policy = Gtk.PolicyType.NEVER
        };
        scrolled_window.expand = true;
        scrolled_window.add (main_grid);

        add (scrolled_window);

        projects_header.add_activated.connect (() => {
            prepare_new_project ();
        });
    }

    private void prepare_new_project () {
        BackendType backend_type = (BackendType) Planner.settings.get_enum ("backend-type");

        var project = new Objects.Project ();
        project.name = _("New Project");
        project.color = Util.get_default ().get_random_color ();

        if (backend_type == BackendType.TODOIST) {
            project.todoist = true;
            projects_header.is_loading = true;
            Planner.todoist.add_project.begin (project, (obj, res) => {
                project.id = Planner.todoist.add_project.end (res);
                Planner.database.insert_project (project);
                projects_header.is_loading = false;
                Planner.event_bus.pane_selected (PaneType.PROJECT, project.id_string);
            });
        } else {
            project.id = Util.get_default ().generate_id ();
            Planner.database.insert_project (project);
        }
    }

    public void init (BackendType backend_type) {
        if (backend_type == BackendType.LOCAL || backend_type == BackendType.TODOIST) {
            listbox.add (inbox);
            listbox.add (today);
            listbox.add (upcoming);
            listbox.add (pinboard);

            // Init signals
            Planner.database.project_added.connect (add_row_project);
            Planner.database.label_added.connect (add_row_label);
            Planner.event_bus.project_parent_changed.connect ((project, old_parent_id) => {
                if (old_parent_id == Constants.INACTIVE) {
                    if (projects_hashmap.has_key (project.id_string)) {
                        projects_hashmap [project.id_string].hide_destroy ();
                        projects_hashmap.unset (project.id_string);
                    }
                }

                if (project.parent_id == Constants.INACTIVE) {
                    add_row_project (project);
                }
            });

            Planner.event_bus.favorite_toggled.connect ((project) => {
                if (favorites_hashmap.has_key (project.id_string)) {
                    favorites_hashmap [project.id_string].hide_destroy ();
                    favorites_hashmap.unset (project.id_string);
                } else {
                    add_row_favorite (project);
                }
                // if (project.favorite) {

                // } else {

                // }
            });

            if (backend_type == BackendType.TODOIST) {
                Planner.todoist.sync_started.connect (todoist_button.sync_started);
                Planner.todoist.sync_finished.connect (todoist_button.sync_finished);
            }

            // Get projects
            add_all_projects ();
            add_all_favorites ();
            add_all_labels ();
        } else if (backend_type == BackendType.CALDAV) {
            listbox.add (today);
            listbox.add (upcoming);
        }
        
        listbox.show_all ();
    }

    private void add_row_project (Objects.Project project) {
        if (!project.inbox_project && project.parent_id == Constants.INACTIVE) {
            if (!projects_hashmap.has_key (project.id_string)) {
                projects_hashmap [project.id_string] = new Layouts.ProjectRow (project);
                projects_header.add_child (projects_hashmap [project.id_string]);
            }
        }
    }

    private void add_row_label (Objects.Label label) {
        labels_header.add_child (new Layouts.LabelRow (label));
    }

    private void add_all_projects () {
        foreach (Objects.Project project in Planner.database.projects) {
            add_row_project (project);
        }
    }

    private void add_all_favorites () {
        foreach (Objects.Project project in Planner.database.projects) {
            add_row_favorite (project);
        }
    }

    private void add_row_favorite (Objects.Project project) {
        if (project.is_favorite) {
            if (!favorites_hashmap.has_key (project.id_string)) {
                favorites_hashmap [project.id_string] = new Layouts.ProjectRow (project, false);
                favorites_header.add_child (favorites_hashmap [project.id_string]);
            }
        }
    }

    private void add_all_labels () {
        foreach (Objects.Label label in Planner.database.labels) {
            add_row_label (label);
        }
    }
}
