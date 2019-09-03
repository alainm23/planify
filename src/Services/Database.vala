public class Services.Database : GLib.Object {
    private Sqlite.Database db; 
    private string db_path;

    public signal void project_added (Objects.Project project);

    public Database (bool skip_tables = false) {
        int rc = 0;
        db_path = Environment.get_home_dir () + "/.local/share/com.github.alainm23.planner/database.db";

        if (!skip_tables) {
            if (create_tables () != Sqlite.OK) {
                stderr.printf ("Error creating db table: %d, %s\n", rc, db.errmsg ());
                Gtk.main_quit ();
            }
        }

        rc = Sqlite.Database.open (db_path, out db);

        if (rc != Sqlite.OK) {
            stderr.printf ("Can't open database: %d, %s\n", rc, db.errmsg ());
            Gtk.main_quit ();
        }
    }

    private int create_tables () {
        int rc;
        string sql;

        rc = Sqlite.Database.open (db_path, out db);

        if (rc != Sqlite.OK) {
            stderr.printf ("Can't open database: %d, %s\n", rc, db.errmsg ());
            Gtk.main_quit ();
        }

        sql = """
            CREATE TABLE IF NOT EXISTS Projects (
                id            INTEGER PRIMARY KEY,
                name          TEXT    NOT NULL,
                note          TEXT,
                due           TEXT,
                color         INTEGER,
                is_todoist    INTEGER,
                inbox_project INTEGER,
                team_inbox    INTEGER,
                child_order   INTEGER,
                is_deleted    INTEGER,
                is_archived   INTEGER,
                is_favorite   INTEGER,
                is_sync       INTEGER
            );
        """;
        rc = db.exec (sql, null, null);
        debug ("Table artists created");

        return rc;
    } 

    public bool is_database_empty () {
        bool returned = false;
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("SELECT COUNT (*) FROM Projects", -1, out stmt);
        assert (res == Sqlite.OK);

        if (stmt.step () == Sqlite.ROW) {
            returned = stmt.column_int (0) <= 0;
        }

        return returned;
    }

    public bool is_project_id_valid (int32 id) {
        bool returned = false;
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("SELECT COUNT (*) FROM Projects WHERE id = ?", -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (1, id);
        assert (res == Sqlite.OK);

        if (stmt.step () == Sqlite.ROW) {
            returned = stmt.column_int (0) <= 0;
        }

        return returned;
    }

    public Objects.Project create_inbox_project (int id = 0) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        var project = new Objects.Project ();
        project.inbox_project = 1;
        project.name = _("Inbox");

        if (id != 0) {
            project.id = id;
            project.is_todoist = 1;
        } else {
            project.id = Application.utils.generate_id ();
        }

        sql = """
            INSERT OR IGNORE INTO Projects (id, name, note, due, color, is_todoist, inbox_project,
                team_inbox, child_order, is_deleted, is_archived, is_favorite, is_sync)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (1, project.id);
        assert (res == Sqlite.OK);
        
        res = stmt.bind_text (2, project.name);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (3, project.note);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (4, project.due);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (5, project.color);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (6, project.is_todoist);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (7, project.inbox_project);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (8, project.team_inbox);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (9, project.child_order);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (10, project.is_deleted);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (11, project.is_archived);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (12, project.is_favorite);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (13, project.is_sync);
        assert (res == Sqlite.OK);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }

        stmt.reset ();

        return project;
    }

    public bool insert_project (Objects.Project project) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            INSERT OR IGNORE INTO Projects (id, name, note, due, color, is_todoist, inbox_project,
                team_inbox, child_order, is_deleted, is_archived, is_favorite, is_sync)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (1, project.id);
        assert (res == Sqlite.OK);
        
        res = stmt.bind_text (2, project.name);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (3, project.note);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (4, project.due);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (5, project.color);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (6, project.is_todoist);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (7, project.inbox_project);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (8, project.team_inbox);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (9, project.child_order);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (10, project.is_deleted);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (11, project.is_archived);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (12, project.is_favorite);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (13, project.is_sync);
        assert (res == Sqlite.OK);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
            return false;
        } else {
            project_added (project);
            return true;
        }
    }

    public Gee.ArrayList<Objects.Project?> get_all_projects () {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            SELECT * FROM Projects;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        var all = new Gee.ArrayList<Objects.Project?> ();

        while ((res = stmt.step()) == Sqlite.ROW) {
            var p = new Objects.Project ();

            p.id = stmt.column_int (0);
            p.name = stmt.column_text (1);
            p.note = stmt.column_text (2);
            p.due = stmt.column_text (3);
            p.color = stmt.column_int (4);
            p.is_todoist = stmt.column_int (5);
            p.inbox_project = stmt.column_int (6);
            p.team_inbox = stmt.column_int (7);
            p.child_order = stmt.column_int (8);
            p.is_deleted = stmt.column_int (9);
            p.is_archived = stmt.column_int (10);
            p.is_favorite = stmt.column_int (11);
            p.is_sync = stmt.column_int (12);

            all.add (p);
        }

        return all;
    }
}
