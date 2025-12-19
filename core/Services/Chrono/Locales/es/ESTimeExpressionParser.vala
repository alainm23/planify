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
     * Spanish time expression parser
     * 
     * Supports: en 5 minutos, en 2 horas, en 3 días, dentro de 5 minutos
     */
    public class ESTimeExpressionParser : Object {
        private Regex time_expr_regex;
        
        public ESTimeExpressionParser () {
            try {
                time_expr_regex = new Regex (
                    "(?:en|dentro\\s+de)\\s+(\\d+)\\s+(segundo|segundos|minuto|minutos|hora|horas|día|dia|días|dias|semana|semanas|mes|meses|trimestre|trimestres|año|ano|años|anos|seg|min|h|d|sem|trim)",
                    RegexCompileFlags.CASELESS
                );
            } catch (Error e) {
                warning ("Error creating time expression regex: %s", e.message);
            }
        }
        
        public ParseResult? parse (string text) {
            try {
                MatchInfo match;
                if (!time_expr_regex.match (text, 0, out match)) {
                    return null;
                }
                
                int amount = int.parse (match.fetch (1));
                string unit_str = match.fetch (2);
                
                TimeUnit? time_unit = ESConstants.get_time_unit (unit_str);
                if (time_unit == null) {
                    return null;
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
            switch (unit) {
                case TimeUnit.SECOND:
                    return date.add_seconds (amount);
                case TimeUnit.MINUTE:
                    return date.add_minutes (amount);
                case TimeUnit.HOUR:
                    return date.add_hours (amount);
                case TimeUnit.DAY:
                    return date.add_days (amount);
                case TimeUnit.WEEK:
                    return date.add_weeks (amount);
                case TimeUnit.MONTH:
                    return date.add_months (amount);
                case TimeUnit.QUARTER:
                    return date.add_months (amount * 3);
                case TimeUnit.YEAR:
                    return date.add_years (amount);
                default:
                    return date;
            }
        }
    }
}
