namespace Chrono {
    /**
     * English casual date expressions parser
     * 
     * Supports: now, today, tonight, tomorrow, overmorrow, tmr, tmrw, yesterday, last night
     */
    public class ENCasualDateParser : Object {
        private Regex casual_regex;
        
        public ENCasualDateParser () {
            try {
                casual_regex = new Regex (
                    "\\b(now|today|tonight|tomorrow|overmorrow|tmr|tmrw|yesterday|last\\s*night)\\b",
                    RegexCompileFlags.CASELESS
                );
            } catch (Error e) {
                warning ("Error creating casual date regex: %s", e.message);
            }
        }
        
        public ParseResult? parse (string text) {
            try {
                MatchInfo match;
                if (!casual_regex.match (text, 0, out match)) {
                    return null;
                }
                
                string keyword = match.fetch (1).down ().replace (" ", "");
                var now = new DateTime.now_local ();
                DateTime date;
                
                switch (keyword) {
                    case "now":
                    case "today":
                        date = now;
                        break;
                    case "tonight":
                        date = new DateTime.local (
                            now.get_year (),
                            now.get_month (),
                            now.get_day_of_month (),
                            20, 0, 0
                        );
                        break;
                    case "tomorrow":
                    case "tmr":
                    case "tmrw":
                        date = now.add_days (1);
                        break;
                    case "overmorrow":
                        date = now.add_days (2);
                        break;
                    case "yesterday":
                        date = now.add_days (-1);
                        break;
                    case "lastnight":
                        date = new DateTime.local (
                            now.get_year (),
                            now.get_month (),
                            now.get_day_of_month (),
                            20, 0, 0
                        ).add_days (-1);
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
    }
}
