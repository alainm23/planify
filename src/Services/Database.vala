public class Services.Database : GLib.Object {
    private Sqlite.Database db;
    private string db_path;
    private string errormsg;

    public signal void opened ();
    public signal void reset ();

    public signal void project_added (Objects.Project project);

    public signal void label_added (Objects.Label label);
    public signal void label_deleted (Objects.Label label);

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

    Gee.ArrayList<Objects.Label> _labels = null;
    public Gee.ArrayList<Objects.Label> labels {
        get {
            if (_labels == null) {
                _labels = get_labels_collection ();
            }
            return _labels;
        }
    }

    construct {
        label_deleted.connect ((label) => {
            if (_labels.remove (label)) {
                debug ("Label Removed: %s", label.name);
            }
        });
    }

    public void init_database () {
        db_path = Environment.get_user_data_dir () + "/com.github.alainm23.planner/database.db";

        create_tables ();
        patch_database ();
        opened ();
    }

    public void patch_database () {

    }

    private void create_tables () {
        Sqlite.Database.open (db_path, out db);
        string sql;
        
        sql = """
            CREATE TABLE IF NOT EXISTS Labels (
                id              INTEGER PRIMARY KEY,
                name            TEXT,
                color           INTEGER,
                item_order      INTEGER,
                is_deleted      INTEGER,
                is_favorite     INTEGER,
                is_todoist      INTEGER
            );
        """;

        if (db.exec (sql, null, out errormsg) != Sqlite.OK) {
            warning (errormsg);
        }

        sql = """
            CREATE TABLE IF NOT EXISTS Projects (
                id               INTEGER PRIMARY KEY,
                name             TEXT NOT NULL,
                note             TEXT,
                due_date         TEXT,
                color            INTEGER,
                is_todoist       INTEGER,
                inbox_project    INTEGER,
                team_inbox       INTEGER,
                child_order      INTEGER,
                is_deleted       INTEGER,
                is_archived      INTEGER,
                is_favorite      INTEGER,
                shared           INTEGER,
                is_kanban        INTEGER,
                show_completed   INTEGER,
                sort_order       INTEGER,
                parent_id        INTEGER,
                collapsed        INTEGER
            );
        """;

        if (db.exec (sql, null, out errormsg) != Sqlite.OK) {
            warning (errormsg);
        }

        sql = """
            CREATE TABLE IF NOT EXISTS Sections (
                id              INTEGER PRIMARY KEY,
                name            TEXT,
                date_archived   TEXT,
                date_added      TEXT,
                note            TEXT,
                project_id      INTEGER,
                item_order      INTEGER,
                collapsed       INTEGER,
                is_deleted      INTEGER,
                is_archived     INTEGER,
                FOREIGN KEY (project_id) REFERENCES Projects (id) ON DELETE CASCADE
            );
        """;

        if (db.exec (sql, null, out errormsg) != Sqlite.OK) {
            warning (errormsg);
        }

        sql = """
            CREATE TABLE IF NOT EXISTS Items (
                id                  INTEGER PRIMARY KEY,
                content             TEXT NOT NULL,
                note                TEXT,
                due_date            TEXT,
                due_timezone        TEXT,
                due_string          TEXT,
                due_lang            TEXT,
                date_added          TEXT,
                date_completed      TEXT,
                date_updated        TEXT,
                section_id          INTEGER,
                user_id             INTEGER,
                assigned_by_uid     INTEGER,
                responsible_uid     INTEGER,
                parent_id           INTEGER,
                priority            INTEGER,
                item_order          INTEGER,
                checked             INTEGER,
                is_deleted          INTEGER,
                day_order           INTEGER,
                collapsed           INTEGER,
                due_is_recurring    INTEGER,
                FOREIGN KEY (section_id) REFERENCES Sections (id) ON DELETE CASCADE
            );
        """;

        if (db.exec (sql, null, out errormsg) != Sqlite.OK) {
            warning (errormsg);
        }
        
        sql = """PRAGMA foreign_keys = ON;""";
        
        if (db.exec (sql, null, out errormsg) != Sqlite.OK) {
            warning (errormsg);
        }
    }

    /*
        Projects
    */

    public Gee.ArrayList<Objects.Project> get_projects_collection () {
        Gee.ArrayList<Objects.Project> return_value = new Gee.ArrayList<Objects.Project> ();

        Sqlite.Statement stmt;
        string sql = """
            SELECT * FROM Projects;
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
        return_value.id = stmt.column_int64 (0);
        return_value.name = stmt.column_text (1);
        return_value.note = stmt.column_text (2);
        return_value.due_date = stmt.column_text (3);
        return_value.color = stmt.column_int (4);
        return_value.is_todoist = stmt.column_int (5);
        return_value.inbox_project = stmt.column_int (6);
        return_value.team_inbox = stmt.column_int (7);
        return_value.child_order = stmt.column_int (8);
        return_value.is_deleted = stmt.column_int (9);
        return_value.is_archived = stmt.column_int (10);
        return_value.is_favorite = stmt.column_int (11);
        return_value.shared = stmt.column_int (12);
        return_value.is_kanban = stmt.column_int (13);
        return_value.show_completed = stmt.column_int (14);
        return_value.sort_order = stmt.column_int (15);
        return_value.parent_id = stmt.column_int64 (16);
        return_value.collapsed = stmt.column_int (17);
        return return_value;
    }

    public bool insert_project (Objects.Project project) {
        Sqlite.Statement stmt;

        string sql = """
            INSERT OR IGNORE INTO Projects (id, name, note, due_date, color, is_todoist, inbox_project,
                team_inbox, child_order, is_deleted, is_archived, is_favorite, shared, is_kanban,
                show_completed, sort_order, parent_id, collapsed)
            VALUES ($id, $name, $note, $due_date, $color, $is_todoist, $inbox_project, $team_inbox,
                $child_order, $is_deleted, $is_archived, $is_favorite, $shared, $is_kanban, $show_completed,
                $sort_order, $parent_id, $collapsed);
        """;

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_int64 (stmt, sql, "$id", project.id);
        set_parameter_str (stmt, sql, "$name", project.name);
        set_parameter_str (stmt, sql, "$note", project.note);
        set_parameter_str (stmt, sql, "$due_date", project.due_date);
        set_parameter_int (stmt, sql, "$color", project.color);
        set_parameter_int (stmt, sql, "$is_todoist", project.is_todoist);
        set_parameter_int (stmt, sql, "$inbox_project", project.inbox_project);
        set_parameter_int (stmt, sql, "$team_inbox", project.team_inbox);
        set_parameter_int (stmt, sql, "$child_order", project.child_order);
        set_parameter_int (stmt, sql, "$is_deleted", project.is_deleted);
        set_parameter_int (stmt, sql, "$is_archived", project.is_archived);
        set_parameter_int (stmt, sql, "$is_favorite", project.is_favorite);
        set_parameter_int (stmt, sql, "$shared", project.shared);
        set_parameter_int (stmt, sql, "$is_kanban", project.is_kanban);
        set_parameter_int (stmt, sql, "$show_completed", project.show_completed);
        set_parameter_int (stmt, sql, "$sort_order", project.sort_order);
        set_parameter_int64 (stmt, sql, "$parent_id", project.parent_id);
        set_parameter_int (stmt, sql, "$collapsed", project.collapsed);

        if (stmt.step () == Sqlite.DONE) {
            projects.add (project);
            project_added (project);
        } else {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }

        stmt.reset ();
        return stmt.step () == Sqlite.DONE;
    }

    /*
    *   Labels
    */

    public Gee.ArrayList<Objects.Label> get_labels_collection () {
        Gee.ArrayList<Objects.Label> return_value = new Gee.ArrayList<Objects.Label> ();

        Sqlite.Statement stmt;
        string sql = """
            SELECT * FROM Labels;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);

        while (stmt.step () == Sqlite.ROW) {
            return_value.add (_fill_label (stmt));
        }
        stmt.reset ();
        return return_value;
    }

    public Objects.Label _fill_label (Sqlite.Statement stmt) {
        Objects.Label return_value = new Objects.Label ();
        return_value.id = stmt.column_int64 (0);
        return_value.name = stmt.column_text (1);
        return_value.color = stmt.column_int (2);
        return_value.item_order = stmt.column_int (3);
        return_value.is_deleted = stmt.column_int (4);
        return_value.is_favorite = stmt.column_int (5);
        return_value.is_todoist = stmt.column_int (6);
        return return_value;
    }

    public bool insert_label (Objects.Label label) {
        Sqlite.Statement stmt;

        string sql = """
            INSERT OR IGNORE INTO Labels (id, name, color, item_order, is_deleted, is_favorite, is_todoist)
            VALUES ($id, $name, $color, $item_order, $is_deleted, $is_favorite, $is_todoist);
        """;

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_int64 (stmt, sql, "$id", label.id);
        set_parameter_str (stmt, sql, "$name", label.name);
        set_parameter_int (stmt, sql, "$color", label.color);
        set_parameter_int (stmt, sql, "$item_order", label.item_order);
        set_parameter_int (stmt, sql, "$is_deleted", label.is_deleted);
        set_parameter_int (stmt, sql, "$is_favorite", label.is_favorite);
        set_parameter_int (stmt, sql, "$is_todoist", label.is_todoist);

        if (stmt.step () == Sqlite.DONE) {
            labels.add (label);
            label_added (label);
        } else {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }

        stmt.reset ();
        return stmt.step () == Sqlite.DONE;
    }

    public bool label_exists (int64 id) {
        bool return_value = false;
        lock (_labels) {
            foreach (var label in _labels) {
                if (label.id == id) {
                    return_value = true;
                    break;
                }
            }

            return return_value;
        }
    }

    public Objects.Label get_label (int64 id) {
        Objects.Label? return_value = null;
        lock (_labels) {
            foreach (var label in _labels) {
                if (label.id == id) {
                    return_value = label;
                    break;
                }
            }

            return return_value;
        }
    }

    public void delete_label (Objects.Label label) {
        Sqlite.Statement stmt;
        string sql = """
            DELETE FROM Labels WHERE id=$id;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_int64 (stmt, sql, "$id", label.id);

        if (stmt.step () == Sqlite.DONE) {
            label.deleted ();
        } else {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }
        stmt.reset ();
    }

    public void update_label (Objects.Label label) {
        Sqlite.Statement stmt;
        string sql = """
            UPDATE Labels SET name=$name, color=$color, item_order=$item_order,
                is_deleted=$is_deleted, is_favorite=$is_favorite, is_todoist=$is_todoist
            WHERE id=$id;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_str (stmt, sql, "$name", label.name);
        set_parameter_int (stmt, sql, "$color", label.color);
        set_parameter_int (stmt, sql, "$item_order", label.item_order);
        set_parameter_int (stmt, sql, "$is_deleted", label.is_deleted);
        set_parameter_int (stmt, sql, "$is_favorite", label.is_favorite);
        set_parameter_int (stmt, sql, "$is_todoist", label.is_todoist);
        set_parameter_int64 (stmt, sql, "$id", label.id);

        if (stmt.step () == Sqlite.DONE) {
            label.updated ();
        } else {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }
        stmt.reset ();
    }

    // PARAMENTER REGION
    private void set_parameter_int (Sqlite.Statement? stmt, string sql, string par, int val) {
        int par_position = stmt.bind_parameter_index (par);
        stmt.bind_int (par_position, val);
    }

    private void set_parameter_int64 (Sqlite.Statement? stmt, string sql, string par, int64 val) {
        int par_position = stmt.bind_parameter_index (par);
        stmt.bind_int64 (par_position, val);
    }
    private void set_parameter_str (Sqlite.Statement? stmt, string sql, string par, string val) {
        int par_position = stmt.bind_parameter_index (par);
        stmt.bind_text (par_position, val);
    }
}