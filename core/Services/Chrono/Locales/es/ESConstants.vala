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
    public class ESConstants : Object {
        private static Gee.HashMap<string, int>? _month_names = null;
        private static Gee.HashMap<string, TimeUnit>? _time_units = null;
        
        private static Gee.HashMap<string, int> get_month_names () {
            if (_month_names == null) {
                _month_names = new Gee.HashMap<string, int> ();
                
                // Nombres completos
                _month_names["enero"] = 1;
                _month_names["febrero"] = 2;
                _month_names["marzo"] = 3;
                _month_names["abril"] = 4;
                _month_names["mayo"] = 5;
                _month_names["junio"] = 6;
                _month_names["julio"] = 7;
                _month_names["agosto"] = 8;
                _month_names["septiembre"] = 9;
                _month_names["octubre"] = 10;
                _month_names["noviembre"] = 11;
                _month_names["diciembre"] = 12;
                
                // Abreviaciones
                _month_names["ene"] = 1;
                _month_names["feb"] = 2;
                _month_names["mar"] = 3;
                _month_names["abr"] = 4;
                _month_names["may"] = 5;
                _month_names["jun"] = 6;
                _month_names["jul"] = 7;
                _month_names["ago"] = 8;
                _month_names["sep"] = 9;
                _month_names["sept"] = 9;
                _month_names["oct"] = 10;
                _month_names["nov"] = 11;
                _month_names["dic"] = 12;
            }
            return _month_names;
        }
        
        public static int? get_month (string name) {
            string key = name.down ();
            var months = get_month_names ();
            if (months.has_key (key)) {
                return months[key];
            }
            return null;
        }
        
        private static Gee.HashMap<string, TimeUnit> get_time_units () {
            if (_time_units == null) {
                _time_units = new Gee.HashMap<string, TimeUnit> ();
                
                // Nombres completos
                _time_units["segundo"] = TimeUnit.SECOND;
                _time_units["segundos"] = TimeUnit.SECOND;
                _time_units["minuto"] = TimeUnit.MINUTE;
                _time_units["minutos"] = TimeUnit.MINUTE;
                _time_units["hora"] = TimeUnit.HOUR;
                _time_units["horas"] = TimeUnit.HOUR;
                _time_units["día"] = TimeUnit.DAY;
                _time_units["dia"] = TimeUnit.DAY;
                _time_units["días"] = TimeUnit.DAY;
                _time_units["dias"] = TimeUnit.DAY;
                _time_units["semana"] = TimeUnit.WEEK;
                _time_units["semanas"] = TimeUnit.WEEK;
                _time_units["mes"] = TimeUnit.MONTH;
                _time_units["meses"] = TimeUnit.MONTH;
                _time_units["trimestre"] = TimeUnit.QUARTER;
                _time_units["trimestres"] = TimeUnit.QUARTER;
                _time_units["año"] = TimeUnit.YEAR;
                _time_units["ano"] = TimeUnit.YEAR;
                _time_units["años"] = TimeUnit.YEAR;
                _time_units["anos"] = TimeUnit.YEAR;
                
                // Abreviaciones
                _time_units["seg"] = TimeUnit.SECOND;
                _time_units["min"] = TimeUnit.MINUTE;
                _time_units["h"] = TimeUnit.HOUR;
                _time_units["d"] = TimeUnit.DAY;
                _time_units["sem"] = TimeUnit.WEEK;
                _time_units["trim"] = TimeUnit.QUARTER;
            }
            return _time_units;
        }
        
        public static TimeUnit? get_time_unit (string name) {
            string key = name.down ();
            var units = get_time_units ();
            if (units.has_key (key)) {
                return units[key];
            }
            return null;
        }
    }
}
