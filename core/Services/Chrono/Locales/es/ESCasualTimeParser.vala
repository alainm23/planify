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
     * Spanish casual time expressions parser
     * 
     * Supports: mañana, tarde, noche, medianoche, mediodía
     * With optional "esta" prefix
     */
    public class ESCasualTimeParser : Object {
        private Regex casual_time_regex;
        
        public ESCasualTimeParser () {
            try {
                casual_time_regex = new Regex (
                    "(?:esta)?\\s{0,3}(mañana|manana|tarde|noche|medianoche|mediodía|mediodia)(?=\\W|$)",
                    RegexCompileFlags.CASELESS
                );
            } catch (Error e) {
                warning ("Error creating casual time regex: %s", e.message);
            }
        }
        
        public ParseResult? parse (string text) {
            try {
                MatchInfo match;
                if (!casual_time_regex.match (text, 0, out match)) {
                    return null;
                }
                
                string keyword = match.fetch (1).down ();
                var now = new DateTime.now_local ();
                int hour;
                
                switch (keyword) {
                    case "mañana":
                    case "manana":
                        hour = 9;
                        break;
                    case "tarde":
                        hour = 14;
                        break;
                    case "noche":
                        hour = 20;
                        break;
                    case "medianoche":
                        hour = 0;
                        break;
                    case "mediodía":
                    case "mediodia":
                        hour = 12;
                        break;
                    default:
                        return null;
                }
                
                var result = new ParseResult ();
                result.date = new DateTime.local (
                    now.get_year (),
                    now.get_month (),
                    now.get_day_of_month (),
                    hour, 0, 0
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
