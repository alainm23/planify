public class Widgets.Popovers.DeadlinePopover : Gtk.Popover {
    public Gtk.Button remove_button;

    public signal void on_selected_date (GLib.DateTime deadline);
    public signal void on_selected_remove ();
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
        calendar.get_style_context ().remove_class ("calendar-no-selected");
        calendar.expand = true;
        calendar.mark_day (new GLib.DateTime.now_local ().get_day_of_month ());

        remove_button = new Gtk.Button.with_label (_("Remove"));
        remove_button.margin_start = 12;
        remove_button.margin_end = 12;
        remove_button.margin_bottom = 6;
        remove_button.no_show_all = true;
        remove_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);

        var main_grid = new Gtk.Grid ();
        main_grid.expand = true;
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.width_request = 250;

        main_grid.add (title_label);
        main_grid.add (calendar);
        main_grid.add (remove_button);

        add (main_grid);

        remove_button.clicked.connect (() => {
            on_selected_remove ();

            remove_button.no_show_all = true;
            remove_button.visible = false;

            popdown ();
        });

        calendar.day_selected.connect (() => {
            calendar.get_style_context ().remove_class ("calendar-no-selected");
            calendar.get_style_context ().add_class ("calendar-selected");
        });

        calendar.day_selected_double_click.connect (() => {
            var deadline_datetime = new GLib.DateTime.local (calendar.year,
                                                             calendar.month + 1,
                                                             calendar.day,
                                                             new GLib.DateTime.now_local ().get_hour (),
                                                             new GLib.DateTime.now_local ().get_minute (),
                                                             new GLib.DateTime.now_local ().get_second ());
            on_selected_date (deadline_datetime);
            popdown ();

            Timeout.add (200, () => {
                remove_button.visible = true;
                return false;
            });
        });
    }
}
