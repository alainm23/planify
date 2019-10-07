public class Services.Database : GLib.Object {
    private Sqlite.Database db; 
    private string db_path;

    public signal void area_added (Objects.Area area);

    public signal void project_added (Objects.Project project);
    public signal void project_updated (Objects.Project project);
    public signal void project_deleted (Objects.Project project);
    public signal void project_moved (Objects.Project project);
    
    public signal void header_added (Objects.Header header);

    public signal void item_added (Objects.Item item);
    public signal void item_updated (Objects.Item item);
    public signal void item_deleted (Objects.Item item);
    public signal void update_due_item (Objects.Item item);

    public signal void check_added (Objects.Check check);
    public signal void check_updated (Objects.Check check);
    public signal void check_deleted (Objects.Check check);

    public Gee.ArrayList<Objects.Item?> items_to_delete;
    public signal void show_toast_delete (int count);
    public signal void show_undo_item (int64 id);

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
        rc = db.exec ("PRAGMA foreign_keys = ON;");
        
        if (rc != Sqlite.OK) {
            stderr.printf ("Can't open database: %d, %s\n", rc, db.errmsg ());
            Gtk.main_quit ();
        }

        items_to_delete = new Gee.ArrayList<Objects.Item?> ();
    }

    public bool add_item_to_delete (Objects.Item item) {
        if (items_to_delete.add (item)) {
            show_toast_delete (items_to_delete.size);
            return true;
        }

        return false;
    }

    public void remove_item_to_delete () {
        new Thread<void*> ("remove_item_to_delete", () => {
            foreach (var item in items_to_delete) {
                delete_item (item);
            }

            items_to_delete.clear ();
            
            return null;
        });
    } 

    public void clear_item_to_delete () {
        foreach (var item in items_to_delete) {
            show_undo_item (item.id);   
        }

        items_to_delete.clear ();
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
            CREATE TABLE IF NOT EXISTS Areas (
                id              INTEGER PRIMARY KEY,
                name            TEXT,
                date_added      TEXT,
                default_area    INTEGER,
                reveal          INTEGER,
                item_order      INTEGER
            );
        """;
        rc = db.exec (sql, null, null);
        debug ("Table Areas created");

        sql = """
            CREATE TABLE IF NOT EXISTS Projects (
                id               INTEGER PRIMARY KEY,
                area_id          INTEGER,
                default_header   INTEGER,
                name             TEXT NOT NULL,
                note             TEXT,
                due              TEXT,
                color            INTEGER,
                is_todoist       INTEGER,
                inbox_project    INTEGER,
                team_inbox       INTEGER,
                item_order       INTEGER,
                is_deleted       INTEGER,
                is_archived      INTEGER,
                is_favorite      INTEGER,
                is_sync          INTEGER
            );
        """; 
        rc = db.exec (sql, null, null);
        debug ("Table Projects created"); 

        sql = """
            CREATE TABLE IF NOT EXISTS Headers (
                id              INTEGER PRIMARY KEY,
                project_id      INTEGER,
                default_header  INTEGER,
                item_order      INTEGER,
                reveal          INTEGER,
                name            TEXT,
                date_added      TEXT
            );
        """;
        rc = db.exec (sql, null, null);
        debug ("Table Headers created");

        sql = """
            CREATE TABLE IF NOT EXISTS Items (
                id              INTEGER PRIMARY KEY,
                header_id       INTEGER,
                project_id      INTEGER,
                item_order      INTEGER,
                checked         INTEGER,
                is_deleted      INTEGER,
                content         TEXT NOT NULL,
                note            TEXT,
                due             TEXT,
                date_added      TEXT,
                date_completed  TEXT,
                date_updated    TEXT
            );
        """;
        rc = db.exec (sql, null, null);
        debug ("Table Items created");

        sql = """
            CREATE TABLE IF NOT EXISTS Checklist (
                id              INTEGER PRIMARY KEY,
                item_id         INTEGER,
                item_order      INTEGER,
                checked         INTEGER,
                content         TEXT NOT NULL,
                date_added      TEXT,
                date_completed  TEXT,
                date_updated    TEXT,
                FOREIGN KEY (item_id) REFERENCES Items (id) ON DELETE CASCADE
            );
        """;
        rc = db.exec (sql, null, null);
        debug ("Table Checklist created");

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

    public bool is_project_id_valid (int64 id) {
        bool returned = false;
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("SELECT COUNT (*) FROM Projects WHERE id = ?", -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, id);
        assert (res == Sqlite.OK);

        if (stmt.step () == Sqlite.ROW) {
            returned = stmt.column_int (0) <= 0;
        }

        return returned;
    }

    /*
        Areas
    */

    public Objects.Area create_default_area () {
        Sqlite.Statement stmt;
        string sql;
        int res;

        var area = new Objects.Area ();
        area.name = _("Default area");
        area.id = Application.utils.generate_id ();
        area.default_area = 1;
        area.item_order = 0;

        sql = """
            INSERT OR IGNORE INTO Areas (id, name, date_added, default_area, reveal, item_order)
            VALUES (?, ?, ?, ?, ?, ?);
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, area.id);
        assert (res == Sqlite.OK);
        
        res = stmt.bind_text (2, area.name);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (3, area.date_added);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (4, area.default_area);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (5, area.reveal);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (6, area.item_order);
        assert (res == Sqlite.OK);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }

        stmt.reset ();

        area_added (area);

        return area;
    }

    public bool insert_area (Objects.Area area) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            SELECT COUNT (*) FROM Areas;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        if (stmt.step () == Sqlite.ROW) {
            area.item_order = stmt.column_int (0);
        }

        stmt.reset ();

        sql = """
            INSERT OR IGNORE INTO Areas (id, name, date_added, default_area, reveal, item_order)
            VALUES (?, ?, ?, ?, ?, ?);
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, area.id);
        assert (res == Sqlite.OK);
        
        res = stmt.bind_text (2, area.name);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (3, area.date_added);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (4, area.default_area);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (5, area.reveal);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (6, area.item_order);
        assert (res == Sqlite.OK);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
            return false;
        } else {
            area_added (area);
            return true;
        }
    }

    public Gee.ArrayList<Objects.Area?> get_all_areas () {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            SELECT * FROM Areas ORDER BY item_order;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        var all = new Gee.ArrayList<Objects.Area?> ();

        while ((res = stmt.step()) == Sqlite.ROW) {
            var a = new Objects.Area ();

            a.id = stmt.column_int64 (0);
            a.name = stmt.column_text (1);
            a.date_added = stmt.column_text (2);
            a.default_area = stmt.column_int (3);
            a.reveal = stmt.column_int (4);
            a.item_order = stmt.column_int (5);

            all.add (a);
        }

        return all;
    }

    public bool update_area (Objects.Area area) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            UPDATE Areas SET name = ?, reveal = ?, item_order = ? WHERE id = ?;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (1, area.name);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (2, area.reveal);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (3, area.item_order);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (4, area.id);
        assert (res == Sqlite.OK);

        res = stmt.step ();

        if (res == Sqlite.DONE) {
            return true;
        } else {
            return false;
        }
    }

    public Objects.Project create_inbox_project (int64 id = 0) {
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
                team_inbox, item_order, is_deleted, is_archived, is_favorite, is_sync, default_header)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, project.id);
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

        res = stmt.bind_int (9, project.item_order);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (10, project.is_deleted);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (11, project.is_archived);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (12, project.is_favorite);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (13, project.is_sync);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (14, project.default_header);
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
            SELECT COUNT (*) FROM Projects WHERE area_id = ?;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, project.area_id);
        assert (res == Sqlite.OK);

        if (stmt.step () == Sqlite.ROW) {
            project.item_order = stmt.column_int (0);
        }

        stmt.reset ();

        sql = """
            INSERT OR IGNORE INTO Projects (id, name, note, due, color, is_todoist, inbox_project,
                team_inbox, item_order, is_deleted, is_archived, is_favorite, is_sync, area_id, default_header)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, project.id);
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

        res = stmt.bind_int (9, project.item_order);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (10, project.is_deleted);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (11, project.is_archived);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (12, project.is_favorite);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (13, project.is_sync);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (14, project.area_id);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (15, project.default_header);
        assert (res == Sqlite.OK);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
            return false;
        }

        project_added (project);

        var default_header = new Objects.Header ();
        default_header.id = project.default_header;
        default_header.project_id = project.id;
        default_header.default_header = 1;

        if (Application.database.insert_header (default_header)) {
            return true;
        }

        return false;
    }

    public bool update_project (Objects.Project project) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            UPDATE Projects SET name = ?, note = ?, due = ?, color = ?, item_order = ?, 
            is_deleted = ?, is_archived = ?, is_favorite = ?, is_sync = ? 
            WHERE id = ?;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (1, project.name);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (2, project.note);
        assert (res == Sqlite.OK);
        
        res = stmt.bind_text (3, project.due);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (4, project.color);
        assert (res == Sqlite.OK);
        
        res = stmt.bind_int (5, project.item_order);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (6, project.is_deleted);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (7, project.is_archived);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (8, project.is_favorite);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (9, project.is_sync);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (10, project.id);
        assert (res == Sqlite.OK);

        res = stmt.step ();

        if (res == Sqlite.DONE) {
            project_updated (project);
            
            return true;
        } else {
            return false;
        }
    }
    
    public bool delete_project (Objects.Project project) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            DELETE FROM Projects WHERE id = ?;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, project.id);
        assert (res == Sqlite.OK);

        res = stmt.step ();

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
            return false;
        } else {
            project_deleted (project);
            return true;
        }
    }

    public bool move_project (Objects.Project project, Objects.Area area) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        project.area_id = area.id;

        sql = """
            SELECT COUNT (*) FROM Projects WHERE area_id = ?;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, area.id);
        assert (res == Sqlite.OK);

        if (stmt.step () == Sqlite.ROW) {
            project.item_order = stmt.column_int (0);
        }

        stmt.reset ();

        sql = """
            UPDATE Projects SET area_id = ?, item_order = ? WHERE id = ?;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, area.id);
        assert (res == Sqlite.OK);
        
        res = stmt.bind_int (2, project.item_order);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (3, project.id);
        assert (res == Sqlite.OK);

        res = stmt.step ();

        if (res == Sqlite.DONE) {
            project_moved (project);
            return true;
        } else {
            return false;
        }
    }

    public Gee.ArrayList<Objects.Project?> get_all_projects_by_area (int64 id) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            SELECT * FROM Projects WHERE area_id = ? ORDER BY item_order;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, id);
        assert (res == Sqlite.OK);

        var all = new Gee.ArrayList<Objects.Project?> ();

        while ((res = stmt.step()) == Sqlite.ROW) {
            var p = new Objects.Project ();

            p.id = stmt.column_int64 (0);
            p.area_id = stmt.column_int64 (1);
            p.default_header = stmt.column_int64 (2);
            p.name = stmt.column_text (3);
            p.note = stmt.column_text (4);
            p.due = stmt.column_text (5);
            p.color = stmt.column_int (6);
            p.is_todoist = stmt.column_int (7);
            p.inbox_project = stmt.column_int (8);
            p.team_inbox = stmt.column_int (9);
            p.item_order = stmt.column_int (10);
            p.is_deleted = stmt.column_int (11);
            p.is_archived = stmt.column_int (12);
            p.is_favorite = stmt.column_int (13);
            p.is_sync = stmt.column_int (14);

            all.add (p);
        }

        return all;
    }

    public Objects.Project? get_project_by_id (int64 id) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            SELECT * FROM Projects WHERE id = ?;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, id);
        assert (res == Sqlite.OK);

        var p = new Objects.Project ();

        if (stmt.step () == Sqlite.ROW) {
            p.id = stmt.column_int64 (0);
            p.area_id = stmt.column_int64 (1);
            p.default_header = stmt.column_int64 (2);
            p.name = stmt.column_text (3);
            p.note = stmt.column_text (4);
            p.due = stmt.column_text (5);
            p.color = stmt.column_int (6);
            p.is_todoist = stmt.column_int (7);
            p.inbox_project = stmt.column_int (8);
            p.team_inbox = stmt.column_int (9);
            p.item_order = stmt.column_int (10);
            p.is_deleted = stmt.column_int (11);
            p.is_archived = stmt.column_int (12);
            p.is_favorite = stmt.column_int (13);
            p.is_sync = stmt.column_int (14);
        }

        return p;
    }

    public void update_project_item_order (int64 project_id, int64 area_id, int item_order) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            UPDATE Projects SET area_id = ?, item_order = ? WHERE id = ?;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, area_id);
        assert (res == Sqlite.OK);
        
        res = stmt.bind_int (2, item_order);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (3, project_id);
        assert (res == Sqlite.OK);

        res = stmt.step ();

        if (res == Sqlite.DONE) {
            //updated_playlist (playlist);
        }
    }

    /*
        Headers
    */

    public bool insert_header (Objects.Header header) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            SELECT COUNT (*) FROM Headers WHERE project_id = ?;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, header.project_id);
        assert (res == Sqlite.OK);

        if (stmt.step () == Sqlite.ROW) {
            header.item_order = stmt.column_int (0);
        }

        stmt.reset ();

        sql = """
            INSERT OR IGNORE INTO Headers (id, project_id, name, date_added, default_header, item_order, reveal)
            VALUES (?, ?, ?, ?, ?, ?, ?);
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, header.id);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (2, header.project_id);
        assert (res == Sqlite.OK);
        
        res = stmt.bind_text (3, header.name);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (4, header.date_added);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (5, header.default_header);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (6, header.item_order);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (7, header.reveal);
        assert (res == Sqlite.OK);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
            return false;
        } else {
            header_added (header);
            return true;
        }
    }

    public Gee.ArrayList<Objects.Header?> get_all_headers_by_project (int64 id) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            SELECT * FROM Headers WHERE project_id = ? ORDER BY item_order;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, id);
        assert (res == Sqlite.OK);

        var all = new Gee.ArrayList<Objects.Header?> ();

        while ((res = stmt.step ()) == Sqlite.ROW) {
            var h = new Objects.Header ();

            h.id = stmt.column_int64 (0);
            h.project_id = stmt.column_int64 (1);
            h.default_header = stmt.column_int (2);
            h.item_order = stmt.column_int (3);
            h.reveal = stmt.column_int (4);
            h.name = stmt.column_text (5);
            h.date_added = stmt.column_text (6);

            all.add (h);
        }

        return all;
    }

    public bool update_header (Objects.Header header) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            UPDATE Headers SET name = ?, reveal = ?, item_order = ? WHERE id = ?;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (1, header.name);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (2, header.reveal);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (3, header.item_order);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (4, header.id);
        assert (res == Sqlite.OK);

        res = stmt.step ();

        if (res == Sqlite.DONE) {
            return true;
        } else {
            return false;
        }
    }

    /*
        Item
    */

    public bool insert_item (Objects.Item item) { 
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            SELECT COUNT (*) FROM Items WHERE header_id = ?;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, item.header_id);
        assert (res == Sqlite.OK);

        if (stmt.step () == Sqlite.ROW) {
            item.item_order = stmt.column_int (0);
        }

        if (item.header_id == 0) { 
            stmt.reset ();
            
            sql = """
                SELECT default_header FROM Projects WHERE id = ?;
            """;

            res = db.prepare_v2 (sql, -1, out stmt);
            assert (res == Sqlite.OK);

            res = stmt.bind_int64 (1, item.project_id);
            assert (res == Sqlite.OK);

            if (stmt.step () == Sqlite.ROW) {
                item.header_id = stmt.column_int64 (0);
            }
        }

        stmt.reset ();
        
        sql = """
            INSERT OR IGNORE INTO Items (id, content, note, due, is_deleted, checked,
            item_order, project_id, header_id, date_added, date_completed, date_updated)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, item.id);
        assert (res == Sqlite.OK);
        
        res = stmt.bind_text (2, item.content);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (3, item.note);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (4, item.due);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (5, item.is_deleted);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (6, item.checked);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (7, item.item_order);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (8, item.project_id);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (9, item.header_id);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (10, item.date_added);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (11, item.date_completed);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (12, item.date_updated);
        assert (res == Sqlite.OK);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
            return false;
        } else {
            item_added (item);
            return true;
        }
    }

    public bool update_item (Objects.Item item) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            UPDATE Items SET content = ?, note = ?, due = ?, is_deleted = ?, checked = ?, 
            item_order = ?, project_id = ?, header_id = ?, date_completed = ?, date_updated = ?
            WHERE id = ?;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (1, item.content);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (2, item.note);
        assert (res == Sqlite.OK);
        
        res = stmt.bind_text (3, item.due);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (4, item.is_deleted);
        assert (res == Sqlite.OK);
        
        res = stmt.bind_int (5, item.checked);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (6, item.item_order);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (7, item.project_id);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (8, item.header_id);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (9, item.date_completed);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (10, item.date_updated);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (11, item.id);
        assert (res == Sqlite.OK);

        res = stmt.step ();

        if (res == Sqlite.DONE) {
            item_updated (item);
            
            return true;
        } else {
            return false;
        }
    }

    public bool delete_item (Objects.Item item) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            DELETE FROM Items WHERE id = ?;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, item.id);
        assert (res == Sqlite.OK);

        res = stmt.step ();

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
            return false;
        } else {
            item_deleted (item);
            return true;
        }
    }

    public void update_item_order (int64 item_id, int64 header_id, int item_order) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            UPDATE Items SET item_order = ?, header_id = ? WHERE id = ?;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (1, item_order);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (2, header_id);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (3, item_id);
        assert (res == Sqlite.OK);

        res = stmt.step ();

        if (res == Sqlite.DONE) {
            //updated_playlist (playlist);
        }
    }

    public bool set_due_item (Objects.Item item, GLib.DateTime? date) {
        Sqlite.Statement stmt;
        string sql;
        int res;
        item.due = "";

        if (date != null) {
            item.due = date.to_string ();
        }

        sql = """
            UPDATE Items SET due = ? WHERE id = ?;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (1, item.due);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (2, item.id);
        assert (res == Sqlite.OK);

        res = stmt.step ();

        if (res == Sqlite.DONE) {
            update_due_item (item);
            return true;
        }

        return false;
    }

    public Gee.ArrayList<Objects.Item?> get_all_items_by_project (int64 id) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            SELECT * FROM Items WHERE project_id = ? ORDER BY item_order;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, id);
        assert (res == Sqlite.OK);
        
        var all = new Gee.ArrayList<Objects.Item?> ();

        while ((res = stmt.step()) == Sqlite.ROW) {
            var i = new Objects.Item ();

            i.id = stmt.column_int64 (0);
            i.header_id = stmt.column_int64 (1);
            i.project_id = stmt.column_int64 (2);
            i.item_order = stmt.column_int (3);
            i.checked = stmt.column_int (4);
            i.is_deleted = stmt.column_int (5);
            i.content = stmt.column_text (6);
            i.note = stmt.column_text (7);
            i.due = stmt.column_text (8);
            i.date_added = stmt.column_text (9);
            i.date_completed = stmt.column_text (10);
            i.date_updated = stmt.column_text (11);

            all.add (i);
        }

        return all;
    }

    public Gee.ArrayList<Objects.Item?> get_all_items_by_header (int64 id) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            SELECT * FROM Items WHERE header_id = ? ORDER BY item_order;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, id);
        assert (res == Sqlite.OK);
        
        var all = new Gee.ArrayList<Objects.Item?> ();

        while ((res = stmt.step()) == Sqlite.ROW) {
            var i = new Objects.Item ();

            i.id = stmt.column_int64 (0);
            i.header_id = stmt.column_int64 (1);
            i.project_id = stmt.column_int64 (2);
            i.item_order = stmt.column_int (3);
            i.checked = stmt.column_int (4);
            i.is_deleted = stmt.column_int (5);
            i.content = stmt.column_text (6);
            i.note = stmt.column_text (7);
            i.due = stmt.column_text (8);
            i.date_added = stmt.column_text (9);
            i.date_completed = stmt.column_text (10);
            i.date_updated = stmt.column_text (11);

            all.add (i);
        }

        return all;
    }

    public bool insert_check (Objects.Check check) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            SELECT COUNT (*) FROM Checklist WHERE item_id = ?;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, check.item_id);
        assert (res == Sqlite.OK);

        if (stmt.step () == Sqlite.ROW) {
            check.item_order = stmt.column_int (0);
        }

        stmt.reset ();

        sql = """
            INSERT OR IGNORE INTO Checklist (id, content, checked,
            item_order, item_id, date_added, date_completed, date_updated)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?);
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, check.id);
        assert (res == Sqlite.OK);
        
        res = stmt.bind_text (2, check.content);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (3, check.checked);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (4, check.item_order);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (5, check.item_id);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (6, check.date_added);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (7, check.date_completed);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (8, check.date_updated);
        assert (res == Sqlite.OK);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
            return false;
        } else {
            check_added (check);
            return true;
        }
    }

    public Gee.ArrayList<Objects.Check?> get_all_cheks_by_item (int64 id) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            SELECT * FROM Checklist WHERE item_id = ? ORDER BY item_order;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, id);
        assert (res == Sqlite.OK);
        
        var all = new Gee.ArrayList<Objects.Check?> ();

        while ((res = stmt.step()) == Sqlite.ROW) {
            var i = new Objects.Check ();

            i.id = stmt.column_int64 (0);
            i.item_id = stmt.column_int64 (1);
            i.item_order = stmt.column_int (2);
            i.checked = stmt.column_int (3);
            i.content = stmt.column_text (4);
            i.date_added = stmt.column_text (5);
            i.date_completed = stmt.column_text (6);
            i.date_updated = stmt.column_text (7);

            all.add (i);
        }

        return all;
    }

    public bool update_check (Objects.Check check) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            UPDATE Checklist SET content = ?, checked = ?, item_order = ?, item_id = ?, 
            date_completed = ?, date_updated = ?
            WHERE id = ?;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (1, check.content);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (2, check.checked);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (3, check.item_order);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (4, check.item_id);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (5, check.date_completed);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (6, check.date_updated);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (7, check.id);
        assert (res == Sqlite.OK);

        res = stmt.step ();

        if (res == Sqlite.DONE) {
            check_updated (check);
            
            return true;
        } else {
            return false;
        }
    }

    public bool delete_check (Objects.Check check) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            DELETE FROM Checklist WHERE id = ?;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, check.id);
        assert (res == Sqlite.OK);

        res = stmt.step ();

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
            return false;
        } else {
            check_deleted (check);
            return true;
        }
    }
}
