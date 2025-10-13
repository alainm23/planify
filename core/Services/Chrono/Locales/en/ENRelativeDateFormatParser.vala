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
