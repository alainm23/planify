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
 * D-Bus GetTasks Contract Tests
 *
 * Services.DBusServer.GetTasks is the read side of the app's D-Bus interface
 * (external clients such as the GNOME Shell extension consume it instead of
 * reading the database). These tests pin down the wire contract: the task
 * selection mirrors the Today view, and the JSON document shape stays stable.
 *
 * Same throwaway-database pattern as test-subitem-cache.vala: Services.Store
 * reads from Services.Database under the XDG_DATA_HOME set by test/meson.build.
 */

namespace Planify.Tests.DBusTasks {
    private const string PROJECT_ID = "dbus-tasks-project";
    private bool database_ready = false;

    private void ensure_database () {
        if (database_ready) {
            return;
        }

        string data_home = Environment.get_variable ("XDG_DATA_HOME");
        if (data_home == null || Environment.get_user_data_dir () != data_home ||
            !data_home.has_suffix ("/test-core-data")) {
            error ("XDG_DATA_HOME must point at the test-core-data scratch dir");
        }

        string app_dir = data_home + "/io.github.alainm23.planify";
        DirUtils.create_with_parents (app_dir, 0700);

        // The Store is a process-wide singleton shared with the other core
        // suites: when it is already populated, just use it. Otherwise start
        // from a fresh database, as app startup does.
        if (Services.Store.instance ().projects.size != 0 ||
            Services.Store.instance ().items.size != 0) {
            database_ready = true;
        } else {
            FileUtils.remove (app_dir + "/database.db");

            Services.Database.get_default ().init_database ();

            // Load the lazy collections while the database is still empty
            // (see test-subitem-cache.vala).
            assert_cmpint (Services.Store.instance ().projects.size, CompareOperator.EQ, 0);
            assert_cmpint (Services.Store.instance ().items.size, CompareOperator.EQ, 0);

            database_ready = true;
        }

        if (Services.Store.instance ().get_project (PROJECT_ID) == null) {
            var project = new Objects.Project ();
            project.id = PROJECT_ID;
            project.name = "DBus Tasks";
            project.color = "#eb5369";
            Services.Store.instance ().insert_project (project);
        }
    }

    private Objects.Item make_item (
        string id, string due_date = "", bool checked = false, bool pinned = false, string parent_id = ""
    ) {
        var item = new Objects.Item ();
        item.id = id;
        item.content = id;
        item.project_id = PROJECT_ID;
        item.pinned = pinned;
        item.parent_id = parent_id;

        if (due_date != "") {
            item.due.date = due_date;
        }

        if (checked) {
            item.checked = true;
            item.completed_at = new GLib.DateTime.now_local ().to_string ();
        }

        return item;
    }

    private string insert_and_serialize (Objects.Item item) {
        Services.Store.instance ().insert_item (item);
        return Services.DBusServer.build_tasks_json (
            Services.DBusServer.collect_today_tasks (),
            Services.DBusServer.count_done_today ()
        );
    }

    private Json.Object parse_task (string json, string id) {
        try {
            var parser = new Json.Parser ();
            parser.load_from_data (json);

            var tasks = parser.get_root ().get_object ().get_array_member ("tasks");
            for (int i = 0; i < tasks.get_length (); i++) {
                var task = tasks.get_object_element (i);
                if (task.get_string_member ("id") == id) {
                    return task;
                }
            }
        } catch (Error e) {
            error ("GetTasks JSON failed to parse: %s", e.message);
        }

        error ("GetTasks JSON has no task '%s'", id);
    }

    private bool has_task (string json, string id) {
        try {
            var parser = new Json.Parser ();
            parser.load_from_data (json);

            var tasks = parser.get_root ().get_object ().get_array_member ("tasks");
            for (int i = 0; i < tasks.get_length (); i++) {
                if (tasks.get_object_element (i).get_string_member ("id") == id) {
                    return true;
                }
            }
        } catch (Error e) {
            error ("GetTasks JSON failed to parse: %s", e.message);
        }

        return false;
    }

