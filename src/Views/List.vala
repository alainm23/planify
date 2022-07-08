public class Views.List : Gtk.EventBox {
    public Objects.Project project { get; construct; }

    private Gtk.ListBox listbox;
    private Layouts.SectionRow inbox_section;
    private Gtk.Stack listbox_placeholder_stack;
    private Gtk.ScrolledWindow scrolled_window;

    public bool has_children {
        get {
            return (listbox.get_children ().length () - 1) > 0;
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

        var top_project = new Widgets.TopHeaderProject (project) {
            margin_start = 20
        };

        listbox = new Gtk.ListBox () {
            valign = Gtk.Align.START,
            activate_on_single_click = true,
            selection_mode = Gtk.SelectionMode.SINGLE,
            expand = true
        };

        Gtk.drag_dest_set (listbox, Gtk.DestDefaults.ALL, Util.get_default ().SECTIONROW_TARGET_ENTRIES, Gdk.DragAction.MOVE);
        listbox.drag_data_received.connect (on_drag_section_received);

        unowned Gtk.StyleContext listbox_context = listbox.get_style_context ();
        listbox_context.add_class ("listbox-background");
        listbox_context.add_class ("listbox-separator-12");
        
        var listbox_grid = new Gtk.Grid ();
        listbox_grid.add (listbox);

        var placeholder = new Widgets.Placeholder (
            project.name,
            _("What will you accomplish?"),
            "planner-emoji-happy");
        
        listbox_placeholder_stack = new Gtk.Stack () {
            expand = true,
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };

        listbox_placeholder_stack.add_named (listbox_grid, "listbox");
        listbox_placeholder_stack.add_named (placeholder, "placeholder");

        var content = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            expand = true,
            margin_top = 36,
            margin_end = 36,
            margin_start = 16,
            margin_bottom = 24,
            margin_top = 6
        };
        content.add (top_project);
        content.add (listbox_placeholder_stack);

        var content_clamp = new Hdy.Clamp () {
            maximum_size = 720
        };

        content_clamp.add (content);

        scrolled_window = new Gtk.ScrolledWindow (null, null) {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            expand = true
        };
        scrolled_window.add (content_clamp);

        add (scrolled_window);
        add_sections ();
        show_all ();
        
        Timeout.add (listbox_placeholder_stack.transition_duration, () => {
            set_sort_func ();
            children_size_changed ();
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

        listbox.add.connect (() => {
            children_size_changed ();
            update_projects_position ();
        });

        listbox.remove.connect (() => {
            children_size_changed ();
            update_projects_position ();
        });

        scrolled_window.vadjustment.value_changed.connect (() => {
            if (scrolled_window.vadjustment.value > 20) {
                Planner.event_bus.view_header (true);
            } else {
                Planner.event_bus.view_header (false);
            }
        });

        Planner.database.section_moved.connect ((section, old_project_id) => {
            if (project.id == old_project_id && sections_map.has_key (section.id_string)) {
                    sections_map [section.id_string].hide_destroy ();
                    sections_map.unset (section.id_string);
            }

            if (project.id == section.project_id &&
                !sections_map.has_key (section.id_string)) {
                    add_section (section);
            }
        });

        Planner.database.section_deleted.connect ((section) => {
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
        Timeout.add (listbox_placeholder_stack.transition_duration, () => {
            GLib.List<weak Gtk.Widget> sections = listbox.get_children ();
            for (int index = 1; index < sections.length (); index++) {
                Objects.Section section = ((Layouts.SectionRow) sections.nth_data (index)).section;
                section.section_order = index;
                Planner.database.update_child_order (section);
            }

            return GLib.Source.REMOVE;
        });
    }

    public void add_sections () {
        foreach (unowned Gtk.Widget child in listbox.get_children ()) {
            child.destroy ();
        }

        add_inbox_section ();
        foreach (Objects.Section section in project.sections) {
            add_section (section);
        }
    }

    private void add_inbox_section () {
        inbox_section = new Layouts.SectionRow.for_project (project);
        inbox_section.children_size_changed.connect (() => {
            children_size_changed (); 
        });
        listbox.add (inbox_section);
    }

    private void add_section (Objects.Section section) {
        var row = new Layouts.SectionRow (section);
        
        row.children_size_changed.connect (() => {
            children_size_changed (); 
        });

        listbox.add (row);
        sections_map [section.id_string] = row;
        listbox.show_all ();
    }
    
    public void prepare_new_item (string content = "") {
        inbox_section.prepare_new_item (content);
        Timeout.add (225, () => {
            scrolled_window.vadjustment.value = 0;
            return GLib.Source.REMOVE;
        });
    }

    public bool validate_children () {
        foreach (unowned Gtk.Widget child in listbox.get_children ()) {
            if (((Layouts.SectionRow) child).has_children) {
                return true;
            }
        }

        return has_children;
    }

    private void children_size_changed () {
        listbox_placeholder_stack.visible_child_name = validate_children () ? "listbox" : "placeholder";
    }

    private void on_drag_section_received (Gdk.DragContext context, int x, int y,
        Gtk.SelectionData selection_data, uint target_type, uint time) {
        Layouts.SectionRow target;
        Layouts.SectionRow source;
        Gtk.Allocation alloc;

        target = (Layouts.SectionRow) listbox.get_row_at_y (y);
        target.get_allocation (out alloc);

        var row = ((Gtk.Widget[]) selection_data.get_data ()) [0];
        source = (Layouts.SectionRow) row;
        
        if (target != null) {
            source.get_parent ().remove (source);

            if (target.get_index () == 1 && y < (alloc.height / 2)) {
                listbox.insert (source, target.get_index ());
            } else {
                listbox.insert (source, target.get_index () + 1);
            }
            
            listbox.show_all ();
        }
    }
}
