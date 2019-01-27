/*
* Copyright © 2019 Alain M. (https://github.com/alainm23/planner)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Alain M. <alain23@protonmail.com>
*/

public class Widgets.Weather : Gtk.EventBox {
    private Gtk.Label temperature_label;
    private Gtk.Label description_label;
    private Gtk.Label description_detail_label;
    private Gtk.Image weather_icon;

    private Gtk.Spinner loading_spinner;

    private Gtk.Stack main_stack;

    private NetworkMonitor monitor;
    private Services.Weather weather_info;

    public const string COLOR_CSS = """
        .planner-weather-widget {
            background: %s;
            border: 1px solid shade(%s, 0.9);
            padding: 0px 6px 0px 6px;
            border-radius: 6px;
            box-shadow:
                inset 0 0 0 1px alpha(white, 0.05),
                inset 0 1px 0 0 alpha(white, 0.25),
                inset 0 -1px 0 0 alpha(white, 0.1),
                0 1px 2px alpha(black, 0.3);
            font-size: 11px;
            font-weight: 700;
            margin: 2px;
            min-height: 18px;
            min-width: 18px;
            text-shadow: 0 1px 1px alpha(black, 0.3);
        }
        
        .planner-weather-widget label {
            color: %s;
        }
        
        .planner-weather-widget image {
            color: %s;
        }

        .planner-weather-widget spinner {
            color: %s;
        }
    """;

    public Weather () {
        Object (
            hexpand: true,
            margin: 6
        );
    }

    construct {
        weather_info = new Services.Weather ();
        monitor = NetworkMonitor.get_default ();

        temperature_label = new Gtk.Label (weather_info.get_temperature ());
        temperature_label.get_style_context ().add_class ("h1");

        description_label = new Gtk.Label ("%s, %s - %s".printf (weather_info.city, weather_info.country, weather_info.description));
        description_label.halign = Gtk.Align.START;

        description_detail_label = new Gtk.Label (weather_info.description_detail);
        description_detail_label.halign = Gtk.Align.START;

        var info_grid = new Gtk.Grid ();
        info_grid.valign = Gtk.Align.CENTER;
        info_grid.orientation = Gtk.Orientation.VERTICAL;
        info_grid.add (description_label);
        info_grid.add (description_detail_label);

        weather_icon = new Gtk.Image ();
        weather_icon.gicon = new ThemedIcon (weather_info.get_symbolic_icon_name ());
        weather_icon.pixel_size = 32;

        loading_spinner = new Gtk.Spinner ();
        loading_spinner.get_style_context ().add_class ("planner-spinner");
		loading_spinner.active = true;
        loading_spinner.valign = Gtk.Align.CENTER;
        loading_spinner.halign = Gtk.Align.CENTER;

        var weather_info_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        weather_info_box.hexpand = true;
        weather_info_box.pack_start (temperature_label, false, false, 0);
        weather_info_box.pack_start (info_grid, false, false, 12);
        weather_info_box.pack_end (weather_icon, false, false, 0);

        var weather_forecast_grid = new Gtk.Grid ();
        weather_forecast_grid.column_homogeneous = true;
        weather_forecast_grid.hexpand = true;

        foreach (var item in weather_info.forecast_list) {
            weather_forecast_grid.add (new ForecastGrid (item));
        } 

        var main_grid = new Gtk.Grid ();
        main_grid.get_style_context ().add_class ("planner-weather-widget");
        main_grid.hexpand = true;
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.add (weather_info_box);
        main_grid.add (weather_forecast_grid);        

        main_stack = new Gtk.Stack ();
        main_stack.hexpand = true;
        main_stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;

        main_stack.add_named (main_grid, "weather");
        main_stack.add_named (loading_spinner, "loading");

        main_stack.visible_child_name = "weather";

        add (main_stack);
        apply_style (weather_info.get_symbolic_icon_name ());
        check_network_available ();

        weather_info.weather_info_updated.connect (() => {
            weather_icon.icon_name = weather_info.get_symbolic_icon_name ();

            description_label.label = "%s, %s - %s".printf (weather_info.city, weather_info.country, weather_info.description);
            description_detail_label.label = weather_info.description_detail;
            temperature_label.label = weather_info.get_temperature ();

            main_stack.visible_child_name = "weather";

            apply_style (weather_info.get_symbolic_icon_name ());
        });

        weather_info.weather_error.connect (() => {
            main_stack.visible_child_name = "loading";
        });

        monitor.network_changed.connect (() => {
            var connection_available = monitor.get_network_available ();

            if (connection_available) {
                weather_info.set_automatic_location (false);

                if (Application.settings.get_boolean ("location-automatic") == false) {
                    weather_info.set_manual_location (Application.settings.get_string ("location-manual-value"));
                } else {
                    weather_info.weather_info_updated ();
                }

                main_stack.visible_child_name = "weather";
            } else {
                main_stack.visible_child_name = "loading";
            }
        });
    }

    private void check_network_available () {
        Timeout.add (200, () => {
            if (Application.utils.check_internet_connection ()) {
                main_stack.visible_child_name = "weather";
            } else {
                main_stack.visible_child_name = "loading";   
            }
            
            return false;
        });
    }

    private void apply_style (string icon) {
        var color = Application.utils.get_weaher_color (icon);

        var provider = new Gtk.CssProvider ();

        try {
            var colored_css = COLOR_CSS.printf (                             
                color,
                color,
                Application.utils.convert_invert (color),
                Application.utils.convert_invert (color),                               
                Application.utils.convert_invert (color)
            );

            provider.load_from_data (colored_css, colored_css.length);

            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (GLib.Error e) {
            return;
        }
    }
}

public class ForecastGrid : Gtk.Grid {
    public Forecast forecast { get; construct; }

    public ForecastGrid (Forecast _forecast) {
        Object (
            forecast: _forecast 
        );
    }

    construct {
        orientation = Gtk.Orientation.VERTICAL;
        halign = Gtk.Align.CENTER;

        var icon = new Gtk.Image ();
        icon.gicon = new ThemedIcon (forecast.icon);
        icon.pixel_size = 16;

        var temp_label = new Gtk.Label (forecast.temperature);

        string format = Granite.DateTime.get_default_time_format (true, false);
        var hour_label = new Gtk.Label (forecast.datetime.format (format));

        add (hour_label);
        add (icon);
        add (temp_label);
    }
}
