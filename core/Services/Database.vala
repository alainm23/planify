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

    public signal void opened ();
    public signal void reset ();

    public signal void project_added (Objects.Project project);
    public signal void project_updated (Objects.Project project);
    public signal void project_deleted (Objects.Project project);

    public signal void label_added (Objects.Label label);
    public signal void label_updated (Objects.Label label);
    public signal void label_deleted (Objects.Label label);

    public signal void section_deleted (Objects.Section section);
    public signal void section_moved (Objects.Section section, string old_project_id);
    
    public signal void item_deleted (Objects.Item item);
    public signal void item_added (Objects.Item item, bool insert = true);
    public signal void item_updated (Objects.Item item, string update_id);

    public signal void item_label_added (Objects.Label label);
    public signal void item_label_deleted (Objects.Label label);

    public signal void reminder_added (Objects.Reminder reminder);
    public signal void reminder_deleted (Objects.Reminder reminder);

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

    Gee.ArrayList<Objects.Section> _sections = null;
    public Gee.ArrayList<Objects.Section> sections {
        get {
            if (_sections == null) {
                _sections = get_sections_collection ();
            }
            return _sections;
        }
    }

    Gee.ArrayList<Objects.Item> _items = null;
    public Gee.ArrayList<Objects.Item> items {
        get {
            if (_items == null) {
                _items = get_items_collection ();
            }
            return _items;
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

    Gee.ArrayList<Objects.Reminder> _reminders = null;
    public Gee.ArrayList<Objects.Reminder> reminders {
        get {
            if (_reminders == null) {
                _reminders = get_reminders_collection ();
            }

            return _reminders;
        }
    }

    construct {
        label_deleted.connect ((label) => {
            if (_labels.remove (label)) {
                debug ("Label Removed: %s", label.name);
            }
        });

        project_deleted.connect ((project) => {
            if (_projects.remove (project)) {
                debug ("Project Removed: %s", project.name);
            }
        });

        section_deleted.connect ((section) => {
            if (_sections.remove (section)) {
                debug ("Section Removed: %s", section.name);
            }
        });

        item_deleted.connect ((item) => {
            if (_items.remove (item)) {
                debug ("item Removed: %s", item.content);
            }
        });

        reminder_deleted.connect ((reminder) => {
            if (_reminders.remove (reminder)) {
                debug ("Reminder Removed: %s", reminder.id.to_string ());
            }
        });
    }

    public void init_database () {
        db_path = Environment.get_user_data_dir () + "/io.github.alainm23.planify/database.db";
                
        create_tables ();
        patch_database ();
        opened ();
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
         * - Add due date to Projects
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
    }

    private void create_tables () {
        Sqlite.Database.open (db_path, out db);

        sql = """
            CREATE TABLE IF NOT EXISTS Labels (
                id              TEXT PRIMARY KEY,
                name            TEXT,
                color           TEXT,
                item_order      INTEGER,
                is_deleted      INTEGER,
                is_favorite     INTEGER,
                backend_type    TEXT,
                CONSTRAINT unique_label UNIQUE (name)
            );
        """;

        if (db.exec (sql, null, out errormsg) != Sqlite.OK) {
            warning (errormsg);
        }

        sql = """
            CREATE TABLE IF NOT EXISTS Sources (
                id                  TEXT PRIMARY KEY,
                type                TEXT,
                username            TEXT,
                email               TEXT,
                credentials         TEXT,
                sync_token          TEXT,
                last_sync           TEXT,
                inbox_project_id    TEXT
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
                sync_id                 TEXT
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
                extra_data          TEXT
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
        
        sql = """PRAGMA foreign_keys = ON;""";
        
        if (db.exec (sql, null, out errormsg) != Sqlite.OK) {
            warning (errormsg);
        }
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

    public bool is_database_empty () {
        return projects.size <= 0;
    }

    public Gee.ArrayList<Objects.BaseObject> get_collection_by_type (Objects.BaseObject base_object) {
        if (base_object is Objects.Project) {
            return projects;
        } else if (base_object is Objects.Section) {
            return sections;
        } else if (base_object is Objects.Item) {
            return items;
        } else if (base_object is Objects.Label) {
            return labels;
        }

        return new Gee.ArrayList<Objects.BaseObject> ();
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

    public Gee.ArrayList<Objects.Project> get_subprojects (Objects.Project _project) {
        Gee.ArrayList<Objects.Project> return_value = new Gee.ArrayList<Objects.Project> ();
        lock (_projects) {
            foreach (var project in projects) {
                if (project.parent_id == _project.id) {
                    return_value.add (project);
                }
            }
        }
        
        return return_value;
    }

    public Gee.ArrayList<Objects.Project> get_projects_by_backend_type (BackendType backend_type) {
        Gee.ArrayList<Objects.Project> return_value = new Gee.ArrayList<Objects.Project> ();
        lock (_projects) {
            foreach (var project in projects) {
                if (project.backend_type == backend_type) {
                    return_value.add (project);
                }
            }

            return return_value;
        }
    }

    public Gee.ArrayList<Objects.Item> get_subitems (Objects.Item i) {
        Gee.ArrayList<Objects.Item> return_value = new Gee.ArrayList<Objects.Item> ();
        lock (_items) {
            foreach (var item in items) {
                if (item.parent_id == i.id) {
                    return_value.add (item);
                }
            }
        }

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
        return_value.sort_order = stmt.column_int (12);
        return_value.parent_id = stmt.column_text (13);
        return_value.collapsed = get_parameter_bool (stmt, 14);
        return_value.icon_style = get_icon_style_by_text (stmt, 15);
        return_value.emoji = stmt.column_text (16);
        return_value.show_completed = get_parameter_bool (stmt, 17);
        return_value.description = stmt.column_text (18);
        return_value.due_date = stmt.column_text (19);
        return_value.inbox_section_hidded = get_parameter_bool (stmt, 20);
        return_value.sync_id = stmt.column_text (21);
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
        } else if (stmt.column_text (col) == "google-tasks") {
            return BackendType.GOOGLE_TASKS;
        } else if (stmt.column_text (col) == "caldav") {
            return BackendType.CALDAV;
        } else {
            return BackendType.NONE;
        }
    }

    public int next_project_child_order (BackendType backend_type) {
        int child_order = 0;

        lock (_projects) {
            foreach (var project in projects) {
                if (project.backend_type == backend_type && !project.is_deleted) {
                    child_order++;
                }
            }

            return child_order;
        }
    } 

    public bool insert_project (Objects.Project project) {
        Sqlite.Statement stmt;

        sql = """
            INSERT OR IGNORE INTO Projects (id, name, color, backend_type, inbox_project,
                team_inbox, child_order, is_deleted, is_archived, is_favorite, shared, view_style,
                sort_order, parent_id, collapsed, icon_style, emoji, show_completed, description, due_date,
                inbox_section_hidded, sync_id)
            VALUES ($id, $name, $color, $backend_type, $inbox_project, $team_inbox,
                $child_order, $is_deleted, $is_archived, $is_favorite, $shared, $view_style,
                $sort_order, $parent_id, $collapsed, $icon_style, $emoji, $show_completed, $description, $due_date,
                $inbox_section_hidded, $sync_id);
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
        set_parameter_int (stmt, "$sort_order", project.sort_order);
        set_parameter_str (stmt, "$parent_id", project.parent_id);
        set_parameter_bool (stmt, "$collapsed", project.collapsed);
        set_parameter_str (stmt, "$icon_style", project.icon_style.to_string ());
        set_parameter_str (stmt, "$emoji", project.emoji);
        set_parameter_bool (stmt, "$show_completed", project.show_completed);
        set_parameter_str (stmt, "$description", project.description);
        set_parameter_str (stmt, "$due_date", project.due_date);
        set_parameter_bool (stmt, "$inbox_section_hidded", project.inbox_section_hidded);
        set_parameter_str (stmt, "$sync_id", project.sync_id);

        if (stmt.step () == Sqlite.DONE) {
            projects.add (project);

            if (project.parent == null) {
                project_added (project);
            } else {
                project.parent.subproject_added (project);
            }
        } else {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }

        stmt.reset ();
        return stmt.step () == Sqlite.DONE;
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
    
    public void delete_project (Objects.Project project) {
        Sqlite.Statement stmt;

        sql = """
            DELETE FROM Projects WHERE id=$id;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_str (stmt, "$id", project.id);

        if (stmt.step () == Sqlite.DONE) {
            foreach (Objects.Section section in get_sections_by_project (project)) {
                delete_section (section);
            }

            foreach (Objects.Item item in get_items_by_project (project)) {
                delete_item (item);
            }

            foreach (Objects.Project subproject in get_subprojects (project)) {
                delete_project (subproject);
            }

            project.deleted ();
        } else {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }

        stmt.reset ();
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

        stmt.reset ();
    }

    public void update_project (Objects.Project project) {
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
                sync_id=$sync_id
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
        set_parameter_int (stmt, "$sort_order", project.sort_order);
        set_parameter_str (stmt, "$parent_id", project.parent_id);
        set_parameter_bool (stmt, "$collapsed", project.collapsed);
        set_parameter_str (stmt, "$icon_style", project.icon_style.to_string ());
        set_parameter_str (stmt, "$emoji", project.emoji);
        set_parameter_bool (stmt, "$show_completed", project.show_completed);
        set_parameter_str (stmt, "$description", project.description);
        set_parameter_str (stmt, "$due_date", project.due_date);
        set_parameter_bool (stmt, "$inbox_section_hidded", project.inbox_section_hidded);
        set_parameter_str (stmt, "$sync_id", project.sync_id);
        set_parameter_str (stmt, "$id", project.id);

        if (stmt.step () == Sqlite.DONE) {
            project.updated ();
            project_updated (project);
        } else {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }
        stmt.reset ();
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
        stmt.reset ();
        return return_value;
    }

    public Gee.ArrayList<Objects.Label> get_labels_by_backend_type (BackendType backend_type) {
        Gee.ArrayList<Objects.Label> return_value = new Gee.ArrayList<Objects.Label> ();
        lock (_labels) {
            foreach (var label in labels) {
                if (backend_type == BackendType.ALL ? true : label.backend_type == backend_type) {
                    return_value.add (label);
                }
            }

            return return_value;
        }
    }

    public Gee.ArrayList<Objects.Label> get_all_labels_by_search (string search_text) {
        Gee.ArrayList<Objects.Label> return_value = new Gee.ArrayList<Objects.Label> ();
        lock (_labels) {
            foreach (var label in labels) {
                if (search_text.down () in label.name.down ()) {
                    return_value.add (label);
                }
            }

            return return_value;
        }
    }

    public Objects.Label _fill_label (Sqlite.Statement stmt) {
        Objects.Label return_value = new Objects.Label ();
        return_value.id = stmt.column_text (0);
        return_value.name = stmt.column_text (1);
        return_value.color = stmt.column_text (2);
        return_value.item_order = stmt.column_int (3);
        return_value.is_deleted = get_parameter_bool (stmt, 4);
        return_value.is_favorite = get_parameter_bool (stmt, 5);
        return_value.backend_type = get_backend_type_by_text (stmt, 6);
        return return_value;
    }

    public bool insert_label (Objects.Label label) {
        Sqlite.Statement stmt;

        sql = """
            INSERT OR IGNORE INTO Labels (id, name, color, item_order, is_deleted, is_favorite, backend_type)
            VALUES ($id, $name, $color, $item_order, $is_deleted, $is_favorite, $backend_type);
        """;

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_str (stmt, "$id", label.id);
        set_parameter_str (stmt, "$name", label.name);
        set_parameter_str (stmt, "$color", label.color);
        set_parameter_int (stmt, "$item_order", label.item_order);
        set_parameter_bool (stmt, "$is_deleted", label.is_deleted);
        set_parameter_bool (stmt, "$is_favorite", label.is_favorite);
        set_parameter_str (stmt, "$backend_type", label.backend_type.to_string ());

        if (stmt.step () == Sqlite.DONE) {
            labels.add (label);
            label_added (label);
        } else {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }

        stmt.reset ();
        return stmt.step () == Sqlite.DONE;
    }

    public bool label_exists (string id) {
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

    public Objects.Label get_label (string id) {
        Objects.Label? return_value = null;
        lock (_labels) {
            foreach (var label in labels) {
                if (label.id == id) {
                    return_value = label;
                    break;
                }
            }

            return return_value;
        }
    }

    public Objects.Label? get_label_by_name (string name, bool lowercase = false, BackendType backend_type) {
        lock (_labels) {
            string compare_name = lowercase ? name.down () : name;

            foreach (var label in labels) {
                string label_name = lowercase ? label.name.down () : label.name;
                if (label.backend_type == backend_type && label_name == compare_name) {
                    return label;
                }
            }

            return null;
        }
    }

    public void delete_label (Objects.Label label) {
        Sqlite.Statement stmt;

        sql = """
            DELETE FROM Labels WHERE id=$id;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_str (stmt, "$id", label.id);

        if (stmt.step () == Sqlite.DONE) {
            label.deleted ();
        } else {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }

        stmt.reset ();
    }

    public void update_label (Objects.Label label) {
        Sqlite.Statement stmt;

        sql = """
            UPDATE Labels SET name=$name, color=$color, item_order=$item_order,
                is_deleted=$is_deleted, is_favorite=$is_favorite, backend_type=$backend_type
            WHERE id=$id;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_str (stmt, "$name", label.name);
        set_parameter_str (stmt, "$color", label.color);
        set_parameter_int (stmt, "$item_order", label.item_order);
        set_parameter_bool (stmt, "$is_deleted", label.is_deleted);
        set_parameter_bool (stmt, "$is_favorite", label.is_favorite);
        set_parameter_str (stmt, "$backend_type", label.backend_type.to_string ());
        set_parameter_str (stmt, "$id", label.id);

        if (stmt.step () == Sqlite.DONE) {
            label.updated ();
            label_updated (label);
        } else {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }
        stmt.reset ();
    }

    public Gee.ArrayList<Objects.Label> get_labels_by_item_labels (string labels) {
        Gee.ArrayList<Objects.Label> return_value = new Gee.ArrayList<Objects.Label> ();

        foreach (string id in labels.split (";")) {
            Objects.Label? label = get_label (id);
            if (label != null) {
                return_value.add (label);
            }
        }

        return return_value;
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

    public int next_item_child_order (string project_id, string section_id) {
        int child_order = 0;

        lock (_items) {
            foreach (var item in items) {
                if (item.project_id == project_id && item.section_id == section_id) {
                    child_order++;
                }
            }

            return child_order;
        }
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

        if (stmt.step () == Sqlite.DONE) {
            sections.add (section);
            section.project.section_added (section);
        } else {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }

        stmt.reset ();
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
        stmt.reset ();
        return return_value;
    }

    public Gee.ArrayList<Objects.Section> get_sections_by_project (Objects.Project project) {
        Gee.ArrayList<Objects.Section> return_value = new Gee.ArrayList<Objects.Section> ();
        lock (_sections) {
            foreach (var section in sections) {
                if (section.project_id == project.id) {
                    return_value.add (section);
                }
            }
        }

        return return_value;
    }

    public Objects.Section get_section (string id) {
        Objects.Section? return_value = null;
        lock (_sections) {
            foreach (var section in sections) {
                if (section.id == id) {
                    return_value = section;
                    break;
                }
            }

            return return_value;
        }
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

    public void delete_section (Objects.Section section) {
        Sqlite.Statement stmt;

        sql = """
            DELETE FROM Sections WHERE id=$id;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_str (stmt, "$id", section.id);

        if (stmt.step () == Sqlite.DONE) {
            foreach (Objects.Item item in section.items) {
                delete_item (item);
            }

            section.deleted ();
        } else {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }

        stmt.reset ();
    }

    public void update_section (Objects.Section section) {
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

        if (stmt.step () == Sqlite.DONE) {
            section.updated ();
        } else {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }

        stmt.reset ();
    }

    public void move_section (Objects.Section section, string old_project_id) {
        Sqlite.Statement stmt;

        sql = """
            UPDATE Sections SET project_id=$project_id WHERE id=$id;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_str (stmt, "$project_id", section.project_id);
        set_parameter_str (stmt, "$id", section.id);

        if (stmt.step () == Sqlite.DONE) {
            stmt.reset ();

            sql = """
                UPDATE Items SET project_id=$project_id WHERE section_id=$section_id;
            """;

            db.prepare_v2 (sql, sql.length, out stmt);
            set_parameter_str (stmt, "$project_id", section.project_id);
            set_parameter_str (stmt, "$section_id", section.id);
            
            if (stmt.step () == Sqlite.DONE) {
                foreach (Objects.Item item in section.items) {
                    item.project_id = section.project_id;
                }

                section_moved (section, old_project_id);
            }

            stmt.reset ();
        } else {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }
    }

    /*
        Items
    */

    public bool insert_item (Objects.Item item, bool insert = true) {
        Sqlite.Statement stmt;

        sql = """
            INSERT OR IGNORE INTO Items (id, content, description, due, added_at, completed_at,
                updated_at, section_id, project_id, parent_id, priority, child_order,
                checked, is_deleted, day_order, collapsed, pinned, labels, extra_data)
            VALUES ($id, $content, $description, $due, $added_at, $completed_at,
                $updated_at, $section_id, $project_id, $parent_id, $priority, $child_order,
                $checked, $is_deleted, $day_order, $collapsed, $pinned, $labels, $extra_data);
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

        if (stmt.step () == Sqlite.DONE) {
            add_item (item, insert);
        } else {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }

        stmt.reset ();
        return stmt.step () == Sqlite.DONE;
    }

    public void add_item (Objects.Item item, bool insert = true) {
        items.add (item);
        item_added (item, insert);

        if (insert) {
            if (item.parent_id != "") {
                item.parent.item_added (item);
            } else {
                if (item.section_id == "") {
                    item.project.item_added (item);
                } else {
                    item.section.item_added (item);
                }
            }
        }

        Services.EventBus.get_default ().update_items_position (item.project_id, item.section_id);
    }

    public Gee.ArrayList<Objects.Item> get_items_collection () {
        Gee.ArrayList<Objects.Item> return_value = new Gee.ArrayList<Objects.Item> ();
        Sqlite.Statement stmt;

        sql = "SELECT * FROM Items WHERE is_deleted = 0;";

        db.prepare_v2 (sql, sql.length, out stmt);

        while (stmt.step () == Sqlite.ROW) {
            return_value.add (_fill_item (stmt));
        }
        stmt.reset ();
        return return_value;
    }

    public Objects.Item get_item (string id) {
        Objects.Item? return_value = null;
        lock (_items) {
            foreach (var item in items) {
                if (item.id == id) {
                    return_value = item;
                    break;
                }
            }

            return return_value;
        }
    }

    public Objects.Item get_item_by_ics (string ics) {
        Objects.Item? return_value = null;
        lock (_items) {
            foreach (var item in items) {
                if (item.ics == ics) {
                    return_value = item;
                    break;
                }
            }

            return return_value;
        }
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

        stmt.reset ();
        return returned;
    }

    public Gee.ArrayList<Objects.Item> get_item_by_baseobject (Objects.BaseObject object) {
        Gee.ArrayList<Objects.Item> return_value = new Gee.ArrayList<Objects.Item> ();
        lock (_items) {
            foreach (var item in items) {
                if (object is Objects.Project) {
                    if (item.project_id == object.id && item.section_id == "" && item.parent_id == "") {
                        return_value.add (item);
                    }
                }
                
                if (object is Objects.Section) {
                    if (item.section_id == object.id && item.parent_id == "") {
                        return_value.add (item);
                    }
                }
            }
        }

        return return_value;
    }

    public Gee.ArrayList<Objects.Item> get_items_by_project (Objects.Project project) {
        Gee.ArrayList<Objects.Item> return_value = new Gee.ArrayList<Objects.Item> ();
        lock (_items) {
            foreach (Objects.Item item in items) {
                if (item.project_id == project.id) {
                    return_value.add (item);
                }
            }

            return return_value;
        }
    }

    public Gee.ArrayList<Objects.Item> get_items_checked_by_project (Objects.Project project) {
        Gee.ArrayList<Objects.Item> return_value = new Gee.ArrayList<Objects.Item> ();
        lock (_items) {
            foreach (Objects.Item item in items) {
                if (item.project_id == project.id && item.checked) {
                    return_value.add (item);
                }
            }

            return return_value;
        }
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
        return_value.labels = get_labels_by_item_labels (stmt.column_text (17));
        return_value.extra_data = stmt.column_text (18);

        return return_value;
    }

    public Gee.ArrayList<Objects.Item> get_items_by_date (GLib.DateTime date, bool checked = true) {
        Gee.ArrayList<Objects.Item> return_value = new Gee.ArrayList<Objects.Item> ();
        lock (_items) {
            foreach (Objects.Item item in items) {
                if (valid_item_by_date (item, date, checked)) {
                    return_value.add (item);
                }
            }

            return return_value;
        }
    }

    public Gee.ArrayList<Objects.Item> get_items_no_date (bool checked = true) {
        Gee.ArrayList<Objects.Item> return_value = new Gee.ArrayList<Objects.Item> ();
        lock (_items) {
            foreach (Objects.Item item in items) {
                if (!item.has_due && item.checked == checked) {
                    return_value.add (item);
                }
            }

            return return_value;
        }
    }

    public Gee.ArrayList<Objects.Item> get_items_repeating (bool checked = true) {
        Gee.ArrayList<Objects.Item> return_value = new Gee.ArrayList<Objects.Item> ();
        lock (_items) {
            foreach (Objects.Item item in items) {
                if (item.has_due && item.due.is_recurring && item.checked == checked) {
                    return_value.add (item);
                }
            }

            return return_value;
        }
    }

    public Gee.ArrayList<Objects.Item> get_items_by_date_range (GLib.DateTime start_date, GLib.DateTime end_date, bool checked = true) {
        Gee.ArrayList<Objects.Item> return_value = new Gee.ArrayList<Objects.Item> ();
        lock (_items) {
            foreach (Objects.Item item in items) {
                if (valid_item_by_date_range (item, start_date, end_date, checked)) {
                    return_value.add (item);
                }
            }

            return return_value;
        }
    }

    public Gee.ArrayList<Objects.Item> get_items_by_month (GLib.DateTime date, bool checked = true) {
        Gee.ArrayList<Objects.Item> return_value = new Gee.ArrayList<Objects.Item> ();
        lock (_items) {
            foreach (Objects.Item item in items) {
                if (valid_item_by_month (item, date, checked)) {
                    return_value.add (item);
                }
            }

            return return_value;
        }
    }

    public Gee.ArrayList<Objects.Item> get_items_pinned (bool checked = true) {
        Gee.ArrayList<Objects.Item> return_value = new Gee.ArrayList<Objects.Item> ();
        lock (_items) {
            foreach (Objects.Item item in items) {
                if (item.pinned && item.checked == checked) {
                    return_value.add (item);
                }
            }

            return return_value;
        }
    }

    public Gee.ArrayList<Objects.Item> get_items_by_priority (int priority, bool checked = true) {
        Gee.ArrayList<Objects.Item> return_value = new Gee.ArrayList<Objects.Item> ();
        lock (_items) {
            foreach (Objects.Item item in items) {
                if (item.priority == priority && item.checked == checked) {
                    return_value.add (item);
                }
            }

            return return_value;
        }
    }

    public Gee.ArrayList<Objects.Item> get_items_completed () {
        Gee.ArrayList<Objects.Item> return_value = new Gee.ArrayList<Objects.Item> ();
        lock (_items) {
            foreach (Objects.Item item in items) {
                if (item.checked) {
                    return_value.add (item);
                }
            }

            return return_value;
        }
    }

    public Gee.ArrayList<Objects.Item> get_items_by_label (Objects.Label label, bool checked = true) {
        Gee.ArrayList<Objects.Item> return_value = new Gee.ArrayList<Objects.Item> ();
        lock (_items) {
            foreach (Objects.Item item in items) {
                if (item.get_label (label.id) != null && item.checked == checked) {
                    return_value.add (item);
                }
            }

            return return_value;
        }
    }

    public Gee.ArrayList<Objects.Item> get_items_unlabeled (bool checked = true) {
        Gee.ArrayList<Objects.Item> return_value = new Gee.ArrayList<Objects.Item> ();
        lock (_items) {
            foreach (Objects.Item item in items) {
                if (item.labels.size <= 0 && item.checked == checked) {
                    return_value.add (item);
                }
            }

            return return_value;
        }
    }

    public Gee.ArrayList<Objects.Item> get_items_by_scheduled (bool checked = true) {
        Gee.ArrayList<Objects.Item> return_value = new Gee.ArrayList<Objects.Item> ();
        lock (_items) {
            foreach (Objects.Item item in items) {
                if (item.has_due &&
                    item.checked == checked &&
                    item.due.datetime.compare (new GLib.DateTime.now_local ()) > 0) {
                    return_value.add (item);
                }
            }

            return return_value;
        }
    }

    public bool valid_item_by_date (Objects.Item item, GLib.DateTime date, bool checked = true) {
        return (item.has_due &&
            item.checked == checked &&
            Granite.DateTime.is_same_day (item.due.datetime, date));
    }

    public bool valid_item_by_date_range (Objects.Item item, GLib.DateTime start_date, GLib.DateTime end_date, bool checked = true) {
        if (!item.has_due) {
            return false;
        }

        var date = Util.get_default ().get_format_date (item.due.datetime);
        var start = Util.get_default ().get_format_date (start_date);
        var end = Util.get_default ().get_format_date (end_date);

        return (item.checked == checked &&
            date.compare (start) >= 0 && date.compare (end) <= 0);
    }

    public bool valid_item_by_month (Objects.Item item, GLib.DateTime date, bool checked = true) {
        return (item.has_due &&
            item.checked == checked && item.due.datetime.get_month () == date.get_month () &&
            item.due.datetime.get_year () == date.get_year ());
    }

    public Gee.ArrayList<Objects.Item> get_items_by_overdeue_view (bool checked = true) {
        GLib.DateTime date_now = new GLib.DateTime.now_local ();
        Gee.ArrayList<Objects.Item> return_value = new Gee.ArrayList<Objects.Item> ();
        lock (_items) {
            foreach (Objects.Item item in items) {
                if (item.has_due &&
                    item.checked == checked &&
                    item.due.datetime.compare (date_now) < 0 &&
                    !Granite.DateTime.is_same_day (item.due.datetime, date_now)) {
                    return_value.add (item);
                }
            }

            return return_value;
        }
    }

    public bool valid_item_by_overdue (Objects.Item item, GLib.DateTime date, bool checked = true) {
        return (item.has_due &&
            item.checked == checked &&
            item.due.datetime.compare (new GLib.DateTime.now_local ()) < 0 &&
            !Granite.DateTime.is_same_day (item.due.datetime, new GLib.DateTime.now_local ()));
    }

    public void delete_item (Objects.Item item) {
        Sqlite.Statement stmt;

        sql = """
            DELETE FROM Items WHERE id=$id;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_str (stmt, "$id", item.id);

        if (stmt.step () == Sqlite.DONE) {
            if (item.project.backend_type == BackendType.LOCAL || item.project.backend_type == BackendType.TODOIST) {
                foreach (Objects.Item subitem in item.items) {
                    delete_item (subitem);
                }
            }

            item.deleted ();
        } else {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }
        
        stmt.reset ();
    }

    public void update_item (Objects.Item item, string update_id = "") {
        item.updated_at = new GLib.DateTime.now_local ().to_string ();
        Sqlite.Statement stmt;

        sql = """
            UPDATE Items SET content=$content, description=$description, due=$due,
                added_at=$added_at, completed_at=$completed_at, updated_at=$updated_at,
                section_id=$section_id, project_id=$project_id, parent_id=$parent_id,
                priority=$priority, child_order=$child_order, checked=$checked,
                is_deleted=$is_deleted, day_order=$day_order, collapsed=$collapsed,
                pinned=$pinned, labels=$labels, extra_data=$extra_data
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
        set_parameter_str (stmt, "$id", item.id);

        if (stmt.step () == Sqlite.DONE) {
            item.updated ();
            item_updated (item, update_id);
        } else {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }

        stmt.reset ();
    }

    public void move_item (Objects.Item item) {
        item.updated_at = new GLib.DateTime.now_local ().to_string ();
        Sqlite.Statement stmt;

        sql = """
            UPDATE Items SET
                section_id=$section_id,
                project_id=$project_id,
                parent_id=$parent_id
            WHERE id=$id;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_str (stmt, "$section_id", item.section_id);
        set_parameter_str (stmt, "$project_id", item.project_id);
        set_parameter_str (stmt, "$parent_id", item.parent_id);
        set_parameter_str (stmt, "$id", item.id);

        if (stmt.step () == Sqlite.DONE) {
            foreach (Objects.Item subitem in item.items) {
                subitem.project_id = item.project_id;
                move_item (subitem);
            }
            
            item.updated ();
            item_updated (item, "");
        } else {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }

        stmt.reset ();
    }

    public void checked_toggled (Objects.Item item, bool old_checked) {
        Sqlite.Statement stmt;

        sql = """
            UPDATE Items SET checked=$checked, completed_at=$completed_at
            WHERE id=$id OR parent_id=$id;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_bool (stmt, "$checked", item.checked);
        set_parameter_str (stmt, "$completed_at", item.completed_at);
        set_parameter_str (stmt, "$id", item.id);

        if (stmt.step () == Sqlite.DONE) {
            foreach (Objects.Item subitem in item.items) {
                subitem.checked = item.checked;
                subitem.completed_at = item.completed_at;
                checked_toggled (subitem, old_checked);
            }

            item.updated ();
            item_updated (item, "");

            Services.EventBus.get_default ().checked_toggled (item, old_checked);
        } else {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }

        stmt.reset ();
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

        stmt.reset ();
    }

    /*
        Quick Find
    */

    public Gee.ArrayList<Objects.Project> get_all_projects_by_search (string search_text) {
        Gee.ArrayList<Objects.Project> return_value = new Gee.ArrayList<Objects.Project> ();
        lock (_projects) {
            foreach (var project in projects) {
                if (search_text.down () in project.name.down ()) {
                    return_value.add (project);
                }
            }

            return return_value;
        }
    }

    public Gee.ArrayList<Objects.Section> get_all_sections_by_search (string search_text) {
        Gee.ArrayList<Objects.Section> return_value = new Gee.ArrayList<Objects.Section> ();
        lock (_projects) {
            foreach (var section in sections) {
                if (search_text.down () in section.name.down ()) {
                    return_value.add (section);
                }
            }

            return return_value;
        }
    }

    public Gee.ArrayList<Objects.Project> get_all_projects_by_todoist () {
        Gee.ArrayList<Objects.Project> return_value = new Gee.ArrayList<Objects.Project> ();
        lock (_projects) {
            foreach (var project in projects) {
                if (project.backend_type == BackendType.TODOIST) {
                    return_value.add (project);
                }
            }

            return return_value;
        }
    }

    public Gee.ArrayList<Objects.Project> get_all_projects_by_backend_type (BackendType backend_type) {
        Gee.ArrayList<Objects.Project> return_value = new Gee.ArrayList<Objects.Project> ();
        lock (_projects) {
            foreach (var project in projects) {
                if (project.backend_type == backend_type) {
                    return_value.add (project);
                }
            }

            return return_value;
        }
    }

    public Gee.ArrayList<Objects.Label> get_all_labels_by_todoist () {
        Gee.ArrayList<Objects.Label> return_value = new Gee.ArrayList<Objects.Label> ();
        lock (_labels) {
            foreach (var label in labels) {
                if (label.backend_type == BackendType.TODOIST) {
                    return_value.add (label);
                }
            }

            return return_value;
        }
    }

    public Gee.ArrayList<Objects.Item> get_all_items_by_search (string search_text) {
        Gee.ArrayList<Objects.Item> return_value = new Gee.ArrayList<Objects.Item> ();
        lock (_items) {
            foreach (var item in items) {
                if (!item.checked && (search_text.down () in item.content.down () ||
                    search_text.down () in item.description.down ())) {
                    return_value.add (item);
                }
            }

            return return_value;
        }
    }

    // Reminders

    public void insert_reminder (Objects.Reminder reminder) {
        Sqlite.Statement stmt;
        string sql;

        sql = """
            INSERT OR IGNORE INTO Reminders (id, item_id, due)
            VALUES ($id, $item_id, $due);
        """;

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_str (stmt, "$id", reminder.id);
        set_parameter_str (stmt, "$item_id", reminder.item_id);
        set_parameter_str (stmt, "$due", reminder.due.to_string ());

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        } else {
            reminder_added (reminder);
            reminders.add (reminder);
            reminder.item.reminder_added (reminder);
        }

        stmt.reset ();
    }

    public Gee.ArrayList<Objects.Reminder> get_reminders_collection () {
        Gee.ArrayList<Objects.Reminder> return_value = new Gee.ArrayList<Objects.Reminder> ();
        Sqlite.Statement stmt;

        sql = """
            SELECT id, item_id, due FROM Reminders;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);

        while (stmt.step () == Sqlite.ROW) {
            return_value.add (_fill_reminder (stmt));
        }
        stmt.reset ();
        return return_value;
    }
    
    public Objects.Reminder _fill_reminder (Sqlite.Statement stmt) {
        Objects.Reminder return_value = new Objects.Reminder ();
        return_value.id = stmt.column_text (0);
        return_value.item_id = stmt.column_text (1);
        return_value.due.update_from_json (get_due_parameter (stmt.column_text (2)));
        return return_value;
    }

    public Gee.ArrayList<Objects.Reminder> get_reminders_by_item (Objects.Item item) {
        Gee.ArrayList<Objects.Reminder> return_value = new Gee.ArrayList<Objects.Reminder> ();
        lock (_reminders) {
            foreach (var reminder in reminders) {
                if (reminder.item_id == item.id) {
                    return_value.add (reminder);
                }
            }

            return return_value;
        }
    }

    public Objects.Reminder get_reminder (string id) {
        Objects.Reminder? return_value = null;
        lock (_reminders) {
            foreach (var reminder in reminders) {
                if (reminder.id == id) {
                    return_value = reminder;
                    break;
                }
            }

            return return_value;
        }
    }

    public void delete_reminder (Objects.Reminder reminder) {
        Sqlite.Statement stmt;
    
        sql = """
            DELETE FROM Reminders WHERE id=$id;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_str (stmt, "$id", reminder.id);

        if (stmt.step () == Sqlite.DONE) {
            reminder.deleted ();
            reminder.item.reminder_deleted (reminder);
        } else {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }
        
        stmt.reset ();
    }

     /*
        Queue
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

    public bool curTempIds_exists (string id) { // vala-lint=naming-convention
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

        stmt.reset ();
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

        stmt.reset ();
        return returned;
    }

    public void update_project_id (string current_id, string new_id) {
        Sqlite.Statement stmt;

        sql = """
            UPDATE Projects SET id = $new_id WHERE id = $current_id;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_str (stmt, "$new_id", new_id);
        set_parameter_str (stmt, "$current_id", current_id);

        if (stmt.step () == Sqlite.DONE) {
            Objects.Project? project = get_project (current_id);
            if (project != null) {
                project.id = new_id;
            }

            stmt.reset ();

            sql = """
                UPDATE Sections SET project_id = $new_id WHERE project_id = $current_id;
            """;

            db.prepare_v2 (sql, sql.length, out stmt);
            set_parameter_str (stmt, "$new_id", new_id);
            set_parameter_str (stmt, "$current_id", current_id);

            if (stmt.step () == Sqlite.DONE) {
                foreach (var section in sections) {
                    if (section.project_id == current_id) {
                        section.project_id = new_id;
                    }
                }

                stmt.reset ();

                sql = """
                    UPDATE Items SET project_id = $new_id WHERE project_id = $current_id;
                """;

                db.prepare_v2 (sql, sql.length, out stmt);
                set_parameter_str (stmt, "$new_id", new_id);
                set_parameter_str (stmt, "$current_id", current_id);

                if (stmt.step () == Sqlite.DONE) {
                    foreach (var item in items) {
                        if (item.project_id == current_id) {
                            item.project_id = new_id;
                        }
                    }
                }
            }
        }

        stmt.reset ();
    }

    public void update_section_id (string current_id, string new_id) {
        Sqlite.Statement stmt;

        sql = """
            UPDATE Sections SET id = $new_id WHERE id = $current_id;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_str (stmt, "$new_id", new_id);
        set_parameter_str (stmt, "$current_id", current_id);

        if (stmt.step () == Sqlite.DONE) {
            foreach (var section in sections) {
                if (section.id == current_id) {
                    section.id = new_id;
                }
            }

            stmt.reset ();

            sql = """
                UPDATE Items SET section_id = $new_id WHERE section_id = $current_id;
            """;

            db.prepare_v2 (sql, sql.length, out stmt);
            set_parameter_str (stmt, "$new_id", new_id);
            set_parameter_str (stmt, "$current_id", current_id);

            if (stmt.step () == Sqlite.DONE) {
                foreach (var item in items) {
                    if (item.section_id == current_id) {
                        item.section_id = new_id;
                    }
                }
            }
        }

        stmt.reset ();
    }

    public void update_item_id (string current_id, string new_id) {
        Sqlite.Statement stmt;

        sql = """
            UPDATE Items SET id = $new_id WHERE id = $current_id;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_str (stmt, "$new_id", new_id);
        set_parameter_str (stmt, "$current_id", current_id);

        if (stmt.step () == Sqlite.DONE) {
            foreach (var item in items) {
                if (item.id == current_id) {
                    item.id = new_id;
                }
            }

            stmt.reset ();

            sql = """
                UPDATE Items SET parent_id = $new_id WHERE parent_id = $current_id;
            """;

            db.prepare_v2 (sql, sql.length, out stmt);
            set_parameter_str (stmt, "$new_id", new_id);
            set_parameter_str (stmt, "$current_id", current_id);

            if (stmt.step () == Sqlite.DONE) {
                foreach (var item in items) {
                    if (item.parent_id == current_id) {
                        item.parent_id = new_id;
                    }
                }
            }
        }

        stmt.reset ();
    }

    public void remove_CurTempIds (string id) { // vala-lint=naming-convention
        Sqlite.Statement stmt;

        sql = """
            DELETE FROM CurTempIds WHERE id = $id;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_str (stmt, "$id", id);

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

        stmt.reset ();
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

        stmt.reset ();
    }

    // PARAMETER REGION
    private void set_parameter_int (Sqlite.Statement? stmt, string par, int val) {
        int par_position = stmt.bind_parameter_index (par);
        stmt.bind_int (par_position, val);
    }

    //  private void set_parameter_int64 (Sqlite.Statement? stmt, string par, int64 val) {
    //      int par_position = stmt.bind_parameter_index (par);
    //      stmt.bind_int64 (par_position, val);
    //  }

    private void set_parameter_str (Sqlite.Statement? stmt, string par, string val) {
        int par_position = stmt.bind_parameter_index (par);
        stmt.bind_text (par_position, val);
    }

    private void set_parameter_bool (Sqlite.Statement? stmt, string par, bool val) {
        int par_position = stmt.bind_parameter_index (par);
        stmt.bind_int (par_position, val ? 1 : 0);
    }

    private bool get_parameter_bool (Sqlite.Statement stmt, int col) {
        return stmt.column_int (col) == 1;
    }

    Json.Parser parser;
    public Json.Object? get_due_parameter (string data) {
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

    public bool column_exists (string table, string column) {
        Sqlite.Statement stmt;
        bool returned = false;

        sql = """
            SELECT * FROM %s LIMIT 1;
        """.printf (table);

        db.prepare_v2 (sql, sql.length, out stmt);

        stmt.step ();

        for (int i = 0; i < stmt.column_count (); i++) {
            if (stmt.column_name (i) == column) {
                returned = true;
            }
        }

        return returned;
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

        stmt.reset ();
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

        stmt.reset ();
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

        stmt.reset ();
    }
}
