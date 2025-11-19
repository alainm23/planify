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
 
namespace Chrono {
    public class Parser : Object {
        private Gee.HashMap<string, LanguageParser> language_parsers;
        
        public Parser () {
            language_parsers = new Gee.HashMap<string, LanguageParser> ();
            register_language ("en", new EnglishParser ());
            register_language ("es", new SpanishParser ());
        }
        
        public void register_language (string code, LanguageParser parser) {
            language_parsers[code] = parser;
        }
        
        public ParseResult? parse (string text, string language, bool parse_recurrence = false) {
            if (!language_parsers.has_key (language)) {
                return null;
            }
            
            return language_parsers[language].parse (text, parse_recurrence);
        }
    }
}
