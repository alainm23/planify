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
    /**
     * Main parser for [LANGUAGE_NAME] language
     * 
     * TODO: Replace "Template" with your language name
     * TODO: Update language_code with your ISO language code
     */
    public class TemplateParser : LanguageParser {
        private Gee.ArrayList<Object> parsers;
        
        public TemplateParser () {
            // TODO: Update with your language code (e.g., "fr", "de", "it")
            language_code = "template";
            
            parsers = new Gee.ArrayList<Object> ();
            
            // Add all parsers for this language
            parsers.add (new TEMPLATECasualDateParser ());
            parsers.add (new TEMPLATERelativeDateFormatParser ());
            // TODO: Add other parsers as you implement them:
            // parsers.add (new TEMPLATECasualTimeParser ());
            // parsers.add (new TEMPLATEMonthNameParser ());
            // parsers.add (new TEMPLATETimeExpressionParser ());
            // parsers.add (new TEMPLATEDateTimeComboParser ());
        }
        
        public override ParseResult? parse (string text) {
            foreach (var parser in parsers) {
                ParseResult? result = null;
                
                // Try each parser type
                if (parser is TEMPLATECasualDateParser) {
                    result = ((TEMPLATECasualDateParser) parser).parse (text);
                } else if (parser is TEMPLATERelativeDateFormatParser) {
                    result = ((TEMPLATERelativeDateFormatParser) parser).parse (text);
                }
                // TODO: Add other parser types as you implement them
                
                if (result != null) {
                    return result;
                }
            }
            
            return null;
        }
        
        public override bool can_parse (string text) {
            return parse (text) != null;
        }
    }
}