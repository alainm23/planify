namespace Chrono {
    /**
     * English time expression parser
     * 
     * Supports: in 5 minutes, in 2 hours, in 3 days, 5 minutes from now
     */
    public class ENTimeExpressionParser : Object {
        private Regex time_expr_regex;
        
        public ENTimeExpressionParser () {
            try {
                time_expr_regex = new Regex (
                    "(?:in|within)\\s+(\\d+)\\s+(second|seconds|minute|minutes|hour|hours|day|days|week|weeks|month|months|year|years|s|sec|m|min|mins|h|hr|hrs|d|w|mo|mon|mos|y|yr)|" +
                    "(\\d+)\\s+(second|seconds|minute|minutes|hour|hours|day|days|week|weeks|month|months|year|years|s|sec|m|min|mins|h|hr|hrs|d|w|mo|mon|mos|y|yr)\\s+(?:from\\s+now|later)",
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
                
                int amount;
                string unit_str;
                
                // Format: in X units
                string? amount_str = match.fetch (1);
                if (amount_str != null && amount_str.length > 0) {
                    amount = int.parse (amount_str);
                    unit_str = match.fetch (2);
                } else {
                    // Format: X units from now / later
                    amount = int.parse (match.fetch (3));
                    unit_str = match.fetch (4);
                }
                
                TimeUnit? time_unit = ENConstants.get_time_unit (unit_str);
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
