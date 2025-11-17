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
    public class ISOParser : Object {
        private Regex iso_regex;
        
        // ISO 8601
        // http://www.w3.org/TR/NOTE-datetime
        // - YYYY-MM-DD
        // - YYYY-MM-DDThh:mmTZD
        // - YYYY-MM-DDThh:mm:ssTZD
        // - YYYY-MM-DDThh:mm:ss.sTZD
        // - TZD = (Z or +hh:mm or -hh:mm)

        public ISOParser () {
            try {
                iso_regex = new Regex (
                    "(\\d{4})-(\\d{2})-(\\d{2})" +
                    "(?:T(\\d{2}):(\\d{2})(?::(\\d{2})(?:\\.(\\d+))?)?" +
                    "(Z|[+-]\\d{2}:\\d{2})?)?",
                    RegexCompileFlags.CASELESS
                );
            } catch (Error e) {
                warning ("Error creating ISO regex: %s", e.message);
            }
        }
        
        public ParseResult? parse (string text) {
            try {
                MatchInfo match;
                if (!iso_regex.match (text, 0, out match)) {
                    return null;
                }
                
                int year = int.parse (match.fetch (1));
                int month = int.parse (match.fetch (2));
                int day = int.parse (match.fetch (3));
                
                int hour = 0, minute = 0, second = 0;
                string? time_part = match.fetch (4);
                
                if (time_part != null && time_part.length > 0) {
                    hour = int.parse (time_part);
                    minute = int.parse (match.fetch (5));
                    
                    string? sec = match.fetch (6);
                    if (sec != null && sec.length > 0) {
                        second = int.parse (sec);
                    }
                }
                
                var result = new ParseResult ();
                result.date = new DateTime.local (year, month, day, hour, minute, second);
                
                int start_pos, end_pos;
                match.fetch_pos (0, out start_pos, out end_pos);
                result.start_index = start_pos;
                result.end_index = end_pos;
                result.matched_text = match.fetch (0);
                
                return result;
            } catch (Error e) {
                return null;
            }
        }
    }
}
