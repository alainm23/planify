public class Objects.Backup : Object {
    public string version { get; set; default = ""; }
    public string date { get; set; default = new GLib.DateTime.now_local ().to_string (); }

    public int default_inbox { get; set; default = 0; }
    public string local_inbox_project_id { get; set; default = ""; }
    public string todoist_access_token { get; set; default = ""; }
    public string todoist_sync_token { get; set; default = ""; }
    public string todoist_user_name { get; set; default = ""; }
    public string todoist_user_email { get; set; default = ""; }
    public string todoist_user_image_id { get; set; default = ""; }
    public string todoist_user_avatar { get; set; default = ""; }
    public bool todoist_user_is_premium { get; set; default = false; }

    public Gee.ArrayList<Objects.Project> projects { get; set; default = new Gee.ArrayList<Objects.Project> (); }
    public Gee.ArrayList<Objects.Section> sections { get; set; default = new Gee.ArrayList<Objects.Section> (); }
    public Gee.ArrayList<Objects.Item> items { get; set; default = new Gee.ArrayList<Objects.Item> (); }
    public Gee.ArrayList<Objects.Label> labels { get; set; default = new Gee.ArrayList<Objects.Label> (); }

    public string path { get; set; }
    public string error { get; set; default = ""; }

    GLib.DateTime _datetime;
    public GLib.DateTime datetime {
        get {
            _datetime = new GLib.DateTime.from_iso8601 (date, new GLib.TimeZone.local ());
            return _datetime;
        }
    }

    private string _title;
    public string title {
        get {
            _title = datetime.format ("%c");
            return _title;
        }
    }

    private bool _todoist_backend;
    public bool todoist_backend {
        get {
            _todoist_backend = todoist_access_token.strip () != "";
            return _todoist_backend;
        }
    }
    public bool google_backend { get; set; default = false; }

    public Backup.from_file (File file) {
        var parser = new Json.Parser ();

        try {
            parser.load_from_file (file.get_path ());
            path = file.get_path ();

            var node = parser.get_root ().get_object ();
            
            version = node.get_string_member ("version");
            date = node.get_string_member ("date");
    
            // Set Settings
            var settings = node.get_object_member ("settings");
            local_inbox_project_id = settings.get_string_member ("local-inbox-project-id");
            todoist_access_token = settings.get_string_member ("todoist-access-token");
            todoist_sync_token = settings.get_string_member ("todoist-sync-token");
            todoist_user_name = settings.get_string_member ("todoist-user-name");
            todoist_user_email = settings.get_string_member ("todoist-user-email");
            todoist_user_image_id = settings.get_string_member ("todoist-user-image-id");
            todoist_user_avatar = settings.get_string_member ("todoist-user-avatar");
            todoist_user_is_premium = settings.get_boolean_member ("todoist-user-is-premium");
            
            // Labels
            labels.clear ();
            unowned Json.Array _labels = node.get_array_member ("labels");
            foreach (unowned Json.Node item in _labels.get_elements ()) {
                labels.add (new Objects.Label.from_import_json (item));
            }
                
            // Projects
            projects.clear ();
            unowned Json.Array _projects = node.get_array_member ("projects");
            foreach (unowned Json.Node item in _projects.get_elements ()) {
                projects.add (new Objects.Project.from_import_json (item));
            }
                
            // Sections
            sections.clear ();
            unowned Json.Array _sections = node.get_array_member ("sections");
            foreach (unowned Json.Node item in _sections.get_elements ()) {
                sections.add (new Objects.Section.from_import_json (item));
            }
                
            // Items
            items.clear ();
            unowned Json.Array _items = node.get_array_member ("items");
            foreach (unowned Json.Node item in _items.get_elements ()) {
                items.add (new Objects.Item.from_import_json (item));
            }
        } catch (Error e) {
            error = e.message;
        }
    }

    public bool valid () {
        if (error != "") {
            return false;
        }

        if (version == null || version == "") {
            return false;
        }

        if (date == null || date == "") {
            return false;
        }

        if (projects.is_empty) {
            return false;
        }

        return true;
    }
}
