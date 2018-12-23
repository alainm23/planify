public class Widgets.Popovers.TaskMenu : Gtk.Popover {
    public signal void on_selected_menu (int index);

    public TaskMenu (Gtk.Widget relative) {
        Object (
            relative_to: relative,
            modal: true,
            position: Gtk.PositionType.TOP
        );
    }

    construct {
        var convert_menu = new Widgets.ModelButton (_("Convert"), "planner-startup-symbolic", _("Convert to Project"));
        var duplicate_menu = new Widgets.ModelButton (_("Duplicate"), "edit-copy-symbolic", _("Duplicate task"));
        var share_menu = new Widgets.ModelButton (_("Share"), "emblem-shared-symbolic", _("Share task"));

        var separator_1 = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator_1.margin_top = 3;
        separator_1.margin_bottom = 3;
        separator_1.expand = true;

        var main_grid = new Gtk.Grid ();
        main_grid.margin_top = 6;
        main_grid.margin_bottom = 6;
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.width_request = 200;

        //main_grid.add (convert_menu);
        main_grid.add (duplicate_menu);
        main_grid.add (separator_1);
        main_grid.add (share_menu);

        add (main_grid);

        // Event
        convert_menu.clicked.connect (() => {
            popdown ();
            on_selected_menu (0);
        });

        duplicate_menu.clicked.connect (() => {
            popdown ();
            on_selected_menu (1);
        });

        share_menu.clicked.connect (() => {
            popdown ();
            on_selected_menu (2);
        });
    }
}
