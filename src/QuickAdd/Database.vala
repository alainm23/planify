/*
* Copyright © 2019 Alain M. (https://github.com/alainm23/planner)
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

public class Database : GLib.Object {
    private Soup.Session session;
    private Sqlite.Database db;

    private const string TODOIST_SYNC_URL = "https://api.todoist.com/sync/v8/sync";
    private string db_path;

    public signal void item_added (Item item);

    public bool is_adding { get; set; default = false; }
    public signal void item_added_started ();
    public signal void item_added_completed ();
    public signal void item_added_error (int http_code, string error_message);

    public Database () {
        session = new Soup.Session ();

        int rc = 0;
        db_path = Environment.get_user_data_dir () + "/com.github.alainm23.planner/database.db";

        rc = Sqlite.Database.open (db_path, out db);

        if (rc != Sqlite.OK) {
            stderr.printf ("Can't open database: %d, %s\n", rc, db.errmsg ());
            Gtk.main_quit ();
        }
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
    
    public Gee.ArrayList<Project?> get_all_projects () {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            SELECT * FROM Projects WHERE inbox_project = 0 ORDER BY item_order;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        var all = new Gee.ArrayList<Project?> ();

        while ((res = stmt.step ()) == Sqlite.ROW) {
            var p = new Project ();

            p.id = stmt.column_int64 (0);
            p.area_id = stmt.column_int64 (1);
            p.name = stmt.column_text (2);
            p.note = stmt.column_text (3);
            p.due_date = stmt.column_text (4);
            p.color = stmt.column_int (5);
            p.is_todoist = stmt.column_int (6);
            p.inbox_project = stmt.column_int (7);
            p.team_inbox = stmt.column_int (8);
            p.item_order = stmt.column_int (9);
            p.is_deleted = stmt.column_int (10);
            p.is_archived = stmt.column_int (11);
            p.is_favorite = stmt.column_int (12);
            p.is_sync = stmt.column_int (13);
            p.shared = stmt.column_int (14);
            p.is_kanban = stmt.column_int (15);

            all.add (p);
        }

        return all;
    }

    public Project? get_project_by_id (int64 id) {
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

        var p = new Project ();

        if (stmt.step () == Sqlite.ROW) {
            p.id = stmt.column_int64 (0);
            p.area_id = stmt.column_int64 (1);
            p.name = stmt.column_text (2);
            p.note = stmt.column_text (3);
            p.due_date = stmt.column_text (4);
            p.color = stmt.column_int (5);
            p.is_todoist = stmt.column_int (6);
            p.inbox_project = stmt.column_int (7);
            p.team_inbox = stmt.column_int (8);
            p.item_order = stmt.column_int (9);
            p.is_deleted = stmt.column_int (10);
            p.is_archived = stmt.column_int (11);
            p.is_favorite = stmt.column_int (12);
            p.is_sync = stmt.column_int (13);
            p.shared = stmt.column_int (14);
            p.is_kanban = stmt.column_int (15);
            p.show_completed = stmt.column_int (16);
        }

        return p;
    }

    public bool insert_item (Item item) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            SELECT COUNT (*) FROM Items WHERE project_id = ? AND section_id = ?;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, item.project_id);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (2, item.section_id);
        assert (res == Sqlite.OK);

        if (stmt.step () == Sqlite.ROW) {
            item.item_order = stmt.column_int (0);
        }

        stmt.reset ();

        sql = """
            INSERT OR IGNORE INTO Items (id, project_id, section_id, user_id, assigned_by_uid,
            responsible_uid, sync_id, parent_id, priority, item_order, checked,
            is_deleted, content, note, due_date, date_added, date_completed, date_updated, 
            due_timezone, due_string, due_lang, due_is_recurring, is_todoist)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, item.id);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (2, item.project_id);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (3, item.section_id);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (4, item.user_id);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (5, item.assigned_by_uid);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (6, item.responsible_uid);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (7, item.sync_id);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (8, item.parent_id);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (9, item.priority);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (10, item.item_order);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (11, item.checked);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (12, item.is_deleted);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (13, item.content);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (14, item.note);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (15, item.due_date);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (16, item.date_added);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (17, item.date_completed);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (18, item.date_updated);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (19, item.due_timezone);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (20, item.due_string);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (21, item.due_lang);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (22, item.due_is_recurring);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (23, item.is_todoist);
        assert (res == Sqlite.OK);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
            return false;
        } else {
            item_added (item);
            return true;
        }
    }

    public bool insert_queue (Queue queue) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            INSERT OR IGNORE INTO Queue (uuid, object_id, query, temp_id, args, date_added)
            VALUES (?, ?, ?, ?, ?, ?);
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (1, queue.uuid);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (2, queue.object_id);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (3, queue.query);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (4, queue.temp_id);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (5, queue.args);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (6, queue.date_added);
        assert (res == Sqlite.OK);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
            return false;
        } else {
            return true;
        }
    }

    public bool insert_CurTempIds (int64 id, string temp_id, string object) { // vala-lint=naming-convention
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            INSERT OR IGNORE INTO CurTempIds (id, temp_id, object)
            VALUES (?, ?, ?);
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, id);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (2, temp_id);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (3, object);
        assert (res == Sqlite.OK);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
            return false;
        } else {
            return true;
        }
    }

    public bool curTempIds_exists (int64 id) { // vala-lint=naming-convention
        bool returned = false;
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("SELECT COUNT (*) FROM CurTempIds WHERE id = ?", -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, id);
        assert (res == Sqlite.OK);

        if (stmt.step () == Sqlite.ROW) {
            returned = stmt.column_int (0) > 0;
        }

        return returned;
    }

    public string get_temp_id (int64 id) {
        string returned = "";
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            SELECT temp_id FROM CurTempIds WHERE id = ?;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, id);
        assert (res == Sqlite.OK);

        if (stmt.step () == Sqlite.ROW) {
            returned = stmt.column_text (0);
        }

        return returned;
    }

    public void add_todoist_item (Item item) {
        item_added_started ();
        is_adding = true;

        new Thread<void*> ("add_todoist_item", () => {
            string temp_id = generate_string ();
            string uuid = generate_string ();

            string url = "%s?token=%s&commands=%s".printf (
                TODOIST_SYNC_URL,
                PlannerQuickAdd.settings.get_string ("todoist-access-token"),
                get_add_item_json (item, temp_id, uuid)
            );

            var message = new Soup.Message ("POST", url);

            session.queue_message (message, (sess, mess) => {
                if (mess.status_code == 200) {
                    try {
                        var parser = new Json.Parser ();
                        parser.load_from_data ((string) mess.response_body.flatten ().data, -1);

                        var node = parser.get_root ().get_object ();

                        var sync_status = node.get_object_member ("sync_status");
                        var uuid_member = sync_status.get_member (uuid);

                        if (uuid_member.get_node_type () == Json.NodeType.VALUE) {
                            string sync_token = node.get_string_member ("sync_token");
                            PlannerQuickAdd.settings.set_string ("todoist-sync-token", sync_token);

                            item.id = node.get_object_member ("temp_id_mapping").get_int_member (temp_id);
                            insert_item (item);
                            print ("Item creado: %s\n".printf (item.content));
                            item_added_completed ();
                            is_adding = false;
                        } else {
                            var http_code = (int32) sync_status.get_object_member (uuid).get_int_member ("http_code");
                            var error_message = sync_status.get_object_member (uuid).get_string_member ("error");
                            item_added_error (http_code, error_message);
                            is_adding = false;
                        }
                    } catch (Error e) {
                        item_added_error ((int32) mess.status_code, e.message);
                        is_adding = false;
                    }
                } else {
                    if (is_disconnected ()) {
                        var queue = new Queue ();
                        queue.uuid = uuid;
                        queue.object_id = item.id;
                        queue.temp_id = temp_id;
                        queue.query = "item_add";
                        queue.args = item.to_json ();

                        if (insert_item (item) &&
                            insert_queue (queue) &&
                            insert_CurTempIds (item.id, temp_id, "item")) {
                            item_added_completed ();
                        }
                    } else {
                        item_added_error ((int32) mess.status_code, _("Connection error"));
                        is_adding = false;
                    }
                }
            });

            return null;
        });
    }

    public string get_add_item_json (Item item, string temp_id, string uuid) {
        var builder = new Json.Builder ();
        builder.begin_array ();
        builder.begin_object ();

        builder.set_member_name ("type");
        builder.add_string_value ("item_add");

        builder.set_member_name ("temp_id");
        builder.add_string_value (temp_id);

        builder.set_member_name ("uuid");
        builder.add_string_value (uuid);

        builder.set_member_name ("args");
            builder.begin_object ();

            builder.set_member_name ("content");
            builder.add_string_value (item.content);

            builder.set_member_name ("project_id");
            builder.add_int_value (item.project_id);

            if (item.parent_id != 0) {
                builder.set_member_name ("parent_id");
                builder.add_int_value (item.parent_id);
            }

            if (item.section_id != 0) {
                builder.set_member_name ("section_id");
                builder.add_int_value (item.section_id);
            }

            builder.end_object ();
        builder.end_object ();
        builder.end_array ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);

        return generator.to_data (null);
    }

    public string generate_string () {
        string allowed_characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz" + "0123456789";

        var password_builder = new StringBuilder ();
        for (var i = 0; i < 36; i++) {
            var random_index = Random.int_range (0, allowed_characters.length);
            password_builder.append_c (allowed_characters[random_index]);
        }

        return password_builder.str;
    }

    public bool is_disconnected () {
        var host = "www.google.com";

        try {
            var resolver = Resolver.get_default ();
            var addresses = resolver.lookup_by_name (host, null);
            var address = addresses.nth_data (0);
            if (address == null) {
                return false;
            }
        } catch (Error e) {
            debug ("%s\n", e.message);
            return true;
        }

        return false;
    }
}
