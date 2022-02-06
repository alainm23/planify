public class Layouts.Sidebar : Gtk.EventBox {
    private Gtk.FlowBox listbox;

    private Layouts.FilterPaneRow inbox;
    private Layouts.FilterPaneRow today;
    private Layouts.FilterPaneRow scheduled;
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
            margin_bottom = 6,
            margin_top = 0
        };
        listbox_grid.add (listbox);

        inbox = new Layouts.FilterPaneRow (FilterType.INBOX);
        today = new Layouts.FilterPaneRow (FilterType.TODAY);
        scheduled = new Layouts.FilterPaneRow (FilterType.SCHEDULED);
        pinboard = new Layouts.FilterPaneRow (FilterType.PINBOARD);

        favorites_header = new Layouts.HeaderItem (PaneType.FAVORITE);
        projects_header = new Layouts.HeaderItem (PaneType.PROJECT);
        labels_header = new Layouts.HeaderItem (PaneType.LABEL);

        var settings_image = new Widgets.DynamicIcon () {
            hexpand = true,
            halign = Gtk.Align.END
        };
        settings_image.size = 19;
        settings_image.update_icon_name ("planner-settings");

        var settings_label = new Gtk.Label (_("Settings"));

        var settings_grid = new Gtk.Grid ();

        settings_grid.add (settings_image);
        settings_grid.add (settings_label);

        var settings_button = new Gtk.Button () {
            can_focus = false,
            halign = Gtk.Align.CENTER,
            valign = Gtk.Align.END,
            vexpand = true,
            margin_bottom = 6
        };

        settings_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        settings_button.get_style_context ().add_class ("rotate-animation");
        settings_button.add (settings_grid);

        main_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL
        };
        
        main_grid.add (todoist_button);
        main_grid.add (listbox_grid);
        main_grid.add (favorites_header);
        main_grid.add (projects_header);
        main_grid.add (labels_header);
        main_grid.add (settings_button);

        var scrolled_window = new Gtk.ScrolledWindow (null, null) {
            hscrollbar_policy = Gtk.PolicyType.NEVER
        };
        scrolled_window.expand = true;
        scrolled_window.add (main_grid);

        add (scrolled_window);

        projects_header.add_activated.connect (() => {
            prepare_new_project ();
        });

        labels_header.add_activated.connect (() => {
            prepare_new_label ();
        });

        settings_button.clicked.connect (() => {
            var dialog = new Dialogs.Settings.Settings ();
            dialog.show_all ();
        });
    }

    private void prepare_new_project () {
        var dialog = new Dialogs.Project.new ();
        dialog.show_all ();
    }

    private void prepare_new_label () {
        var dialog = new Dialogs.Label.new ();
        dialog.show_all ();
    }

    public void init (BackendType backend_type) {
        if (backend_type == BackendType.LOCAL || backend_type == BackendType.TODOIST) {
            listbox.add (inbox);
            listbox.add (today);
            listbox.add (scheduled);
            listbox.add (pinboard);

            inbox.init ();
            today.init ();
            scheduled.init ();
            pinboard.init ();

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

    private void add_row_label (Objects.Label label) {
        labels_header.add_child (new Layouts.LabelRow (label));
    }
}
