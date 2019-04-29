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

    // Project events
    public signal void project_added (Objects.Project project);
    public signal void project_updated (Objects.Project project);

    // User
    //public signal void user_added (Objects.User user);

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

        rc = Sqlite.Database.open (db_path, out db);

        if (rc != Sqlite.OK) {
            stderr.printf ("Can't open database: %d, %s\n", rc, db.errmsg ());
            Gtk.main_quit ();
        }

        rc = db.exec ("CREATE TABLE IF NOT EXISTS PROJECTS (" +
            "id             INTEGER PRIMARY KEY, " +
            "name           VARCHAR, " +
            "note           VARCHAR, " +
            "color          VARCHAR, " +
            "icon           VARCHAR, " +
            "labels         VARCHAR, " +
            "duedate        VARCHAR, " +
            "child_order    INTEGER, " +
            "is_todoist     INTEGER, " +
            "is_inbox       INTEGER, " +
            "is_deleted     INTEGER, " +
            "is_archived    INTEGER, " +
            "is_favorite    INTEGER)", null, null);
        debug ("Table PROJECTS created");

        rc = db.exec ("CREATE TABLE IF NOT EXISTS USERS (" +
            "id             INTEGER PRIMARY KEY, " +
            "full_name      VARCHAR, " +
            "email          VARCHAR, " +
            "token          VARCHAR, " +
            "sync_token     VARCHAR, " +
            "is_todoist     INTEGER, " +
            "is_premium     INTEGER, " +
            "avatar         VARCHAR, " +
            "join_date      VARCHAR, " +
            "inbox_project  INTEGER)", null, null);
        debug ("Table USERS created");

        rc = db.exec ("CREATE TABLE IF NOT EXISTS ITEMS (" +
            "id              INTEGER PRIMARY KEY, " +
            "content         VARCHAR, " +
            "date_added      VARCHAR, " +
            "date_completed  VARCHAR, " +
            "labels          VARCHAR, " +
            "due             VARCHAR, " +
            "checked         INTEGER, " +
            "child_order     INTEGER, " +
            "day_order       INTEGER, " +
            "assigned_by_uid INTEGER, " +
            "user_id         INTEGER, " +
            "parent_id       INTEGER, " +
            "responsible_uid INTEGER, " +
            "priority        INTEGER, " +
            "is_deleted      INTEGER, " +
            "collapsed       INTEGER, " +
            "project_id      INTEGER)", null, null);
        debug ("Table ITEMS created");

        return rc;
    }
    
    /*
        Projects 
    */
    /*
    public int add_project (Objects.Project project) {
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("INSERT INTO PROJECTS (id, name, note, color, icon, " +
            "labels, duedate, child_order, is_todoist, is_inbox, is_deleted, is_archived, is_favorite)" +
            "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, project.id);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (2, project.name);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (3, project.note);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (4, project.color);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (5, project.icon);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (6, project.labels);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (7, project.duedate);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (8, project.child_order);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (9, project.is_todoist);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (10, project.is_inbox);
        assert (res == Sqlite.OK);
        
        res = stmt.bind_int (11, project.is_deleted);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (12, project.is_archived);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (13, project.is_favorite);
        assert (res == Sqlite.OK);

        res = stmt.step ();

        if (res == Sqlite.DONE) {
            project_added (project);
        }
        
        return res;
    }
    
    public Gee.ArrayList<Objects.Project?> get_all_projects () {
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("SELECT * FROM PROJECTS",
            -1, out stmt);
        assert (res == Sqlite.OK);

        var all = new Gee.ArrayList<Objects.Project?> ();

        while ((res = stmt.step()) == Sqlite.ROW) {
            var project = new Objects.Project ();

            project.id = stmt.column_int64 (0);
            project.name = stmt.column_text (1);
            project.note = stmt.column_text (2);
            project.color = stmt.column_text (3);
            project.icon = stmt.column_text (4);
            project.labels = stmt.column_text (5);
            project.duedate = stmt.column_text (6);
            project.child_order = stmt.column_int (7);
            project.is_todoist = stmt.column_int (8);
            project.is_inbox = stmt.column_int (9);
            project.is_deleted = stmt.column_int (10);
            project.is_archived = stmt.column_int (11);
            project.is_favorite = stmt.column_int (12);

            all.add (project);
        }

        return all;
    }
    
    public int update_project (Objects.Project project) {
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("UPDATE PROJECTS SET name = ?, note = ?, color = ?, icon = ?, " +
            "labels = ?, duedate = ?, child_order = ?, is_todoist = ?, is_inbox = ?, is_deleted = ?, is_archived = ?, is_favorite = ? " +
            "WHERE id = ?", -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (1, project.name);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (2, project.note);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (3, project.color);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (4, project.icon);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (5, project.labels);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (6, project.duedate);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (7, project.child_order);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (8, project.is_todoist);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (9, project.is_inbox);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (10, project.is_deleted);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (11, project.is_archived);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (12, project.is_favorite);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (13, project.id);
        assert (res == Sqlite.OK);

        res = stmt.step ();

        if (res == Sqlite.DONE) {
            project_updated (project);
        }

        return res;
    }
    */
    /*
        User 
    */
    public bool user_exists () {
        bool exists = false;
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("SELECT COUNT (*) FROM USERS", -1, out stmt);
        assert (res == Sqlite.OK);

        if (stmt.step () == Sqlite.ROW) {
            exists = stmt.column_int (0) > 0;
        }

        return exists;
    }
    /*
    public int create_user (Objects.User user) {
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("INSERT INTO USERS (id, full_name, email, token, sync_token, " +
            "is_todoist, is_premium, avatar, join_date, inbox_project)" +
            "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", -1, out stmt);
        assert (res == Sqlite.OK);


        res = stmt.bind_int64 (1, user.id);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (2, user.full_name);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (3, user.email);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (4, user.token);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (5, user.sync_token);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (6, user.is_todoist);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (7, user.is_premium);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (8, user.avatar);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (9, user.join_date);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (10, user.inbox_project);
        assert (res == Sqlite.OK);

        res = stmt.step ();

        if (res == Sqlite.DONE) {
            user_added (user);
        }

        return res;
    }
    */
    /*
    public Objects.User get_user () {
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("SELECT * FROM USERS ORDER BY id ASC LIMIT 1",
            -1, out stmt);
        assert (res == Sqlite.OK);

        stmt.step ();

        var user = new Objects.User ();

        user.id = stmt.column_int64 (0);
        user.full_name = stmt.column_text (1);
        user.email = stmt.column_text (2);
        user.token = stmt.column_text (3);
        user.sync_token = stmt.column_text (4);
        user.is_todoist = stmt.column_int (5);
        user.is_premium = stmt.column_int (6);
        user.avatar = stmt.column_text (7);
        user.join_date = stmt.column_text (8);
        user.inbox_project = stmt.column_int64 (9);

        return user;
    }
    */
    public int update_sync_token (Objects.User user) {
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("UPDATE USERS SET sync_token = ? WHERE id = ?", -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (1, user.sync_token);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (2, user.id);
        assert (res == Sqlite.OK);

        res = stmt.step ();

        /*
        if (res == Sqlite.DONE) {
            project_updated (project);
        }
        */

        return res;
    }
}