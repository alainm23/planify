public class Views.Main : Gtk.Paned {
    public Widgets.ProjectsList projects_list;
    private Gtk.Stack stack;

    private Views.Inbox inbox_view;
    private Views.Today today_view;
    private Views.Tomorrow tomorrow_view;

    public Main () {
        Object (
            orientation: Gtk.Orientation.HORIZONTAL,
            position: Planner.settings.get_int ("project-sidebar-width")
        );
    }

    construct {
        get_style_context ().add_class ("view");
        projects_list = new Widgets.ProjectsList ();

        inbox_view = new Views.Inbox ();
        today_view = new Views.Today ();
        tomorrow_view = new Views.Tomorrow ();

        stack = new Gtk.Stack ();
        stack.expand = true;
        stack.transition_type = Gtk.StackTransitionType.SLIDE_UP_DOWN;
        stack.add_named (inbox_view, "inbox_view");
        stack.add_named (today_view, "today_view");
        stack.add_named (tomorrow_view, "tomorrow_view");
        stack.visible_child_name = "today_view";

        pack1 (projects_list, false, false);
        pack2 (stack, true, true);

        projects_list.on_selected_item.connect ((type, index) => {
            if (type == "item") {
                if (index == 0) {
                    stack.visible_child_name = "inbox_view";
                } else if (index == 1) {
                    stack.visible_child_name = "today_view";
                } else {
                    stack.visible_child_name = "tomorrow_view";
                }
            }
        });
    }
}
