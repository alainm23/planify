public class Widgets.Events : Gtk.Revealer {
    private Gtk.Button close_button;
    private Widgets.Weather weather_widget;
    public signal void on_signal_close ();
    public Events () {
        Object (
            transition_type: Gtk.RevealerTransitionType.SLIDE_LEFT,
            transition_duration: 300,
            reveal_child: false,
            margin: 6
        );
    }

    construct {
        close_button = new Gtk.Button.from_icon_name ("pan-end-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
        close_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
        close_button.get_style_context ().add_class ("no-padding");
        close_button.height_request = 64;
        close_button.can_focus = false;
        close_button.valign = Gtk.Align.CENTER;
        close_button.halign = Gtk.Align.START;

        weather_widget = new Widgets.Weather ();

        var events_label = new Granite.HeaderLabel (_("Up next"));
        events_label.margin_start = 6;

        var main_grid = new Gtk.Grid ();
        main_grid.width_request = 250;
        main_grid.get_style_context ().add_class ("popover");
        main_grid.get_style_context ().add_class ("planner-popover");
        main_grid.orientation = Gtk.Orientation.VERTICAL;

        main_grid.add (weather_widget);
        main_grid.add (events_label);

        var main_overlay = new Gtk.Overlay ();
        main_overlay.add_overlay (close_button);
        main_overlay.add (main_grid);

        add (main_overlay);

        close_button.clicked.connect (() => {
            on_signal_close ();
        });
    }
}
