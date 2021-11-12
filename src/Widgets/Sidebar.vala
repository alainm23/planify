public class Widgets.Sidebar : Gtk.EventBox {
    private Gtk.ListBox listbox;

    private Widgets.FilterPaneRow quick_search;
    private Widgets.FilterPaneRow inbox;
    private Widgets.FilterPaneRow today;
    private Widgets.FilterPaneRow upcoming;
    private Widgets.FilterPaneRow trash;

    private Widgets.TodoistSync todoist_button;
    private Widgets.HeaderItem projects_header;
    private Widgets.HeaderItem labels_header;
    private Gtk.Grid main_grid;
    
    public Gee.HashMap <string, Widgets.LabelRow> labels_hashmap;
    public Gee.HashMap <string, Widgets.ProjectRow> projects_hashmap;

    construct {
        labels_hashmap = new Gee.HashMap <string, Widgets.LabelRow> ();
        projects_hashmap = new Gee.HashMap <string, Widgets.ProjectRow> ();

        todoist_button = new Widgets.TodoistSync ();

        listbox = new Gtk.ListBox () {
            hexpand = true
        };
        
        unowned Gtk.StyleContext listbox_context = listbox.get_style_context ();
        listbox_context.add_class ("pane-listbox");

        quick_search = new Widgets.FilterPaneRow (FilterType.QUICK_SEARCH);
        inbox = new Widgets.FilterPaneRow (FilterType.INBOX);
        today = new Widgets.FilterPaneRow (FilterType.TODAY);
        upcoming = new Widgets.FilterPaneRow (FilterType.UPCOMING);
        trash = new Widgets.FilterPaneRow (FilterType.TRASH);

        var listbox_grid = new Gtk.Grid () {
            margin = 9,
            margin_top = 0
        };
        listbox_grid.add (listbox);

        projects_header = new Widgets.HeaderItem (PaneType.PROJECT);
        labels_header = new Widgets.HeaderItem (PaneType.LABEL);

        main_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL
        };
        
        main_grid.add (todoist_button);
        main_grid.add (listbox_grid);
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
        project.color = GLib.Random.int_range (30, 50);

        if (backend_type == BackendType.TODOIST) {
            project.is_todoist = 1;
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
            listbox.add (quick_search);
            listbox.add (inbox);
            listbox.add (today);
            listbox.add (upcoming);
            listbox.add (trash);

            // Init signals
            Planner.database.project_added.connect (add_row_project);
            Planner.database.project_deleted.connect (delete_row_project);

            Planner.database.label_added.connect (add_row_label);
            Planner.database.label_deleted.connect (delete_row_label);

            Planner.event_bus.delete_row_project.connect (delete_row_project);

            Planner.todoist.sync_started.connect (todoist_button.sync_started);
            Planner.todoist.sync_finished.connect (todoist_button.sync_finished);

            // Get projects
            add_all_projects ();
            add_all_labels ();
        } else if (backend_type == BackendType.CALDAV) {
            listbox.add (today);
            listbox.add (upcoming);
        }
        
        listbox.show_all ();
    }

    private void add_row_project (Objects.Project project) {
        if (project.inbox_project == 0) {
            var row = new Widgets.ProjectRow (project);
            projects_hashmap [project.id_string] = row;

            if (project.parent_id == 0) {
                projects_header.add_child (row);
            } else {
                projects_hashmap [project.parent_id_string].add_subproject (row);
            }
        }
    }

    private void add_row_label (Objects.Label label) {
        var row = new Widgets.LabelRow (label);
        labels_header.add_child (row);
        labels_hashmap [label.id_string] = row;
    }

    private void add_all_projects () {
        foreach (Objects.Project project in Planner.database.projects) {
            add_row_project (project);
        }
    }

    private void add_all_labels () {
        foreach (Objects.Label label in Planner.database.labels) {
            add_row_label (label);
        }
    }

    private void delete_row_label (Objects.Label label) {
        if (labels_hashmap.has_key (label.id_string)) {
            labels_hashmap [label.id_string].hide_destroy ();
            labels_hashmap.unset (label.id_string);
        }
    }

    private void delete_row_project (Objects.Project project) {
        if (projects_hashmap.has_key (project.id_string)) {
            projects_hashmap [project.id_string].hide_destroy ();
            projects_hashmap.unset (project.id_string);
        }
    }
}
