public class Widgets.Popovers.QuickSearchPopover : Gtk.Popover {
    public QuickSearchPopover (Gtk.Widget relative) {
        Object (
            relative_to: relative,
            modal: false,
            position: Gtk.PositionType.BOTTOM
        );
    }

    construct {
        var main_grid = new Gtk.Grid ();
        main_grid.expand = true;
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.width_request = 250;
        main_grid.height_request = 250;

        add (main_grid);
    }
}
