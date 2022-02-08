public class Views.Project : Gtk.EventBox {
    public Objects.Project project { get; construct; }

    private Views.List list_view;
    private Gtk.Stack listbox_stack;

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

        var listbox_placeholder = new Widgets.Placeholder (
            project.name,
            _("What will you accomplish?"),
            "planner-emoji-happy");

        listbox_stack = new Gtk.Stack () {
            expand = true,
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };

        listbox_stack.add_named (list_view, "listbox");
        listbox_stack.add_named (listbox_placeholder, "placeholder");

        var content = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            expand = true,
            margin_start = 36,
            margin_end = 36,
            margin_bottom = 36,
            margin_top = 6
        };
        content.add (top_project);
        content.add (listbox_stack);

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

        Timeout.add (listbox_stack.transition_duration, () => {
            validate_placeholder ();
            return GLib.Source.REMOVE;
        });

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

        list_view.children_size_changed.connect (validate_placeholder);
    }

    private void validate_placeholder () {
        listbox_stack.visible_child_name = list_view.validate_placeholder () ? "listbox" : "placeholder";
    }
}
