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

/**
 * Section Cache Tests
 *
 * Project.sections is cached on the project, and views like Manage Sections read from it.
 * Sections inserted through the Store, as sync does, must show up there without a restart.
 */

namespace Planify.Tests.SectionCache {
    private const string PROJECT_ID = "section-cache-project";
    private Objects.Project? project = null;

    private Objects.Project get_project () {
        if (project == null) {
            ScratchDatabase.open ();

            project = new Objects.Project ();
            project.id = PROJECT_ID;
            project.name = PROJECT_ID;
            Services.Store.instance ().insert_project (project);
        }

        return project;
    }

    private Objects.Section make_section (string id) {
        var section = new Objects.Section ();
        section.id = id;
        section.name = id;
        section.project_id = PROJECT_ID;
        return section;
    }

    private int count_sections (string id) {
        int count = 0;
        foreach (Objects.Section section in get_project ().sections) {
            if (section.id == id) {
                count++;
            }
        }

        return count;
    }

    private void test_store_insert_updates_project_cache () {
        // Reading the list first populates the cache, like opening the project does.
        assert_true (count_sections ("section-cache-synced") == 0);

        Services.Store.instance ().insert_section (make_section ("section-cache-synced"));

        assert_true (count_sections ("section-cache-synced") == 1);
    }

    private void test_add_if_not_exists_keeps_one_copy () {
        get_project ().add_section_if_not_exists (make_section ("section-cache-local"));

        assert_true (count_sections ("section-cache-local") == 1);
    }

    public void register_tests () {
        Test.add_func ("/core/section_cache/store_insert_updates_project_cache",
            test_store_insert_updates_project_cache);
        Test.add_func ("/core/section_cache/add_if_not_exists_keeps_one_copy",
            test_add_if_not_exists_keeps_one_copy);
    }
}
