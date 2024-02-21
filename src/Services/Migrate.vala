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

public class Services.Migrate : GLib.Object {
    static GLib.Once<Migrate> _instance;

    public static unowned Migrate get_default () {
        return _instance.once (() => {
            return new Migrate ();
        });
    }

    public bool migrate_from_file (GLib.File file) {
        string db_path = file.get_path ();

        Sqlite.Database db;
        Sqlite.Database.open (db_path, out db);

        migrate_labels (db);
        migrate_projects (db);
        migrate_sections (db);
        migrate_items (db);

        return true;
    }

    private void migrate_labels (Sqlite.Database db) {
        Sqlite.Statement stmt;

        string sql = """
            SELECT * FROM Labels where todoist = 0;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);

        while (stmt.step () == Sqlite.ROW) {
            Objects.Label label = new Objects.Label ();
            label.id = stmt.column_text (0);
            label.name = "(Planner) %s".printf (stmt.column_text (1));
            label.color = stmt.column_text (2);
            label.backend_type = BackendType.LOCAL;

            Services.Database.get_default ().insert_label (label);
        }

        stmt.reset ();
    }

    private void migrate_projects (Sqlite.Database db) {
        Sqlite.Statement stmt;

        string sql = """
            SELECT * FROM Projects WHERE todoist = 0;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);

        while (stmt.step () == Sqlite.ROW) {
            Objects.Project project = new Objects.Project ();
            project.id = stmt.column_text (0);
            project.name = "(Planner) %s".printf (stmt.column_text (1));
            project.color = stmt.column_text (2);
            project.backend_type = BackendType.LOCAL;

            Services.Database.get_default ().insert_project (project);
        }

        stmt.reset ();
    }

    private void migrate_sections (Sqlite.Database db) {
        Sqlite.Statement stmt;

        string sql = """
            SELECT * FROM Sections;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);

        while (stmt.step () == Sqlite.ROW) {
            Objects.Section section = new Objects.Section ();
            section.id = stmt.column_text (0);
            section.name = stmt.column_text (1);
            section.project_id = stmt.column_text (4);

            Objects.Project? project = Services.Database.get_default ().get_project (section.project_id);
            if (project != null) {
                project.add_section_if_not_exists (section);
            }
        }

        stmt.reset ();
    }

    private void migrate_items (Sqlite.Database db) {
        Sqlite.Statement stmt;

        string sql = """
            SELECT * FROM Items;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);

        while (stmt.step () == Sqlite.ROW) {
            Objects.Item item = new Objects.Item ();
            item.id = stmt.column_text (0);
            item.content = stmt.column_text (1);
            item.description = stmt.column_text (2);
            item.due.update_from_json (Services.Database.get_default ().get_due_parameter (stmt.column_text (3)));
            item.section_id = stmt.column_text (7) == "0" ? "" : stmt.column_text (7);
            item.project_id = stmt.column_text (8);
            item.parent_id = stmt.column_text (9) == "0" ? "" : stmt.column_text (9);
            item.priority = stmt.column_int (10);
            item.checked = stmt.column_int (12) == 1;
            item.pinned = stmt.column_int (16) == 1;
            item.labels = get_labels_by_item (db, item.id);

            if (item.parent_id != "") {
                Objects.Item? parent_item = Services.Database.get_default ().get_item (item.parent_id);
                if (parent_item != null) {
                    parent_item.add_item_if_not_exists (item);
                }
            } else {
                if (item.section_id != "") {
                    Objects.Section? section = Services.Database.get_default ().get_section (item.section_id);
                    if (section != null) {
                        section.add_item_if_not_exists (item);
                    }
                } else {
                    Objects.Project? project = Services.Database.get_default ().get_project (item.project_id);
                    if (project != null) {
                        project.add_item_if_not_exists (item);
                    }
                }
            }
        }

        stmt.reset ();
    }

    private Gee.ArrayList<Objects.Label> get_labels_by_item (Sqlite.Database db, string id) {
        Gee.ArrayList<Objects.Label> return_value = new Gee.ArrayList<Objects.Label> ();
        Sqlite.Statement stmt;

        string sql = """
            SELECT * FROM Items_Labels WHERE item_id = $item_id;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_str (stmt, "$item_id", id);

        while (stmt.step () == Sqlite.ROW) {
            Objects.Label? label = Services.Database.get_default ().get_label (stmt.column_text (2));
            if (label != null) {
                return_value.add (label);
            }
        }

        return return_value;
    }

    private void set_parameter_str (Sqlite.Statement? stmt, string par, string val) {
        int par_position = stmt.bind_parameter_index (par);
        stmt.bind_text (par_position, val);
    }
}
