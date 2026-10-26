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
 * All Items Filter Tests
 *
 * Covers Objects.Filters.AllItems.includes (), which decides whether a task added or edited
 * while the All Tasks view is open gets a row of its own there. The view lists top-level tasks
 * only; a subtask is shown inside its parent's row.
 *
 * includes () is static and reads only the item, so the fixtures never reach the database.
 */

namespace Planify.Tests.AllItemsFilter {
    private Objects.Item make_item (bool checked, string parent_id) {
        var item = new Objects.Item ();
        item.id = "all-items-%s-%s".printf (checked.to_string (), parent_id);
        item.checked = checked;
        item.parent_id = parent_id;
        return item;
    }

    private void test_includes_an_open_top_level_task () {
        assert_true (Objects.Filters.AllItems.includes (make_item (false, "")));
    }

    private void test_excludes_a_completed_task () {
        assert_false (Objects.Filters.AllItems.includes (make_item (true, "")));
    }

    private void test_excludes_a_subtask () {
        assert_false (Objects.Filters.AllItems.includes (make_item (false, "some-parent")));
    }

    public void register_tests () {
        Test.add_func ("/core/all_items_filter/includes_an_open_top_level_task", test_includes_an_open_top_level_task);
        Test.add_func ("/core/all_items_filter/excludes_a_completed_task", test_excludes_a_completed_task);
        Test.add_func ("/core/all_items_filter/excludes_a_subtask", test_excludes_a_subtask);
    }
}
