public class Dialogs.ContextMenu.Menu : Hdy.Window {
    private Gtk.Grid content_grid;

    public Menu () {
        Object (
            transient_for: (Gtk.Window) PlannerQuickAdd.instance.main_window.get_toplevel (),
            destroy_with_parent: true,
            window_position: Gtk.WindowPosition.MOUSE,
            resizable: false,
            width_request: 296
        );
    }

    construct {
        content_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL
        };

        unowned Gtk.StyleContext content_grid_context = content_grid.get_style_context ();
        content_grid_context.add_class ("view");
        content_grid_context.add_class ("menu");

        add (content_grid);

        focus_out_event.connect (() => {
            hide_destroy ();
            return false;
        });

         key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                hide_destroy ();
            }

            return false;
        });
    }

    public void hide_destroy () {
        hide ();

        Timeout.add (500, () => {
            destroy ();
            return GLib.Source.REMOVE;
        });
    }

    public void add_item (Gtk.Widget widget) {
        content_grid.add (widget);
        content_grid.show_all ();
    }

    public void popup () {
        show_all ();
    }
}
