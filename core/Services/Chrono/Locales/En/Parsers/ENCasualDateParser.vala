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

public class Chrono.En.ENCasualDateParser : GLib.Object, Chrono.AbstractParser {
    GLib.Regex PATTERN = /(now|today|tonight|tomorrow|tmr|tmrw|yesterday|last\s*night)(?=\W|$)/;

    public GLib.Regex inner_pattern () {
        return PATTERN;
    }

    public Chrono.ParsingResult inner_extract (GLib.MatchInfo match) {
        var component = new Chrono.ParsingResult ();
        var lowerText = match.fetch_all () [0].down ();
        component.text = lowerText;

        switch (lowerText) {
            case "now":
                component.datetime = new GLib.DateTime.now_local ();
                break;
            case "today":
                component.datetime = new GLib.DateTime.now_local ();
                break;
            case "tonight":
                component.datetime = new GLib.DateTime.now_local ();
                break;
            case "tomorrow":
            case "tmr":
            case "tmrw":
                component.datetime = new GLib.DateTime.now_local ().add_days (1);
                break;
            case "yesterday":
                component.datetime = new GLib.DateTime.now_local ().add_days (-1);
                break;
        }

        return component;
    }
}