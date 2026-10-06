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
 * Item Sorting Tests
 *
 * Covers Util.set_item_project_sort_func, the comparator behind the All Tasks view's
 * "Project" sort: tasks are grouped by project and ordered by priority inside each group.
 *
 * The fixtures never reach the database. Objects.Project only connects to Services.Store
 * signals in its construct block, Services.Store loads its collections lazily, and
 * Item.set_project () populates the backing field so Item.project never calls
 * Store.get_project ().
 */

namespace Planify.Tests.ItemSorting {
    private Objects.Project make_project (string id, string name) {
        var project = new Objects.Project ();
        project.id = id;
        project.name = name;
        return project;
    }

    /**
     * Builds a task. Pass a null project to model an orphaned task, whose project row is
     * gone but whose rows still show up in the All Tasks view (cf. upstream #2652).
     */
    private Objects.Item make_item (Objects.Project ? project, int priority, string added_at, string content) {
        var item = new Objects.Item ();
        item.content = content;
        item.priority = priority;
        item.added_at = added_at;

        if (project != null) {
            item.project_id = project.id;
            item.set_project (project);
        }

        return item;
    }

    private int compare (Objects.Item item1, Objects.Item item2, SortOrderType sort_order) {
        return Util.get_default ().set_item_project_sort_func (item1, item2, sort_order);
    }

    /**
     * Asserts that first sorts ahead of second, and that the comparator is antisymmetric
     * about that pair — a comparator that returns 0 both ways passes neither check.
     */
    private void assert_sorts_before (Objects.Item first, Objects.Item second, SortOrderType sort_order) {
        int forward = compare (first, second, sort_order);
        int backward = compare (second, first, sort_order);

        if (forward >= 0 || backward <= 0) {
            Test.fail_printf ("expected '%s' to sort before '%s' (got %d forward, %d backward)",
                              first.content, second.content, forward, backward);
        }
    }

    void test_orders_by_priority_within_the_same_project () {
        var project = make_project ("project-a", "Alpha");
        var high = make_item (project, Constants.PRIORITY_1, "2026-01-02T10:00:00Z", "high");
        var low = make_item (project, Constants.PRIORITY_4, "2026-01-01T10:00:00Z", "low");

        // Priority wins over date added, so the older low-priority task still sorts last.
        assert_sorts_before (high, low, SortOrderType.ASC);
    }

    void test_breaks_a_priority_tie_by_date_added () {
        var project = make_project ("project-a", "Alpha");
        var older = make_item (project, Constants.PRIORITY_2, "2026-01-01T10:00:00Z", "older");
        var newer = make_item (project, Constants.PRIORITY_2, "2026-01-05T10:00:00Z", "newer");

        assert_sorts_before (older, newer, SortOrderType.ASC);
    }

    void test_groups_projects_alphabetically_when_ascending () {
        var alpha = make_project ("project-a", "Alpha");
        var zulu = make_project ("project-z", "Zulu");

        // The low-priority Alpha task still precedes the high-priority Zulu one: the
        // grouping is the outer sort, priority only orders within a group.
        var alpha_low = make_item (alpha, Constants.PRIORITY_4, "2026-01-01T10:00:00Z", "alpha low");
        var zulu_high = make_item (zulu, Constants.PRIORITY_1, "2026-01-01T10:00:00Z", "zulu high");

        assert_sorts_before (alpha_low, zulu_high, SortOrderType.ASC);
    }

    void test_keeps_priority_highest_first_when_descending () {
        var alpha = make_project ("project-a", "Alpha");
        var zulu = make_project ("project-z", "Zulu");

        var alpha_high = make_item (alpha, Constants.PRIORITY_1, "2026-01-01T10:00:00Z", "alpha high");
        var alpha_low = make_item (alpha, Constants.PRIORITY_4, "2026-01-01T10:00:00Z", "alpha low");
        var zulu_high = make_item (zulu, Constants.PRIORITY_1, "2026-01-01T10:00:00Z", "zulu high");

        // Descending reverses the grouping …
        assert_sorts_before (zulu_high, alpha_high, SortOrderType.DESC);

        // … but not the ranking inside a group: P1 stays above P4 in both directions.
        assert_sorts_before (alpha_high, alpha_low, SortOrderType.DESC);
    }

