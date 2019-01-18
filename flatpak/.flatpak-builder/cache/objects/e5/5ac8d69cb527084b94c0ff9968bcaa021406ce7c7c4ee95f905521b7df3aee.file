/*
* Copyright © 2019 Alain M. (https://github.com/alainm23/planner)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Alain M. <alain23@protonmail.com>
*/

public class Services.Database : GLib.Object {
    private Sqlite.Database db;
    private string db_path;

    public signal void update_project_signal (Objects.Project project);
    public signal void on_add_project_signal ();
    public signal void on_signal_remove_project (Objects.Project project);

    public signal void add_task_signal (Objects.Task task);
    public signal void on_signal_remove_task (Objects.Task task);
    public signal void update_task_signal (Objects.Task task);

    public signal void update_indicators ();

    public signal void adden_new_repository (Objects.Repository repository);
    public signal void adden_new_user (Objects.User user);
    public Database (bool skip_tables = false) {
        int rc = 0;
        db_path = Environment.get_home_dir () + "/.cache/com.github.alainm23.planner/database.db";

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

        rc = db.exec ("CREATE TABLE IF NOT EXISTS USERS (" +
            "id         INTEGER," +
            "name       VARCHAR," +
            "login      VARCHAR," +
            "token      VARCHAR," +
            "avatar_url VARCHAR)", null, null);
        debug ("Table GITHUB_USER created");
        
        rc = db.exec ("CREATE TABLE IF NOT EXISTS REPOSITORIES (" +
            "id         INTEGER," +
            "name       VARCHAR," +
            "sensitive  INTEGER," +
            "issues     VARCHAR," +
            "user_id    INTEGER)", null, null);
        debug ("Table REPOSITORY created");

        return rc;
    }

    public int add_user (Objects.User user) {
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("INSERT INTO USERS (id, name, login, token, avatar_url)" +
            "VALUES (?, ?, ?, ?, ?)", -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, user.id);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (2, user.name);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (3, user.login);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (4, user.token);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (5, user.avatar_url);
        assert (res == Sqlite.OK);

        res = stmt.step ();

        if (res == Sqlite.DONE) {
            adden_new_user (user);
        }

        return res;
    }

    public bool user_exists () {
        bool file_exists = false;
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("SELECT COUNT (*) FROM USERS", -1, out stmt);
        assert (res == Sqlite.OK);

        if (stmt.step () == Sqlite.ROW) {
            file_exists = stmt.column_int (0) > 0;
        }

        return file_exists;
    }

    public bool repo_exists () {
        bool file_exists = false;
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("SELECT COUNT (*) FROM REPOSITORIES", -1, out stmt);
        assert (res == Sqlite.OK);

        if (stmt.step () == Sqlite.ROW) {
            file_exists = stmt.column_int (0) > 0;
        }

        return file_exists;
    }

    public Objects.User get_user () {
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("SELECT * FROM USERS ORDER BY id ASC LIMIT 1",
            -1, out stmt);
        assert (res == Sqlite.OK);

        stmt.step ();

        var user = new Objects.User ();

        user.id = stmt.column_int64 (0);
        user.name = stmt.column_text (1);
        user.login = stmt.column_text (2);
        user.token = stmt.column_text (3);
        user.avatar_url = stmt.column_text (4);

        return user;
    }

    public bool repository_exists (int64 id) {
        bool exists = false;
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("SELECT COUNT (*) FROM REPOSITORIES WHERE id = ?", -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, id);
        assert (res == Sqlite.OK);

        if (stmt.step () == Sqlite.ROW) {
            exists = stmt.column_int (0) > 0;
        }

        return exists;
    }

    public int add_repository (Objects.Repository repository) {
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("INSERT INTO REPOSITORIES (id, name, sensitive, issues, user_id)" +
            "VALUES (?, ?, ?, ?, ?)", -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, repository.id);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (2, repository.name);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (3, repository.sensitive);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (4, repository.issues);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (5, repository.user_id);
        assert (res == Sqlite.OK);

        res = stmt.step ();

        if (res == Sqlite.DONE) {
            adden_new_repository (repository);
        }

        return res;
    }

