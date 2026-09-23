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
 * Item Reparent Tests
 *
 * Covers Objects.Item.can_become_subtask_of (), the guard on dropping a task onto another
 * task's row. The fixtures never reach the database: Item.set_parent () populates the backing
 * field, so Item.parent never calls Store.get_item ().
 */

namespace Planify.Tests.ItemReparent {
    private Objects.Item make_item (string id, string project_id, Objects.Item ? parent = null) {
        var item = new Objects.Item ();
        item.id = id;
        item.project_id = project_id;

        if (parent != null) {
            // parent_id's setter clears the cached parent, so it has to come first.
            item.parent_id = parent.id;
            item.set_parent (parent);
        }

        return item;
    }

    private void test_allows_a_task_in_the_same_project () {
        var picked = make_item ("picked", "project-a");
        var target = make_item ("target", "project-a");
        assert_true (picked.can_become_subtask_of (target));
    }

    private void test_allows_a_subtask_moving_to_another_parent () {
        var old_parent = make_item ("old-parent", "project-a");
        var picked = make_item ("picked", "project-a", old_parent);
        var target = make_item ("target", "project-a");
        assert_true (picked.can_become_subtask_of (target));
    }

    private void test_refuses_the_task_itself () {
        var picked = make_item ("picked", "project-a");
        assert_false (picked.can_become_subtask_of (picked));
    }

    private void test_refuses_a_task_in_another_project () {
        var picked = make_item ("picked", "project-a");
        var target = make_item ("target", "project-b");
        assert_false (picked.can_become_subtask_of (target));
    }

    private void test_refuses_its_own_child () {
        var picked = make_item ("picked", "project-a");
        var child = make_item ("child", "project-a", picked);
        assert_false (picked.can_become_subtask_of (child));
    }

    private void test_refuses_its_own_grandchild () {
        var picked = make_item ("picked", "project-a");
        var child = make_item ("child", "project-a", picked);
        var grandchild = make_item ("grandchild", "project-a", child);
        assert_false (picked.can_become_subtask_of (grandchild));
    }

    public void register_tests () {
        Test.add_func ("/core/item_reparent/allows_a_task_in_the_same_project", test_allows_a_task_in_the_same_project);
        Test.add_func ("/core/item_reparent/allows_a_subtask_moving_to_another_parent", test_allows_a_subtask_moving_to_another_parent);
        Test.add_func ("/core/item_reparent/refuses_the_task_itself", test_refuses_the_task_itself);
        Test.add_func ("/core/item_reparent/refuses_a_task_in_another_project", test_refuses_a_task_in_another_project);
        Test.add_func ("/core/item_reparent/refuses_its_own_child", test_refuses_its_own_child);
        Test.add_func ("/core/item_reparent/refuses_its_own_grandchild", test_refuses_its_own_grandchild);
    }
}
