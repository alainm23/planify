namespace Chrono {
    public class Parser : Object {
        private Gee.HashMap<string, LanguageParser> language_parsers;
        
        public Parser () {
            language_parsers = new Gee.HashMap<string, LanguageParser> ();
            register_language ("en", new EnglishParser ());
        }
        
        public void register_language (string code, LanguageParser parser) {
            language_parsers[code] = parser;
        }
        
        public ParseResult? parse (string text, string language) {
            if (!language_parsers.has_key (language)) {
                return null;
            }
            
            return language_parsers[language].parse (text);
        }
    }
}
