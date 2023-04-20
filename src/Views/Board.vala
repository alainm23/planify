public class Views.Board : Gtk.Grid {
    public Objects.Project project { get; construct; }

    private Layouts.SectionBoard inbox_board;
    private Gtk.FlowBox flowbox;

    public Gee.HashMap <string, Layouts.SectionBoard> sections_map;

    public Board (Objects.Project project) {
        Object (
            project: project
        );
    }

    construct {
        sections_map = new Gee.HashMap <string, Layouts.SectionBoard> ();

        flowbox = new Gtk.FlowBox () {
            vexpand = true,
            max_children_per_line = 1,
            homogeneous = true,
            orientation = Gtk.Orientation.VERTICAL,
            column_spacing = 24,
            halign = Gtk.Align.START
        };

        var flowbox_grid = new Gtk.Grid () {
            vexpand = true,
            margin_top = 12,
            margin_start = 6,
            margin_end = 6,
            margin_bottom = 12,
            halign = Gtk.Align.START
        };

        flowbox_grid.attach (flowbox, 0, 0);

        var flowbox_scrolled = new Gtk.ScrolledWindow () {
            vscrollbar_policy = Gtk.PolicyType.NEVER,
            hexpand = true,
            vexpand = true,
            child = flowbox_grid
        };

        attach (flowbox_scrolled, 0, 0);
        add_sections ();

        project.section_added.connect ((section) => {
            add_section (section);

            if (section.activate_name_editable) {
                Timeout.add (175, () => {
                    flowbox_scrolled.hadjustment.set_value (
                        flowbox_scrolled.hadjustment.get_upper () - flowbox_scrolled.hadjustment.get_page_size ()
                    );
                    return GLib.Source.REMOVE;
                });
            }
        });

        Services.Database.get_default ().section_moved.connect ((section, old_project_id) => {
            if (project.id == old_project_id && sections_map.has_key (section.id_string)) {
                    sections_map [section.id_string].hide_destroy ();
                    sections_map.unset (section.id_string);
            }

            if (project.id == section.project_id &&
                !sections_map.has_key (section.id_string)) {
                    add_section (section);
            }
        });

        Services.Database.get_default ().section_deleted.connect ((section) => {
            if (sections_map.has_key (section.id_string)) {
                sections_map [section.id_string].hide_destroy ();
                sections_map.unset (section.id_string);
            }
        });
    }
    
    public void add_sections () {
        add_inbox_section ();
        foreach (Objects.Section section in project.sections) {
            add_section (section);
        }
    }

    private void add_inbox_section () {
        inbox_board = new Layouts.SectionBoard.for_project (project);
        flowbox.append (inbox_board);
    }

    private void add_section (Objects.Section section) {
        if (!sections_map.has_key (section.id)) {
            sections_map[section.id] = new Layouts.SectionBoard (section);
            flowbox.append (sections_map[section.id]);
        }
    }
}