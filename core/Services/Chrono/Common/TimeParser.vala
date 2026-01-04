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
     * Time format parser (language independent)
     * 
     * For examples:
     * - 14:30
     * - 23:45
     * - 2:30pm
     * - 3pm
     * - 15:00
     */
    public class TimeParser : Object {
        private Regex time_24h_regex;
        private Regex time_12h_regex;
        
        public TimeParser () {
            try {
                // 24-hour format: 14:30, 23:45
                time_24h_regex = new Regex (
                    "(\\d{1,2}):(\\d{2})",
                    RegexCompileFlags.CASELESS
                );
                
                // 12-hour format: 2:30pm, 3pm, 11:45am
                time_12h_regex = new Regex (
                    "(\\d{1,2})(?::(\\d{2}))?\\s*(am|pm)",
                    RegexCompileFlags.CASELESS
                );
            } catch (Error e) {
                warning ("Error creating time regex: %s", e.message);
            }
        }
        
        public ParseResult? parse (string text) {
            var result = parse_12h (text);
            if (result != null) {
                return result;
            }
            
            return parse_24h (text);
        }
        
        private ParseResult? parse_12h (string text) {
            try {
                MatchInfo match;
                if (!time_12h_regex.match (text, 0, out match)) {
                    return null;
                }
                
                int hour = int.parse (match.fetch (1));
                int minute = 0;
                
                string? min_str = match.fetch (2);
                if (min_str != null && min_str.length > 0) {
                    minute = int.parse (min_str);
                }
                
                string period = match.fetch (3).down ();
                if (period == "pm" && hour < 12) {
                    hour += 12;
                } else if (period == "am" && hour == 12) {
                    hour = 0;
                }
                
                var now = new DateTime.now_local ();
                var result = new ParseResult ();
                result.date = new DateTime.local (
                    now.get_year (),
                    now.get_month (),
                    now.get_day_of_month (),
                    hour,
                    minute,
                    0
                );
                
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
        
        private ParseResult? parse_24h (string text) {
            try {
                MatchInfo match;
                if (!time_24h_regex.match (text, 0, out match)) {
                    return null;
                }
                
                int hour = int.parse (match.fetch (1));
                int minute = int.parse (match.fetch (2));
                
                if (hour > 23 || minute > 59) {
                    return null;
                }
                
                var now = new DateTime.now_local ();
                var result = new ParseResult ();
                result.date = new DateTime.local (
                    now.get_year (),
                    now.get_month (),
                    now.get_day_of_month (),
                    hour,
                    minute,
                    0
                );
                
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
