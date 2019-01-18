/*
* Copyright © 2019 Alain M. (https://github.com/alainm23/planner)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
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
*
* Authored by: Alain M. <alain23@protonmail.com>
*/

public class Services.Share : GLib.Object {
    public Share () {

    }

    public void exort_project (int id, string path) {
        var project = Application.database.get_project (id);
        var tasks = Application.database.get_all_tasks_by_project (id);

        var builder = new Json.Builder ();
        builder.begin_object ();
            builder.set_member_name ("name");
            builder.add_string_value ("Planner");

            builder.set_member_name ("version");
            builder.add_string_value ("1.1.1");

            builder.set_member_name ("type");
            builder.add_string_value ("project");

            // Project Data
            builder.set_member_name ("project");
                builder.begin_object ();
                    builder.set_member_name ("name");
                    builder.add_string_value (project.name);

                    builder.set_member_name ("note");
                    builder.add_string_value (project.note);

                    builder.set_member_name ("deadline");
                    builder.add_string_value (project.deadline);

                    builder.set_member_name ("color");
                    builder.add_string_value (project.color);

                    // Tasks
                    builder.set_member_name ("tasks");
                    builder.begin_array ();

                    foreach (var task in tasks) {
                        builder.begin_object ();
                            builder.set_member_name ("checked");
                            builder.add_int_value ((int64) task.checked);

                            builder.set_member_name ("has_reminder");
                            builder.add_int_value ((int64) task.has_reminder);

                            builder.set_member_name ("was_notified");
                            builder.add_int_value ((int64) task.was_notified);

                            builder.set_member_name ("content");
                            builder.add_string_value (task.content);
                            
                            builder.set_member_name ("note");
                            builder.add_string_value (task.note);

                            builder.set_member_name ("when_date_utc");
                            builder.add_string_value (task.when_date_utc);

                            builder.set_member_name ("reminder_time");
                            builder.add_string_value (task.reminder_time);

                            builder.set_member_name ("checklist");
                            builder.add_string_value (task.checklist);

                            builder.set_member_name ("labels");
                            builder.add_string_value (task.labels);
                        builder.end_object ();
                    }

                    builder.end_array ();
                builder.end_object ();
            builder.end_object ();
        builder.end_object ();
        
        var generator = new Json.Generator ();
	    var root = builder.get_root ();

        generator.set_root (root);
        generator.to_file (path);
    }

    public void import_project (string path) {
        try {
            var parser = new Json.Parser ();
            parser.load_from_file (path);

            var root = parser.get_root ().get_object ();

            var node_project = root.get_object_member ("project");
            
            // Project
            var project = new Objects.Project ();
            project.name = node_project.get_string_member ("name");
            project.note = node_project.get_string_member ("note");
            project.deadline = node_project.get_string_member ("deadline");
            project.color = node_project.get_string_member ("color");

            int project_id = Application.database.add_project_return (project);
            
            // Tasks
            var tasks = node_project.get_array_member ("tasks");
            foreach (var item in tasks.get_elements ()) {
                var item_details = item.get_object ();

                var task = new Objects.Task ();
                task.checked = (int) item_details.get_int_member ("checked");
                task.has_reminder = (int) item_details.get_int_member ("has_reminder");
                task.was_notified = (int) item_details.get_int_member ("was_notified");
                task.content = item_details.get_string_member ("content");
                task.note = item_details.get_string_member ("note");
                task.when_date_utc = item_details.get_string_member ("when_date_utc");
                task.reminder_time = item_details.get_string_member ("reminder_time");
                task.checklist = item_details.get_string_member ("checklist");
                task.labels = item_details.get_string_member ("labels");

                task.project_id = project_id;

                Application.database.add_task (task);
            }

            Application.signals.check_project_import (project_id);
            Application.notification.send_local_notification (
                project.name,
                _("Your project was imported correctly"),
                "document-import",
                4,
                false
            );
        } catch (Error e) {
            print ("Error: %s\n", e.message);
        }
    }
}
