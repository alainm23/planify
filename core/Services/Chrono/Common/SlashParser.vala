namespace Chrono {
    public class SlashParser : Object {
        private Regex slash_regex;

        //  Date format with slash "/" (or dot ".") between numbers.
        //  For examples:
        //   - 7/10
        //  - 7/12/2020
        //  - 7.12.2020
        
        public SlashParser () {
            try {
                // Matches: d/m, d/m/y, d.m, d.m.y
                slash_regex = new Regex (
                    "(\\d{1,2})[/\\.](\\d{1,2})(?:[/\\.](\\d{2,4}))?",
                    RegexCompileFlags.CASELESS
                );
            } catch (Error e) {
                warning ("Error creating slash regex: %s", e.message);
            }
        }
        
        public ParseResult? parse (string text) {
            try {
                MatchInfo match;
                if (!slash_regex.match (text, 0, out match)) {
                    return null;
                }
                
                int day = int.parse (match.fetch (1));
                int month = int.parse (match.fetch (2));
                
                var now = new DateTime.now_local ();
                int year = now.get_year ();
                
                string? year_str = match.fetch (3);
                if (year_str != null && year_str.length > 0) {
                    year = int.parse (year_str);
                    if (year < 100) {
                        year += 2000;
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
