/*
 * Copyright © 2026 Alain M. (https://github.com/alainm23/planify)
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
 */

/**
 * Label Uniqueness Tests: label names are unique per source, not across all sources.
 */

namespace Planify.Tests.LabelUnique {
    private Objects.Label make_label (string id, string name, string source_id) {
        var label = new Objects.Label ();
        label.id = id;
        label.name = name;
        label.color = "blue";
        label.source_id = source_id;
        return label;
    }

    private bool database_has_label (string id) {
        foreach (Objects.Label label in Services.Database.get_default ().get_labels_collection ()) {
            if (label.id == id) {
                return true;
            }
        }

        return false;
    }

    private void test_same_name_in_another_source_is_stored () {
        ScratchDatabase.open ();

        assert_true (Services.Database.get_default ().insert_label (
            make_label ("label-unique-a", "Cycling", "label-unique-source-a")));
        assert_true (Services.Database.get_default ().insert_label (
            make_label ("label-unique-b", "Cycling", "label-unique-source-b")));

        assert_true (database_has_label ("label-unique-a"));
        assert_true (database_has_label ("label-unique-b"));
    }

    private void test_insert_label_reports_an_ignored_insert () {
        ScratchDatabase.open ();

        assert_true (Services.Database.get_default ().insert_label (
            make_label ("label-unique-dup", "Gifts", "label-unique-source-a")));
        Test.expect_message (null, LogLevelFlags.LEVEL_WARNING, "*was not stored*");
        assert_false (Services.Database.get_default ().insert_label (
            make_label ("label-unique-dup", "Gifts again", "label-unique-source-a")));
        Test.assert_expected_messages ();
    }

    // Migrating an old UNIQUE (name) table restores a task's dropped label from CATEGORIES.
    private void test_opening_an_old_database_restores_dropped_labels () {
        #if WITH_EVOLUTION
        ScratchDatabase.open ();

        string SOURCE_ID = "label-unique-caldav";
        string PROJECT_ID = "label-unique-project";
        string ITEM_ID = "label-unique-item";

        var project = new Objects.Project ();
        project.id = PROJECT_ID;
        project.name = PROJECT_ID;
        project.source_id = SOURCE_ID;
        Services.Store.instance ().insert_project (project);

        string vtodo = string.joinv ("\r\n", {
            "BEGIN:VCALENDAR", "VERSION:2.0", "PRODID:-//test//EN",
            "BEGIN:VTODO", "UID:" + ITEM_ID, "SUMMARY:Ride", "CATEGORIES:Hiking",
            "END:VTODO", "END:VCALENDAR", ""
        });

        var item = new Objects.Item ();
        item.id = ITEM_ID;
        item.content = "Ride";
        item.project_id = PROJECT_ID;
        item.extra_data = Util.generate_extra_data ("https://example.invalid/ride.ics", "", vtodo);
        Services.Store.instance ().insert_item (item);

        Sqlite.Database db;
        assert_cmpint (Sqlite.Database.open (ScratchDatabase.path (), out db), CompareOperator.EQ, Sqlite.OK);
        string errmsg;
        int result = db.exec ("""
            DROP TABLE Labels;
            CREATE TABLE Labels (
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
            INSERT INTO Labels (id, name, color, item_order, is_deleted, is_favorite, backend_type, source_id)
                VALUES ('label-unique-orphan', 'Hiking', 'blue', 0, 0, 0, 'none', 'label-unique-removed');
            UPDATE Items SET labels = 'label-unique-never-stored' WHERE id = 'label-unique-item';
        """, null, out errmsg);
        assert_cmpint (result, CompareOperator.EQ, Sqlite.OK);

        Services.Database.get_default ().init_database ();

        Sqlite.Statement stmt;
        db.prepare_v2 ("SELECT sql FROM sqlite_master WHERE type = 'table' AND name = 'Labels';", -1, out stmt);
        assert_cmpint (stmt.step (), CompareOperator.EQ, Sqlite.ROW);
        assert_true (stmt.column_text (0).contains ("UNIQUE (name, source_id)"));

        db.prepare_v2 ("""
            SELECT l.id FROM Labels l JOIN Items i ON i.labels = l.id
            WHERE i.id = 'label-unique-item' AND l.name = 'Hiking' AND l.source_id = 'label-unique-caldav';
        """, -1, out stmt);
        assert_cmpint (stmt.step (), CompareOperator.EQ, Sqlite.ROW);

        // The removed account's label is left as it was.
        assert_true (database_has_label ("label-unique-orphan"));
        #else
        Test.skip ("CalDAV categories are only read in builds with Evolution");
        #endif
    }

    public void register_tests () {
        Test.add_func ("/core/label_unique/same_name_in_another_source_is_stored",
            test_same_name_in_another_source_is_stored);
        Test.add_func ("/core/label_unique/insert_label_reports_an_ignored_insert",
            test_insert_label_reports_an_ignored_insert);
        Test.add_func ("/core/label_unique/opening_an_old_database_restores_dropped_labels",
            test_opening_an_old_database_restores_dropped_labels);
    }
}
