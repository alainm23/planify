public class Widgets.Popovers.NotificationsPopover : Gtk.Popover {
    public NotificationsPopover (Gtk.Widget relative) {
        Object (
            relative_to: relative,
            modal: true,
            position: Gtk.PositionType.BOTTOM
        );
    }

    construct {
        //get_style_context ().add_class ("planner-popover");

        var main_grid = new Gtk.Grid ();
        main_grid.expand = true;
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.width_request = 250;

        add (main_grid);
    }
}
