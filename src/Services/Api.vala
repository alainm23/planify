/*
* Copyright © 2025 Alain M. (https://github.com/alainm23/planify)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
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
* Authored by: Alain M. <alainmh23@gmail.com>
*/

public class Services.Api : GLib.Object {
    private static Api? _instance;
    public static Api get_default () {
        if (_instance == null) {
            _instance = new Api ();
        }
        return _instance;
    }

    public async Gee.HashMap<string, Objects.TranslationMetric> get_translation_metrics () throws Error {
        var session = new Soup.Session ();
        var message = new Soup.Message ("GET", "https://raw.githubusercontent.com/alainm23/planify/refs/heads/master/data/translations_metrics.json");
        
        var response = yield session.send_and_read_async (message, Priority.DEFAULT, null);
        var json_string = (string) response.get_data ();
        
        var parser = new Json.Parser ();
        parser.load_from_data (json_string);
        
        var root_object = parser.get_root ().get_object ();
        var metrics = new Gee.HashMap<string, Objects.TranslationMetric> ();
        
        root_object.foreach_member ((object, code, node) => {
            var metric_object = node.get_object ();
            var metric = new Objects.TranslationMetric.from_json (code, metric_object);
            metrics.set (code, metric);
        });
        
        return metrics;
    }
}