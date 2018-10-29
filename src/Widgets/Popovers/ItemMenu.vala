public class Widgets.Popovers.ItemMenu : Gtk.Popover {
    public signal void on_selected_menu (int index);

    public ItemMenu (Gtk.Widget relative) {
        Object (
            relative_to: relative,
            modal: true,
            position: Gtk.PositionType.BOTTOM
        );
    }

    construct {
        var filter_menu = new Widgets.ModelButton (_("Filter by labels"), "tag-symbolic", _("Filter by labels"));
        var paste_menu = new Widgets.ModelButton (_("Paste"), "edit-copy-symbolic", _("Paste"));
        var share_menu = new Widgets.ModelButton (_("Share"), "emblem-shared-symbolic", _("Share"));

        var main_grid = new Gtk.Grid ();
        main_grid.margin_top = 6;
        main_grid.margin_bottom = 6;
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.width_request = 200;

        main_grid.add (filter_menu);
        main_grid.add (paste_menu);
        main_grid.add (share_menu);

        add (main_grid);

        // Event
        filter_menu.clicked.connect (() => {
            popdown ();
            on_selected_menu (0);
        });

        paste_menu.clicked.connect (() => {
            popdown ();
            on_selected_menu (1);
        });

        share_menu.clicked.connect (() => {
            popdown ();
            on_selected_menu (2);
        });
    }
}
