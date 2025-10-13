namespace Chrono {
    public enum RecurrenceType {
        DAILY,
        WEEKLY,
        MONTHLY,
        YEARLY
    }
    
    public class RecurrenceRule : Object {
        public RecurrenceType recurrence_type { get; set; }
        public int interval { get; set; default = 1; }
        public Gee.ArrayList<int>? days_of_week { get; set; }
        public int? day_of_month { get; set; }
        public int? month_of_year { get; set; }
        public int? hour { get; set; }
        public bool? last_day { get; set; }
        
        public RecurrenceRule (RecurrenceType recurrence_type) {
            this.recurrence_type = recurrence_type;
        }
    }
}
