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
 * Subitem Cache Tests
 *
 * Item.items and Item.items_uncomplete are cached on the parent. Every Store operation that
 * changes a parent's set of children must invalidate that cache, or a view built later (for
 * example a project view opened for the first time after adding a subtask from All Tasks)
 * renders the stale list.
 *
 * Services.Store reads its collections from Services.Database, so the tests use the shared
 * scratch database (scratch-database.vala). The Store is a singleton shared by every test, so
 * each test uses its own ids.
 */

namespace Planify.Tests.SubitemCache {
    private const string PROJECT_ID = "subitem-cache-project";
    private bool database_ready = false;

    private void ensure_database () {
        if (database_ready) {
            return;
        }

        ScratchDatabase.open ();

        // Store.insert_item () notifies a top-level task's project, so it has to exist.
        var project = new Objects.Project ();
        project.id = PROJECT_ID;
        project.name = PROJECT_ID;
        Services.Store.instance ().insert_project (project);

        database_ready = true;
    }

    private Objects.Item make_item (string id, string parent_id = "") {
        var item = new Objects.Item ();
        item.id = id;
        item.content = id;
        item.project_id = PROJECT_ID;
        item.parent_id = parent_id;
        return item;
    }

    private bool contains_id (Gee.ArrayList<Objects.Item> items, string id) {
        foreach (Objects.Item item in items) {
            if (item.id == id) {
                return true;
            }
        }

        return false;
    }

    private void test_insert_updates_parent_items () {
        ensure_database ();

        var parent = make_item ("insert-parent");
        Services.Store.instance ().insert_item (parent);
        // Prime the cache, as the parent's row in the All Tasks view does.
        assert_cmpint (parent.items.size, CompareOperator.EQ, 0);
        assert_cmpint (parent.items_uncomplete.size, CompareOperator.EQ, 0);

        Services.Store.instance ().insert_item (make_item ("insert-child", parent.id));

        assert_true (contains_id (parent.items, "insert-child"));
        assert_true (contains_id (parent.items_uncomplete, "insert-child"));
    }

    private void test_move_updates_old_and_new_parent_items () {
        ensure_database ();

        var old_parent = make_item ("move-old-parent");
        var new_parent = make_item ("move-new-parent");
        var child = make_item ("move-child", old_parent.id);
        Services.Store.instance ().insert_item (old_parent);
        Services.Store.instance ().insert_item (new_parent);
        Services.Store.instance ().insert_item (child);

        assert_true (contains_id (old_parent.items, child.id));
        assert_cmpint (new_parent.items.size, CompareOperator.EQ, 0);

        child.parent_id = new_parent.id;
        Services.Store.instance ().move_item (child, child.project_id, "", old_parent.id);

        assert_false (contains_id (old_parent.items, child.id));
        assert_true (contains_id (new_parent.items, child.id));
    }

    /**
     * Dropping a task onto another task's row, and CalDAV/Todoist sync, reparent through
     * Store.update_item () + EventBus.item_moved instead of Store.move_item ().
     */
    private void test_item_moved_event_updates_old_and_new_parent_items () {
        ensure_database ();

        var old_parent = make_item ("event-old-parent");
        var new_parent = make_item ("event-new-parent");
        var child = make_item ("event-child", old_parent.id);
        Services.Store.instance ().insert_item (old_parent);
        Services.Store.instance ().insert_item (new_parent);
        Services.Store.instance ().insert_item (child);

        assert_true (contains_id (old_parent.items, child.id));
        assert_cmpint (new_parent.items.size, CompareOperator.EQ, 0);

        child.parent_id = new_parent.id;
        Services.Store.instance ().update_item (child);
        Services.EventBus.get_default ().item_moved (child, child.project_id, "", old_parent.id);

        assert_false (contains_id (old_parent.items, child.id));
        assert_true (contains_id (new_parent.items, child.id));
    }

    private void test_complete_updates_parent_items_uncomplete () {
        ensure_database ();

        var parent = make_item ("complete-parent");
        var child = make_item ("complete-child", parent.id);
        Services.Store.instance ().insert_item (parent);
        Services.Store.instance ().insert_item (child);

        assert_true (contains_id (parent.items_uncomplete, child.id));

        child.checked = true;
        Services.Store.instance ().complete_item (child, false);

        assert_false (contains_id (parent.items_uncomplete, child.id));
    }

    public void register_tests () {
        Test.add_func ("/core/subitem_cache/insert_updates_parent_items", test_insert_updates_parent_items);
        Test.add_func ("/core/subitem_cache/move_updates_old_and_new_parent_items", test_move_updates_old_and_new_parent_items);
        Test.add_func ("/core/subitem_cache/item_moved_event_updates_old_and_new_parent_items", test_item_moved_event_updates_old_and_new_parent_items);
        Test.add_func ("/core/subitem_cache/complete_updates_parent_items_uncomplete", test_complete_updates_parent_items_uncomplete);
    }
}
