public class Widgets.Popovers.DeadlinePopover : Gtk.Popover {
    private int item_selected = 0;
    public DeadlinePopover (Gtk.Widget relative) {
        Object (
            relative_to: relative,
            modal: true,
            position: Gtk.PositionType.RIGHT
        );
    }

    construct {
        var title_label = new Gtk.Label ("<small>%s</small>".printf (_("Deadline")));
        title_label.use_markup = true;
        title_label.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);

        var calendar = new Gtk.Calendar ();
        calendar.get_style_context ().add_class ("menuitem");
        calendar.get_style_context ().add_class ("calendar-no-selected");
        calendar.expand = true;
        calendar.mark_day (new GLib.DateTime.now_local ().get_day_of_month ());

        var main_grid = new Gtk.Grid ();
        main_grid.expand = true;
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.width_request = 250;

        main_grid.add (title_label);
        main_grid.add (calendar);

        add (main_grid);
    }
}
