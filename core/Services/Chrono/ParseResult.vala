namespace Chrono {
    public class ParseResult : Object {
        public DateTime? date { get; set; }
        public RecurrenceRule? recurrence { get; set; }
        public int start_index { get; set; }
        public int end_index { get; set; }
        public string matched_text { get; set; }
        
        public ParseResult () {
            start_index = -1;
            end_index = -1;
            matched_text = "";
        }
    }
}
