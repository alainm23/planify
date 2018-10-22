public class Services.Database : GLib.Object {
    private Sqlite.Database db;
    private string db_path;

    public signal void add_inbox_task_signal ();
    public Database (bool skip_tables = false) {
        int rc = 0;
        db_path = Environment.get_home_dir () + "/.local/share/com.github.artegeek.planner/database.db";

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

        rc = Sqlite.Database.open (db_path, out db);

        if (rc != Sqlite.OK) {
            stderr.printf ("Can't open database: %d, %s\n", rc, db.errmsg ());
            Gtk.main_quit ();
        }

        rc = db.exec ("CREATE TABLE IF NOT EXISTS PROJECTS (" +
            "id             INTEGER PRIMARY KEY AUTOINCREMENT, " +
            "name           VARCHAR," +
            "description    VARCHAR," +
            "duedate        DATETIME," +
            "item_order     INTEGER," +
            "is_deleted     INTEGER," +
            "color          VARCHAR)", null, null);
        debug ("Table PROJECTS created");

        rc = db.exec ("CREATE TABLE IF NOT EXISTS TASKS (" +
            "id             INTEGER PRIMARY KEY AUTOINCREMENT, " +
            "checked        INTEGER," +
            "project_id     INTEGER," +
            "task_order     INTEGER," +
            "is_inbox       INTEGER," +
            "content        VARCHAR," +
            "note           VARCHAR," +
            "when_date_utc  VARCHAR," +
            "reminder_time  VARCHAR," +
            "checklist      VARCHAR," +
            "labels         VARCHAR)", null, null);
        debug ("Table TASKS created");

        rc = db.exec ("CREATE TABLE IF NOT EXISTS LABELS (" +
            "id             INTEGER PRIMARY KEY AUTOINCREMENT, " +
            "name           VARCHAR," +
            "color          VARCHAR)", null, null);
        debug ("Table TASKS created");

        return rc;
    }

    public int add_project (Objects.Project project) {
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("INSERT INTO PROJECTS (name," +
            "description, duedate, item_order, is_deleted, color)" +
            "VALUES (?, ?, ?, ?, ?, ?)", -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (1, project.name);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (2, project.description);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (3, project.duedate);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (4, project.item_order);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (5, project.is_deleted);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (6, project.color);
        assert (res == Sqlite.OK);

        res = stmt.step ();

        return res;
    }

    public int update_project (Objects.Project project) {
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("UPDATE PROJECTS SET name = ?, " +
            "description = ?, duedate = ?, item_order = ?, is_deleted = ?, color = ? " +
            "WHERE id = ?", -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (1, project.name);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (2, project.description);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (3, project.duedate);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (4, project.item_order);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (5, project.is_deleted);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (6, project.color);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (7, project.id);
        assert (res == Sqlite.OK);

        res = stmt.step ();

        return res;
    }

    public Gee.ArrayList<Objects.Project?> get_all_projects () {
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("SELECT * FROM PROJECTS WHERE is_deleted = 0 ORDER BY id",
            -1, out stmt);
        assert (res == Sqlite.OK);

        var all = new Gee.ArrayList<Objects.Project?> ();

        while ((res = stmt.step()) == Sqlite.ROW) {
            var project = new Objects.Project ();

            project.id = int.parse (stmt.column_text (0));
            project.name = stmt.column_text (1);
            project.description = stmt.column_text (2);
            project.duedate = stmt.column_text (3);
            project.item_order = int.parse (stmt.column_text (4));
            project.is_deleted = int.parse (stmt.column_text (5));
            project.color = stmt.column_text (6);

            all.add (project);
        }

        return all;
    }

    public int add_task (Objects.Task task) {
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("INSERT INTO TASKS (checked," +
            "project_id, task_order, is_inbox, content, note, when_date_utc, reminder_time, labels, checklist)" +
            "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (1, task.checked);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (2, task.project_id);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (3, task.task_order);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (4, task.is_inbox);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (5, task.content);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (6, task.note);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (7, task.when_date_utc);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (8, task.reminder_time);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (9, task.labels);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (10, task.checklist);
        assert (res == Sqlite.OK);

        res = stmt.step ();

        if (res == Sqlite.DONE) {
            add_inbox_task_signal ();
        }


        return res;
    }

    /*
    public int update_task (Objects.Task task) {
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("UPDATE TASKS SET checked = ?, " +
            "title = ?, note = ?, duedate = ?, has_reminder = ?, id_project = ? " +
            "WHERE id = ?", -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (1, task.checked);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (2, task.title);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (3, task.note);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (4, task.duedate);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (5, task.has_reminder);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (6, task.id_project);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (7, task.id);
        assert (res == Sqlite.OK);

        res = stmt.step ();

        if (res == Sqlite.DONE) {
            add_inbox_task_signal ();
        }

        return res;
    }
    */

    public Gee.ArrayList<Objects.Task?> get_all_inbox_tasks () {
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("SELECT * FROM TASKS WHERE is_inbox = 1",
            -1, out stmt);
        assert (res == Sqlite.OK);

        var all = new Gee.ArrayList<Objects.Task?> ();

        while ((res = stmt.step()) == Sqlite.ROW) {
            var task = new Objects.Task ();

            task.id = int.parse (stmt.column_text (0));
            task.checked = int.parse (stmt.column_text (1));
            task.project_id = int.parse (stmt.column_text (2));
            task.task_order = int.parse (stmt.column_text (3));
            task.is_inbox = int.parse (stmt.column_text (4));
            task.content = stmt.column_text (5);
            task.note = stmt.column_text (6);
            task.when_date_utc = stmt.column_text (7);
            task.reminder_time = stmt.column_text (8);
            task.checklist = stmt.column_text (9);
            task.labels = stmt.column_text (10);

            all.add (task);
        }

        return all;
    }

    public string get_inbox_number () {
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("SELECT * FROM TASKS WHERE project_id = 0 and checked = 0",
            -1, out stmt);
        assert (res == Sqlite.OK);

        var all = new Gee.ArrayList<Objects.Task?> ();

        while ((res = stmt.step()) == Sqlite.ROW) {
            var task = new Objects.Task ();

            task.id = int.parse (stmt.column_text (0));

            all.add (task);
        }

        return all.size.to_string ();
    }

    public int add_label (Objects.Label label) {
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("INSERT INTO LABELS (name," +
            "color)" +
            "VALUES (?, ?)", -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (1, label.name);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (2, label.color);
        assert (res == Sqlite.OK);

        res = stmt.step ();

        return res;
    }

    public int remove_label (Objects.Label label) {
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("DELETE FROM LABELS " +
            "WHERE id = ?", -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (1, label.id);
        assert (res == Sqlite.OK);

        res = stmt.step ();

        return res;
    }

    public Gee.ArrayList<Objects.Label?> get_all_labels () {
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("SELECT * FROM LABELS",
            -1, out stmt);
        assert (res == Sqlite.OK);

        var all = new Gee.ArrayList<Objects.Label?> ();

        while ((res = stmt.step()) == Sqlite.ROW) {
            var label = new Objects.Label ();

            label.id = int.parse (stmt.column_text (0));
            label.name = stmt.column_text (1);
            label.color = stmt.column_text (2);

            all.add (label);
        }

        return all;
    }
}
