/*
* Copyright © 2024 Alain M. (https://github.com/alainm23/planify)
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

public class Chrono.Parse : GLib.Object {
    public string lang { get; construct; }

    private Gee.HashMap<string, Chrono.Configuration> configurations;
    private Chrono.Configuration configuration;

    public Parse (string lang = "en") {
        Object (
            lang: lang
        );
    }

    construct {
        configurations = new Gee.HashMap<string, Chrono.Configuration> ();
        configurations.set ("en", new Chrono.En.Parse ());

        if (configurations.has_key (lang)) {
            configuration = configurations.get (lang);
        } else {
            configuration = new Chrono.En.Parse ();
        }
    }

    public void parse(string text) {
        Gee.ArrayList<Chrono.ParsingResult> results = new Gee.ArrayList<Chrono.ParsingResult> ();

        GLib.MatchInfo match;
        foreach (Chrono.AbstractParser parser in configuration.parsers) {
            if (parser.inner_pattern ().match_all (text, 0, out match)) {
                Chrono.ParsingResult result =  parser.inner_extract (match);
                results.add (result);
            }
        }

        foreach (Chrono.ParsingResult result in results) {
            print ("Date: %s\n", result.datetime.to_string ());
        }
    }
}
