public class Services.Database : GLib.Object {
    private Sqlite.Database db; 
    private string db_path;

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
        /*
            object.set_int_member ("id", project.id); 
            object.set_string_member ("name", project.name);
            object.set_string_member ("note", project.note);
            object.set_int_member ("color", project.color);
            object.set_string_member ("due", project.due);
            object.set_boolean_member ("is_todoist", project.is_todoist);
            object.set_boolean_member ("inbox_project", project.inbox_project);
            object.set_boolean_member ("team_inbox", project.team_inbox);
            object.set_string_member ("note", project.note);
            object.set_int_member ("child_order", project.child_order);
            object.set_int_member ("is_deleted", project.is_deleted);
            object.set_int_member ("is_archived", project.is_archived);
            object.set_int_member ("is_favorite", project.is_favorite);
        */

        sql = """
            CREATE TABLE IF NOT EXISTS projects (
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
        bool empty = false;
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("SELECT COUNT (*) FROM projects", -1, out stmt);
        assert (res == Sqlite.OK);

        if (stmt.step () == Sqlite.ROW) {
            empty = stmt.column_int (0) <= 0;
        }

        return empty;
    }
}
