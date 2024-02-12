public class Widgets.ProjectPicker.ProjectPickerPopover : Gtk.Popover {
    public signal void selected (Objects.Project project);

    public ProjectPickerPopover () {
        Object (
            height_request: 300,
            width_request: 275,
            has_arrow: false,
            position: Gtk.PositionType.BOTTOM
        );
    }

    construct {
        var search_entry = new Gtk.SearchEntry () {
            margin_top = 9,
            margin_start = 9,
            margin_end = 9,
            margin_bottom = 9
        };
            
        var inbox_group = new Layouts.HeaderItem (null) {
            reveal_child = true
        };

        var local_group = new Layouts.HeaderItem (_("On this Computer")) {
            reveal_child = Services.Database.get_default ().get_projects_by_backend_type (BackendType.LOCAL).size > 0
        };
        
        var todoist_group = new Layouts.HeaderItem (_("Todoist")) {
            reveal_child = Services.Database.get_default ().get_projects_by_backend_type (BackendType.TODOIST).size > 0
        };

        var nextcloud_group = new Layouts.HeaderItem (_("Nextcloud")) {
            reveal_child = Services.Database.get_default ().get_projects_by_backend_type (BackendType.CALDAV).size > 0
        };

        var scrolled_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        scrolled_box.append (inbox_group);
        scrolled_box.append (local_group);
        scrolled_box.append (todoist_group);
        scrolled_box.append (nextcloud_group);

        var listbox = new Gtk.ListBox () {
            hexpand = true,
            vexpand = true
        };
        
        var stack = new Gtk.Stack () {
            hexpand = true,
            vexpand = true,
            transition_type = Gtk.StackTransitionType.CROSSFADE,
            margin_start = 6,
            margin_end = 6,
            margin_bottom = 6
        };

        stack.add_named (scrolled_box, "projects");
        stack.add_named (listbox, "search");
        
        var scrolled_window = new Gtk.ScrolledWindow () {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            hexpand = true,
            vexpand = true,
            child = stack
        };

        var toolbar_view = new Adw.ToolbarView ();
		toolbar_view.add_top_bar (search_entry);
		toolbar_view.content = scrolled_window;

        child = toolbar_view;
        add_css_class ("popover-no-content");
        search_entry.grab_focus ();
        
        foreach (Objects.Project project in Services.Database.get_default ().projects) {
            var row = new Widgets.ProjectPicker.ProjectPickerRow (project);
            var row_2 = new Widgets.ProjectPicker.ProjectPickerRow (project);

            row.selected.connect (() => {
                selected (row.project);
                popdown ();
            });

            row_2.selected.connect (() => {
                selected (row.project);
                popdown ();
            });

            listbox.append (row_2);

            if (project.is_inbox_project) {
                inbox_group.add_child (row);
            } else {
                if (project.backend_type == BackendType.LOCAL) {
                    local_group.add_child (row);
                } else if (project.backend_type == BackendType.TODOIST) {
                    todoist_group.add_child (row);
                } else if (project.backend_type == BackendType.CALDAV) {
                    nextcloud_group.add_child (row);
                }
            }
        }

        search_entry.search_changed.connect (() => {
            scrolled_window.vadjustment.value = 0;
            listbox.invalidate_filter ();
            stack.visible_child_name = search_entry.text.length > 0 ? "search" : "projects";
        });

        listbox.set_filter_func ((row) => {
            var project = ((Widgets.ProjectPicker.ProjectPickerRow) row).project;
            return search_entry.text.down () in project.name.down ();
        });

        closed.connect (() => {
            stack.visible_child_name = "projects";
        });
    }
}
