/*
* Copyright © 2019 Alain M. (https://github.com/alainm23/planner)
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
*
* Authored by: Alain M. <alainmh23@gmail.com>
*/

public class Item : GLib.Object {
    public int64 id { get; set; default = 0; }
    public int64 project_id { get; set; default = 0; }
    public int64 section_id { get; set; default = 0; }
    public int64 user_id { get; set; default = 0; }
    public int64 assigned_by_uid { get; set; default = 0; }
    public int64 responsible_uid { get; set; default = 0; }
    public int64 sync_id { get; set; default = 0; }
    public int64 parent_id { get; set; default = 0; }
    public int priority { get; set; default = 0; }
    public int item_order { get; set; default = 0; }
    public int checked { get; set; default = 0; }
    public int is_deleted { get; set; default = 0; }
    public int is_todoist { get; set; default = 0; }
    public string content { get; set; default = ""; }
    public string note { get; set; default = ""; }

    public string due_date { get; set; default = ""; }
    public string due_timezone { get; set; default = ""; }
    public string due_string { get; set; default = ""; }
    public string due_lang { get; set; default = ""; }
    public int due_is_recurring { get; set; default = 0; }

    public string date_added { get; set; default = new GLib.DateTime.now_local ().to_string (); }
    public string date_completed { get; set; default = ""; }
    public string date_updated { get; set; default = new GLib.DateTime.now_local ().to_string (); }

    public string to_json () {
        var builder = new Json.Builder ();
        builder.begin_object ();

        builder.set_member_name ("id");
        builder.add_int_value (this.id);

        builder.set_member_name ("project_id");
        if (PlannerQuickAdd.database.curTempIds_exists (this.project_id)) {
            builder.add_string_value (PlannerQuickAdd.database.get_temp_id (this.project_id));
        } else {
            builder.add_int_value (this.project_id);
        }

        builder.set_member_name ("section_id");
        if (PlannerQuickAdd.database.curTempIds_exists (this.section_id)) {
            builder.add_string_value (PlannerQuickAdd.database.get_temp_id (this.section_id));
        } else {
            builder.add_int_value (this.section_id);
        }

        builder.set_member_name ("parent_id");
        if (PlannerQuickAdd.database.curTempIds_exists (this.parent_id)) {
            builder.add_string_value (PlannerQuickAdd.database.get_temp_id (this.parent_id));
        } else {
            builder.add_int_value (this.parent_id);
        }

        builder.set_member_name ("content");
        builder.add_string_value (this.content);

        builder.set_member_name ("checked");
        builder.add_int_value (this.checked);

        builder.set_member_name ("due_date");
        builder.add_string_value (this.due_date);

        builder.end_object ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);

        return generator.to_data (null);
    }
}
