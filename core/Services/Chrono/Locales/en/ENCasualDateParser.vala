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
     * English casual date expressions parser
     * 
     * Supports: now, today, tonight, tomorrow, overmorrow, tmr, tmrw, yesterday, last night
     */
    public class ENCasualDateParser : Object {
        private Regex casual_regex;
        
        public ENCasualDateParser () {
            try {
                casual_regex = new Regex (
                    "\\b(now|today|tonight|tomorrow|overmorrow|tmr|tmrw|yesterday|last\\s*night)\\b",
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
                
                string keyword = match.fetch (1).down ().replace (" ", "");
                var now = new DateTime.now_local ();
                DateTime date;
                
                switch (keyword) {
                    case "now":
                        date = now;
                        break;
                    case "today":
                        date = new DateTime.local (
                            now.get_year (),
                            now.get_month (),
                            now.get_day_of_month (),
                            0, 0, 0
                        );
                        break;
                    case "tonight":
                        date = new DateTime.local (
                            now.get_year (),
                            now.get_month (),
                            now.get_day_of_month (),
                            20, 0, 0
                        );
                        break;
                    case "tomorrow":
                    case "tmr":
                    case "tmrw":
                        var tomorrow = now.add_days (1);
                        date = new DateTime.local (
                            tomorrow.get_year (),
                            tomorrow.get_month (),
                            tomorrow.get_day_of_month (),
                            0, 0, 0
                        );
                        break;
                    case "overmorrow":
                        var overmorrow = now.add_days (2);
                        date = new DateTime.local (
                            overmorrow.get_year (),
                            overmorrow.get_month (),
                            overmorrow.get_day_of_month (),
                            0, 0, 0
                        );
                        break;
                    case "yesterday":
                        var yesterday = now.add_days (-1);
                        date = new DateTime.local (
                            yesterday.get_year (),
                            yesterday.get_month (),
                            yesterday.get_day_of_month (),
                            0, 0, 0
                        );
                        break;
                    case "lastnight":
                        date = new DateTime.local (
                            now.get_year (),
                            now.get_month (),
                            now.get_day_of_month (),
                            20, 0, 0
                        ).add_days (-1);
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
