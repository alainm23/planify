
public class Views.Project : Gtk.Grid {
    public Objects.Project project { get; construct; }

    private Gtk.Stack view_stack;

    public Project (Objects.Project project) {
        Object (
            project: project
        );
    }

    construct {
        var magic_button = new Widgets.MagicButton ();

        view_stack = new Gtk.Stack () {
            hexpand = true,
            vexpand = true,
            transition_type = Gtk.StackTransitionType.SLIDE_RIGHT
        };

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            hexpand = true,
            vexpand = true
        };

        content_box.append (view_stack);

        var content_overlay = new Gtk.Overlay () {
            hexpand = true,
            vexpand = true
        };
        
        content_overlay.add_overlay (magic_button);
        content_overlay.child = content_box;

        attach(content_overlay, 0, 0);
        update_project_view (ProjectViewStyle.LIST);
        show();

        magic_button.clicked.connect (() => {
            prepare_new_item ();
        });
    }
    
    private void update_project_view (ProjectViewStyle view_style) {
        if (view_style == ProjectViewStyle.LIST) {
            Views.List? list_view;
            list_view = (Views.List) view_stack.get_child_by_name (view_style.to_string ());
            if (list_view == null) {
                list_view = new Views.List (project);
                view_stack.add_named (list_view, view_style.to_string ());
            }
        } else if (view_style == ProjectViewStyle.BOARD) {
            //  Views.Board? board_view;
            //  board_view = (Views.Board) view_stack.get_child_by_name (view_style.to_string ());
            //  if (board_view == null) {
            //      board_view = new Views.Board (project);
            //      view_stack.add_named (board_view, view_style.to_string ());
            //  }
        }

        view_stack.set_visible_child_name (view_style.to_string ());
    }

    public void prepare_new_item (string content = "") {
        if (project.view_style == ProjectViewStyle.LIST) {
            Views.List? list_view;
            list_view = (Views.List) view_stack.get_child_by_name (project.view_style.to_string ());
            if (list_view != null) {
                list_view.prepare_new_item (content);
            }
        } else {
            //  Views.Board? board_view;
            //  board_view = (Views.Board) view_stack.get_child_by_name (project.view_style.to_string ());
            //  if (board_view != null) {
                
            //  }
        }
    }
}