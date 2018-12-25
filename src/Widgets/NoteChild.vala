public class Widgets.NoteChild : Gtk.FlowBoxChild {
    private Gtk.SourceView source_view;

    public NoteChild () {
        /*
        Object (
            label: _label
        );
        */
    }

    construct {
        can_focus = false;

        source_view = new Gtk.SourceView ();
        source_view.margin = 6;
        source_view.expand = true;

        var main_grid = new Gtk.Grid ();
        main_grid.get_style_context ().add_class (Granite.STYLE_CLASS_CARD);
        main_grid.expand = true;
        main_grid.add (source_view);

        add (main_grid);
    }
}
