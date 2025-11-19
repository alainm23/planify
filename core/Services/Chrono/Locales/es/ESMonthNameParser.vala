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
     * Spanish month name parser
     * 
     * Supports: 15 de marzo, 15 marzo, marzo 15, 15 mar 2024, enero 2012, enero
     */
    public class ESMonthNameParser : Object {
        private Regex month_regex;
        
        public ESMonthNameParser () {
            try {
                month_regex = new Regex (
                    "(?:el\\s+)?(\\d{1,2})\\s+(?:de\\s+)?(enero|febrero|marzo|abril|mayo|junio|julio|agosto|septiembre|octubre|noviembre|diciembre|ene|feb|mar|abr|may|jun|jul|ago|sep|sept|oct|nov|dic)(?:\\s+(?:de|del)\\s+(\\d{2,4}))?|" +
                    "(?:el\\s+)?(enero|febrero|marzo|abril|mayo|junio|julio|agosto|septiembre|octubre|noviembre|diciembre|ene|feb|mar|abr|may|jun|jul|ago|sep|sept|oct|nov|dic)(?:,?\\s+(?:de|del)\\s+(\\d{4}))|" +
                    "(?:el\\s+)?(enero|febrero|marzo|abril|mayo|junio|julio|agosto|septiembre|octubre|noviembre|diciembre|ene|feb|mar|abr|may|jun|jul|ago|sep|sept|oct|nov|dic)\\s+(\\d{1,2})(?:,?\\s+(?:de|del)\\s+(\\d{2,4}))?|" +
                    "(?:el\\s+)?(enero|febrero|marzo|abril|mayo|junio|julio|agosto|septiembre|octubre|noviembre|diciembre|ene|feb|mar|abr|may|jun|jul|ago|sep|sept|oct|nov|dic)",
                    RegexCompileFlags.CASELESS
                );
            } catch (Error e) {
                warning ("Error creating month regex: %s", e.message);
            }
        }
        
        public ParseResult? parse (string text) {
            try {
                MatchInfo match;
                if (!month_regex.match (text, 0, out match)) {
                    return null;
                }
                
                int day, month, year;
                var now = new DateTime.now_local ();
                year = now.get_year ();
                day = 1;
                
                // Format: 15 de marzo or 15 marzo 2024
                string? day_str = match.fetch (1);
                if (day_str != null && day_str.length > 0) {
                    day = int.parse (day_str);
                    int? month_val = ESConstants.get_month (match.fetch (2));
                    if (month_val == null) {
                        return null;
                    }
                    month = month_val;
                    
                    string? year_str = match.fetch (3);
                    if (year_str != null && year_str.length > 0) {
                        year = int.parse (year_str);
                        if (year < 100) {
                            year += 2000;
                        }
                    }
                } else {
                    string? month_str = match.fetch (4);
                    if (month_str != null && month_str.length > 0) {
                        // Format: enero 2012 or enero de 2012
                        int? month_val = ESConstants.get_month (month_str);
                        if (month_val == null) {
                            return null;
                        }
                        month = month_val;
                        
                        string? year_str = match.fetch (5);
                        if (year_str != null && year_str.length > 0) {
                            year = int.parse (year_str);
                        }
                    } else {
                        month_str = match.fetch (6);
                        if (month_str != null && month_str.length > 0) {
                            // Format: marzo 15 or marzo 15 de 2024
                            int? month_val = ESConstants.get_month (month_str);
                            if (month_val == null) {
                                return null;
                            }
                            month = month_val;
                            
                            string? day_str2 = match.fetch (7);
                            if (day_str2 != null && day_str2.length > 0) {
                                day = int.parse (day_str2);
                            }
                            
                            string? year_str = match.fetch (8);
                            if (year_str != null && year_str.length > 0) {
                                year = int.parse (year_str);
                                if (year < 100) {
                                    year += 2000;
                                }
                            }
                        } else {
                            // Format: enero
                            int? month_val = ESConstants.get_month (match.fetch (9));
                            if (month_val == null) {
                                return null;
                            }
                            month = month_val;
                        }
                    }
                }
                
                if (year < 1000 && year >= 100) {
                    return null;
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
