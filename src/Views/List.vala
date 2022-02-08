public class Views.List : Gtk.EventBox {
    public Objects.Project project { get; construct; }

    private Gtk.ListBox listbox;
    private Layouts.SectionRow inbox_section;

    public signal void children_size_changed ();

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

        var main_grid = new Gtk.Grid () {
            expand = true
        };
        main_grid.add (listbox_grid);

        add (main_grid);
        add_sections ();

        project.section_added.connect ((section) => {
            add_section (section);
        });

        listbox.add.connect (() => {
            children_size_changed (); 
        });

        listbox.remove.connect (() => {
            children_size_changed (); 
        });
    }

    public void add_sections () {
        foreach (unowned Gtk.Widget child in listbox.get_children ()) {
            child.destroy ();
        }

        inbox_section = new Layouts.SectionRow.for_project (project);
        inbox_section.children_size_changed.connect (() => {
            children_size_changed (); 
        });
        listbox.add (inbox_section);
        foreach (Objects.Section section in project.sections) {
            add_section (section);
        }
    }

    private void add_section (Objects.Section section) {
        var row = new Layouts.SectionRow (section);
        row.children_size_changed.connect (() => {
            children_size_changed (); 
        });
        listbox.add (row);
        listbox.show_all ();
    }
    
    public void prepare_new_item () {
        inbox_section.prepare_new_item ();
    }

    public bool validate_placeholder () {
        foreach (unowned Gtk.Widget child in listbox.get_children ()) {
            if (((Layouts.SectionRow) child).has_children) {
                return true;
            }
        }

        return has_children;
    }
}
