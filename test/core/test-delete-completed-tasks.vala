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
 * Delete Completed Tasks Tests
 *
 * Covers Services.Store.delete_completed_items_by_project (), ensuring that:
 * 1. Only checked (completed) tasks belonging to the specified project are deleted.
 * 2. Uncompleted tasks within the project are preserved.
 * 3. Completed tasks in other projects are untouched.
 */

namespace Planify.Tests.DeleteCompletedTasks {
    private const string PROJECT_A_ID = "delete-completed-project-a";
    private const string PROJECT_B_ID = "delete-completed-project-b";
    private bool database_ready = false;

    private Objects.Project project_a;
    private Objects.Project project_b;

    private void ensure_database () {
        if (database_ready) {
            return;
        }

        ScratchDatabase.open ();

        project_a = new Objects.Project ();
        project_a.id = PROJECT_A_ID;
        project_a.name = "Project A";
        Services.Store.instance ().insert_project (project_a);

        project_b = new Objects.Project ();
        project_b.id = PROJECT_B_ID;
        project_b.name = "Project B";
        Services.Store.instance ().insert_project (project_b);

        database_ready = true;
    }

    private Objects.Item make_item (string id, string project_id, bool completed) {
        var item = new Objects.Item ();
        item.id = id;
        item.content = id;
        item.project_id = project_id;
        item.checked = completed;
        item.completed_at = completed ? new GLib.DateTime.now_local ().to_string () : "";
        return item;
    }

    private void test_delete_completed_items_by_project () {
        ensure_database ();

        var item_a_active_1 = make_item ("item-a-act-1", PROJECT_A_ID, false);
        var item_a_active_2 = make_item ("item-a-act-2", PROJECT_A_ID, false);
        var item_a_done_1 = make_item ("item-a-done-1", PROJECT_A_ID, true);
        var item_a_done_2 = make_item ("item-a-done-2", PROJECT_A_ID, true);
        var item_b_done_1 = make_item ("item-b-done-1", PROJECT_B_ID, true);

        Services.Store.instance ().insert_item (item_a_active_1);
        Services.Store.instance ().insert_item (item_a_active_2);
        Services.Store.instance ().insert_item (item_a_done_1);
        Services.Store.instance ().insert_item (item_a_done_2);
        Services.Store.instance ().insert_item (item_b_done_1);

        var checked_a_before = Services.Store.instance ().get_items_checked_by_project (project_a);
        assert_cmpint (checked_a_before.size, CompareOperator.EQ, 2);

        var checked_b_before = Services.Store.instance ().get_items_checked_by_project (project_b);
        assert_cmpint (checked_b_before.size, CompareOperator.EQ, 1);

        // Delete all completed tasks in project A
        Services.Store.instance ().delete_completed_items_by_project (project_a);

        // Project A completed tasks should now be 0
        var checked_a_after = Services.Store.instance ().get_items_checked_by_project (project_a);
        assert_cmpint (checked_a_after.size, CompareOperator.EQ, 0);

        // Project A active tasks should still exist
        assert_true (Services.Store.instance ().get_item (item_a_active_1.id) != null);
        assert_true (Services.Store.instance ().get_item (item_a_active_2.id) != null);

        // Project A completed tasks should no longer exist
        assert_true (Services.Store.instance ().get_item (item_a_done_1.id) == null);
        assert_true (Services.Store.instance ().get_item (item_a_done_2.id) == null);

        // Project B completed task should NOT be deleted
        var checked_b_after = Services.Store.instance ().get_items_checked_by_project (project_b);
        assert_cmpint (checked_b_after.size, CompareOperator.EQ, 1);
        assert_true (Services.Store.instance ().get_item (item_b_done_1.id) != null);
    }

    public void register_tests () {
        Test.add_func (
            "/Store/delete_completed_items_by_project",
            test_delete_completed_items_by_project
        );
    }
}
