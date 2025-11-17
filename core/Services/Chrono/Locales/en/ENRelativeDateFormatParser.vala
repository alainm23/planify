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
     * English relative date format parser
     * 
     * Supports: this week, last month, next year, past 2 days, etc.
     */
    public class ENRelativeDateFormatParser : Object {
        private Regex relative_regex;
        
        public ENRelativeDateFormatParser () {
            try {
                relative_regex = new Regex (
                    "(this|last|past|next|after\\s+this)\\s+(second|seconds|minute|minutes|hour|hours|day|days|week|weeks|month|months|quarter|quarters|year|years|s|sec|m|min|mins|h|hr|hrs|d|w|mo|mon|mos|qtr|y|yr)(?=\\W|$)",
                    RegexCompileFlags.CASELESS
                );
            } catch (Error e) {
                warning ("Error creating relative date regex: %s", e.message);
            }
        }
        
        public ParseResult? parse (string text) {
            try {
                MatchInfo match;
                if (!relative_regex.match (text, 0, out match)) {
                    return null;
                }
                
                string modifier = match.fetch (1).down ().replace (" ", "");
                string unit_str = match.fetch (2);
                
                TimeUnit? time_unit = ENConstants.get_time_unit (unit_str);
                if (time_unit == null) {
                    return null;
                }
                
                var now = new DateTime.now_local ();
                DateTime date;
                
                switch (modifier) {
                    case "this":
                    case "afterthis":
                        date = now;
                        break;
                    case "last":
                    case "past":
                        date = add_time_unit (now, time_unit, -1);
                        break;
                    case "next":
                        date = add_time_unit (now, time_unit, 1);
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
        
        private DateTime add_time_unit (DateTime date, TimeUnit unit, int amount) {
            DateTime result;
            switch (unit) {
                case TimeUnit.SECOND:
                    return date.add_seconds (amount);
                case TimeUnit.MINUTE:
                    return date.add_minutes (amount);
                case TimeUnit.HOUR:
                    return date.add_hours (amount);
                case TimeUnit.DAY:
                    result = date.add_days (amount);
                    return new DateTime.local (result.get_year (), result.get_month (), result.get_day_of_month (), 0, 0, 0);
                case TimeUnit.WEEK:
                    result = date.add_weeks (amount);
                    return new DateTime.local (result.get_year (), result.get_month (), result.get_day_of_month (), 0, 0, 0);
                case TimeUnit.MONTH:
                    result = date.add_months (amount);
                    return new DateTime.local (result.get_year (), result.get_month (), result.get_day_of_month (), 0, 0, 0);
                case TimeUnit.QUARTER:
                    result = date.add_months (amount * 3);
                    return new DateTime.local (result.get_year (), result.get_month (), result.get_day_of_month (), 0, 0, 0);
                case TimeUnit.YEAR:
                    result = date.add_years (amount);
                    return new DateTime.local (result.get_year (), result.get_month (), result.get_day_of_month (), 0, 0, 0);
                default:
                    return date;
            }
        }
    }
}
