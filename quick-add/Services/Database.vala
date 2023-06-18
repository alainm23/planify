public class Services.Database : GLib.Object {
    private Sqlite.Database db;
    private string db_path;
    private string sql;

    public signal void opened ();
    public signal void reset ();

    private static Database? _instance;
    public static Database get_default () {
        if (_instance == null) {
            _instance = new Database ();
        }

        return _instance;
    }

    Gee.ArrayList<Objects.Project> _projects = null;
    public Gee.ArrayList<Objects.Project> projects {
        get {
            if (_projects == null) {
                _projects = get_projects_collection ();
            }
            return _projects;
        }
    }

    construct {
        db_path = Environment.get_user_data_dir () + "/io.github.alainm23.planify/database.db";
        Sqlite.Database.open (db_path, out db);
    }

    public bool is_database_empty () {
        return projects.size <= 0;
    }

    /*
        Projects
    */

    public Gee.ArrayList<Objects.Project> get_projects_collection () {
        Gee.ArrayList<Objects.Project> return_value = new Gee.ArrayList<Objects.Project> ();

        Sqlite.Statement stmt;
        
        sql = """
            SELECT * FROM Projects WHERE is_deleted = 0 ORDER BY child_order;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);

        while (stmt.step () == Sqlite.ROW) {
            return_value.add (_fill_project (stmt));
        }
        stmt.reset ();
        return return_value;
    }

    public Objects.Project _fill_project (Sqlite.Statement stmt) {
        Objects.Project return_value = new Objects.Project ();
        return_value.id = stmt.column_text (0);
        return_value.name = stmt.column_text (1);
        return_value.color = stmt.column_text (2);
        return_value.backend_type = get_backend_type_by_text (stmt, 3);
        return_value.inbox_project = get_parameter_bool (stmt, 4);
        return_value.team_inbox = get_parameter_bool (stmt, 5);
        return_value.child_order = stmt.column_int (6);
        return_value.is_deleted = get_parameter_bool (stmt, 7);
        return_value.is_archived = get_parameter_bool (stmt, 8);
        return_value.is_favorite = get_parameter_bool (stmt, 9);
        return_value.shared = get_parameter_bool (stmt, 10);
        return_value.view_style = get_view_style_by_text (stmt, 11);
        return_value.parent_id = stmt.column_int64 (13);
        return_value.collapsed = get_parameter_bool (stmt, 14);
        return_value.icon_style = get_icon_style_by_text (stmt, 15);
        return_value.emoji = stmt.column_text (16);
        return_value.description = stmt.column_text (18);
        return_value.due_date = stmt.column_text (19);
        return return_value;
    }

    private ProjectViewStyle get_view_style_by_text (Sqlite.Statement stmt, int col) {
        if (stmt.column_text (col) == "board") {
            return ProjectViewStyle.BOARD;
        }

        return ProjectViewStyle.LIST;
    }

    private ProjectIconStyle get_icon_style_by_text (Sqlite.Statement stmt, int col) {
        if (stmt.column_text (col) == "emoji") {
            return ProjectIconStyle.EMOJI;
        }

        return ProjectIconStyle.PROGRESS;
    }

    private BackendType get_backend_type_by_text (Sqlite.Statement stmt, int col) {
        if (stmt.column_text (col) == "local") {
            return BackendType.LOCAL;
        } else if (stmt.column_text (col) == "todoist") {
            return BackendType.TODOIST;
        } else if (stmt.column_text (col) == "caldav") {
            return BackendType.CALDAV;
        } else {
            return BackendType.NONE;
        }
    }

    public Objects.Project get_project (string id) {
        Objects.Project? return_value = null;
        lock (_projects) {
            foreach (var project in projects) {
                if (project.id == id) {
                    return_value = project;
                    break;
                }
            }

            return return_value;
        }
    }

    /*
        Items
    */

    public bool insert_item (Objects.Item item) {
        Sqlite.Statement stmt;

        sql = """
            INSERT OR IGNORE INTO Items (id, content, description, due, added_at, completed_at,
                updated_at, section_id, project_id, parent_id, priority, child_order,
                checked, is_deleted, day_order, collapsed, pinned)
            VALUES ($id, $content, $description, $due, $added_at, $completed_at,
                $updated_at, $section_id, $project_id, $parent_id, $priority, $child_order,
                $checked, $is_deleted, $day_order, $collapsed, $pinned);
        """;

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_str (stmt, "$id", item.id);
        set_parameter_str (stmt, "$content", item.content);
        set_parameter_str (stmt, "$description", item.description);
        set_parameter_str (stmt, "$due", item.due.to_string ());
        set_parameter_str (stmt, "$added_at", item.added_at);
        set_parameter_str (stmt, "$completed_at", item.completed_at);
        set_parameter_str (stmt, "$updated_at", item.updated_at);
        set_parameter_str (stmt, "$section_id", item.section_id);
        set_parameter_str (stmt, "$project_id", item.project_id);
        set_parameter_str (stmt, "$parent_id", item.parent_id);
        set_parameter_int (stmt, "$priority", item.priority);
        set_parameter_int (stmt, "$child_order", item.child_order);
        set_parameter_bool (stmt, "$checked", item.checked);
        set_parameter_bool (stmt, "$is_deleted", item.is_deleted);
        set_parameter_int (stmt, "$day_order", item.day_order);
        set_parameter_bool (stmt, "$collapsed", item.collapsed);
        set_parameter_bool (stmt, "$pinned", item.pinned);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }

        stmt.reset ();
        return stmt.step () == Sqlite.DONE;
    }

    /*
     * Queue
     */

    public void insert_queue (Objects.Queue queue) {
        Sqlite.Statement stmt;

        sql = """
            INSERT OR IGNORE INTO Queue (uuid, object_id, query, temp_id, args, date_added)
            VALUES ($uuid, $object_id, $query, $temp_id, $args, $date_added);
        """;

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_str (stmt, "$uuid", queue.uuid);
        set_parameter_str (stmt, "$object_id", queue.object_id);
        set_parameter_str (stmt, "$query", queue.query);
        set_parameter_str (stmt, "$temp_id", queue.temp_id);
        set_parameter_str (stmt, "$args", queue.args);
        set_parameter_str (stmt, "$date_added", queue.date_added);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }

        stmt.reset ();
    }

    public Gee.ArrayList<Objects.Queue> get_all_queue () {
        Gee.ArrayList<Objects.Queue> return_value = new Gee.ArrayList<Objects.Queue> ();
        Sqlite.Statement stmt;

        sql = """
            SELECT * FROM Queue ORDER BY date_added;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);

        while (stmt.step () == Sqlite.ROW) {
            return_value.add (_fill_queue (stmt));
        }
        stmt.reset ();
        return return_value;
    }

    public Objects.Queue _fill_queue (Sqlite.Statement stmt) {
        Objects.Queue return_value = new Objects.Queue ();
        return_value.uuid = stmt.column_text (0);
        return_value.object_id = stmt.column_text (1);
        return_value.query = stmt.column_text (2);
        return_value.temp_id = stmt.column_text (3);
        return_value.args = stmt.column_text (4);
        return_value.date_added = stmt.column_text (5);
        return return_value;
    }

    public void insert_CurTempIds (string id, string temp_id, string object) { // vala-lint=naming-convention
        Sqlite.Statement stmt;

        sql = """
            INSERT OR IGNORE INTO CurTempIds (id, temp_id, object)
            VALUES ($id, $temp_id, $object);
        """;

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_str (stmt, "$id", id);
        set_parameter_str (stmt, "$temp_id", temp_id);
        set_parameter_str (stmt, "$object", object);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }

        stmt.reset ();
    }

    public bool curTempIds_exists (int64 id) { // vala-lint=naming-convention
        bool returned = false;
        Sqlite.Statement stmt;

        sql = """
            SELECT COUNT (*) FROM CurTempIds WHERE id = $id;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_int64 (stmt, "$id", id);

        if (stmt.step () == Sqlite.ROW) {
            returned = stmt.column_int (0) > 0;
        }

        stmt.reset ();
        return returned;
    }

    public string get_temp_id (int64 id) {
        string returned = "";
        Sqlite.Statement stmt;

        sql = """
            SELECT temp_id FROM CurTempIds WHERE id = $id;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_int64 (stmt, "$id", id);

        if (stmt.step () == Sqlite.ROW) {
            returned = stmt.column_text (0);
        }

        stmt.reset ();
        return returned;
    }

    public void remove_CurTempIds (int64 id) { // vala-lint=naming-convention
        Sqlite.Statement stmt;

        sql = """
            DELETE FROM CurTempIds WHERE id = $id;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_int64 (stmt, "$id", id);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }

        stmt.reset ();
    }

    public void remove_queue (string uuid) {
        Sqlite.Statement stmt;

        sql = """
            DELETE FROM Queue WHERE uuid = $uuid;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_str (stmt, "$uuid", uuid);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }

        stmt.reset ();
    }

    // PARAMETER REGION
    private void set_parameter_int (Sqlite.Statement? stmt, string par, int val) {
        int par_position = stmt.bind_parameter_index (par);
        stmt.bind_int (par_position, val);
    }

    private void set_parameter_int64 (Sqlite.Statement? stmt, string par, int64 val) {
        int par_position = stmt.bind_parameter_index (par);
        stmt.bind_int64 (par_position, val);
    }
    private void set_parameter_str (Sqlite.Statement? stmt, string par, string val) {
        int par_position = stmt.bind_parameter_index (par);
        stmt.bind_text (par_position, val);
    }

    private void set_parameter_bool (Sqlite.Statement? stmt, string par, bool val) {
        int par_position = stmt.bind_parameter_index (par);
        stmt.bind_int (par_position, val ? Constants.ACTIVE : Constants.INACTIVE);
    }

    private bool get_parameter_bool (Sqlite.Statement stmt, int col) {
        return stmt.column_int (col) == Constants.ACTIVE;
    }
}
