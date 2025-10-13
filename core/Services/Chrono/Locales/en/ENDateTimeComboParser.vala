namespace Chrono {
    /**
     * English date + time combination parser
     * 
     * Supports: tomorrow at 3pm, Monday at 9am, March 15 at 14:30
     */
    public class ENDateTimeComboParser : Object {
        private Regex combo_regex;
        private ENCasualDateParser casual_parser;
        private ENMonthNameParser month_parser;
        private TimeParser time_parser;
        
        public ENDateTimeComboParser () {
            casual_parser = new ENCasualDateParser ();
            month_parser = new ENMonthNameParser ();
            time_parser = new TimeParser ();
            
            try {
                // Match: [date expression] at [time expression]
                combo_regex = new Regex (
                    "(.+?)\\s+at\\s+(.+)",
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
                if (date_result == null) {
                    date_result = month_parser.parse (date_part);
                }
                
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