    public int update_repository (Objects.Repository repository) {
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("UPDATE REPOSITORIES SET name = ?, " +
            "sensitive = ?, issues = ?, user_id = ? " +
            "WHERE id = ?", -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (1, repository.name);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (2, repository.sensitive);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (3, repository.issues);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (4, repository.user_id);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (5, repository.id);
        assert (res == Sqlite.OK);

        res = stmt.step ();

        if (res == Sqlite.DONE) {
            
        }

        return res;
    }

    public Gee.ArrayList<Objects.Repository?> get_all_repos () {
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("SELECT * FROM REPOSITORIES",
            -1, out stmt);
        assert (res == Sqlite.OK);

        var all = new Gee.ArrayList<Objects.Repository?> ();

        while ((res = stmt.step()) == Sqlite.ROW) {
            var repo = new Objects.Repository ();

            repo.id = stmt.column_int (0);
            repo.name = stmt.column_text (1);
            repo.sensitive = stmt.column_int (2);
            repo.issues = stmt.column_text (3);
            repo.user_id = stmt.column_int (4);

            all.add (repo);
        }

        return all;
    }

    public int remove_all_users () {
        Sqlite.Statement stmt;
        
        int res = db.prepare_v2 ("DELETE FROM USERS;",
            -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.step ();

        return res;
    }

    public int remove_all_repos () {
        Sqlite.Statement stmt;
        
        int res = db.prepare_v2 ("DELETE FROM REPOSITORIES;",
            -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.step ();
        
        return res;
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

        if (res == Sqlite.DONE) {
            on_add_project_signal ();
        }

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
            stmt.reset ();

            res = db.prepare_v2 ("DELETE FROM TASKS WHERE project_id = ?", -1, out stmt);
            assert (res == Sqlite.OK);

            res = stmt.bind_int (1, id);
            assert (res == Sqlite.OK);

            res = stmt.step ();
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

        stmt.reset ();

        res = db.prepare_v2 ("SELECT id FROM TASKS WHERE content = ?", -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (1, task.content);
        assert (res == Sqlite.OK);
        
        if (stmt.step () == Sqlite.ROW) {
            task.id = stmt.column_int (0);

            // Add track to list
            add_task_signal (task);
            update_indicators ();

            return Sqlite.DONE;
        } else {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
            return Sqlite.ERROR;
        }
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

    public Objects.Task get_task (int id) {
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("SELECT * FROM TASKS WHERE id = ?",
            -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (1, id);
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

        if (res == Sqlite.DONE) {
            update_indicators ();
        }

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
            update_indicators ();
        }

        return res;
    }

    public Gee.ArrayList<Objects.Task?> get_all_search_tasks () {
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("SELECT * FROM TASKS",
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

    public Gee.ArrayList<Objects.Task?> get_all_completed_tasks_2 () {
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("SELECT * FROM TASKS WHERE checked = 1",
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

            if (Application.utils.is_today (when) || Application.utils.is_before_today (when)) {
                if (task.checked == 0) {
                    all.add (task);
                }
            }
        }

        return all;
    }

    public Gee.ArrayList<Objects.Task?> get_all_upcoming_tasks () {
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

            if (Application.utils.is_upcoming (when)) {
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

            if (Application.utils.is_today (when)) {
                count++;
            }
        }

        return count;
    }

    public int get_before_today_number () {
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("SELECT * FROM TASKS WHERE checked = 0 AND when_date_utc != ''",
            -1, out stmt);
        assert (res == Sqlite.OK);

        int count = 0;
        while ((res = stmt.step()) == Sqlite.ROW) {
            var when = new GLib.DateTime.from_iso8601 (stmt.column_text (11), new GLib.TimeZone.local ());

            if (Application.utils.is_before_today (when) && Application.utils.is_today (when) == false && stmt.column_int (1) == 0) {
                count++;
            }
        }

        return count;
    }

    public int get_upcoming_number () {
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("SELECT * FROM TASKS WHERE checked = 0 AND when_date_utc != ''",
            -1, out stmt);
        assert (res == Sqlite.OK);

        int count = 0;
        while ((res = stmt.step()) == Sqlite.ROW) {
            var when = new GLib.DateTime.from_iso8601 (stmt.column_text (11), new GLib.TimeZone.local ());

            if (Application.utils.is_today (when) == false && Application.utils.is_before_today (when) == false) {
                count++;
            }
        }

        return count;
    }

    public int get_all_tasks_number () {
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("SELECT COUNT (*) FROM TASKS",
            -1, out stmt);
        assert (res == Sqlite.OK);

        stmt.step ();

        int count = 0;
        count = stmt.column_int (0);

        return count;
    }

    public int get_completed_number () {
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("SELECT COUNT (*) FROM TASKS WHERE checked = 1",
            -1, out stmt);
        assert (res == Sqlite.OK);

        stmt.step ();

        int count = 0;
        count = stmt.column_int (0);

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

    public int update_label (Objects.Label label) {
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("UPDATE LABELS SET name = ?, " +
            "color = ? WHERE id = ?", -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (1, label.name);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (2, label.color);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (3, label.id);
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
