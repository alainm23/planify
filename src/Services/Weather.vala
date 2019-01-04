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

public class Services.Weather : GLib.Object {
    public double latitude { get; set; }
    public double longitude { get; set; }
    public string city { get; set; }
    public string country { get; set; }
    public double temperature;
    public string description { get; set; }
    public string icon { get; set; }

    public string geo_city;
    public string geo_country;

    public signal void weather_info_updated ();
    public signal void weather_error ();

    // Signals Weather
    public signal void on_signal_weather_update ();
    public signal void on_signal_location_manual ();

    public Weather () {
        latitude = 0.0;
        longitude = 0.0;
        city = "-";
        country = "-";
        temperature = 0;
        description = "-";

        geo_city = "-";
        geo_country = "-";

        set_automatic_location (false);

        if (Application.settings.get_boolean ("location-automatic") == false) {
            set_manual_location (Application.settings.get_string ("location-manual-value"));
        } else {
            update_weather_info ();
        }

        Application.notification.on_signal_weather_update.connect (() => {
            update_weather_info ();
        });

        Application.notification.on_signal_location_manual.connect (() => {
            set_manual_location (Application.settings.get_string ("location-manual-value"));
        });

        Timeout.add_seconds (1 * 60 * 15, () => {
            update_weather_info ();
            return true;
        });
    }

    public void get_location_info (bool fetch_weather_info) {
      string APP_ID = "0c6dd6ac81b50705599a4d7e3cf02e89";
      string API_URL = "http://api.openweathermap.org/data/2.5/weather";
      string units = get_units ();

      string uri = "%s?lat=%f&lon=%f&appid=%s&units=%s".printf (API_URL, this.latitude, this.longitude, APP_ID, units);

      var session = new Soup.Session ();
      var message = new Soup.Message ("GET", uri);
      session.send_message (message);

      try {
          var parser = new Json.Parser ();
          parser.load_from_data ((string) message.response_body.flatten ().data, -1);

          var response_root_object = parser.get_root ().get_object ();
          var sys = response_root_object.get_object_member ("sys");

          geo_city = response_root_object.get_string_member ("name");
          geo_country = sys.get_string_member ("country");

          if (fetch_weather_info) {
              update_weather_info ();
          }
      } catch (Error e) {
          weather_error ();
          stderr.printf ("Failed to connect to OpenWeatherMap service.\n");
      }
    }

    public void update_weather_info () {
        string APP_ID = "0c6dd6ac81b50705599a4d7e3cf02e89";
        string API_URL = "http://api.openweathermap.org/data/2.5/weather";
        string units = get_units ();

        string uri;
        if (Application.settings.get_boolean ("location-automatic")) {
            uri = "%s?lat=%f&lon=%f&appid=%s&units=%s".printf (API_URL, this.latitude, this.longitude, APP_ID, units);
        } else {
            uri = "%s?q=%s,%s&appid=%s&units=%s".printf (API_URL, this.city, this.country, APP_ID, units);
        }

        var session = new Soup.Session ();
        var message = new Soup.Message ("GET", uri);
        session.send_message (message);

        try {
            var parser = new Json.Parser ();
            parser.load_from_data ((string) message.response_body.flatten ().data, -1);

            var response_root_object = parser.get_root ().get_object ();
            var weather = response_root_object.get_array_member ("weather");
            var sys = response_root_object.get_object_member ("sys");
            var main = response_root_object.get_object_member ("main");

            string weather_description = "";
            string weather_icon = "";
            foreach (var weather_details_item in weather.get_elements ()) {
                var weather_details = weather_details_item.get_object ();

                weather_description = weather_details.get_string_member ("main");
                weather_icon = weather_details.get_string_member ("icon");
            }

            city = response_root_object.get_string_member ("name");
            country = sys.get_string_member ("country");
            temperature = main.get_double_member ("temp");
            description = weather_description;
            icon = weather_icon;

            weather_info_updated ();
        } catch (Error e) {
            weather_error ();
            stderr.printf ("Failed to connect to OpenWeatherMap service.\n");
        }
    }

    public void set_automatic_location (bool fetch_weather_info) {
        get_location.begin (fetch_weather_info);
    }

    public async void get_location (bool fetch_weather_info) {
        try {
            var simple = yield new GClue.Simple ("com.github.alainm23.planner", GClue.AccuracyLevel.CITY, null);
            on_location_updated (simple.location.latitude, simple.location.longitude, fetch_weather_info);
        } catch (Error e) {
            weather_error ();
            warning ("Failed to connect to GeoClue2 service: %s", e.message);
            return;
        }
    }

    public void on_location_updated (double latitude, double longitude, bool fetch_weather_info) {
        set_location (latitude, longitude);
        get_location_info (fetch_weather_info);
    }

    public void set_location (double _latitude, double _longitude) {
        latitude = _latitude;
        longitude = _longitude;
    }

    public void set_manual_location (string location) {
        string[] location_details = location.split (", ");
        this.city = location_details[0];
        this.country = location_details[1];

        update_weather_info ();
    }

    public string get_units () {
        if (Application.settings.get_enum ("weather-unit-format") == 0) {
            return "imperial";
        } else {
            return "metric";
        }
    }

    public string get_symbolic_icon_name () {
        return Application.utils.get_weather_icon_name (icon);
    }

    public string get_temperature () {
        var formatted_temperature = _("%i°").printf ((int) this.temperature);
        return formatted_temperature;
    }

    public void print_weather_info () {
       stdout.printf ("City: %s\n", this.city);
       stdout.printf ("Country: %s\n", this.country);
       stdout.printf ("Description: %s\n", this.description);
       stdout.printf ("Temperature: %f\n", this.temperature);

       stdout.printf ("GEO City: %s\n", this.geo_city);
       stdout.printf ("GEO Country: %s\n", this.geo_country);
   }
}
