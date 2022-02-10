public class Views.Board : Gtk.EventBox {
    public Objects.Project project { get; construct; }

    private Gtk.FlowBox flowbox;

    public Board (Objects.Project project) {
        Object (
            project: project
        );
    }

    construct {
        var top_project = new Widgets.TopHeaderProject (project) {
            margin = 36,
            margin_bottom = 0,
            margin_top = 6
        };

        flowbox = new Gtk.FlowBox () {
            expand = true,
            max_children_per_line = 1,
            homogeneous = true,
            orientation = Gtk.Orientation.VERTICAL
        };

        var flowbox_grid = new Gtk.Grid () {
            margin = 36,
            margin_top = 12,
            margin_bottom = 0
        };

        flowbox_grid.add (flowbox);

        var flowbox_scrolled = new Gtk.ScrolledWindow (null, null) {
            vscrollbar_policy = Gtk.PolicyType.NEVER,
            expand = true
        };
        flowbox_scrolled.add (flowbox_grid);

        var main_content = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            expand = true
        };
        main_content.add (top_project);
        main_content.add (flowbox_scrolled);

        add (main_content);
        add_sections ();
    }

    public void add_sections () {
        foreach (unowned Gtk.Widget child in flowbox.get_children ()) {
            child.destroy ();
        }

        foreach (Objects.Section section in project.sections) {
            add_section (section);
        }
    }

    private void add_section (Objects.Section section) {
        var row = new Layouts.SectionChild (section);
        flowbox.add (row);
        flowbox.show_all ();
    }
}