public class Planify.SearchRepository : Object {

    private Sqlite.Database db;
    private bool db_open = false;

    public struct ResultMeta {
        public string name;
        public string description;
    }

    construct {
        var db_path = Path.build_filename (
            Environment.get_user_data_dir (),
            "io.github.alainm23.planify", "database.db"
        );

        if (FileUtils.test (db_path, FileTest.EXISTS)) {
            if (Sqlite.Database.open_v2 (db_path, out db, Sqlite.OPEN_READONLY) == Sqlite.OK) {
                db_open = true;
            }
        }

        if (!db_open) {
            warning ("Could not open database: %s", db_path);
        }
    }

    public string[] search (string query) {
        if (!db_open) {
            return {};
        }

        var results = new GenericArray<string> ();
        string term = "%" + query.down () + "%";

        search_projects (term, results);
        search_items (term, results);

        return results.data;
    }

    public ResultMeta? get_meta (string identifier) {
        if (!db_open) {
            return null;
        }

        if (identifier.has_prefix ("project-")) {
            return get_project_meta (identifier.substring (8));
        } else if (identifier.has_prefix ("item-")) {
            return get_item_meta (identifier.substring (5));
        }

        return null;
    }

    private void search_projects (string term, GenericArray<string> results) {
        Sqlite.Statement stmt;

        var sql = """
            SELECT id FROM Projects
            WHERE is_deleted = 0 AND is_archived = 0
            AND LOWER(name) LIKE $term
            LIMIT 5;
        """;

        if (db.prepare_v2 (sql, sql.length, out stmt) == Sqlite.OK) {
            stmt.bind_text (stmt.bind_parameter_index ("$term"), term);
            while (stmt.step () == Sqlite.ROW) {
                results.add ("project-" + stmt.column_text (0));
            }
        }
    }

    private void search_items (string term, GenericArray<string> results) {
        Sqlite.Statement stmt;

        var sql = """
            SELECT i.id FROM Items i
            LEFT JOIN Projects p ON i.project_id = p.id
            WHERE i.is_deleted = 0 AND i.checked = 0
            AND (p.is_archived = 0 OR p.is_archived IS NULL)
            AND (LOWER(i.content) LIKE $term OR LOWER(i.description) LIKE $term)
            LIMIT 5;
        """;

        if (db.prepare_v2 (sql, sql.length, out stmt) == Sqlite.OK) {
            stmt.bind_text (stmt.bind_parameter_index ("$term"), term);
            while (stmt.step () == Sqlite.ROW) {
                results.add ("item-" + stmt.column_text (0));
            }
        }
    }

    private ResultMeta? get_project_meta (string project_id) {
        Sqlite.Statement stmt;

        var sql = """
            SELECT p.name,
                (SELECT COUNT(*) FROM Items i
                 WHERE i.project_id = p.id AND i.checked = 0 AND i.is_deleted = 0)
            FROM Projects p WHERE p.id = $id;
        """;

        if (db.prepare_v2 (sql, sql.length, out stmt) == Sqlite.OK) {
            stmt.bind_text (stmt.bind_parameter_index ("$id"), project_id);
            if (stmt.step () == Sqlite.ROW) {
                int count = stmt.column_int (1);
                return ResultMeta () {
                    name = stmt.column_text (0),
                    description = "%d %s".printf (count, count == 1 ? "task" : "tasks")
                };
            }
        }

        return null;
    }

    private ResultMeta? get_item_meta (string item_id) {
        Sqlite.Statement stmt;

        var sql = """
            SELECT i.content, p.name FROM Items i
            LEFT JOIN Projects p ON i.project_id = p.id
            WHERE i.id = $id;
        """;

        if (db.prepare_v2 (sql, sql.length, out stmt) == Sqlite.OK) {
            stmt.bind_text (stmt.bind_parameter_index ("$id"), item_id);
            if (stmt.step () == Sqlite.ROW) {
                return ResultMeta () {
                    name = stmt.column_text (0),
                    description = stmt.column_text (1) ?? ""
                };
            }
        }

        return null;
    }
}
