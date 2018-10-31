public class Widgets.Popovers.ProjectMenu : Gtk.Popover {
    public signal void on_selected_menu (int index);

    public ProjectMenu (Gtk.Widget relative) {
        Object (
            relative_to: relative,
            modal: true,
            position: Gtk.PositionType.BOTTOM
        );
    }

    construct {
        var finalize_menu = new Widgets.ModelButton (_("Finalize"), "emblem-default-symbolic", _("Finalize project"));
        var edit_menu = new Widgets.ModelButton (_("Edit"), "edit-symbolic", _("Change project name"));

        var favorite_menu = new Widgets.ModelButton (_("Favorite"), "emblem-favorite-symbolic", _("Favorite"));

        var remove_menu = new Widgets.ModelButton (_("Remove"), "user-trash-symbolic", _("Remove project"));
        var share_menu = new Widgets.ModelButton (_("Share"), "emblem-shared-symbolic", _("Share project"));

        var separator_1 = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator_1.expand = true;

        var main_grid = new Gtk.Grid ();
        main_grid.margin_top = 6;
        main_grid.margin_bottom = 6;
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.width_request = 200;

        main_grid.add (finalize_menu);
        main_grid.add (edit_menu);
        main_grid.add (favorite_menu);
        main_grid.add (separator_1);
        main_grid.add (share_menu);
        main_grid.add (remove_menu);

        add (main_grid);

        // Event
        edit_menu.clicked.connect (() => {
            popdown ();
            on_selected_menu (2);
        });

        remove_menu.clicked.connect (() => {
            popdown ();
            on_selected_menu (4);
        });
    }
}
