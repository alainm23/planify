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
     * Spanish relative date format parser
     * 
     * Supports: esta semana, el mes pasado, el próximo año, la semana que viene
     */
    public class ESRelativeDateFormatParser : Object {
        private Regex relative_regex;
        
        public ESRelativeDateFormatParser () {
            try {
                relative_regex = new Regex (
                    "(?:el|la)?\\s*(?:próximo|proximo|próxima|proxima|siguiente|pasado|pasada|que\\s+viene)\\s+(segundo|segundos|minuto|minutos|hora|horas|día|dia|días|dias|semana|semanas|mes|meses|trimestre|trimestres|año|ano|años|anos)|" +
                    "(?:el|la)?\\s*(segundo|segundos|minuto|minutos|hora|horas|día|dia|días|dias|semana|semanas|mes|meses|trimestre|trimestres|año|ano|años|anos)\\s+(?:próximo|proximo|próxima|proxima|siguiente|pasado|pasada|que\\s+viene)|" +
                    "(?:este|esta)\\s+(segundo|segundos|minuto|minutos|hora|horas|día|dia|días|dias|semana|semanas|mes|meses|trimestre|trimestres|año|ano|años|anos)",
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
                
                string full_match = match.fetch (0).down ();
                string? unit_str = null;
                int amount = 0;
                
                // Try to get unit from different capture groups
                for (int i = 1; i <= 3; i++) {
                    string? temp = match.fetch (i);
                    if (temp != null && temp.length > 0) {
                        unit_str = temp;
                        break;
                    }
                }
                
                if (unit_str == null) {
                    return null;
                }
                
                TimeUnit? time_unit = ESConstants.get_time_unit (unit_str);
                if (time_unit == null) {
                    return null;
                }
                
                // Determine direction based on keywords
                if (full_match.contains ("próximo") || full_match.contains ("proximo") || 
                    full_match.contains ("próxima") || full_match.contains ("proxima") ||
                    full_match.contains ("siguiente") || full_match.contains ("que viene")) {
                    amount = 1;
                } else if (full_match.contains ("pasado") || full_match.contains ("pasada")) {
                    amount = -1;
                } else if (full_match.contains ("este") || full_match.contains ("esta")) {
                    amount = 0;
                }
                
                var now = new DateTime.now_local ();
                DateTime date = add_time_unit (now, time_unit, amount);
                
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
