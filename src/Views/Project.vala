public class Views.Project : Gtk.EventBox {
    public Objects.Project project { get; construct; }

    private Views.List? list_view;
    private Views.Board? board_view;
    private Gtk.Stack view_stack;

    public Project (Objects.Project project) {
        Object (
            project: project
        );
    }

    construct {
        var magic_button = new Widgets.MagicButton ();

        view_stack = new Gtk.Stack ();

        var main_content = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            expand = true
        };

        main_content.add (view_stack);

        var overlay = new Gtk.Overlay () {
            expand = true
        };
        overlay.add_overlay (magic_button);
        overlay.add (main_content);

        add (overlay);
        update_project_view (ProjectViewStyle.LIST);
        show_all ();

        magic_button.clicked.connect (() => {
            list_view.prepare_new_item ();
        });
    }

    private void update_project_view (ProjectViewStyle view_style) {
        if (view_style == ProjectViewStyle.LIST) {
            list_view = (Views.List) view_stack.get_child_by_name (view_style.to_string ());
            if (list_view == null) {
                list_view = new Views.List (project);
                view_stack.add_named (list_view, view_style.to_string ());
            }
        } else if (view_style == ProjectViewStyle.BOARD) {
            board_view = (Views.Board) view_stack.get_child_by_name (view_style.to_string ());
            if (board_view == null) {
                board_view = new Views.Board (project);
                view_stack.add_named (board_view, view_style.to_string ());
            }
        }

        view_stack.set_visible_child_name (view_style.to_string ());
    }

    public void prepare_new_item (string content = "") {
        // TODO: Valid View
        if (list_view != null) {
            list_view.prepare_new_item (content);
        }
    }
}
