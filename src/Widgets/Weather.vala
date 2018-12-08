public class Widgets.Weather : Gtk.EventBox {
    private Gtk.Label temperature_label;
    private Gtk.Label description_label;
    private Gtk.Label location_label;
    private Gtk.Image weather_icon;

    private Gtk.Spinner loading_spinner;
    private Services.Weather weather_info;

    private Gtk.Stack main_stack;
    public Weather () {
        Object (
            hexpand: true,
            margin: 6
        );
    }

    construct {
        // Weather Services
        weather_info = new Services.Weather ();

        temperature_label = new Gtk.Label (weather_info.get_temperature ());
        temperature_label.get_style_context ().add_class ("h1");

        description_label = new Gtk.Label (weather_info.description);
        description_label.halign = Gtk.Align.START;

        location_label = new Gtk.Label (weather_info.city);
        location_label.halign = Gtk.Align.START;

        var info_grid = new Gtk.Grid ();
        info_grid.valign = Gtk.Align.CENTER;
        info_grid.orientation = Gtk.Orientation.VERTICAL;
        info_grid.add (description_label);
        info_grid.add (location_label);

        weather_icon = new Gtk.Image ();
        weather_icon.gicon = new ThemedIcon (weather_info.get_symbolic_icon_name ());
        weather_icon.pixel_size = 32;

        loading_spinner = new Gtk.Spinner ();
		loading_spinner.active = true;
        loading_spinner.valign = Gtk.Align.CENTER;
        loading_spinner.halign = Gtk.Align.CENTER;

        var main_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        main_box.margin = 6;
        main_box.pack_start (temperature_label, false, false, 0);
        main_box.pack_start (info_grid, false, false, 12);
        main_box.pack_end (weather_icon, false, false, 0);

        main_stack = new Gtk.Stack ();
        main_stack.get_style_context ().add_class (Granite.STYLE_CLASS_CARD);
        main_stack.get_style_context ().add_class ("planner-weather-widget");
        main_stack.margin = 6;
        main_stack.hexpand = true;
        main_stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;

        main_stack.add_named (main_box, "weather");
        main_stack.add_named (loading_spinner, "error");

        main_stack.visible_child_name = "weather";

        add (main_stack);
        check_network_available ();

        weather_info.weather_info_updated.connect (() => {
            location_label.label = weather_info.city + ", " + weather_info.country;

            weather_icon.icon_name = weather_info.get_symbolic_icon_name ();
            description_label.label = weather_info.description;

            temperature_label.label = weather_info.get_temperature ();

            main_stack.visible_child_name = "weather";
        });

        weather_info.weather_error.connect (() => {
            main_stack.visible_child_name = "error";
        });

        NetworkMonitor.get_default ().network_changed.connect (() => {
            var connection_available = NetworkMonitor.get_default ().get_network_available ();

            if (connection_available) {
                weather_info.set_automatic_location (false);

                if (Application.settings.get_boolean ("location-automatic") == false) {
                    weather_info.set_manual_location (Application.settings.get_string ("location-manual-value"));
                } else {
                    weather_info.update_weather_info ();
                }

                main_stack.visible_child_name = "weather";
            } else {
                main_stack.visible_child_name = "error";
            }
        });
    }

    private void check_network_available () {
        var connection_available = NetworkMonitor.get_default ().get_network_available ();
        
        Timeout.add (200, () => {
            if (connection_available) {
                main_stack.visible_child_name = "weather";
            } else {
                main_stack.visible_child_name = "error";
            }
            return false;
        });

    }
}
