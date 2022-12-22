public class Views.List : Gtk.Grid {
    public Objects.Project project { get; construct; }

    private Gtk.ListBox listbox;
    private Layouts.SectionRow inbox_section;
    private Gtk.Stack listbox_placeholder_stack;
    private Gtk.ScrolledWindow scrolled_window;

    public bool has_children {
        get {
            return (Util.get_default ().get_children (listbox).length () - 1) > 0;
        }
    }

    public Gee.HashMap <string, Layouts.SectionRow> sections_map;

    public List (Objects.Project project) {
        Object (
            project: project
        );
    }

    construct {
        sections_map = new Gee.HashMap <string, Layouts.SectionRow> ();

        var top_project = new Widgets.HeaderProject (project) {
            margin_start = 24,
            margin_top = 24,
            margin_end = 16
        };

        listbox = new Gtk.ListBox () {
            valign = Gtk.Align.START,
            selection_mode = Gtk.SelectionMode.NONE,
            hexpand = true,
            vexpand = true
        };

        listbox.add_css_class ("listbox-background");

        var listbox_grid = new Gtk.Grid ();
        listbox_grid.attach (listbox, 0, 0);

        var placeholder = new Widgets.Placeholder (
            project.name,
            _("What will you accomplish?"),
            "planner-emoji-happy");

        listbox_placeholder_stack = new Gtk.Stack () {
            vexpand = true,
            hexpand = true,
            margin_end = 24,
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };

        listbox_placeholder_stack.add_named (listbox_grid, "listbox");
        listbox_placeholder_stack.add_named (placeholder, "placeholder");

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            hexpand = true,
            vexpand = true
        };

        content_box.append (top_project);
        content_box.append (listbox_placeholder_stack);

        var content_clamp = new Adw.Clamp () {
            maximum_size = 720
        };

        content_clamp.child = content_box;

        scrolled_window = new Gtk.ScrolledWindow () {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            hexpand = true,
            vexpand = true
        };
        scrolled_window.child = content_clamp;

        attach (scrolled_window, 0, 0);
        add_sections ();
        show ();

        Timeout.add (listbox_placeholder_stack.transition_duration, () => {
            set_sort_func ();
            return GLib.Source.REMOVE;
        });


        project.section_added.connect ((section) => {
            add_section (section);
            if (section.activate_name_editable) {
                Timeout.add (listbox_placeholder_stack.transition_duration, () => {
                    scrolled_window.vadjustment.set_value (
                        scrolled_window.vadjustment.get_upper () - scrolled_window.vadjustment.get_page_size ()
                    );
                    return GLib.Source.REMOVE;
                });
            }
        });

        scrolled_window.vadjustment.value_changed.connect (() => {
            if (scrolled_window.vadjustment.value > 50) {
                Planner.event_bus.view_header (true);
            } else {
                Planner.event_bus.view_header (false);
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

    private void set_sort_func () {
        listbox.set_sort_func ((row1, row2) => {
            Objects.Section item1 = ((Layouts.SectionRow) row1).section;
            Objects.Section item2 = ((Layouts.SectionRow) row2).section;

            return item1.section_order - item2.section_order;
        });

        listbox.set_sort_func (null);
    }

    private void update_projects_position () {
        //  Timeout.add (listbox_placeholder_stack.transition_duration, () => {
        //      GLib.List<weak Gtk.Widget> sections = listbox.get_children ();
        //      for (int index = 1; index < sections.length (); index++) {
        //          Objects.Section section = ((Layouts.SectionRow) sections.nth_data (index)).section;
        //          section.section_order = index;
        //          Services.Database.get_default ().update_child_order (section);
        //      }

        //      return GLib.Source.REMOVE;
        //  });
    }

    private void add_sections () {
        for (Gtk.Widget child = listbox.get_first_child (); child != null; child = listbox.get_next_sibling ()) {
            child.destroy ();
        }

        add_inbox_section ();
        foreach (Objects.Section section in project.sections) {
            add_section (section);
        }
    }

    private void add_inbox_section () {
        inbox_section = new Layouts.SectionRow.for_project (project);
        listbox.append (inbox_section);
    }

    private void add_section (Objects.Section section) {
        sections_map [section.id_string] = new Layouts.SectionRow (section);
        listbox.append (sections_map [section.id_string]);
    }

    public void prepare_new_item (string content = "") {
        inbox_section.prepare_new_item (content);
        Timeout.add (225, () => {
            scrolled_window.vadjustment.value = 0;
            return GLib.Source.REMOVE;
        });
    }

    public bool validate_children () {
        foreach (unowned Gtk.Widget child in Util.get_default ().get_children (listbox)) {
            if (((Layouts.SectionRow) child).has_children) {
                return true;
            }
        }

        return has_children;
    }
}