public class Widgets.ProjectPicker.ProjectPickerButton : Adw.Bin {
    private Objects.Project _project;
    public Objects.Project project {
        set {
            _project = value;
            update_project_request ();
            add_sections (project);
        }

        get {
            return _project;
        }
    }

    private Objects.Section _section;
    public Objects.Section section {
        set {
            _section = value;
            section_label.label = _section.name;
        }
    }

    private Widgets.IconColorProject icon_project;
    private Gtk.Label name_label;
    private Gtk.Label section_label;
    private Layouts.HeaderItem sections_group;
    private Gtk.Popover sections_popover;
    private Gtk.Revealer section_box_revealer;
    
    public signal void project_change (Objects.Project project);
    public signal void section_change (Objects.Section? section);

    public Gee.HashMap <string, Gtk.ListBoxRow> sections_map = new Gee.HashMap <string, Gtk.ListBoxRow> ();

    construct {
        //  Project Button
        icon_project = new Widgets.IconColorProject (10);

        name_label = new Gtk.Label (null) {
            valign = Gtk.Align.CENTER,
            ellipsize = Pango.EllipsizeMode.END
        };

        var project_box = new Gtk.Box (HORIZONTAL, 6) {
            valign = CENTER
        };
        project_box.append (icon_project);
        project_box.append (name_label);

        var project_picker_popover = new Widgets.ProjectPicker.ProjectPickerPopover ();

        var project_button = new Gtk.MenuButton () {
            popover = project_picker_popover,
            child = project_box,
            css_classes = { "flat" }
        };

        // Section Button
        section_label = new Gtk.Label (_("No Section")) {
            valign = Gtk.Align.CENTER,
            ellipsize = Pango.EllipsizeMode.END,
            max_width_chars = 16
        };

        sections_popover = build_sections_popover ();

        var arrow_label = new Gtk.Label ("→"); 

        var section_button = new Gtk.MenuButton () {
            popover = sections_popover,
            child = section_label,
            css_classes = { "flat" }
        };

        var section_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        section_box.append (arrow_label);
        section_box.append (section_button);

        section_box_revealer = new Gtk.Revealer () {
			transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT,
            reveal_child = true,
			child = section_box
		};

        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        box.append (project_button);
        box.append (section_box_revealer);

        child = box;

        project_picker_popover.selected.connect ((_project) => {
            project = _project;
            update_project_request ();
            add_sections (project);
            project_change (_project);
        });
    }

    public void update_project_request () {
        name_label.label = project.is_inbox_project ? _("Inbox") : project.name;
        icon_project.project = project;
        icon_project.update_request ();
        section_box_revealer.reveal_child = project.source_type != SourceType.CALDAV;
    }

    private Gtk.Popover build_sections_popover () {
        sections_group = new Layouts.HeaderItem (null) {
            reveal_child = true
        };

        var popover = new Gtk.Popover () {
			has_arrow = false,
			position = Gtk.PositionType.BOTTOM,
			child = sections_group,
			width_request = 250
		};

        return popover;
    }

    private void add_sections (Objects.Project project) {
        sections_group.clear ();

        sections_group.add_child (get_section_row (null));
        foreach (Objects.Section section in project.sections) {
            sections_group.add_child (get_section_row (section));
        }
    }

    private Gtk.ListBoxRow get_section_row (Objects.Section? section) {
        var button = new Widgets.ContextMenu.MenuItem (section != null ? section.name : _("No Section")) {
            max_width_chars = 16
        };

        var row = new Gtk.ListBoxRow () {
            css_classes = { "row" },
            child = button
        };

        button.clicked.connect (() => {
            sections_popover.popdown ();
            section_label.label = section != null ? section.name : _("No Section");
            section_change (section);
        });

        return row;
    }
}
