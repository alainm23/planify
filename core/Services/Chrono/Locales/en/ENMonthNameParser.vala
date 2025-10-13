namespace Chrono {
    /**
     * English month name parser
     * 
     * Supports: 15 March, March 15, 15 Mar 2024, Mar 15 2024, January 2012, January, Jan
     */
    public class ENMonthNameParser : Object {
        private Regex month_regex;
        
        public ENMonthNameParser () {
            try {
                month_regex = new Regex (
                    "(\\d{1,2})\\s+(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|jun|jul|aug|sep|sept|oct|nov|dec)(?:\\s+(\\d{2,4}))?|" +
                    "(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|jun|jul|aug|sep|sept|oct|nov|dec)(?:,?\\s+(\\d{4}))|" +
                    "(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|jun|jul|aug|sep|sept|oct|nov|dec)\\s+(\\d{1,2})(?:,?\\s+(\\d{2,4}))?|" +
                    "(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|jun|jul|aug|sep|sept|oct|nov|dec)",
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
                
                // Format: 15 March or 15 March 2024
                string? day_str = match.fetch (1);
                if (day_str != null && day_str.length > 0) {
                    day = int.parse (day_str);
                    int? month_val = ENConstants.get_month (match.fetch (2));
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
                        // Format: January 2012
                        int? month_val = ENConstants.get_month (month_str);
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
                            // Format: March 15 or March 15, 2024
                            int? month_val = ENConstants.get_month (month_str);
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
                            // Format: January
                            int? month_val = ENConstants.get_month (match.fetch (9));
                            if (month_val == null) {
                                return null;
                            }
                            month = month_val;
                        }
                    }
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
