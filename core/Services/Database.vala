/*
 * Copyright © 2023 Alain M. (https://github.com/alainm23/planify)
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 3 of the License, or (at your option) any later version.
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
 * Authored by: Alain M. <alainmh23@gmail.com>
 */

public class Services.Database : GLib.Object {
    private Sqlite.Database db;
    private string db_path;
    private string errormsg;
    private string sql;

    private Gee.HashMap<string, Gee.ArrayList<string> > table_columns = new Gee.HashMap<string, Gee.ArrayList<string> > ();

    public bool is_opened { get; set; default = false; }
    public signal void opened ();
    public signal void reset ();

    private static Database ? _instance;
    public static Database get_default () {
        if (_instance == null) {
            _instance = new Database ();
        }

        return _instance;
    }

    construct {
        table_columns["Attachments"] = new Gee.ArrayList<string> ();
        table_columns["Attachments"].add ("id");
        table_columns["Attachments"].add ("item_id");
        table_columns["Attachments"].add ("file_type");
        table_columns["Attachments"].add ("file_name");
        table_columns["Attachments"].add ("file_size");
        table_columns["Attachments"].add ("file_path");

        table_columns["CurTempIds"] = new Gee.ArrayList<string> ();
        table_columns["CurTempIds"].add ("id");
        table_columns["CurTempIds"].add ("temp_id");
        table_columns["CurTempIds"].add ("object");

        table_columns["Items"] = new Gee.ArrayList<string> ();
        table_columns["Items"].add ("id");
        table_columns["Items"].add ("content");
        table_columns["Items"].add ("description");
        table_columns["Items"].add ("due");
        table_columns["Items"].add ("added_at");
        table_columns["Items"].add ("completed_at");
        table_columns["Items"].add ("updated_at");
        table_columns["Items"].add ("section_id");
        table_columns["Items"].add ("project_id");
        table_columns["Items"].add ("parent_id");
        table_columns["Items"].add ("priority");
        table_columns["Items"].add ("child_order");
        table_columns["Items"].add ("checked");
        table_columns["Items"].add ("is_deleted");
        table_columns["Items"].add ("day_order");
        table_columns["Items"].add ("collapsed");
        table_columns["Items"].add ("pinned");
        table_columns["Items"].add ("labels");
        table_columns["Items"].add ("extra_data");
        table_columns["Items"].add ("item_type");

        table_columns["Labels"] = new Gee.ArrayList<string> ();
        table_columns["Labels"].add ("id");
        table_columns["Labels"].add ("name");
        table_columns["Labels"].add ("color");
        table_columns["Labels"].add ("item_order");
        table_columns["Labels"].add ("is_deleted");
        table_columns["Labels"].add ("is_favorite");
        table_columns["Labels"].add ("backend_type");
        table_columns["Labels"].add ("source_id");

        table_columns["OEvents"] = new Gee.ArrayList<string> ();
        table_columns["OEvents"].add ("id");
        table_columns["OEvents"].add ("event_type");
        table_columns["OEvents"].add ("event_date");
        table_columns["OEvents"].add ("object_id");
        table_columns["OEvents"].add ("object_type");
        table_columns["OEvents"].add ("object_key");
        table_columns["OEvents"].add ("object_old_value");
        table_columns["OEvents"].add ("object_new_value");
        table_columns["OEvents"].add ("parent_item_id");
        table_columns["OEvents"].add ("parent_project_id");

        table_columns["Projects"] = new Gee.ArrayList<string> ();
        table_columns["Projects"].add ("id");
        table_columns["Projects"].add ("name");
        table_columns["Projects"].add ("color");
        table_columns["Projects"].add ("backend_type");
        table_columns["Projects"].add ("inbox_project");
        table_columns["Projects"].add ("team_inbox");
        table_columns["Projects"].add ("child_order");
        table_columns["Projects"].add ("is_deleted");
        table_columns["Projects"].add ("is_archived");
        table_columns["Projects"].add ("is_favorite");
        table_columns["Projects"].add ("shared");
        table_columns["Projects"].add ("view_style");
        table_columns["Projects"].add ("sort_order");
        table_columns["Projects"].add ("parent_id");
        table_columns["Projects"].add ("collapsed");
        table_columns["Projects"].add ("icon_style");
        table_columns["Projects"].add ("emoji");
        table_columns["Projects"].add ("show_completed");
        table_columns["Projects"].add ("description");
        table_columns["Projects"].add ("due_date");
        table_columns["Projects"].add ("inbox_section_hidded");
        table_columns["Projects"].add ("sync_id");
        table_columns["Projects"].add ("source_id");
        table_columns["Projects"].add ("calendar_url");
        table_columns["Projects"].add ("sorted_by");

        table_columns["Queue"] = new Gee.ArrayList<string> ();
        table_columns["Queue"].add ("uuid");
        table_columns["Queue"].add ("object_id");
        table_columns["Queue"].add ("query");
        table_columns["Queue"].add ("temp_id");
        table_columns["Queue"].add ("args");
        table_columns["Queue"].add ("date_added");

        table_columns["Reminders"] = new Gee.ArrayList<string> ();
        table_columns["Reminders"].add ("id");
        table_columns["Reminders"].add ("notify_uid");
        table_columns["Reminders"].add ("item_id");
        table_columns["Reminders"].add ("service");
        table_columns["Reminders"].add ("type");
        table_columns["Reminders"].add ("due");
        table_columns["Reminders"].add ("mm_offset");
        table_columns["Reminders"].add ("is_deleted");

        table_columns["Sections"] = new Gee.ArrayList<string> ();
        table_columns["Sections"].add ("id");
        table_columns["Sections"].add ("name");
        table_columns["Sections"].add ("archived_at");
        table_columns["Sections"].add ("added_at");
        table_columns["Sections"].add ("project_id");
        table_columns["Sections"].add ("section_order");
        table_columns["Sections"].add ("collapsed");
        table_columns["Sections"].add ("is_deleted");
        table_columns["Sections"].add ("is_archived");
        table_columns["Sections"].add ("color");
        table_columns["Sections"].add ("description");
        table_columns["Sections"].add ("hidded");

        table_columns["Sources"] = new Gee.ArrayList<string> ();
        table_columns["Sources"].add ("id");
        table_columns["Sources"].add ("source_type");
        table_columns["Sources"].add ("display_name");
        table_columns["Sources"].add ("added_at");
        table_columns["Sources"].add ("updated_at");
        table_columns["Sources"].add ("is_visible");
        table_columns["Sources"].add ("child_order");
        table_columns["Sources"].add ("sync_server");
        table_columns["Sources"].add ("last_sync");
        table_columns["Sources"].add ("data");
    }

    public void init_database () {
        db_path = Environment.get_user_data_dir () + "/io.github.alainm23.planify/database.db";
        Sqlite.Database.open (db_path, out db);

        create_tables ();
        create_triggers ();
        patch_database ();
        opened ();
        is_opened = true;
    }

