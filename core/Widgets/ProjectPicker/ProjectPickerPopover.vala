public class Widgets.ProjectPicker.ProjectPickerPopover : Gtk.Popover {
    public signal void selected (Objects.Project project);

    private Gtk.ListBox listbox;
    private Gtk.Revealer search_entry_revealer;
    
    public bool search_visible {
        set {
            search_entry_revealer.reveal_child = value;
        }
    }

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

        search_entry_revealer = new Gtk.Revealer () {
            child = search_entry,
            reveal_child = true
        };

        listbox = new Gtk.ListBox () {
            hexpand = true,
            valign = Gtk.Align.START,
            css_classes = { "listbox-background" },
            margin_start = 9,
            margin_end = 9,
            margin_bottom = 9
        };

        listbox.set_sort_func (sort_source_function);
        listbox.set_header_func (header_project_function);
        
        var scrolled_window = new Gtk.ScrolledWindow () {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            hexpand = true,
            vexpand = true,
            child = listbox
        };

        var toolbar_view = new Adw.ToolbarView ();
		toolbar_view.add_top_bar (search_entry_revealer);
		toolbar_view.content = scrolled_window;

        child = toolbar_view;
        add_css_class ("popover-no-content");
        search_entry.grab_focus ();
        add_projects ();

        search_entry.search_changed.connect (() => {
            scrolled_window.vadjustment.value = 0;
            listbox.invalidate_filter ();
        });

        listbox.set_filter_func ((row) => {
            var project = ((Widgets.ProjectPicker.ProjectPickerRow) row).project;
            return search_entry.text.down () in project.name.down ();
        });
    }

    private void add_projects () {
        foreach (Objects.Project project in Services.Store.instance ().projects) {
            listbox.append (build_project_row (project));
        }
    }

    private Gtk.Widget build_project_row (Objects.Project project) {
        var row = new Widgets.ProjectPicker.ProjectPickerRow (project);

        row.selected.connect (() => {
            selected (row.project);
            popdown ();
        });

        return row;
    }

    private int sort_source_function (Gtk.ListBoxRow row1, Gtk.ListBoxRow? row2) {
        var project1 = ((Widgets.ProjectPicker.ProjectPickerRow) row1).project;
        var project2 = ((Widgets.ProjectPicker.ProjectPickerRow) row2).project;
        return project2.source.id.collate (project1.source.id);
    }

    private void header_project_function (Gtk.ListBoxRow lbrow, Gtk.ListBoxRow? lbbefore) {
        if (!(lbrow is Widgets.ProjectPicker.ProjectPickerRow)) {
            return;
        }

        var row = (Widgets.ProjectPicker.ProjectPickerRow) lbrow;
        if (lbbefore != null && lbbefore is Widgets.ProjectPicker.ProjectPickerRow) {
            var before = (Widgets.ProjectPicker.ProjectPickerRow) lbbefore;

            if (row.project.source.id == before.project.source.id) {
                row.set_header (null);
                return;
            }
        }

        row.set_header (get_header_box (row.project.source.header_text));   

    }

    private Gtk.Widget get_header_box (string title) {
        var header_label = new Gtk.Label (title) {
            css_classes = { "heading" },
            halign = START,
            margin_start = 3
        };

        var header_separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
            hexpand = true,
            margin_bottom = 6,
            margin_start = 3
        };

        var header_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
            margin_top = 12,
            margin_start = 3
        };

        header_box.append (header_label);
        header_box.append (header_separator);

        return header_box;
    }
}
