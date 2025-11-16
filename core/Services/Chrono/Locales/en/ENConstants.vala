namespace Chrono {
    public enum TimeUnit {
        SECOND,
        MINUTE,
        HOUR,
        DAY,
        WEEK,
        MONTH,
        QUARTER,
        YEAR
    }
    
    public class ENConstants : Object {
        private static Gee.HashMap<string, int>? _month_names = null;
        private static Gee.HashMap<string, TimeUnit>? _time_units = null;
        
        private static Gee.HashMap<string, int> get_month_names () {
            if (_month_names == null) {
                _month_names = new Gee.HashMap<string, int> ();
                
                // Full month names
                _month_names["january"] = 1;
                _month_names["february"] = 2;
                _month_names["march"] = 3;
                _month_names["april"] = 4;
                _month_names["may"] = 5;
                _month_names["june"] = 6;
                _month_names["july"] = 7;
                _month_names["august"] = 8;
                _month_names["september"] = 9;
                _month_names["october"] = 10;
                _month_names["november"] = 11;
                _month_names["december"] = 12;
                
                // Abbreviations
                _month_names["jan"] = 1;
                _month_names["feb"] = 2;
                _month_names["mar"] = 3;
                _month_names["apr"] = 4;
                _month_names["jun"] = 6;
                _month_names["jul"] = 7;
                _month_names["aug"] = 8;
                _month_names["sep"] = 9;
                _month_names["sept"] = 9;
                _month_names["oct"] = 10;
                _month_names["nov"] = 11;
                _month_names["dec"] = 12;
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
                
                // Abbreviations
                _time_units["s"] = TimeUnit.SECOND;
                _time_units["sec"] = TimeUnit.SECOND;
                _time_units["m"] = TimeUnit.MINUTE;
                _time_units["min"] = TimeUnit.MINUTE;
                _time_units["mins"] = TimeUnit.MINUTE;
                _time_units["h"] = TimeUnit.HOUR;
                _time_units["hr"] = TimeUnit.HOUR;
                _time_units["hrs"] = TimeUnit.HOUR;
                _time_units["d"] = TimeUnit.DAY;
                _time_units["w"] = TimeUnit.WEEK;
                _time_units["mo"] = TimeUnit.MONTH;
                _time_units["mon"] = TimeUnit.MONTH;
                _time_units["mos"] = TimeUnit.MONTH;
                _time_units["qtr"] = TimeUnit.QUARTER;
                _time_units["y"] = TimeUnit.YEAR;
                _time_units["yr"] = TimeUnit.YEAR;
                
                // Full names
                _time_units["second"] = TimeUnit.SECOND;
                _time_units["seconds"] = TimeUnit.SECOND;
                _time_units["minute"] = TimeUnit.MINUTE;
                _time_units["minutes"] = TimeUnit.MINUTE;
                _time_units["hour"] = TimeUnit.HOUR;
                _time_units["hours"] = TimeUnit.HOUR;
                _time_units["day"] = TimeUnit.DAY;
                _time_units["days"] = TimeUnit.DAY;
                _time_units["week"] = TimeUnit.WEEK;
                _time_units["weeks"] = TimeUnit.WEEK;
                _time_units["month"] = TimeUnit.MONTH;
                _time_units["months"] = TimeUnit.MONTH;
                _time_units["quarter"] = TimeUnit.QUARTER;
                _time_units["quarters"] = TimeUnit.QUARTER;
                _time_units["year"] = TimeUnit.YEAR;
                _time_units["years"] = TimeUnit.YEAR;
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