    private void create_tables () {
        sql = """
            CREATE TABLE IF NOT EXISTS Labels (
                id              TEXT PRIMARY KEY,
                name            TEXT,
                color           TEXT,
                item_order      INTEGER,
                is_deleted      INTEGER,
                is_favorite     INTEGER,
                backend_type    TEXT,
                source_id       TEXT,
                CONSTRAINT unique_label UNIQUE (name)
            );
        """;

        if (db.exec (sql, null, out errormsg) != Sqlite.OK) {
            warning (errormsg);
        }

        sql = """
            CREATE TABLE IF NOT EXISTS Projects (
                id                      TEXT PRIMARY KEY,
                name                    TEXT NOT NULL,
                color                   TEXT,
                backend_type            TEXT,
                inbox_project           INTEGER,
                team_inbox              INTEGER,
                child_order             INTEGER,
                is_deleted              INTEGER,
                is_archived             INTEGER,
                is_favorite             INTEGER,
                shared                  INTEGER,
                view_style              TEXT,
                sort_order              INTEGER,
                parent_id               TEXT,
                collapsed               INTEGER,
                icon_style              TEXT,
                emoji                   TEXT,
                show_completed          INTEGER,
                description             TEXT,
                due_date                TEXT,
                inbox_section_hidded    INTEGER,
                sync_id                 TEXT,
                source_id               TEXT,
                calendar_url            TEXT,
                sorted_by               TEXT
            );
        """;

        if (db.exec (sql, null, out errormsg) != Sqlite.OK) {
            warning (errormsg);
        }

        sql = """
            CREATE TABLE IF NOT EXISTS Sections (
                id              TEXT PRIMARY KEY,
                name            TEXT,
                archived_at     TEXT,
                added_at        TEXT,
                project_id      TEXT,
                section_order   INTEGER,
                collapsed       INTEGER,
                is_deleted      INTEGER,
                is_archived     INTEGER,
                color           TEXT,
                description     TEXT,
                hidded          INTEGER,
                FOREIGN KEY (project_id) REFERENCES Projects (id) ON DELETE CASCADE
            );
        """;

        if (db.exec (sql, null, out errormsg) != Sqlite.OK) {
            warning (errormsg);
        }

        sql = """
            CREATE TABLE IF NOT EXISTS Items (
                id                  TEXT PRIMARY KEY,
                content             TEXT NOT NULL,
                description         TEXT,
                due                 TEXT,
                added_at            TEXT,
                completed_at        TEXT,
                updated_at          TEXT,
                section_id          TEXT,
                project_id          TEXT,
                parent_id           TEXT,
                priority            INTEGER,
                child_order         INTEGER,
                checked             INTEGER,
                is_deleted          INTEGER,
                day_order           INTEGER,
                collapsed           INTEGER,
                pinned              INTEGER,
                labels              TEXT,
                extra_data          TEXT,
                item_type           TEXT
            );
        """;

        if (db.exec (sql, null, out errormsg) != Sqlite.OK) {
            warning (errormsg);
        }

        sql = """
            CREATE TABLE IF NOT EXISTS Reminders (
                id                  TEXT PRIMARY KEY,
                notify_uid          INTEGER,
                item_id             TEXT,
                service             TEXT,
                type                TEXT,
                due                 TEXT,
                mm_offset           INTEGER,
                is_deleted          INTEGER,
                FOREIGN KEY (item_id) REFERENCES Items (id) ON DELETE CASCADE
            );
        """;

        if (db.exec (sql, null, out errormsg) != Sqlite.OK) {
            warning (errormsg);
        }

        sql = """
            CREATE TABLE IF NOT EXISTS Queue (
                uuid       TEXT PRIMARY KEY,
                object_id  TEXT,
                query      TEXT,
                temp_id    TEXT,
                args       TEXT,
                date_added TEXT
            );
        """;

        if (db.exec (sql, null, out errormsg) != Sqlite.OK) {
            warning (errormsg);
        }

        sql = """
            CREATE TABLE IF NOT EXISTS CurTempIds (
                id          TEXT PRIMARY KEY,
                temp_id     TEXT,
                object      TEXT
            );
        """;

        if (db.exec (sql, null, out errormsg) != Sqlite.OK) {
            warning (errormsg);
        }

        sql = """
            CREATE TABLE IF NOT EXISTS Attachments (
                id              TEXT PRIMARY KEY,
                item_id         TEXT,
                file_type       TEXT,
                file_name       TEXT,
                file_size       TEXT,
                file_path       TEXT,
                FOREIGN KEY (item_id) REFERENCES Items (id) ON DELETE CASCADE
            );
        """;

        if (db.exec (sql, null, out errormsg) != Sqlite.OK) {
            warning (errormsg);
        }

        sql = """
            CREATE TABLE IF NOT EXISTS OEvents (
                id                  INTEGER PRIMARY KEY AUTOINCREMENT,
                event_type          TEXT,
                event_date          DATETIME DEFAULT (datetime('now','localtime')),
                object_id           TEXT,
                object_type         TEXT,
                object_key          TEXT,
                object_old_value    TEXT,
                object_new_value    TEXT,
                parent_item_id      TEXT,
                parent_project_id   TEXT
            );
        """;

        if (db.exec (sql, null, out errormsg) != Sqlite.OK) {
            warning (errormsg);
        }

        sql = """
            CREATE TABLE IF NOT EXISTS Sources (
                id                  TEXT PRIMARY KEY,
                source_type         TEXT NOT NULL,
                display_name        TEXT,
                added_at            TEXT,
                updated_at          TEXT,
                is_visible          INTEGER,
                child_order         INTEGER,
                sync_server         INTEGER,
                last_sync           TEXT,
                data                TEXT
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

    private void create_triggers () {
        sql = """
            CREATE TRIGGER IF NOT EXISTS after_insert_item
            AFTER INSERT ON Items
            BEGIN
                INSERT OR IGNORE INTO OEvents (event_type, object_id,
                    object_type, object_key, object_old_value, object_new_value, parent_project_id)
                VALUES ('insert', NEW.id, 'item', 'content', NEW.content,
                    NEW.content, NEW.project_id);
            END;
        """;

        if (db.exec (sql, null, out errormsg) != Sqlite.OK) {
            warning (errormsg);
        }

        sql = """
            CREATE TRIGGER IF NOT EXISTS after_update_content_item
            AFTER UPDATE ON Items
            FOR EACH ROW
            WHEN NEW.content != OLD.content
            BEGIN
                INSERT OR IGNORE INTO OEvents (event_type, object_id,
                    object_type, object_key, object_old_value, object_new_value, parent_project_id)
                VALUES ('update', NEW.id, 'item', 'content', OLD.content,
                    NEW.content, NEW.project_id);
            END;
        """;

        if (db.exec (sql, null, out errormsg) != Sqlite.OK) {
            warning (errormsg);
        }

        sql = """
            CREATE TRIGGER IF NOT EXISTS after_update_description_item
            AFTER UPDATE ON Items
            FOR EACH ROW
            WHEN NEW.description != OLD.description
            BEGIN
                INSERT OR IGNORE INTO OEvents (event_type, object_id,
                    object_type, object_key, object_old_value, object_new_value, parent_project_id)
                VALUES ('update', NEW.id, 'item', 'description', OLD.description,
                    NEW.description, NEW.project_id);
            END;
        """;

        if (db.exec (sql, null, out errormsg) != Sqlite.OK) {
            warning (errormsg);
        }

        sql = """
            CREATE TRIGGER IF NOT EXISTS after_update_due_item
            AFTER UPDATE ON Items
            FOR EACH ROW
            WHEN NEW.due != OLD.due
            BEGIN
                INSERT OR IGNORE INTO OEvents (event_type, object_id,
                    object_type, object_key, object_old_value, object_new_value, parent_project_id)
                VALUES ('update', NEW.id, 'item', 'due', OLD.due,
                    NEW.due, NEW.project_id);
            END;
        """;

        if (db.exec (sql, null, out errormsg) != Sqlite.OK) {
            warning (errormsg);
        }

        sql = """
            CREATE TRIGGER IF NOT EXISTS after_update_priority_item
            AFTER UPDATE ON Items
            FOR EACH ROW
            WHEN NEW.priority != OLD.priority
            BEGIN
                INSERT OR IGNORE INTO OEvents (event_type, object_id,
                    object_type, object_key, object_old_value, object_new_value, parent_project_id)
                VALUES ('update', NEW.id, 'item', 'priority', OLD.priority,
                    NEW.priority, NEW.project_id);
            END;
        """;

        if (db.exec (sql, null, out errormsg) != Sqlite.OK) {
            warning (errormsg);
        }

        sql = """
            CREATE TRIGGER IF NOT EXISTS after_update_labels_item
            AFTER UPDATE ON Items
            FOR EACH ROW
            WHEN NEW.labels != OLD.labels
            BEGIN
                INSERT OR IGNORE INTO OEvents (event_type, object_id,
                    object_type, object_key, object_old_value, object_new_value, parent_project_id)
                VALUES ('update', NEW.id, 'item', 'labels', OLD.labels,
                    NEW.labels, NEW.project_id);
            END;
        """;

        if (db.exec (sql, null, out errormsg) != Sqlite.OK) {
            warning (errormsg);
        }

        sql = """
            CREATE TRIGGER IF NOT EXISTS after_update_pinned_item
            AFTER UPDATE ON Items
            FOR EACH ROW
            WHEN NEW.pinned != OLD.pinned
            BEGIN
                INSERT OR IGNORE INTO OEvents (event_type, object_id,
                    object_type, object_key, object_old_value, object_new_value, parent_project_id)
                VALUES ('update', NEW.id, 'item', 'pinned', OLD.pinned,
                    NEW.pinned, NEW.project_id);
            END;
        """;

        if (db.exec (sql, null, out errormsg) != Sqlite.OK) {
            warning (errormsg);
        }

        sql = """
            CREATE TRIGGER IF NOT EXISTS after_update_checked_item
            AFTER UPDATE ON Items
            FOR EACH ROW
            WHEN NEW.checked != OLD.checked
            BEGIN
                INSERT OR IGNORE INTO OEvents (event_type, object_id,
                    object_type, object_key, object_old_value, object_new_value, parent_project_id)
                VALUES ('update', NEW.id, 'item', 'checked', OLD.checked,
                    NEW.checked, NEW.project_id);
            END;
        """;

        sql = """
            CREATE TRIGGER IF NOT EXISTS after_update_section_item
            AFTER UPDATE ON Items
            FOR EACH ROW
            WHEN NEW.section_id != OLD.section_id
            BEGIN
                INSERT OR IGNORE INTO OEvents (event_type, object_id,
                    object_type, object_key, object_old_value, object_new_value, parent_project_id)
                VALUES ('update', NEW.id, 'item', 'section', OLD.section_id,
                    NEW.section_id, NEW.project_id);
            END;
        """;

        if (db.exec (sql, null, out errormsg) != Sqlite.OK) {
            warning (errormsg);
        }

        sql = """
            CREATE TRIGGER IF NOT EXISTS after_update_project_item
            AFTER UPDATE ON Items
            FOR EACH ROW
            WHEN NEW.project_id != OLD.project_id
            BEGIN
                INSERT OR IGNORE INTO OEvents (event_type, object_id,
                    object_type, object_key, object_old_value, object_new_value, parent_project_id)
                VALUES ('update', NEW.id, 'item', 'project', OLD.project_id,
                    NEW.project_id, NEW.project_id);
            END;
        """;

        if (db.exec (sql, null, out errormsg) != Sqlite.OK) {
            warning (errormsg);
        }
    }

    public void patch_database () {
        /*
         * Planner 3 - Beta 1
         * - Add pinned (0|1) to Items
         */

        add_int_column ("Items", "pinned", 0);

        /*
         * Planner 3 - Beta 2
         * - Add show_completed (0|1) to Projects
         */

        add_int_column ("Projects", "show_completed", 0);

        /*
         *  Planner 3.10
         * - Add description to Projects
         */

        add_text_column ("Projects", "description", "");

        /*
         * Planify 4.4
         * - Add labels column to Items
         * - Add color column to Section
         * - Add description column to Section
         */

        add_item_label_column ();
        add_text_column ("Sections", "color", "blue");
        add_text_column ("Sections", "description", "");

        /*
         * Planify 4.5
         * - Add extra data column to Items
         */

        add_text_column ("Items", "extra_data", "");
        add_int_column ("Sections", "hidded", 0);
        add_int_column ("Projects", "inbox_section_hidded", 0);

        /*
         * Planify 4.5.2
         * - Add sync_id column to Projects
         */

        add_text_column ("Projects", "sync_id", "");

        /*
         * Planify 4.8
         * - Add item_type column to Items
         */

        add_text_column ("Items", "item_type", ItemType.TASK.to_string ());

        /*
         * Planify 4.10
         * - Add source_id column to Projects
         */

        add_project_labels_source_id ();


        /*
         * Planify 4.14
         * - Add calendar_url column to Projects
         */

        add_calendar_url_to_project ();
        add_text_column ("Projects", "sorted_by", SortedByType.MANUAL.to_string ());
    }

    public void clear_database () {
        string db_path = Environment.get_user_data_dir () + "/io.github.alainm23.planify/database.db";
        File db_file = File.new_for_path (db_path);

        if (db_file.query_exists ()) {
            try {
                db_file.delete ();
            } catch (Error err) {
                warning (err.message);
            }
        }
    }

    public bool verify_integrity () {
        Sqlite.Statement stmt;

        // Verify Data Integrity
        sql = """
            PRAGMA integrity_check;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);

