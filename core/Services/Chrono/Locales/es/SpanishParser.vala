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
    public class SpanishParser : LanguageParser {
        private ESDateTimeComboParser combo_parser;
        private ISOParser iso_parser;
        private SlashParser slash_parser;
        private TimeParser time_parser;
        private ESCasualDateParser casual_parser;
        private ESCasualTimeParser casual_time_parser;
        private ESMonthNameParser month_parser;
        private ESRelativeDateFormatParser relative_parser;
        private ESTimeExpressionParser time_expr_parser;
        
        public SpanishParser () {
            combo_parser = new ESDateTimeComboParser ();
            iso_parser = new ISOParser ();
            slash_parser = new SlashParser ();
            time_parser = new TimeParser ();
            casual_parser = new ESCasualDateParser ();
            casual_time_parser = new ESCasualTimeParser ();
            month_parser = new ESMonthNameParser ();
            relative_parser = new ESRelativeDateFormatParser ();
            time_expr_parser = new ESTimeExpressionParser ();
        }
        
        public override ParseResult? parse (string text, bool parse_recurrence = false) {
            ParseResult? result = null;
            
            result = combo_parser.parse (text);
            if (result != null) {
                return result;
            }
            
            result = iso_parser.parse (text);
            if (result != null) {
                return result;
            }
            
            result = slash_parser.parse (text);
            if (result != null) {
                return result;
            }
            
            result = time_parser.parse (text);
            if (result != null) {
                return result;
            }
            
            result = casual_parser.parse (text);
            if (result != null) {
                return result;
            }
            
            result = casual_time_parser.parse (text);
            if (result != null) {
                return result;
            }
            
            result = month_parser.parse (text);
            if (result != null) {
                return result;
            }
            
            result = relative_parser.parse (text);
            if (result != null) {
                return result;
            }
            
            result = time_expr_parser.parse (text);
            if (result != null) {
                return result;
            }
            
            return null;
        }
    }
}
