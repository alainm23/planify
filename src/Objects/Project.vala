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

    public string _id_string;
    public string id_string {
        get {
            _id_string = id.to_string ();
            return _id_string;
        }
    }

    public string _view_id;
    public string view_id {
        get {
            _view_id ="project-%s".printf (id_string);
            return _view_id;
        }
    }

     public string _parent_id_string;
    public string parent_id_string {
        get {
            _parent_id_string = parent_id.to_string ();
            return _parent_id_string;
        }
    }

    private uint update_timeout_id { get; set; default = 0; }

    // Gee.ArrayList<Objects.Label> _childs = null;
    // public Gee.ArrayList<Objects.Label> childs {
    //     get {
    //         if (_childs == null) {
    //             _childs = get_projects_childs_collection (this);
    //         }
    //         return _childs;
    //     }
    // }

    public signal void deleted ();
    public signal void updated ();

    construct {
        deleted.connect (() => {
            Planner.database.project_deleted (this);
        });
    }

    public Project.from_json (Json.Node node) {
        id = node.get_object ().get_int_member ("id");
        update_from_json (node);
        is_todoist = 1;
    }

    public void update_from_json (Json.Node node) {
        name = node.get_object ().get_string_member ("name");

        if (!node.get_object ().get_null_member ("color")) {
            color = (int32) node.get_object ().get_int_member ("color");
        }
        
        if (!node.get_object ().get_null_member ("is_deleted")) {
            is_deleted = (int32) node.get_object ().get_int_member ("is_deleted");
        }
        
        if (!node.get_object ().get_null_member ("is_archived")) {
            is_archived = (int32) node.get_object ().get_int_member ("is_archived");
        }
        
        if (!node.get_object ().get_null_member ("is_favorite")) {
            is_favorite = (int32) node.get_object ().get_int_member ("is_favorite");
        }
        
        if (!node.get_object ().get_null_member ("child_order")) {
            child_order = (int32) node.get_object ().get_int_member ("child_order");
        }
        
        if (!node.get_object ().get_null_member ("parent_id")) {
            parent_id = node.get_object ().get_int_member ("parent_id");
        } else {
            parent_id = 0;
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

    public void update (bool todoist=true) {
        if (update_timeout_id != 0) {
            Source.remove (update_timeout_id);
        }

        update_timeout_id = Timeout.add (500, () => {
            update_timeout_id = 0;

            Planner.database.update_project (this);
            if (is_todoist == 1 && todoist) {
                Planner.todoist.update_project.begin (this, (obj, res) => {
                    Planner.todoist.update_project.end (res);
                });
            }

            return GLib.Source.REMOVE;
        });
    }

    public string get_add_json (string temp_id, string uuid) {
        var builder = new Json.Builder ();
        builder.begin_array ();
        builder.begin_object ();

        builder.set_member_name ("type");
        builder.add_string_value ("project_add");

        builder.set_member_name ("temp_id");
        builder.add_string_value (temp_id);

        builder.set_member_name ("uuid");
        builder.add_string_value (uuid);

        builder.set_member_name ("args");
            builder.begin_object ();

            builder.set_member_name ("name");
            builder.add_string_value (Util.get_default ().get_encode_text (name));

            builder.set_member_name ("color");
            builder.add_int_value (color);

            builder.end_object ();
        builder.end_object ();
        builder.end_array ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);

        return generator.to_data (null);
    }

    public string get_update_json (string uuid) {
        var builder = new Json.Builder ();
        builder.begin_array ();
        builder.begin_object ();

        // Set type
        builder.set_member_name ("type");
        builder.add_string_value ("project_update");

        builder.set_member_name ("uuid");
        builder.add_string_value (uuid);

        builder.set_member_name ("args");
            builder.begin_object ();

            builder.set_member_name ("id");
            builder.add_int_value (id);

            builder.set_member_name ("name");
            builder.add_string_value (Util.get_default ().get_encode_text (name));

            builder.set_member_name ("color");
            builder.add_int_value (color);

            builder.set_member_name ("collapsed");
            builder.add_int_value (collapsed);

            builder.end_object ();
        builder.end_object ();
        builder.end_array ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);

        return generator.to_data (null);
    }
}
