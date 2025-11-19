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
     * [LANGUAGE_NAME] casual date parser
     * 
     * TODO: Update patterns to support your language
     * Examples: "today", "tomorrow", "yesterday"
     */
    public class TEMPLATECasualDateParser : Object {
        private Regex casual_regex;
        
        public TEMPLATECasualDateParser () {
            try {
                // TODO: Update these patterns for your language
                casual_regex = new Regex (
                    "\\b(today|tomorrow|yesterday)\\b",
                    RegexCompileFlags.CASELESS
                );
            } catch (Error e) {
                warning ("Error creating casual date regex: %s", e.message);
            }
        }
        
        public ParseResult? parse (string text) {
            try {
                MatchInfo match;
                if (!casual_regex.match (text, 0, out match)) {
                    return null;
                }
                
                string matched_word = match.fetch (1).down ();
                var now = new DateTime.now_local ();
                DateTime date;
                
                // TODO: Update these keywords for your language
                switch (matched_word) {
                    case "today":
                        date = new DateTime.local (now.get_year (), now.get_month (), now.get_day_of_month (), 0, 0, 0);
                        break;
                    case "tomorrow":
                        var tomorrow = now.add_days (1);
                        date = new DateTime.local (tomorrow.get_year (), tomorrow.get_month (), tomorrow.get_day_of_month (), 0, 0, 0);
                        break;
                    case "yesterday":
                        var yesterday = now.add_days (-1);
                        date = new DateTime.local (yesterday.get_year (), yesterday.get_month (), yesterday.get_day_of_month (), 0, 0, 0);
                        break;
                    default:
                        return null;
                }
                
                var result = new ParseResult ();
                result.date = date;
                
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