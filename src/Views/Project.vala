public class Views.Project : Gtk.EventBox {
    public Objects.Project project { get; construct; }

    private Views.List list_view;

    public Project (Objects.Project project) {
        Object (
            project: project
        );
    }

    construct {
        var top_project = new Widgets.TopHeaderProject (project);
        var magic_button = new Widgets.MagicButton ();

        list_view = new Views.List (project) {
            margin_top = 0
        };

        var content = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            expand = true,
            margin_start = 36,
            margin_end = 36,
            margin_bottom = 36,
            margin_top = 6
        };
        content.add (top_project);
        content.add (list_view);

        var content_clamp = new Hdy.Clamp () {
            maximum_size = 720
        };

        content_clamp.add (content);

        var scrolled_window = new Gtk.ScrolledWindow (null, null) {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            expand = true
        };
        scrolled_window.add (content_clamp);

        var overlay = new Gtk.Overlay () {
            expand = true
        };
        overlay.add_overlay (magic_button);
        overlay.add (scrolled_window);

        add (overlay);
        show_all ();

        scrolled_window.vadjustment.value_changed.connect (() => {
            if (scrolled_window.vadjustment.value > 20) {
                Planner.event_bus.view_header (true);
            } else {
                Planner.event_bus.view_header (false);
            }
        });

        magic_button.clicked.connect (() => {
            list_view.prepare_new_item ();
        });
    }
}
