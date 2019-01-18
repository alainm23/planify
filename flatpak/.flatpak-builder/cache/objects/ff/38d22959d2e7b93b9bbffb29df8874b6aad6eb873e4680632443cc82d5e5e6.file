// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2011-2015 elementary LLC
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored by: Mario Guerriero <marioguerriero33@gmail.com>
 */

namespace Maya.Services {

public class EventParserHandler : GLib.Object {

    public const string FALLBACK_LANG = "en";

    private Gee.HashMap<string, EventParser> handlers;

    public EventParserHandler (string? lang = null) {
        handlers = new Gee.HashMap<string, EventParser> ();

        if (lang == null)
            lang = get_locale ();

        // Grant at least the fallback parser
        register_handler (FALLBACK_LANG, new ParserEn ());

        // Register other default parsers
        var parser = new ParserDe ();
        register_handler (parser.get_language (), parser); // de

    }

    public void register_handler (string lang, EventParser parser) {
        handlers.set (lang, parser);
    }

    public EventParser get_parser (string lang) {
        if (!handlers.has_key (lang))
            return handlers.get (FALLBACK_LANG);
        return handlers.get (lang);
    }

    public unowned string? get_locale () {
        return Environment.get_variable ("LANGUAGE");
    }
}

}
