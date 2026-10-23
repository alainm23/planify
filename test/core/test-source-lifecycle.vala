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
 * Source lifecycle tests use synthetic rows in the core test scratch database. They do not
 * start a CalDAV service or read a real account/database.
 */
namespace Planify.Tests.SourceLifecycle {
    private const string SOURCE_ID = "source-lifecycle-caldav";
    private bool database_ready = false;

    private void ensure_database () {
        if (database_ready) {
            return;
        }

        ScratchDatabase.open ();
        database_ready = true;
    }

    private Objects.Project make_project (string id, string source_id) {
        var project = new Objects.Project ();
        project.id = id;
        project.name = id;
        project.source_id = source_id;
        project.backend_type = SourceType.CALDAV;
        return project;
    }

    private bool database_has_source_project (string source_id) {
        foreach (Objects.Project project in Services.Database.get_default ().get_projects_collection ()) {
            if (project.source_id == source_id) {
                return true;
            }
        }

        return false;
    }

    private void test_orphan_source_type_falls_back_to_backend () {
        ensure_database ();

        var project = make_project ("source-lifecycle-orphan", "source-lifecycle-missing");

        assert_true (project.source == null);
        assert_true (project.source_type == SourceType.CALDAV);
    }

    private void test_source_deletion_rejects_late_project_insert () {
        ensure_database ();

        var store = Services.Store.instance ();
        var source = new Objects.Source ();
        source.id = SOURCE_ID;
        source.source_type = SourceType.CALDAV;
        source.data = new Objects.SourceCalDAVData ();
        source.display_name = SOURCE_ID;
        store.insert_source (source);

        // Five initial rows reach the source-deletion batch yield, where a synthetic in-flight
        // sync attempts to add another project.
        for (int i = 0; i < 5; i++) {
            store.insert_project (make_project ("%s-%d".printf (SOURCE_ID, i), SOURCE_ID));
        }

        bool late_insert_attempted = false;
        var loop = new MainLoop ();
        Timeout.add (1, () => {
            late_insert_attempted = true;
            store.insert_project (make_project ("%s-late".printf (SOURCE_ID), SOURCE_ID));
            return false;
        });

        source.delete_source.begin ((obj, res) => {
            source.delete_source.end (res);
            loop.quit ();
        });
        loop.run ();

        assert_true (late_insert_attempted);
        assert_true (store.get_source (SOURCE_ID) == null);
        assert_cmpint (store.get_projects_by_source (SOURCE_ID).size, CompareOperator.EQ, 0);
        assert_false (database_has_source_project (SOURCE_ID));
    }

    public void register_tests () {
        Test.add_func (
            "/core/source_lifecycle/orphan_source_type_falls_back_to_backend",
            test_orphan_source_type_falls_back_to_backend
        );
        Test.add_func (
            "/core/source_lifecycle/deletion_rejects_late_project_insert",
            test_source_deletion_rejects_late_project_insert
        );
    }
}
