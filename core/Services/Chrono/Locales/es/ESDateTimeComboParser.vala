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
     * Spanish date + time combination parser
     * 
     * Supports: mañana a las 3pm, lunes a las 9am, 15 de marzo a las 14:30
     */
    public class ESDateTimeComboParser : Object {
        private Regex combo_regex;
        private ESCasualDateParser casual_parser;
        private TimeParser time_parser;
        
        public ESDateTimeComboParser () {
            casual_parser = new ESCasualDateParser ();
            time_parser = new TimeParser ();
            
            try {
                // Match: [date expression] a las [time expression]
                combo_regex = new Regex (
                    "(.+?)\\s+a\\s+las\\s+(.+)",
                    RegexCompileFlags.CASELESS
                );
            } catch (Error e) {
                warning ("Error creating combo regex: %s", e.message);
            }
        }
        
        public ParseResult? parse (string text) {
            try {
                MatchInfo match;
                if (!combo_regex.match (text, 0, out match)) {
                    return null;
                }
                
                string date_part = match.fetch (1).strip ();
                string time_part = match.fetch (2).strip ();
                
                // Parse date part
                ParseResult? date_result = casual_parser.parse (date_part);
                
                if (date_result == null || date_result.date == null) {
                    return null;
                }
                
                // Parse time part
                ParseResult? time_result = time_parser.parse (time_part);
                if (time_result == null || time_result.date == null) {
                    return null;
                }
                
                // Combine date and time
                var combined_date = new DateTime.local (
                    date_result.date.get_year (),
                    date_result.date.get_month (),
                    date_result.date.get_day_of_month (),
                    time_result.date.get_hour (),
                    time_result.date.get_minute (),
                    time_result.date.get_second ()
                );
                
                var result = new ParseResult ();
                result.date = combined_date;
                
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
