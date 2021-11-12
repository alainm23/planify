public class Views.Project : Gtk.EventBox {
    public Objects.Project project { get; construct; }

    public Project (Objects.Project project) {
        Object (
            project: project
        );
    }

    construct {
        var top_project = new Widgets.TopHeaderProject (project);

        var note_hypertextview = new Granite.HyperTextView () {
            hexpand = true,
            margin_top = 6,
            margin_start = 27,
            margin_end = 24,
            wrap_mode = Gtk.WrapMode.WORD_CHAR
        };

        var main_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            expand = true
        };
        main_grid.add (top_project);
        main_grid.add (note_hypertextview);

        var clamp = new Hdy.Clamp () {
            maximum_size = 1200,
            tightening_threshold = 0,
        };
        clamp.add (main_grid);

        add (clamp);

        show_all ();
    }
}