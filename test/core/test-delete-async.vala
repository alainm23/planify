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
 * Delete Without Confirmation Tests
 *
 * Covers Item.delete_item_async (), Section.delete_section_async () and
 * Project.delete_project_async (), the deletes without a confirmation dialog that the
 * CLI uses. On local projects they must:
 * 1. Report success, not offline, once the delete is done.
 * 2. Remove the object and everything under it from the Store and the database.
 * 3. Leave other objects alone.
 */

namespace Planify.Tests.DeleteAsync {
    private int project_count = 0;

    private Objects.Project make_project (string name) {
        ScratchDatabase.open ();

        var project = new Objects.Project ();
        project.id = "delete-async-project-%d".printf (project_count++);
        project.name = name;
        Services.Store.instance ().insert_project (project);
        return project;
    }

    private Objects.Section make_section (string id, Objects.Project project) {
        var section = new Objects.Section ();
        section.id = id;
        section.name = id;
        section.project_id = project.id;
        Services.Store.instance ().insert_section (section);
        return section;
    }

    private Objects.Item make_item (string id, Objects.Project project, string section_id = "", string parent_id = "") {
        var item = new Objects.Item ();
        item.id = id;
        item.content = id;
        item.project_id = project.id;
        item.section_id = section_id;
        item.parent_id = parent_id;
        Services.Store.instance ().insert_item (item);
        return item;
    }

    // The deletes are async, as for remote accounts; wait for them like the CLI does.
    private HttpResponse wait_item (Objects.Item item) {
        var loop = new MainLoop ();
        HttpResponse? response = null;
        item.delete_item_async.begin ((obj, res) => {
            response = item.delete_item_async.end (res);
            loop.quit ();
        });
        if (response == null) {
            loop.run ();
        }
        return response;
    }

    private HttpResponse wait_section (Objects.Section section) {
        var loop = new MainLoop ();
        HttpResponse? response = null;
        section.delete_section_async.begin ((obj, res) => {
            response = section.delete_section_async.end (res);
            loop.quit ();
        });
        if (response == null) {
            loop.run ();
        }
        return response;
    }

    private HttpResponse wait_project (Objects.Project project) {
        var loop = new MainLoop ();
        HttpResponse? response = null;
        project.delete_project_async.begin ((obj, res) => {
            response = project.delete_project_async.end (res);
            loop.quit ();
        });
        if (response == null) {
            loop.run ();
        }
        return response;
    }

    // get_item_by_id returns an empty item when the row isn't there.
    private bool item_in_database (string id) {
        return Services.Database.get_default ().get_item_by_id (id).id == id;
    }

    private void test_delete_item () {
        var project = make_project ("Delete task");
        var task = make_item ("delete-async-task", project);
        var subtask = make_item ("delete-async-subtask", project, "", task.id);
        var other = make_item ("delete-async-other", project);

        var response = wait_item (task);

        assert_true (response.status);
        assert_false (response.offline);
        assert_true (Services.Store.instance ().get_item (task.id) == null);
        assert_true (Services.Store.instance ().get_item (subtask.id) == null);
        assert_false (item_in_database (task.id));
        assert_false (item_in_database (subtask.id));

        // Other tasks of the project stay.
        assert_true (Services.Store.instance ().get_item (other.id) != null);
        assert_true (item_in_database (other.id));
    }

    private void test_delete_section () {
        var project = make_project ("Delete section");
        var section = make_section ("delete-async-section", project);
        var other_section = make_section ("delete-async-other-section", project);
        var in_section = make_item ("delete-async-in-section", project, section.id);
        var in_other_section = make_item ("delete-async-in-other-section", project, other_section.id);
        var without_section = make_item ("delete-async-without-section", project);

        var response = wait_section (section);

        assert_true (response.status);
        assert_false (response.offline);
        assert_true (Services.Store.instance ().get_section (section.id) == null);
        assert_true (Services.Store.instance ().get_item (in_section.id) == null);
        assert_false (item_in_database (in_section.id));

        assert_true (Services.Store.instance ().get_section (other_section.id) != null);
        assert_true (Services.Store.instance ().get_item (in_other_section.id) != null);
        assert_true (Services.Store.instance ().get_item (without_section.id) != null);
    }

    private void test_delete_project () {
        var project = make_project ("Delete project");
        var section = make_section ("delete-async-project-section", project);
        var in_section = make_item ("delete-async-project-in-section", project, section.id);
        var top_level = make_item ("delete-async-project-top-level", project);

        var other_project = make_project ("Keep project");
        var other_item = make_item ("delete-async-other-project-item", other_project);

        var response = wait_project (project);

        assert_true (response.status);
        assert_false (response.offline);
        assert_true (Services.Store.instance ().get_project (project.id) == null);
        assert_true (Services.Store.instance ().get_section (section.id) == null);
        assert_true (Services.Store.instance ().get_item (in_section.id) == null);
        assert_true (Services.Store.instance ().get_item (top_level.id) == null);
        assert_false (item_in_database (in_section.id));
        assert_false (item_in_database (top_level.id));

        assert_true (Services.Store.instance ().get_project (other_project.id) != null);
        assert_true (Services.Store.instance ().get_item (other_item.id) != null);
    }

    public void register_tests () {
        Test.add_func ("/Delete/item_async", test_delete_item);
        Test.add_func ("/Delete/section_async", test_delete_section);
        Test.add_func ("/Delete/project_async", test_delete_project);
    }
}
