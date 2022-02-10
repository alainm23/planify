public class Views.List : Gtk.EventBox {
    public Objects.Project project { get; construct; }

    private Gtk.ListBox listbox;
    private Layouts.SectionRow inbox_section;
    private Gtk.Stack listbox_placeholder_stack;

    public bool has_children {
        get {
            return (listbox.get_children ().length () - 1) > 0;
        }
    }

    public List (Objects.Project project) {
        Object (
            project: project
        );
    }

    construct {
        var top_project = new Widgets.TopHeaderProject (project);

        listbox = new Gtk.ListBox () {
            valign = Gtk.Align.START,
            activate_on_single_click = true,
            selection_mode = Gtk.SelectionMode.SINGLE,
            expand = true
        };

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
            margin = 36,
            margin_top = 6
        };
        content.add (top_project);
        content.add (listbox_placeholder_stack);

        var content_clamp = new Hdy.Clamp () {
            maximum_size = 720
        };

        content_clamp.add (content);

        var scrolled_window = new Gtk.ScrolledWindow (null, null) {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            expand = true
        };
        scrolled_window.add (content_clamp);

        add (scrolled_window);
        add_sections ();

        Timeout.add (listbox_placeholder_stack.transition_duration, () => {
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
        });

        listbox.remove.connect (() => {
            children_size_changed (); 
        });

        scrolled_window.vadjustment.value_changed.connect (() => {
            if (scrolled_window.vadjustment.value > 20) {
                Planner.event_bus.view_header (true);
            } else {
                Planner.event_bus.view_header (false);
            }
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
        listbox.show_all ();
    }
    
    public void prepare_new_item (string content = "") {
        inbox_section.prepare_new_item (content);
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
}
