public class Objects.ProjectV2 : GLib.Object {
    public int64 area_id { get; set; default = 0; }
    public int64 parent_id { get; set; default = 0; }
    public int64 id { get; set; default = 0; }
    public string name { get; set; default = ""; }
    public string note { get; set; default = ""; }
    public string due_date { get; set; default = ""; }

    public int color { get; set; default = 0; }
    public int is_todoist { get; set; default = 0; }
    public int inbox_project { get; set; default = 0; }
    public int team_inbox { get; set; default = 0; }
    public int item_order { get; set; default = 0; }
    public int is_deleted { get; set; default = 0; }
    public int is_archived { get; set; default = 0; }
    public int is_favorite { get; set; default = 0; }
    public int64 is_sync { get; set; default = 0; }
    public int shared { get; set; default = 0; }
    public int is_kanban { get; set; default = 0; }
    public int show_completed { get; set; default = 0; }
    public int sort_order { get; set; default = 0; }
    public int collapsed { get; set; default = 0; }
}

public class Objects.SectionV2 : GLib.Object {
    public int64 id { get; set; default = 0; }
    public int64 project_id { get; set; default = 0; }
    public int64 sync_id { get; set; default = 0; }
    public string name { get; set; default = ""; }
    public string note { get; set; default = ""; }
    public int item_order { get; set; default = 0; }
    public int collapsed { get; set; default = 1; }
    public int is_todoist { get; set; default = 0; }
    public int is_deleted { get; set; default = 0; }
    public int is_archived { get; set; default = 0; }
    public string date_archived { get; set; default = ""; }
    public string date_added { get; set; default = new GLib.DateTime.now_local ().to_string (); }
}

public class Objects.ItemV2 : GLib.Object {
    public int64 id { get; set; default = 0; }
    public int64 project_id { get; set; default = 0; }
    public int64 section_id { get; set; default = 0; }
    public int64 user_id { get; set; default = 0; }
    public int64 assigned_by_uid { get; set; default = 0; }
    public int64 responsible_uid { get; set; default = 0; }
    public int64 sync_id { get; set; default = 0; }
    public int64 parent_id { get; set; default = 0; }
    public int priority { get; set; default = 1; }
    public int item_order { get; set; default = 0; }
    public int day_order { get; set; default = -1; }
    public int checked { get; set; default = 0; }
    public int is_deleted { get; set; default = 0; }
    public int is_todoist { get; set; default = 0; }
    public string content { get; set; default = ""; }
    public string note { get; set; default = ""; }
    public string due_date { get; set; default = ""; }
    public string due_timezone { get; set; default = ""; }
    public string due_string { get; set; default = ""; }
    public string due_lang { get; set; default = ""; }
    public int due_is_recurring { get; set; default = 0; }
    public int collapsed { get; set; default = 0; }

    public string date_added { get; set; default = new GLib.DateTime.now_local ().to_string (); }
    public string date_completed { get; set; default = ""; }
    public string date_updated { get; set; default = new GLib.DateTime.now_local ().to_string (); }
}