    private void test_document_shape () {
        ensure_database ();

        string json = Services.DBusServer.build_tasks_json (new Gee.ArrayList<Objects.Item> (), 0);

        var parser = new Json.Parser ();
        try {
            parser.load_from_data (json);
        } catch (Error e) {
            error ("GetTasks JSON failed to parse: %s", e.message);
        }

        var root = parser.get_root ().get_object ();
        assert_cmpint ((int) root.get_int_member ("version"), CompareOperator.EQ, 1);
        assert_true (root.has_member ("tasks"));
        assert_true (root.get_member ("tasks").get_node_type () == Json.NodeType.ARRAY);
        // Built from literals, so the count is exactly the one passed in.
        assert_cmpint ((int) root.get_int_member ("done_today"), CompareOperator.EQ, 0);
    }

    private void test_today_view_selection () {
        ensure_database ();

        var now = new GLib.DateTime.now_local ();
        string today = now.format ("%Y-%m-%d");
        string yesterday = now.add_days (-1).format ("%Y-%m-%d");
        string tomorrow = now.add_days (1).format ("%Y-%m-%d");

        string json = insert_and_serialize (make_item ("dbus-today", today));
        json = insert_and_serialize (make_item ("dbus-overdue", yesterday));
        json = insert_and_serialize (make_item ("dbus-future", tomorrow));
        json = insert_and_serialize (make_item ("dbus-pinned-undated", "", false, true));

        // Today view semantics: due today and overdue are in, later dates and
        // pinned tasks without a due date are not.
        assert_true (has_task (json, "dbus-today"));
        assert_true (has_task (json, "dbus-overdue"));
        assert_false (has_task (json, "dbus-future"));
        assert_false (has_task (json, "dbus-pinned-undated"));

        // Overdue tasks come before today's (append order, not a sort).
        // Compare relative positions: the shared Store may hold unrelated
        // dated items from other suites.
        try {
            var parser = new Json.Parser ();
            parser.load_from_data (json);
            var tasks = parser.get_root ().get_object ().get_array_member ("tasks");
            int overdue_index = -1;
            int today_index = -1;
            for (int i = 0; i < tasks.get_length (); i++) {
                string id = tasks.get_object_element (i).get_string_member ("id");
                if (id == "dbus-overdue") {
                    overdue_index = i;
                }
                if (id == "dbus-today") {
                    today_index = i;
                }
            }
            assert_true (overdue_index != -1);
            assert_true (today_index != -1);
            assert_true (overdue_index < today_index);
        } catch (Error e) {
            error ("GetTasks JSON failed to parse: %s", e.message);
        }
    }

    private void test_task_field_mapping () {
        ensure_database ();

        var now = new GLib.DateTime.now_local ();
        var item = make_item ("dbus-fields", now.format ("%Y-%m-%d"));
        item.description = "with \"quotes\" and \\ backslashes";
        item.priority = Constants.PRIORITY_1;
        string json = insert_and_serialize (item);

        var task = parse_task (json, "dbus-fields");
        assert_cmpstr (task.get_string_member ("content"), CompareOperator.EQ, item.content);
        assert_cmpstr (task.get_string_member ("description"), CompareOperator.EQ, item.description);
        assert_cmpint ((int) task.get_int_member ("priority"), CompareOperator.EQ, Constants.PRIORITY_1);
        assert_false (task.get_boolean_member ("pinned"));

        var due = task.get_object_member ("due");
        assert_cmpstr (due.get_string_member ("date"), CompareOperator.EQ, item.due.date);
        assert_false (due.get_boolean_member ("is_recurring"));

        var project = task.get_object_member ("project");
        assert_cmpstr (project.get_string_member ("id"), CompareOperator.EQ, PROJECT_ID);
        assert_cmpstr (project.get_string_member ("name"), CompareOperator.EQ, "DBus Tasks");
        assert_cmpstr (project.get_string_member ("color"), CompareOperator.EQ, "#eb5369");
    }