    void test_never_interleaves_two_projects_sharing_a_name () {
        var first = make_project ("project-a", "Work");
        var second = make_project ("project-b", "Work");

        // Names collate equal, so only the project id keeps the two groups apart. Without
        // it the rows interleave and the view emits a repeated "Work" header.
        var first_low = make_item (first, Constants.PRIORITY_4, "2026-01-01T10:00:00Z", "first low");
        var second_high = make_item (second, Constants.PRIORITY_1, "2026-01-01T10:00:00Z", "second high");

        assert_sorts_before (first_low, second_high, SortOrderType.ASC);
    }

    void test_sorts_orphaned_tasks_by_priority_without_dereferencing_null () {
        var high = make_item (null, Constants.PRIORITY_1, "2026-01-01T10:00:00Z", "orphan high");
        var low = make_item (null, Constants.PRIORITY_4, "2026-01-01T10:00:00Z", "orphan low");

        assert_sorts_before (high, low, SortOrderType.ASC);
    }

    void test_sorts_an_orphaned_task_against_one_with_a_project () {
        var project = make_project ("project-a", "Alpha");
        var orphan = make_item (null, Constants.PRIORITY_1, "2026-01-01T10:00:00Z", "orphan");
        var owned = make_item (project, Constants.PRIORITY_1, "2026-01-01T10:00:00Z", "owned");

        // An orphan collates under the empty name, which sorts first ascending.
        assert_sorts_before (orphan, owned, SortOrderType.ASC);
    }

    void test_returns_zero_only_when_comparing_an_item_with_itself () {
        var alpha = make_project ("project-a", "Alpha");
        var zulu = make_project ("project-z", "Zulu");

        Objects.Item[] items = {
            make_item (alpha, Constants.PRIORITY_1, "2026-01-01T10:00:00Z", "a1"),
            make_item (alpha, Constants.PRIORITY_1, "2026-01-02T10:00:00Z", "a2"),
            make_item (alpha, Constants.PRIORITY_4, "2026-01-01T10:00:00Z", "a3"),
            make_item (zulu, Constants.PRIORITY_2, "2026-01-01T10:00:00Z", "z1"),
            make_item (null, Constants.PRIORITY_3, "2026-01-01T10:00:00Z", "orphan")
        };

        foreach (SortOrderType sort_order in new SortOrderType[] { SortOrderType.ASC, SortOrderType.DESC }) {
            for (int i = 0; i < items.length; i++) {
                for (int j = 0; j < items.length; j++) {
                    int result = compare (items[i], items[j], sort_order);

                    if ((i == j) != (result == 0)) {
                        Test.fail_printf ("comparing '%s' with '%s' returned %d",
                                          items[i].content, items[j].content, result);
                        return;
                    }
                }
            }
        }
    }

    public void register_tests () {
        Test.add_func ("/item-sorting/orders-by-priority-within-the-same-project",
                       test_orders_by_priority_within_the_same_project);
        Test.add_func ("/item-sorting/breaks-a-priority-tie-by-date-added",
                       test_breaks_a_priority_tie_by_date_added);
        Test.add_func ("/item-sorting/groups-projects-alphabetically-when-ascending",
                       test_groups_projects_alphabetically_when_ascending);
        Test.add_func ("/item-sorting/keeps-priority-highest-first-when-descending",
                       test_keeps_priority_highest_first_when_descending);
        Test.add_func ("/item-sorting/never-interleaves-two-projects-sharing-a-name",
                       test_never_interleaves_two_projects_sharing_a_name);
        Test.add_func ("/item-sorting/sorts-orphaned-tasks-by-priority-without-dereferencing-null",
                       test_sorts_orphaned_tasks_by_priority_without_dereferencing_null);
        Test.add_func ("/item-sorting/sorts-an-orphaned-task-against-one-with-a-project",
                       test_sorts_an_orphaned_task_against_one_with_a_project);
        Test.add_func ("/item-sorting/returns-zero-only-when-comparing-an-item-with-itself",
                       test_returns_zero_only_when_comparing_an_item_with_itself);
    }
}
