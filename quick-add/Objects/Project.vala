public class Objects.Project : GLib.Object {
    public int64 id { get; set; default = Constants.INACTIVE; }
    public int64 parent_id { get; set; default = 0; }
    public string due_date { get; set; default = ""; }
    public string name { get; set; default = ""; }
    public string color { get; set; default = ""; }
    public string emoji { get; set; default = ""; }
    public ProjectViewStyle view_style { get; set; default = ProjectViewStyle.LIST; }
    public ProjectIconStyle icon_style { get; set; default = ProjectIconStyle.PROGRESS; }
    public bool todoist { get; set; default = false; }
    public bool inbox_project { get; set; default = false; }
    public bool team_inbox { get; set; default = false; }
    public bool is_deleted { get; set; default = false; }
    public bool is_archived { get; set; default = false; }
    public bool is_favorite { get; set; default = false; }
    public bool shared { get; set; default = false; }
    public bool collapsed { get; set; default = false; }

    string _id_string;
    public string id_string {
        get {
            _id_string = id.to_string ();
            return _id_string;
        }
    }

    public int sort_order { get; set; default = 0; }
    public int child_order { get; set; default = 0; }
    
    string _view_id;
    public string view_id {
        get {
            _view_id ="project-%s".printf (id_string);
            return _view_id;
        }
    }

    string _parent_id_string;
    public string parent_id_string {
        get {
            _parent_id_string = parent_id.to_string ();
            return _parent_id_string;
        }
    }

    string _short_name;
    public string short_name {
        get {
            _short_name = QuickAddUtil.get_short_name (name);
            return _short_name;
        }
    }
}
