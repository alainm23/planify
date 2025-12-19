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
    public class SlashParser : Object {
        private Regex slash_regex;

        //  Date format with slash "/" (or dot ".") between numbers.
        //  For examples:
        //   - 7/10
        //  - 7/12/2020
        //  - 7.12.2020
        
        public SlashParser () {
            try {
                // Matches: d/m, d/m/y, d.m, d.m.y
                slash_regex = new Regex (
                    "(\\d{1,2})[/\\.](\\d{1,2})(?:[/\\.](\\d{2,4}))?",
                    RegexCompileFlags.CASELESS
                );
            } catch (Error e) {
                warning ("Error creating slash regex: %s", e.message);
            }
        }
        
        public ParseResult? parse (string text) {
            try {
                MatchInfo match;
                if (!slash_regex.match (text, 0, out match)) {
                    return null;
                }
                
                int day = int.parse (match.fetch (1));
                int month = int.parse (match.fetch (2));
                
                var now = new DateTime.now_local ();
                int year = now.get_year ();
                
                string? year_str = match.fetch (3);
                if (year_str != null && year_str.length > 0) {
                    year = int.parse (year_str);
                    if (year < 100) {
                        year += 2000;
                    }
                }
                
                var result = new ParseResult ();
                result.date = new DateTime.local (year, month, day, 0, 0, 0);
                
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
