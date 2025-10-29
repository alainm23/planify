namespace Chrono {
    public class Chrono : Object {
        private Parser parser;
        
        public Chrono () {
            parser = new Parser ();
        }
        
        public ParseResult? parse (string text, string language = "en") {
            return parser.parse (text, language);
        }
    }
}