        if (stmt.step () == Sqlite.ROW) {
            if (stmt.column_text (0) != "ok") {
                return false;
            }
        }

        // Verify Tables Integrity
        string[] tables = { "Attachments", "CurTempIds", "Items", "Labels",
                            "OEvents", "Projects", "Queue", "Reminders", "Sections", "Sources" };

        foreach (var table_name in tables) {
            if (!table_exists (table_name)) {
                return false;
            }
        }

        // Verify Table Columns
        foreach (var table in table_columns.keys) {
            if (!table_columns_exists (table, table_columns.get (table))) {
                return false;
            }
        }

        return true;
    }

    private bool table_exists (string table_name) {
        Sqlite.Statement stmt;

        sql = """
            SELECT name FROM sqlite_master WHERE type='table' AND name='%s';
        """.printf (table_name);

        db.prepare_v2 (sql, sql.length, out stmt);

        return stmt.step () == Sqlite.ROW;
    }

    private bool table_columns_exists (string table, Gee.ArrayList<string> columns) {
        Sqlite.Statement stmt;

        sql = """
            PRAGMA table_info(%s);
        """.printf (table);

        db.prepare_v2 (sql, sql.length, out stmt);

        stmt.step ();

        while (stmt.step () == Sqlite.ROW) {
            if (!columns.contains (stmt.column_text (1))) {
                return false;
            }
        }

        return true;
    }

    /*
        Sources
     */

    public Gee.ArrayList<Objects.Source> get_sources_collection () {
        Gee.ArrayList<Objects.Source> return_value = new Gee.ArrayList<Objects.Source> ();

        Sqlite.Statement stmt;

        sql = """
            SELECT * FROM Sources ORDER BY child_order;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);

        while (stmt.step () == Sqlite.ROW) {
            return_value.add (_fill_source (stmt));
        }

        return return_value;
    }

    private Objects.Source _fill_source (Sqlite.Statement stmt) {
        Objects.Source return_value = new Objects.Source ();
        return_value.id = stmt.column_text (0);
        return_value.source_type = SourceType.parse (stmt.column_text (1));
        return_value.display_name = stmt.column_text (2);
        return_value.added_at = stmt.column_text (3);
        return_value.updated_at = stmt.column_text (4);
        return_value.is_visible = get_parameter_bool (stmt, 5);
        return_value.child_order = stmt.column_int (6);
        return_value.sync_server = get_parameter_bool (stmt, 7);
        return_value.last_sync = stmt.column_text (8);

        if (return_value.source_type == SourceType.TODOIST) {
            return_value.data = new Objects.SourceTodoistData.from_json (stmt.column_text (9));
        } else if (return_value.source_type == SourceType.CALDAV) {
            return_value.data = new Objects.SourceCalDAVData.from_json (stmt.column_text (9));
        }

        return return_value;
    }

    public bool insert_source (Objects.Source source) {
        Sqlite.Statement stmt;

        sql = """
            INSERT OR IGNORE INTO Sources (id, source_type, display_name, added_at,
                updated_at, is_visible, child_order, sync_server, last_sync, data)
            VALUES ($id, $source_type, $display_name, $added_at,
                $updated_at, $is_visible, $child_order, $sync_server, $last_sync, $data);
        """;

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_str (stmt, "$id", source.id);
        set_parameter_str (stmt, "$source_type", source.source_type.to_string ());
        set_parameter_str (stmt, "$display_name", source.display_name);
        set_parameter_str (stmt, "$added_at", source.added_at);
        set_parameter_str (stmt, "$updated_at", source.updated_at);
        set_parameter_bool (stmt, "$is_visible", source.is_visible);
        set_parameter_int (stmt, "$child_order", source.child_order);
        set_parameter_bool (stmt, "$sync_server", source.sync_server);
        set_parameter_str (stmt, "$last_sync", source.last_sync);
        set_parameter_str (stmt, "$data", source.data.to_json ());

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }

        return stmt.step () == Sqlite.DONE;
    }

    public bool delete_source (Objects.Source source) {
        Sqlite.Statement stmt;

        sql = """
            DELETE FROM Sources WHERE id=$id;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_str (stmt, "$id", source.id);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }

        return stmt.step () == Sqlite.DONE;
    }

    public bool update_source (Objects.Source source) {
        Sqlite.Statement stmt;

        sql = """
            UPDATE Sources SET
                source_type=$source_type,
                display_name=$display_name,
                updated_at=$updated_at,
                is_visible=$is_visible,
                child_order=$child_order,
                sync_server=$sync_server,
                last_sync=$last_sync,
                data=$data
            WHERE id=$id;
        """;
        
        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_str (stmt, "$source_type", source.source_type.to_string ());
        set_parameter_str (stmt, "$display_name", source.display_name);
        set_parameter_str (stmt, "$updated_at", source.updated_at);
        set_parameter_bool (stmt, "$is_visible", source.is_visible);
        set_parameter_int (stmt, "$child_order", source.child_order);
        set_parameter_bool (stmt, "$sync_server", source.sync_server);
        set_parameter_str (stmt, "$last_sync", source.last_sync);
        set_parameter_str (stmt, "$data", source.data.to_json ());
        set_parameter_str (stmt, "$id", source.id);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }

        return stmt.step () == Sqlite.DONE;
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

        return return_value;
    }

    public Objects.Project _fill_project (Sqlite.Statement stmt) {
        Objects.Project return_value = new Objects.Project ();
        return_value.id = stmt.column_text (0);
        return_value.name = stmt.column_text (1);
        return_value.color = stmt.column_text (2);
        return_value.backend_type = SourceType.parse (stmt.column_text (3));
        return_value.inbox_project = get_parameter_bool (stmt, 4);
        return_value.team_inbox = get_parameter_bool (stmt, 5);
        return_value.child_order = stmt.column_int (6);
        return_value.is_deleted = get_parameter_bool (stmt, 7);
        return_value.is_archived = get_parameter_bool (stmt, 8);
        return_value.is_favorite = get_parameter_bool (stmt, 9);
        return_value.shared = get_parameter_bool (stmt, 10);
        return_value.view_style = ProjectViewStyle.parse (stmt.column_text (11));
        return_value.sort_order = SortOrderType.parse (stmt.column_text (12));
        return_value.parent_id = stmt.column_text (13);
        return_value.collapsed = get_parameter_bool (stmt, 14);
        return_value.icon_style = ProjectIconStyle.parse (stmt.column_text (15));
        return_value.emoji = stmt.column_text (16);
        return_value.show_completed = get_parameter_bool (stmt, 17);
        return_value.description = stmt.column_text (18);
        return_value.due_date = stmt.column_text (19);
        return_value.inbox_section_hidded = get_parameter_bool (stmt, 20);
        return_value.sync_id = stmt.column_text (21);
        return_value.source_id = stmt.column_text (22);
        return_value.calendar_url = stmt.column_text (23);
        return_value.sorted_by = SortedByType.parse (stmt.column_text (24));
        return return_value;
    }

    public bool insert_project (Objects.Project project) {
        Sqlite.Statement stmt;

        sql = """
            INSERT OR IGNORE INTO Projects (id, name, color, backend_type, inbox_project,
                team_inbox, child_order, is_deleted, is_archived, is_favorite, shared, view_style,
                sort_order, parent_id, collapsed, icon_style, emoji, show_completed, description, due_date,
                inbox_section_hidded, sync_id, source_id, calendar_url, sorted_by)
            VALUES ($id, $name, $color, $backend_type, $inbox_project, $team_inbox,
                $child_order, $is_deleted, $is_archived, $is_favorite, $shared, $view_style,
                $sort_order, $parent_id, $collapsed, $icon_style, $emoji, $show_completed, $description, $due_date,
                $inbox_section_hidded, $sync_id, $source_id, $calendar_url, $sorted_by);
        """;

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_str (stmt, "$id", project.id);
        set_parameter_str (stmt, "$name", project.name);
        set_parameter_str (stmt, "$color", project.color);
        set_parameter_str (stmt, "$backend_type", project.backend_type.to_string ());
        set_parameter_bool (stmt, "$inbox_project", project.inbox_project);
        set_parameter_bool (stmt, "$team_inbox", project.team_inbox);
        set_parameter_int (stmt, "$child_order", project.child_order);
        set_parameter_bool (stmt, "$is_deleted", project.is_deleted);
        set_parameter_bool (stmt, "$is_archived", project.is_archived);
        set_parameter_bool (stmt, "$is_favorite", project.is_favorite);
        set_parameter_bool (stmt, "$shared", project.shared);
        set_parameter_str (stmt, "$view_style", project.view_style.to_string ());
        set_parameter_str (stmt, "$sort_order", project.sort_order.to_string ());
        set_parameter_str (stmt, "$parent_id", project.parent_id);
        set_parameter_bool (stmt, "$collapsed", project.collapsed);
        set_parameter_str (stmt, "$icon_style", project.icon_style.to_string ());
        set_parameter_str (stmt, "$emoji", project.emoji);
        set_parameter_bool (stmt, "$show_completed", project.show_completed);
        set_parameter_str (stmt, "$description", project.description);
        set_parameter_str (stmt, "$due_date", project.due_date);
        set_parameter_bool (stmt, "$inbox_section_hidded", project.inbox_section_hidded);
        set_parameter_str (stmt, "$sync_id", project.sync_id);
        set_parameter_str (stmt, "$source_id", project.source_id);
        set_parameter_str (stmt, "$calendar_url", project.calendar_url);
        set_parameter_str (stmt, "$sorted_by", project.sorted_by.to_string ());

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }

        return stmt.step () == Sqlite.DONE;
    }

    public bool delete_project (Objects.Project project) {
        Sqlite.Statement stmt;

        sql = """
            DELETE FROM Projects WHERE id=$id;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_str (stmt, "$id", project.id);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }

        return stmt.step () == Sqlite.DONE;
    }

    public void delete_project_db (Objects.Project project) {
        Sqlite.Statement stmt;

        sql = """
            DELETE FROM Projects WHERE id=$id;
            DELETE FROM Items WHERE project_id=$item_project_id;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_str (stmt, "$id", project.id);
        set_parameter_str (stmt, "$section_project_id", project.id);
        set_parameter_str (stmt, "$item_project_id", project.id);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }
    }

    public bool update_project (Objects.Project project) {
        Sqlite.Statement stmt;

        sql = """
            UPDATE Projects SET
                name=$name,
                color=$color,
                backend_type=$backend_type,
                inbox_project=$inbox_project,
                team_inbox=$team_inbox,
                child_order=$child_order,
                is_deleted=$is_deleted,
                is_archived=$is_archived,
                is_favorite=$is_favorite,
                shared=$shared,
                view_style=$view_style,
                sort_order=$sort_order,
                parent_id=$parent_id,
                collapsed=$collapsed,
                icon_style=$icon_style,
                emoji=$emoji,
                show_completed=$show_completed,
                description=$description,
                due_date=$due_date,
                inbox_section_hidded=$inbox_section_hidded,
                sync_id=$sync_id,
                source_id=$source_id,
                calendar_url=$calendar_url,
                sorted_by=$sorted_by
            WHERE id=$id;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_str (stmt, "$name", project.name);
        set_parameter_str (stmt, "$color", project.color);
        set_parameter_str (stmt, "$backend_type", project.backend_type.to_string ());
        set_parameter_bool (stmt, "$inbox_project", project.inbox_project);
        set_parameter_bool (stmt, "$team_inbox", project.team_inbox);
        set_parameter_int (stmt, "$child_order", project.child_order);
        set_parameter_bool (stmt, "$is_deleted", project.is_deleted);
        set_parameter_bool (stmt, "$is_archived", project.is_archived);
        set_parameter_bool (stmt, "$is_favorite", project.is_favorite);
        set_parameter_bool (stmt, "$shared", project.shared);
        set_parameter_str (stmt, "$view_style", project.view_style.to_string ());
        set_parameter_str (stmt, "$sort_order", project.sort_order.to_string ());
        set_parameter_str (stmt, "$parent_id", project.parent_id);
        set_parameter_bool (stmt, "$collapsed", project.collapsed);
        set_parameter_str (stmt, "$icon_style", project.icon_style.to_string ());
        set_parameter_str (stmt, "$emoji", project.emoji);
        set_parameter_bool (stmt, "$show_completed", project.show_completed);
        set_parameter_str (stmt, "$description", project.description);
        set_parameter_str (stmt, "$due_date", project.due_date);
        set_parameter_bool (stmt, "$inbox_section_hidded", project.inbox_section_hidded);
        if (project.sync_id != null) {
            set_parameter_str (stmt, "$sync_id", project.sync_id);
        }
        set_parameter_str (stmt, "$source_id", project.source_id);
        set_parameter_str (stmt, "$calendar_url", project.calendar_url);
        set_parameter_str (stmt, "$sorted_by", project.sorted_by.to_string ());
        set_parameter_str (stmt, "$id", project.id);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }

        return stmt.step () == Sqlite.DONE;
    }

    public bool archive_project (Objects.Project project) {
        Sqlite.Statement stmt;

        sql = """
            UPDATE Projects SET is_archived=$is_archived WHERE id=$id;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_bool (stmt, "$is_archived", project.is_archived);
        set_parameter_str (stmt, "$id", project.id);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }

        return stmt.step () == Sqlite.DONE;
    }

    /*
     *   Labels
     */

    public Gee.ArrayList<Objects.Label> get_labels_collection () {
        Gee.ArrayList<Objects.Label> return_value = new Gee.ArrayList<Objects.Label> ();
        Sqlite.Statement stmt;

        sql = """
            SELECT * FROM Labels;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);

        while (stmt.step () == Sqlite.ROW) {
            return_value.add (_fill_label (stmt));
        }

        return return_value;
    }

    public Objects.Label _fill_label (Sqlite.Statement stmt) {
        Objects.Label return_value = new Objects.Label ();
        return_value.id = stmt.column_text (0);
        return_value.name = stmt.column_text (1);
        return_value.color = stmt.column_text (2);
        return_value.item_order = stmt.column_int (3);
        return_value.is_deleted = get_parameter_bool (stmt, 4);
        return_value.is_favorite = get_parameter_bool (stmt, 5);
        return_value.backend_type = SourceType.parse (stmt.column_text (6));
        return_value.source_id = stmt.column_text (7);
        return return_value;
    }

    public bool insert_label (Objects.Label label) {
        Sqlite.Statement stmt;

        sql = """
            INSERT OR IGNORE INTO Labels (id, name, color, item_order,
                is_deleted, is_favorite, backend_type, source_id)
            VALUES ($id, $name, $color, $item_order,
                $is_deleted, $is_favorite, $backend_type, $source_id);
        """;

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_str (stmt, "$id", label.id);
        set_parameter_str (stmt, "$name", label.name);
        set_parameter_str (stmt, "$color", label.color);
        set_parameter_int (stmt, "$item_order", label.item_order);
        set_parameter_bool (stmt, "$is_deleted", label.is_deleted);
        set_parameter_bool (stmt, "$is_favorite", label.is_favorite);
        set_parameter_str (stmt, "$backend_type", label.backend_type.to_string ());
        set_parameter_str (stmt, "$source_id", label.source_id);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }

        return stmt.step () == Sqlite.DONE;
    }

    public bool delete_label (Objects.Label label) {
        Sqlite.Statement stmt;

        sql = """
            DELETE FROM Labels WHERE id=$id;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_str (stmt, "$id", label.id);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }

        return stmt.step () == Sqlite.DONE;
    }

    public bool update_label (Objects.Label label) {
        Sqlite.Statement stmt;

        sql = """
            UPDATE Labels SET name=$name, color=$color, item_order=$item_order,
                is_deleted=$is_deleted, is_favorite=$is_favorite
            WHERE id=$id;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_str (stmt, "$name", label.name);
        set_parameter_str (stmt, "$color", label.color);
        set_parameter_int (stmt, "$item_order", label.item_order);
        set_parameter_bool (stmt, "$is_deleted", label.is_deleted);
        set_parameter_bool (stmt, "$is_favorite", label.is_favorite);
        set_parameter_str (stmt, "$id", label.id);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }

        return stmt.step () == Sqlite.DONE;
    }

    /*
        Sections
     */

    public bool insert_section (Objects.Section section) {
        Sqlite.Statement stmt;

        sql = """
            INSERT OR IGNORE INTO Sections (id, name, archived_at, added_at, project_id, section_order,
            collapsed, is_deleted, is_archived, color, description, hidded)
            VALUES ($id, $name, $archived_at, $added_at, $project_id, $section_order,
            $collapsed, $is_deleted, $is_archived, $color, $description, $hidded);
        """;

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_str (stmt, "$id", section.id);
        set_parameter_str (stmt, "$name", section.name);
        set_parameter_str (stmt, "$archived_at", section.archived_at);
        set_parameter_str (stmt, "$added_at", section.added_at);
        set_parameter_str (stmt, "$project_id", section.project_id);
        set_parameter_int (stmt, "$section_order", section.section_order);
        set_parameter_bool (stmt, "$collapsed", section.collapsed);
        set_parameter_bool (stmt, "$is_deleted", section.is_deleted);
        set_parameter_bool (stmt, "$is_archived", section.is_archived);
        set_parameter_str (stmt, "$color", section.color);
        set_parameter_str (stmt, "$description", section.description);
        set_parameter_bool (stmt, "$hidded", section.hidded);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }

        return stmt.step () == Sqlite.DONE;
    }

    public Gee.ArrayList<Objects.Section> get_sections_collection () {
        Gee.ArrayList<Objects.Section> return_value = new Gee.ArrayList<Objects.Section> ();

        Sqlite.Statement stmt;
        sql = "SELECT * FROM Sections WHERE is_deleted = 0;";

        db.prepare_v2 (sql, sql.length, out stmt);

        while (stmt.step () == Sqlite.ROW) {
            return_value.add (_fill_section (stmt));
        }

        return return_value;
    }

    public Objects.Section _fill_section (Sqlite.Statement stmt) {
        Objects.Section return_value = new Objects.Section ();
        return_value.id = stmt.column_text (0);
        return_value.name = stmt.column_text (1);
        return_value.archived_at = stmt.column_text (2);
        return_value.added_at = stmt.column_text (3);
        return_value.project_id = stmt.column_text (4);
        return_value.section_order = stmt.column_int (5);
        return_value.collapsed = get_parameter_bool (stmt, 6);
        return_value.is_deleted = get_parameter_bool (stmt, 7);
        return_value.is_archived = get_parameter_bool (stmt, 8);
        return_value.color = stmt.column_text (9);
        return_value.description = stmt.column_text (10);
        return_value.hidded = get_parameter_bool (stmt, 11);
        return return_value;
    }

    public bool delete_section (Objects.Section section) {
        Sqlite.Statement stmt;

        sql = """
            DELETE FROM Sections WHERE id=$id;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_str (stmt, "$id", section.id);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }

        return stmt.step () == Sqlite.DONE;
    }

    public bool update_section (Objects.Section section) {
        Sqlite.Statement stmt;

        sql = """
            UPDATE Sections SET name=$name, archived_at=$archived_at, added_at=$added_at,
                project_id=$project_id, section_order=$section_order, collapsed=$collapsed,
                is_deleted=$is_deleted, is_archived=$is_archived, color=$color, description=$description,
                hidded=$hidded
            WHERE id=$id;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_str (stmt, "$name", section.name);
        set_parameter_str (stmt, "$archived_at", section.archived_at);
        set_parameter_str (stmt, "$added_at", section.added_at);
        set_parameter_str (stmt, "$project_id", section.project_id);
        set_parameter_int (stmt, "$section_order", section.section_order);
        set_parameter_bool (stmt, "$collapsed", section.collapsed);
        set_parameter_bool (stmt, "$is_deleted", section.is_deleted);
        set_parameter_bool (stmt, "$is_archived", section.is_archived);
        set_parameter_str (stmt, "$color", section.color);
        set_parameter_str (stmt, "$description", section.description);
        set_parameter_bool (stmt, "$hidded", section.hidded);
        set_parameter_str (stmt, "$id", section.id);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }

        return stmt.step () == Sqlite.DONE;
    }

    public bool move_section (Objects.Section section, string old_project_id) {
        Sqlite.Statement stmt;

        sql = """
            UPDATE Sections SET project_id=$project_id WHERE id=$id;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_str (stmt, "$project_id", section.project_id);
        set_parameter_str (stmt, "$id", section.id);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }

        return stmt.step () == Sqlite.DONE;
    }

    public bool move_section_items (Objects.Section section) {
        Sqlite.Statement stmt;

        sql = """
            UPDATE Items SET project_id=$project_id WHERE section_id=$section_id;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_str (stmt, "$project_id", section.project_id);
        set_parameter_str (stmt, "$section_id", section.id);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }


        return stmt.step () == Sqlite.DONE;
    }

    public bool archive_section (Objects.Section section) {
        Sqlite.Statement stmt;

        sql = """
            UPDATE Sections SET is_archived=$is_archived WHERE id=$id;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_bool (stmt, "$is_archived", section.is_archived);
        set_parameter_str (stmt, "$id", section.id);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }


        return stmt.step () == Sqlite.DONE;
    }

    /*
        Items
     */

    public bool insert_item (Objects.Item item, bool insert = true) {
        Sqlite.Statement stmt;

        sql = """
            INSERT OR IGNORE INTO Items (id, content, description, due, added_at, completed_at,
                updated_at, section_id, project_id, parent_id, priority, child_order,
                checked, is_deleted, day_order, collapsed, pinned, labels, extra_data, item_type)
            VALUES ($id, $content, $description, $due, $added_at, $completed_at,
                $updated_at, $section_id, $project_id, $parent_id, $priority, $child_order,
                $checked, $is_deleted, $day_order, $collapsed, $pinned, $labels, $extra_data, $item_type);
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
        set_parameter_str (stmt, "$labels", get_labels_ids (item.labels));
        set_parameter_str (stmt, "$extra_data", item.extra_data);
        set_parameter_str (stmt, "$item_type", item.item_type.to_string ());

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }

        return stmt.step () == Sqlite.DONE;
    }

    public Gee.ArrayList<Objects.Item> get_items_collection () {
        Gee.ArrayList<Objects.Item> return_value = new Gee.ArrayList<Objects.Item> ();
        Sqlite.Statement stmt;

        sql = "SELECT * FROM Items WHERE is_deleted = 0;";

        db.prepare_v2 (sql, sql.length, out stmt);

        while (stmt.step () == Sqlite.ROW) {
            return_value.add (_fill_item (stmt));
        }

        return return_value;
    }

    public Objects.Item get_item_by_id (string id) {
        Objects.Item returned = new Objects.Item ();
        Sqlite.Statement stmt;

        sql = "SELECT * FROM Items WHERE id = $id LIMIT 1;";

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_str (stmt, "$id", id);

        if (stmt.step () == Sqlite.ROW) {
            returned = _fill_item (stmt);
        }


        return returned;
    }

    public Objects.Item _fill_item (Sqlite.Statement stmt) {
        Objects.Item return_value = new Objects.Item ();
        return_value.id = stmt.column_text (0);
        return_value.content = stmt.column_text (1);
        return_value.description = stmt.column_text (2);
        return_value.due.update_from_json (get_due_parameter (stmt.column_text (3)));
        return_value.added_at = stmt.column_text (4);
        return_value.completed_at = stmt.column_text (5);
        return_value.updated_at = stmt.column_text (6);
        return_value.section_id = stmt.column_text (7);
        return_value.project_id = stmt.column_text (8);
        return_value.parent_id = stmt.column_text (9);
        return_value.priority = stmt.column_int (10);
        return_value.child_order = stmt.column_int (11);
        return_value.checked = get_parameter_bool (stmt, 12);
        return_value.is_deleted = get_parameter_bool (stmt, 13);
        return_value.day_order = stmt.column_int (14);
        return_value.collapsed = get_parameter_bool (stmt, 15);
        return_value.pinned = get_parameter_bool (stmt, 16);
        return_value.labels = Services.Store.instance ().get_labels_by_item_labels (stmt.column_text (17));
        return_value.extra_data = stmt.column_text (18);
        return_value.item_type = ItemType.parse (stmt.column_text (19));

        return return_value;
    }

    public bool delete_item (Objects.Item item) {
        Sqlite.Statement stmt;

        sql = """
            DELETE FROM Items WHERE id=$id;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_str (stmt, "$id", item.id);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }


        return stmt.step () == Sqlite.DONE;
    }

    public bool update_item (Objects.Item item, string update_id = "") {
        item.updated_at = new GLib.DateTime.now_local ().to_string ();
        Sqlite.Statement stmt;

        sql = """
            UPDATE Items SET content=$content, description=$description, due=$due,
                added_at=$added_at, completed_at=$completed_at, updated_at=$updated_at,
                section_id=$section_id, project_id=$project_id, parent_id=$parent_id,
                priority=$priority, child_order=$child_order, checked=$checked,
                is_deleted=$is_deleted, day_order=$day_order, collapsed=$collapsed,
                pinned=$pinned, labels=$labels, extra_data=$extra_data, item_type=$item_type
            WHERE id=$id;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);
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
        set_parameter_str (stmt, "$labels", get_labels_ids (item.labels));
        set_parameter_str (stmt, "$extra_data", item.extra_data);
        set_parameter_str (stmt, "$item_type", item.item_type.to_string ());
        set_parameter_str (stmt, "$id", item.id);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }


        return stmt.step () == Sqlite.DONE;
    }

    public bool move_item (Objects.Item item) {
        item.updated_at = new GLib.DateTime.now_local ().to_string ();
        Sqlite.Statement stmt;

        sql = """
            UPDATE Items SET
                section_id=$section_id,
                project_id=$project_id,
                parent_id=$parent_id,
                extra_data=$extra_data
            WHERE id=$id;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_str (stmt, "$section_id", item.section_id);
        set_parameter_str (stmt, "$project_id", item.project_id);
        set_parameter_str (stmt, "$parent_id", item.parent_id);
        set_parameter_str (stmt, "$extra_data", item.extra_data);
        set_parameter_str (stmt, "$id", item.id);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }


        return stmt.step () == Sqlite.DONE;
    }

    public bool complete_item (Objects.Item item, bool old_checked) {
        Sqlite.Statement stmt;

        sql = """
            UPDATE Items SET checked=$checked, completed_at=$completed_at
            WHERE id=$id OR parent_id=$id;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_bool (stmt, "$checked", item.checked);
        set_parameter_str (stmt, "$completed_at", item.completed_at);
        set_parameter_str (stmt, "$id", item.id);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }


        return stmt.step () == Sqlite.DONE;
    }

    public void update_child_order (Objects.BaseObject base_object) {
        Sqlite.Statement stmt;

        sql = """
            UPDATE %s SET %s=$order WHERE id=$id;
        """.printf (base_object.table_name, base_object.column_order_name);

        db.prepare_v2 (sql, sql.length, out stmt);

        if (base_object is Objects.Item) {
            set_parameter_int (stmt, "$order", ((Objects.Item) base_object).child_order);
        } else if (base_object is Objects.Section) {
            set_parameter_int (stmt, "$order", ((Objects.Section) base_object).section_order);
        } else if (base_object is Objects.Project) {
            set_parameter_int (stmt, "$order", ((Objects.Project) base_object).child_order);
        } else if (base_object is Objects.Label) {
            set_parameter_int (stmt, "$order", ((Objects.Label) base_object).item_order);
        }

        set_parameter_str (stmt, "$id", base_object.id);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }
    }

    // Reminders
    public bool insert_reminder (Objects.Reminder reminder) {
        Sqlite.Statement stmt;
        string sql;

        sql = """
            INSERT OR IGNORE INTO Reminders (id, item_id, type, due, mm_offset)
            VALUES ($id, $item_id, $type, $due, $mm_offset);
        """;

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_str (stmt, "$id", reminder.id);
        set_parameter_str (stmt, "$item_id", reminder.item_id);
        set_parameter_str (stmt, "$type", reminder.reminder_type.to_string ());
        set_parameter_str (stmt, "$due", reminder.due.to_string ());
        set_parameter_int (stmt, "$mm_offset", reminder.mm_offset);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }


        return stmt.step () == Sqlite.DONE;
    }

    public Gee.ArrayList<Objects.Reminder> get_reminders_collection () {
        Gee.ArrayList<Objects.Reminder> return_value = new Gee.ArrayList<Objects.Reminder> ();
        Sqlite.Statement stmt;

        sql = """
            SELECT id, item_id, type, due, mm_offset FROM Reminders;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);

        while (stmt.step () == Sqlite.ROW) {
            return_value.add (_fill_reminder (stmt));
        }

        return return_value;
    }

    public Objects.Reminder _fill_reminder (Sqlite.Statement stmt) {
        Objects.Reminder return_value = new Objects.Reminder ();
        return_value.id = stmt.column_text (0);
        return_value.item_id = stmt.column_text (1);
        return_value.reminder_type = stmt.column_text (2) == "absolute" ? ReminderType.ABSOLUTE : ReminderType.RELATIVE;
        return_value.due.update_from_json (get_due_parameter (stmt.column_text (3)));
        return_value.mm_offset = stmt.column_int (4);
        return return_value;
    }

    public Gee.ArrayList<Objects.Reminder> get_reminders_by_item_id (string id) {
        Gee.ArrayList<Objects.Reminder> return_value = new Gee.ArrayList<Objects.Reminder> ();
        Sqlite.Statement stmt;

        sql = """
            SELECT id, item_id, type, due, mm_offset FROM Reminders WHERE item_id=$item_id;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_str (stmt, "$item_id", id);

        while (stmt.step () == Sqlite.ROW) {
            return_value.add (_fill_reminder (stmt));
        }

        return return_value;
    }

    public bool delete_reminder (Objects.Reminder reminder) {
        Sqlite.Statement stmt;

        sql = """
            DELETE FROM Reminders WHERE id=$id;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_str (stmt, "$id", reminder.id);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }


        return stmt.step () == Sqlite.DONE;
    }

    // Atrachments
    public bool insert_attachment (Objects.Attachment attachment) {
        Sqlite.Statement stmt;
        string sql;

        sql = """
            INSERT OR IGNORE INTO Attachments (id, item_id, file_type, file_name, file_size, file_path)
            VALUES ($id, $item_id, $file_type, $file_name, $file_size, $file_path);
        """;

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_str (stmt, "$id", attachment.id);
        set_parameter_str (stmt, "$item_id", attachment.item_id);
        set_parameter_str (stmt, "$file_type", attachment.file_type);
        set_parameter_str (stmt, "$file_name", attachment.file_name);
        set_parameter_int64 (stmt, "$file_size", attachment.file_size);
        set_parameter_str (stmt, "$file_path", attachment.file_path);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }


        return stmt.step () == Sqlite.DONE;
    }

    public Gee.ArrayList<Objects.Attachment> get_attachments_collection () {
        Gee.ArrayList<Objects.Attachment> return_value = new Gee.ArrayList<Objects.Attachment> ();
        Sqlite.Statement stmt;

        sql = """
            SELECT * FROM Attachments;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);

        while (stmt.step () == Sqlite.ROW) {
            return_value.add (_fill_attachment (stmt));
        }

        return return_value;
    }

    public Objects.Attachment _fill_attachment (Sqlite.Statement stmt) {
        Objects.Attachment return_value = new Objects.Attachment ();
        return_value.id = stmt.column_text (0);
        return_value.item_id = stmt.column_text (1);
        return_value.file_type = stmt.column_text (2);
        return_value.file_name = stmt.column_text (3);
        return_value.file_size = stmt.column_int64 (4);
        return_value.file_path = stmt.column_text (5);
        return return_value;
    }

    public bool delete_attachment (Objects.Attachment attachment) {
        Sqlite.Statement stmt;

        sql = """
            DELETE FROM Attachments WHERE id=$id;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_str (stmt, "$id", attachment.id);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }


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

    public void insert_CurTempIds (string id, string temp_id, string object) {     // vala-lint=naming-convention
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
    }

    public bool curTempIds_exists (string id) {     // vala-lint=naming-convention
        bool returned = false;
        Sqlite.Statement stmt;

        sql = """
            SELECT COUNT (*) FROM CurTempIds WHERE id = $id;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_str (stmt, "$id", id);

        if (stmt.step () == Sqlite.ROW) {
            returned = stmt.column_int (0) > 0;
        }

        return returned;
    }

    public string get_temp_id (string id) {
        string returned = "";
        Sqlite.Statement stmt;

        sql = """
            SELECT temp_id FROM CurTempIds WHERE id = $id;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_str (stmt, "$id", id);

        if (stmt.step () == Sqlite.ROW) {
            returned = stmt.column_text (0);
        }


        return returned;
    }

    public bool update_project_id (string current_id, string new_id) {
        Sqlite.Statement stmt;

        sql = """
            UPDATE Projects SET id = $new_id WHERE id = $current_id;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_str (stmt, "$new_id", new_id);
        set_parameter_str (stmt, "$current_id", current_id);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }


        return stmt.step () == Sqlite.DONE;
    }

    public bool update_project_section_id (string current_id, string new_id) {
        Sqlite.Statement stmt;

        sql = """
                UPDATE Sections SET project_id = $new_id WHERE project_id = $current_id;
            """;

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_str (stmt, "$new_id", new_id);
        set_parameter_str (stmt, "$current_id", current_id);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }


        return stmt.step () == Sqlite.DONE;
    }

    public bool update_project_item_id (string current_id, string new_id) {
        Sqlite.Statement stmt;

        sql = """
            UPDATE Items SET project_id = $new_id WHERE project_id = $current_id;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_str (stmt, "$new_id", new_id);
        set_parameter_str (stmt, "$current_id", current_id);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }


        return stmt.step () == Sqlite.DONE;
    }

    public bool update_section_id (string current_id, string new_id) {
        Sqlite.Statement stmt;

        sql = """
            UPDATE Sections SET id = $new_id WHERE id = $current_id;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_str (stmt, "$new_id", new_id);
        set_parameter_str (stmt, "$current_id", current_id);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }


        return stmt.step () == Sqlite.DONE;
    }

    public bool update_section_item_id (string current_id, string new_id) {
        Sqlite.Statement stmt;

        sql = """
            UPDATE Items SET section_id = $new_id WHERE section_id = $current_id;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_str (stmt, "$new_id", new_id);
        set_parameter_str (stmt, "$current_id", current_id);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }


        return stmt.step () == Sqlite.DONE;
    }

    public bool update_item_id (string current_id, string new_id) {
        Sqlite.Statement stmt;

        sql = """
            UPDATE Items SET id = $new_id WHERE id = $current_id;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_str (stmt, "$new_id", new_id);
        set_parameter_str (stmt, "$current_id", current_id);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }


        return stmt.step () == Sqlite.DONE;
    }

    public bool update_item_child_id (string current_id, string new_id) {
        Sqlite.Statement stmt;

        sql = """
            UPDATE Items SET parent_id = $new_id WHERE parent_id = $current_id;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_str (stmt, "$new_id", new_id);
        set_parameter_str (stmt, "$current_id", current_id);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }


        return stmt.step () == Sqlite.DONE;
    }

    public void remove_CurTempIds (string id) {     // vala-lint=naming-convention
        Sqlite.Statement stmt;

        sql = """
            DELETE FROM CurTempIds WHERE id = $id;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_str (stmt, "$id", id);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }
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
    }

    public void clear_queue () {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            DELETE FROM Queue;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }
    }

    public void clear_cur_temp_ids () {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            DELETE FROM CurTempIds;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }
    }

    /*
     * ObjectsEvent
     */

    public Gee.ArrayList<Objects.ObjectEvent> get_events_by_item (string id, int start_week, int end_week) {
        Gee.ArrayList<Objects.ObjectEvent> return_value = new Gee.ArrayList<Objects.ObjectEvent> ();

        Sqlite.Statement stmt;

        sql = """
            SELECT * FROM OEvents
                WHERE object_id = $object_id
                AND (event_date >= DATETIME('now', '-%d days')
                AND event_date <= DATETIME('now', '-%d days'))
            ORDER BY event_date DESC
        """.printf (end_week, start_week);

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_str (stmt, "$object_id", id);

        while (stmt.step () == Sqlite.ROW) {
            return_value.add (_fill_object_event (stmt));
        }

        return return_value;
    }

    public Objects.ObjectEvent _fill_object_event (Sqlite.Statement stmt) {
        Objects.ObjectEvent return_value = new Objects.ObjectEvent ();
        return_value.id = stmt.column_int64 (0);
        return_value.event_type = ObjectEventType.parse (stmt.column_text (1));
        return_value.event_date = stmt.column_text (2);
        return_value.object_id = stmt.column_text (3);
        return_value.object_type = stmt.column_text (4);
        return_value.object_key = ObjectEventKeyType.parse (stmt.column_text (5));
        return_value.object_old_value = stmt.column_text (6);
        return_value.object_new_value = stmt.column_text (7);
        return_value.parent_item_id = stmt.column_text (8);
        return_value.parent_project_id = stmt.column_text (9);
        return return_value;
    }

    // PARAMETER REGION
    private void set_parameter_int (Sqlite.Statement ? stmt, string par, int val) {
        int par_position = stmt.bind_parameter_index (par);
        if (par_position == 0) {
            warning ("bind parameter not found: %s", par);
            return;
        }
        stmt.bind_int (par_position, val);
    }

    private void set_parameter_int64 (Sqlite.Statement ? stmt, string par, int64 val) {
        int par_position = stmt.bind_parameter_index (par);
        if (par_position == 0) {
            warning ("bind parameter not found: %s", par);
            return;
        }
        stmt.bind_int64 (par_position, val);
    }

    private void set_parameter_str (Sqlite.Statement ? stmt, string par, string val) {
        int par_position = stmt.bind_parameter_index (par);
        if (par_position == 0) {
            warning ("bind parameter not found: %s", par);
            return;
        }
        stmt.bind_text (par_position, val);
    }

    private void set_parameter_bool (Sqlite.Statement ? stmt, string par, bool val) {
        int par_position = stmt.bind_parameter_index (par);
        if (par_position == 0) {
            warning ("bind parameter not found: %s", par);
            return;
        }
        stmt.bind_int (par_position, val ? 1 : 0);
    }

    private bool get_parameter_bool (Sqlite.Statement stmt, int col) {
        return stmt.column_int (col) == 1;
    }

    Json.Parser parser;
    public Json.Object ? get_due_parameter (string data) {
        if (parser == null) {
            parser = new Json.Parser ();
        }

        try {
            parser.load_from_data (data, -1);
        } catch (Error e) {
            debug (e.message);
        }

        return parser.get_root ().get_object ();
    }

    public string get_labels_ids (Gee.ArrayList<Objects.Label> labels) {
        string return_value = "";

        foreach (Objects.Label label in labels) {
            return_value += label.id + ";";
        }

        if (return_value.length > 0) {
            return_value = return_value.substring (0, return_value.length - 1);
        }

        return return_value;
    }

    public bool column_exists (string table, string column) {
        Sqlite.Statement stmt;

        sql = """
            PRAGMA table_info(%s);
        """.printf (table);

        db.prepare_v2 (sql, sql.length, out stmt);

        stmt.step ();

        while (stmt.step () == Sqlite.ROW) {
            if (stmt.column_text (1) == column) {
                return true;
            }
        }

        return false;
    }

    public void add_text_column (string table, string column, string default_value) {
        if (column_exists (table, column)) {
            return;
        }

        Sqlite.Statement stmt;

        sql = """
            ALTER TABLE %s ADD COLUMN %s TEXT DEFAULT '%s';
        """.printf (table, column, default_value);

        db.prepare_v2 (sql, sql.length, out stmt);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }
    }

    public void add_int_column (string table, string column, int default_value) {
        if (column_exists (table, column)) {
            return;
        }

        Sqlite.Statement stmt;

        sql = """
            ALTER TABLE %s ADD COLUMN %s INTEGER DEFAULT %i;
        """.printf (table, column, default_value);

        db.prepare_v2 (sql, sql.length, out stmt);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }
    }

    public void add_item_label_column () {
        if (column_exists ("Items", "labels")) {
            return;
        }

        Sqlite.Statement stmt;

        sql = """
            ALTER TABLE Items ADD COLUMN labels TEXT;

            UPDATE Items
            SET labels = (
                SELECT GROUP_CONCAT(label_id, ';')
                FROM Items_Labels
                WHERE item_id = Items.id
            );
        """;

        db.prepare_v2 (sql, sql.length, out stmt);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }
    }

    public void add_project_labels_source_id () {
        if (column_exists ("Projects", "source_id")) {
            return;
        }

        sql = """
            ALTER TABLE Projects ADD COLUMN source_id TEXT;
            UPDATE Projects SET source_id = backend_type;
        """;

        if (db.exec (sql, null, out errormsg) != Sqlite.OK) {
            warning (errormsg);
        }

        sql = """
            ALTER TABLE Labels ADD COLUMN source_id TEXT;
            UPDATE Labels SET source_id = backend_type;
        """;

        if (db.exec (sql, null, out errormsg) != Sqlite.OK) {
            warning (errormsg);
        }

        Util.get_default ().create_local_source ();
    }

    public void add_calendar_url_to_project () {
        if (column_exists ("Projects", "calendar_url")) {
            return;
        }

        add_text_column ("Projects", "calendar_url", "");

        Gee.ArrayList<Objects.Project> projects = get_projects_collection ();

        foreach (var project in projects) {
            if (project.source.source_type != SourceType.CALDAV) {
                continue;
            }

            var url = Path.build_filename (
                project.source.caldav_data.server_url,
                "calendars", 
                project.source.caldav_data.username,
                project.id
            );

            if (!url.has_suffix ("/")) {
                url += "/";
            }

            debug ("Migration: Adding calendar_url for Project (%s) (%s)\n", project.name, url);

            Sqlite.Statement stmt;

            sql = """
                UPDATE Projects SET calendar_url = $calendar_url WHERE id = $id;
            """;

            db.prepare_v2 (sql, sql.length, out stmt);

            set_parameter_str (stmt, "$calendar_url", url);
            set_parameter_str (stmt, "$id", project.id);

            if (stmt.step () != Sqlite.DONE) {
                warning ("Error: %d: %s", db.errcode (), db.errmsg ());
            }
        }
    }
}
