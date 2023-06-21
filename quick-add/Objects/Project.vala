public class Objects.Project : Objects.BaseObject {
    public int64 parent_id { get; set; default = 0; }
    public string due_date { get; set; default = ""; }
    public string color { get; set; default = ""; }
    public string emoji { get; set; default = ""; }
    public string description { get; set; default = ""; }
    public ProjectIconStyle icon_style { get; set; default = ProjectIconStyle.PROGRESS; }
    public BackendType backend_type { get; set; default = BackendType.NONE; }
    public bool inbox_project { get; set; default = false; }
    public bool team_inbox { get; set; default = false; }
    public bool is_deleted { get; set; default = false; }
    public bool is_archived { get; set; default = false; }
    public bool is_favorite { get; set; default = false; }
    public bool shared { get; set; default = false; }
    public bool collapsed { get; set; default = false; }
    
    ProjectViewStyle _view_style = ProjectViewStyle.LIST;
    public ProjectViewStyle view_style {
        get {
            return _view_style;
        }

        set {
            _view_style = value;
        }
    }
    
    public int child_order { get; set; default = 0; }
    
    public bool is_inbox_project {
        get {
            return id == Services.Settings.get_default ().settings.get_string ("inbox-project-id");
        }
    }
    
    construct {}
}