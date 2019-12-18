public class Objects.Reminder : GLib.Object {
    public int64 id { get; set; default = Planner.utils.generate_id (); }
    public int64 notify_uid { get; set; default = 0; }
    public int64 item_id { get; set; default = 0; }
    public int64 project_id { get; set; default = 0; }

    public string service { get; set; default = "push"; }
    //public string type { get; set; default = "relative"; }
    public string due_date { get; set; default = ""; }
    public string due_timezone { get; set; default = ""; }
    public string due_string { get; set; default = ""; }
    public string due_lang { get; set; default = "en"; }
    public string content { get; set; default = ""; }
    
    public int due_is_recurring { get; set; default = 0; }
    public int mm_offset { get; set; default = 180; }
    public int is_deleted { get; set; default = 0; }
    public int is_todoist { get; set; default = 0; }

    private GLib.DateTime _datetime;
    public GLib.DateTime datetime {
        get {
            _datetime = new GLib.DateTime.from_iso8601 (due_date, new GLib.TimeZone.local ());
            return _datetime;
        }
    }

    public string _project_name;
    public string project_name {
        get {
            _project_name = Planner.database.get_project_by_id (project_id).name;
            return _project_name;
        }
    }
}