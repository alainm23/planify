public class Services.Database : GLib.Object {
    private Sqlite.Database db;
    private string db_path;

    public signal void add_task_signal ();
    public signal void update_project_signal (Objects.Project project);
    public signal void on_signal_remove_task (Objects.Task task);
    public signal void update_task_signal (Objects.Task task);

    public Database (bool skip_tables = false) {
        int rc = 0;
        db_path = Environment.get_home_dir () + "/.cache/com.github.artegeek.planner/database.db";

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
            "note    VARCHAR," +
            "deadline       VARCHAR," +
            "item_order     INTEGER," +
            "is_deleted     INTEGER," +
            "color          VARCHAR)", null, null);
        debug ("Table PROJECTS created");

        rc = db.exec ("CREATE TABLE IF NOT EXISTS TASKS (" +
            "id             INTEGER PRIMARY KEY AUTOINCREMENT, " +
            "checked        INTEGER," +
            "project_id     INTEGER," +
            "list_id        INTEGER," +
            "task_order     INTEGER," +
            "is_inbox       INTEGER," +
            "has_reminder   INTEGER," +
            "sidebar_width  INTEGER," +
            "was_notified   INTEGER," +
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
            "note, deadline, item_order, is_deleted, color)" +
            "VALUES (?, ?, ?, ?, ?, ?)", -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (1, project.name);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (2, project.note);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (3, project.deadline);
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
            "note = ?, deadline = ?, item_order = ?, is_deleted = ?, color = ? " +
            "WHERE id = ?", -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (1, project.name);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (2, project.note);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (3, project.deadline);
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

        if (res == Sqlite.DONE) {
            update_project_signal (project);
        }

        return res;
    }

    public int remove_project (int id) {
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("DELETE FROM PROJECTS WHERE id = ?", -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (1, id);
        assert (res == Sqlite.OK);

        res = stmt.step ();

        if (res == Sqlite.DONE) {
            // Remove all tasks project
            var all_tasks = new Gee.ArrayList<Objects.Task?> ();
            all_tasks = Application.database.get_all_tasks_by_project (id);

            foreach (var task in all_tasks) {
                remove_task (task);
            }
        }

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

            project.id = stmt.column_int (0);
            project.name = stmt.column_text (1);
            project.note = stmt.column_text (2);
            project.deadline = stmt.column_text (3);
            project.item_order = stmt.column_int (4);
            project.is_deleted = stmt.column_int (5);
            project.color = stmt.column_text (6);

            all.add (project);
        }

        return all;
    }

    public Objects.Project get_project (int id) {
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("SELECT * FROM PROJECTS WHERE id = ?",
            -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (1, id);
        assert (res == Sqlite.OK);

        stmt.step ();

        var project = new Objects.Project ();

        project.id = stmt.column_int (0);
        project.name = stmt.column_text (1);
        project.note = stmt.column_text (2);
        project.deadline = stmt.column_text (3);
        project.item_order = stmt.column_int (4);
        project.is_deleted = stmt.column_int (5);
        project.color = stmt.column_text (6);

        return project;
    }

    public Objects.Project get_last_project () {
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("SELECT * FROM PROJECTS ORDER BY id DESC LIMIT 1",
            -1, out stmt);
        assert (res == Sqlite.OK);

        stmt.step ();

        var project = new Objects.Project ();

        project.id = stmt.column_int (0);
        project.name = stmt.column_text (1);
        project.note = stmt.column_text (2);
        project.deadline = stmt.column_text (3);
        project.item_order = stmt.column_int (4);
        project.is_deleted = stmt.column_int (5);
        project.color = stmt.column_text (6);

        return project;
    }

    public int get_project_no_completed_tasks_number (int id) {
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("SELECT * FROM TASKS WHERE project_id = ? AND checked = 0",
            -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (1, id);
        assert (res == Sqlite.OK);

        int count = 0;
        while ((res = stmt.step()) == Sqlite.ROW) {
            count++;
        }

        return count;
    }

    public int get_project_completed_tasks_number (int id) {
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("SELECT * FROM TASKS WHERE project_id = ? AND checked = 1",
            -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (1, id);
        assert (res == Sqlite.OK);

        int count = 0;
        while ((res = stmt.step()) == Sqlite.ROW) {
            count++;
        }

        return count;
    }

    public int get_project_tasks_number (int id) {
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("SELECT * FROM TASKS WHERE project_id = ?",
            -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (1, id);
        assert (res == Sqlite.OK);

        int count = 0;
        while ((res = stmt.step()) == Sqlite.ROW) {
            count++;
        }

        return count;
    }

    public int add_task (Objects.Task task) {
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("INSERT INTO TASKS (checked," +
            "project_id, list_id, task_order, is_inbox, has_reminder, sidebar_width, was_notified, content, note, when_date_utc, reminder_time, labels, checklist)" +
            "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (1, task.checked);
        assert (res == Sqlite.OK);
        res = stmt.bind_int (2, task.project_id);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (3, task.list_id);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (4, task.task_order);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (5, task.is_inbox);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (6, task.has_reminder);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (7, task.sidebar_width);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (8, task.was_notified);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (9, task.content);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (10, task.note);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (11, task.when_date_utc);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (12, task.reminder_time);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (13, task.labels);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (14, task.checklist);
        assert (res == Sqlite.OK);

        res = stmt.step ();

        if (res == Sqlite.DONE) {
            add_task_signal ();
        }

        return res;
    }

    public Objects.Task get_last_task () {
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("SELECT * FROM TASKS ORDER BY id DESC LIMIT 1",
            -1, out stmt);
        assert (res == Sqlite.OK);

        stmt.step ();

        var task = new Objects.Task ();

        task.id = stmt.column_int (0);
        task.checked = stmt.column_int (1);
        task.project_id = stmt.column_int (2);
        task.list_id = stmt.column_int (3);
        task.task_order = stmt.column_int (4);
        task.is_inbox = stmt.column_int (5);
        task.has_reminder = stmt.column_int (6);
        task.sidebar_width = stmt.column_int (7);
        task.was_notified = stmt.column_int (8);
        task.content = stmt.column_text (9);
        task.note = stmt.column_text (10);
        task.when_date_utc = stmt.column_text (11);
        task.reminder_time = stmt.column_text (12);
        task.checklist = stmt.column_text (13);
        task.labels = stmt.column_text (14);

        return task;
    }


    public int update_task (Objects.Task task) {
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("UPDATE TASKS SET checked = ?, " +
            "project_id = ?, list_id = ?, task_order = ?, is_inbox = ?, has_reminder = ?, sidebar_width = ?, was_notified = ?, content = ?, note = ?, " +
            "when_date_utc = ?, reminder_time = ?, checklist = ?, labels = ? WHERE id = ?", -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (1, task.checked);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (2, task.project_id);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (3, task.list_id);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (4, task.task_order);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (5, task.is_inbox);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (6, task.has_reminder);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (7, task.sidebar_width);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (8, task.was_notified);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (9, task.content);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (10, task.note);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (11, task.when_date_utc);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (12, task.reminder_time);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (13, task.checklist);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (14, task.labels);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (15, task.id);
        assert (res == Sqlite.OK);

        res = stmt.step ();

        return res;
    }

    public int remove_task (Objects.Task task) {
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("DELETE FROM TASKS WHERE id = ?", -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (1, task.id);
        assert (res == Sqlite.OK);

        res = stmt.step ();

        if (res == Sqlite.DONE) {
            on_signal_remove_task (task);
        }

        return res;
    }

    public Gee.ArrayList<Objects.Task?> get_all_inbox_tasks () {
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("SELECT * FROM TASKS WHERE is_inbox = 1 AND when_date_utc = ''",
            -1, out stmt);
        assert (res == Sqlite.OK);

        var all = new Gee.ArrayList<Objects.Task?> ();

        while ((res = stmt.step()) == Sqlite.ROW) {
            var task = new Objects.Task ();

            task.id = stmt.column_int (0);
            task.checked = stmt.column_int (1);
            task.project_id = stmt.column_int (2);
            task.list_id = stmt.column_int (3);
            task.task_order = stmt.column_int (4);
            task.is_inbox = stmt.column_int (5);
            task.has_reminder = stmt.column_int (6);
            task.sidebar_width = stmt.column_int (7);
            task.was_notified = stmt.column_int (8);
            task.content = stmt.column_text (9);
            task.note = stmt.column_text (10);
            task.when_date_utc = stmt.column_text (11);
            task.reminder_time = stmt.column_text (12);
            task.checklist = stmt.column_text (13);
            task.labels = stmt.column_text (14);

            all.add (task);
        }

        return all;
    }

    public Gee.ArrayList<Objects.Task?> get_all_tasks_by_project (int id) {
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("SELECT * FROM TASKS WHERE project_id = ?",
            -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (1, id);
        assert (res == Sqlite.OK);

        var all = new Gee.ArrayList<Objects.Task?> ();

        while ((res = stmt.step()) == Sqlite.ROW) {
            var task = new Objects.Task ();

            task.id = stmt.column_int (0);
            task.checked = stmt.column_int (1);
            task.project_id = stmt.column_int (2);
            task.list_id = stmt.column_int (3);
            task.task_order = stmt.column_int (4);
            task.is_inbox = stmt.column_int (5);
            task.has_reminder = stmt.column_int (6);
            task.sidebar_width = stmt.column_int (7);
            task.was_notified = stmt.column_int (8);
            task.content = stmt.column_text (9);
            task.note = stmt.column_text (10);
            task.when_date_utc = stmt.column_text (11);
            task.reminder_time = stmt.column_text (12);
            task.checklist = stmt.column_text (13);
            task.labels = stmt.column_text (14);

            all.add (task);
        }

        return all;
    }

    public Gee.ArrayList<Objects.Task?> get_all_today_tasks () {
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("SELECT * FROM TASKS WHERE when_date_utc != ''",
            -1, out stmt);
        assert (res == Sqlite.OK);

        var all = new Gee.ArrayList<Objects.Task?> ();

        while ((res = stmt.step()) == Sqlite.ROW) {
            var task = new Objects.Task ();

            task.id = stmt.column_int (0);
            task.checked = stmt.column_int (1);
            task.project_id = stmt.column_int (2);
            task.list_id = stmt.column_int (3);
            task.task_order = stmt.column_int (4);
            task.is_inbox = stmt.column_int (5);
            task.has_reminder = stmt.column_int (6);
            task.sidebar_width = stmt.column_int (7);
            task.was_notified = stmt.column_int (8);
            task.content = stmt.column_text (9);
            task.note = stmt.column_text (10);
            task.when_date_utc = stmt.column_text (11);
            task.reminder_time = stmt.column_text (12);
            task.checklist = stmt.column_text (13);
            task.labels = stmt.column_text (14);

            var when = new GLib.DateTime.from_iso8601 (task.when_date_utc, new GLib.TimeZone.local ());

            if (Granite.DateTime.is_same_day (new GLib.DateTime.now_local (), when)) {
                all.add (task);
            }
        }

        return all;
    }

    public Gee.ArrayList<Objects.Task?> get_all_reminder_tasks () {
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("SELECT * FROM TASKS WHERE has_reminder = 1 AND was_notified = 0",
            -1, out stmt);
        assert (res == Sqlite.OK);

        var all = new Gee.ArrayList<Objects.Task?> ();

        while ((res = stmt.step()) == Sqlite.ROW) {
            var task = new Objects.Task ();

            task.id = stmt.column_int (0);
            task.checked = stmt.column_int (1);
            task.project_id = stmt.column_int (2);
            task.list_id = stmt.column_int (3);
            task.task_order = stmt.column_int (4);
            task.is_inbox = stmt.column_int (5);
            task.has_reminder = stmt.column_int (6);
            task.sidebar_width = stmt.column_int (7);
            task.was_notified = stmt.column_int (8);
            task.content = stmt.column_text (9);
            task.note = stmt.column_text (10);
            task.when_date_utc = stmt.column_text (11);
            task.reminder_time = stmt.column_text (12);
            task.checklist = stmt.column_text (13);
            task.labels = stmt.column_text (14);

            all.add (task);
        }

        return all;

    }

    public int get_all_completed_tasks () {
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("SELECT * FROM TASKS WHERE checked = 1",
            -1, out stmt);
        assert (res == Sqlite.OK);

        int count = 0;
        while ((res = stmt.step()) == Sqlite.ROW) {
            count++;
        }

        return count;
    }

    public int get_all_todo_tasks () {
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("SELECT * FROM TASKS WHERE checked = 0",
            -1, out stmt);
        assert (res == Sqlite.OK);

        int count = 0;
        while ((res = stmt.step()) == Sqlite.ROW) {
            count++;
        }

        return count;
    }

    public int get_all_tasks () {
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("SELECT * FROM TASKS",
            -1, out stmt);
        assert (res == Sqlite.OK);

        int count = 0;
        while ((res = stmt.step()) == Sqlite.ROW) {
            count++;
        }

        return count;
    }

    public int get_inbox_number () {
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("SELECT * FROM TASKS WHERE is_inbox = 1 and checked = 0 AND when_date_utc = ''",
            -1, out stmt);
        assert (res == Sqlite.OK);

        int count = 0;
        while ((res = stmt.step()) == Sqlite.ROW) {
            count++;
        }

        return count;
    }

    public int get_today_number () {
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("SELECT * FROM TASKS WHERE checked = 0 AND when_date_utc != ''",
            -1, out stmt);
        assert (res == Sqlite.OK);

        int count = 0;
        while ((res = stmt.step()) == Sqlite.ROW) {
            var when = new GLib.DateTime.from_iso8601 (stmt.column_text (11), new GLib.TimeZone.local ());

            if (Granite.DateTime.is_same_day (new GLib.DateTime.now_local (), when)) {
                count++;
            }
        }

        return count;
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

    public Objects.Label get_label (string id) {
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("SELECT * FROM LABELS WHERE id = ?", -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (1, id);
        assert (res == Sqlite.OK);

        stmt.step ();

        var label = new Objects.Label ();

        label.id = stmt.column_int (0);
        label.name = stmt.column_text (1);
        label.color = stmt.column_text (2);

        return label;
    }

    public Gee.ArrayList<Objects.Label?> get_all_labels () {
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("SELECT * FROM LABELS",
            -1, out stmt);
        assert (res == Sqlite.OK);

        var all = new Gee.ArrayList<Objects.Label?> ();

        while ((res = stmt.step()) == Sqlite.ROW) {
            var label = new Objects.Label ();

            label.id = stmt.column_int (0);
            label.name = stmt.column_text (1);
            label.color = stmt.column_text (2);

            all.add (label);
        }

        return all;
    }
}
