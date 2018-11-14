public class Objects.Task {
    public int id;
    public int checked;
    public int project_id;
    public int list_id;
    public int task_order;
    public int is_inbox;
    public int has_reminder;
    public int sidebar_width;
    public int was_notified;
    public string content;
    public string note;
    public string when_date_utc;
    public string reminder_time;
    public string labels;
    public string checklist;

    public Task (int id = 0,
                 int checked = 0,
                 int project_id = 0,
                 int list_id = 0,
                 int task_order = 0,
                 int is_inbox = 0,
                 int has_reminder = 0,
                 int sidebar_width = 0,
                 int was_notified = 0,
                 string content = "",
                 string note = "",
                 string when_date_utc = "",
                 string reminder_time = "",
                 string labels = "",
                 string checklist = "") {
        this.id = id;
        this.checked = checked;
        this.project_id = project_id;
        this.list_id = list_id;
        this.task_order = task_order;
        this.is_inbox = is_inbox;
        this.has_reminder = has_reminder;
        this.sidebar_width = sidebar_width;
        this.was_notified = was_notified;
        this.content = content;
        this.note = note;
        this.when_date_utc = when_date_utc;
        this.reminder_time = reminder_time;
        this.labels = labels;
        this.checklist = checklist;
    }
}
