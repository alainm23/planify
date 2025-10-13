namespace Chrono {
    /**
     * English casual time expressions parser
     * 
     * Supports: morning, afternoon, evening, night, midnight, midday, noon
     * With optional "this" prefix
     */
    public class ENCasualTimeParser : Object {
        private Regex casual_time_regex;
        
        public ENCasualTimeParser () {
            try {
                casual_time_regex = new Regex (
                    "(?:this)?\\s{0,3}(morning|afternoon|evening|night|midnight|midday|noon)(?=\\W|$)",
                    RegexCompileFlags.CASELESS
                );
            } catch (Error e) {
                warning ("Error creating casual time regex: %s", e.message);
            }
        }
        
        public ParseResult? parse (string text) {
            try {
                MatchInfo match;
                if (!casual_time_regex.match (text, 0, out match)) {
                    return null;
                }
                
                string keyword = match.fetch (1).down ();
                var now = new DateTime.now_local ();
                int hour;
                
                switch (keyword) {
                    case "morning":
                        hour = 9;
                        break;
                    case "afternoon":
                        hour = 14;
                        break;
                    case "evening":
                        hour = 18;
                        break;
                    case "night":
                        hour = 20;
                        break;
                    case "midnight":
                        hour = 0;
                        break;
                    case "midday":
                    case "noon":
                        hour = 12;
                        break;
                    default:
                        return null;
                }
                
                var result = new ParseResult ();
                result.date = new DateTime.local (
                    now.get_year (),
                    now.get_month (),
                    now.get_day_of_month (),
                    hour, 0, 0
                );
                
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