    private void test_selection_edges () {
        ensure_database ();

        var now = new GLib.DateTime.now_local ();
        string today = now.format ("%Y-%m-%d");

        // Recurring due-today tasks pass is_recurring through.
        var recurring = make_item ("dbus-recurring", today);
        recurring.due.is_recurring = true;
        string json = insert_and_serialize (recurring);
        assert_true (has_task (json, "dbus-recurring"));
        assert_true (parse_task (json, "dbus-recurring").get_object_member ("due").get_boolean_member ("is_recurring"));

        // Timed dues count as today all day and keep their time.
        string timed_due = now.format ("%FT%T");
        insert_and_serialize (make_item ("dbus-timed", timed_due));

        // Notes are never part of the selection.
        var note = make_item ("dbus-note", today);
        note.item_type = ItemType.NOTE;
        json = insert_and_serialize (note);

        // A due-today subtask is included, with its parent_id.
        insert_and_serialize (make_item ("dbus-child", today, false, false, "dbus-recurring"));

        // Pinned tasks with a due date appear like any other dated task.
        insert_and_serialize (make_item ("dbus-pinned-today", today, false, true));

        // Trashed items are excluded even when due today.
        var trashed = make_item ("dbus-trashed", today);
        trashed.is_trash = true;
        json = insert_and_serialize (trashed);

        // Orphaned rows (project missing from the Store, as in restored
        // databases) serialize with a null project instead of crashing.
        // insert_item's notify path dereferences item.project, so the row
        // is added the way a reload would: straight into the Store.
        var orphan = make_item ("dbus-orphan", today);
        orphan.project_id = "dbus-missing-project";
        Services.Store.instance ().insert_item (orphan, false, false);
        json = Services.DBusServer.build_tasks_json (
            Services.DBusServer.collect_today_tasks (),
            Services.DBusServer.count_done_today ()
        );

        assert_true (has_task (json, "dbus-timed"));
        assert_true (has_task (json, "dbus-child"));
        assert_true (has_task (json, "dbus-pinned-today"));
        assert_true (has_task (json, "dbus-orphan"));
        assert_false (has_task (json, "dbus-trashed"));
        assert_false (has_task (json, "dbus-note"));
        assert_cmpstr (
            parse_task (json, "dbus-timed").get_object_member ("due").get_string_member ("date"),
            CompareOperator.EQ, timed_due
        );
        assert_cmpstr (
            parse_task (json, "dbus-child").get_string_member ("parent_id"),
            CompareOperator.EQ, "dbus-recurring"
        );
        assert_true (parse_task (json, "dbus-orphan").get_member ("project").get_node_type () == Json.NodeType.NULL);
        assert_true (parse_task (json, "dbus-pinned-today").get_boolean_member ("pinned"));

        // Don't leave the orphan behind: other suites' code may not expect
        // a Store item without a project row.
        Services.Store.instance ().delete_item (orphan);
    }

    private void test_done_today_count () {
        ensure_database ();

        var now = new GLib.DateTime.now_local ();
        int baseline = Services.DBusServer.count_done_today ();

        insert_and_serialize (make_item ("dbus-done-today", now.format ("%Y-%m-%d"), true));
        var done_yesterday = make_item ("dbus-done-yesterday", now.add_days (-1).format ("%Y-%m-%d"), true);
        done_yesterday.completed_at = now.add_days (-1).to_string ();
        insert_and_serialize (done_yesterday);

        // Completions count regardless of the task's due date.
        insert_and_serialize (make_item ("dbus-done-due-tomorrow", now.add_days (1).format ("%Y-%m-%d"), true));

        // Todoist completions carry UTC (Z-suffixed) timestamps: this one is
        // 01:00 local today, which falls on the previous UTC date in
        // UTC-positive zones — counted on the local day only because of the
        // to_timezone conversion.
        var early_local = new GLib.DateTime.now_local ();
        early_local = early_local.add_hours (-early_local.get_hour ())
            .add_minutes (-early_local.get_minute ())
            .add_seconds (-early_local.get_seconds ())
            .add_hours (1);
        var done_utc = make_item ("dbus-done-utc", now.format ("%Y-%m-%d"), true);
        done_utc.completed_at = early_local.to_utc ().format ("%Y-%m-%dT%H:%M:%SZ");
        string json = insert_and_serialize (done_utc);

        assert_false (has_task (json, "dbus-done-today"));
        assert_false (has_task (json, "dbus-done-yesterday"));
        assert_false (has_task (json, "dbus-done-due-tomorrow"));
        assert_cmpint (
            Services.DBusServer.count_done_today () - baseline, CompareOperator.EQ, 3
        );
    }

    public void register_tests () {
        Test.add_func ("/core/dbus_tasks/document_shape", test_document_shape);
        Test.add_func ("/core/dbus_tasks/today_view_selection", test_today_view_selection);
        Test.add_func ("/core/dbus_tasks/selection_edges", test_selection_edges);
        Test.add_func ("/core/dbus_tasks/task_field_mapping", test_task_field_mapping);
        Test.add_func ("/core/dbus_tasks/done_today_count", test_done_today_count);
    }
}
