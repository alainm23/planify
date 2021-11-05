public class Objects.Project : GLib.Object {
    public int64 id { get; set; default = 0; }
    public string name { get; set; default = ""; }
    public string note { get; set; default = ""; }
    public string due_date { get; set; default = ""; }
    public int color { get; set; default = 0; }
    public int is_todoist { get; set; default = 0; }
    public int inbox_project { get; set; default = 0; }
    public int team_inbox { get; set; default = 0; }
    public int child_order { get; set; default = 0; }
    public int is_deleted { get; set; default = 0; }
    public int is_archived { get; set; default = 0; }
    public int is_favorite { get; set; default = 0; }
    public int shared { get; set; default = 0; }
    public int is_kanban { get; set; default = 0; }
    public int show_completed { get; set; default = 0; }
    public int sort_order { get; set; default = 0; }
    public int collapsed { get; set; default = 0; }
    public int64 parent_id { get; set; default = 0; }

    public Project.from_json (Json.Node node) {
        id = node.get_object ().get_int_member ("id");
        name = node.get_object ().get_string_member ("name");
        color = (int32) node.get_object ().get_int_member ("color");
        is_deleted = (int32) node.get_object ().get_int_member ("is_deleted");
        is_archived = (int32) node.get_object ().get_int_member ("is_archived");
        is_favorite = (int32) node.get_object ().get_int_member ("is_favorite");
        child_order = (int32) node.get_object ().get_int_member ("child_order");
        is_todoist = 1;

        if (!node.get_object ().get_null_member ("parent_id")) {
            parent_id = node.get_object ().get_int_member ("parent_id");
        }

        if (node.get_object ().has_member ("team_inbox") && node.get_object ().get_boolean_member ("team_inbox")) {
            team_inbox = 1;
        } else {
            team_inbox = 0;
        }

        if (node.get_object ().has_member ("inbox_project") && node.get_object ().get_boolean_member ("inbox_project")) {
            inbox_project = 1;
        } else {
            inbox_project = 0;
        }

        if (node.get_object ().get_boolean_member ("shared")) {
            shared = 1;
        } else {
            shared = 0;
        }
    }
}