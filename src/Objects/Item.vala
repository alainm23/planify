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

public class Objects.Item : Objects.BaseObject {
    public string content { get; set; default = ""; }
    public string description { get; set; default = ""; }
    
    public Objects.DueDate due { get; set; default = new Objects.DueDate (); }

    public string added_at { get; set; default = ""; }
    public string completed_at { get; set; default = ""; }
    public string updated_at { get; set; default = ""; }
    public int64 section_id { get; set; default = 0; }
    public int64 project_id { get; set; default = 0; }
    public int64 parent_id { get; set; default = 0; }
    public int priority { get; set; default = 0; }
    public int child_order { get; set; default = 0; }
    public int day_order { get; set; default = 0; }
    public int due_is_recurring { get; set; default = 0; }
    public bool checked { get; set; default = false; }
    public bool is_deleted { get; set; default = false; }
    public bool collapsed { get; set; default = false; }

    public bool completed {
        get {
            return checked;
        }
    }

    public bool has_due {
        get {
            return due.datetime != null;
        }
    }

    Objects.Project? _project;
    public Objects.Project project {
        get {
            _project = Planner.database.get_project (project_id);
            return _project;
        }
    }

    Objects.Section? _section;
    public Objects.Section section {
        get {
            _section = Planner.database.get_section (section_id);
            return _section;
        }
    }

    construct {
        deleted.connect (() => {
            Planner.database.item_deleted (this);
        });
    }

    public Item.from_json (Json.Node node) {
        id = node.get_object ().get_int_member ("id");
        update_from_json (node);
    }

    public void update_from_json (Json.Node node) {
        project_id = node.get_object ().get_int_member ("project_id");
        content = node.get_object ().get_string_member ("content");
        description = node.get_object ().get_string_member ("description");
        checked = node.get_object ().get_boolean_member ("checked");
        priority = (int32) node.get_object ().get_int_member ("priority");
        is_deleted = node.get_object ().get_boolean_member ("is_deleted");
        added_at = node.get_object ().get_string_member ("added_at");

        if (!node.get_object ().get_null_member ("section_id")) {
            section_id = node.get_object ().get_int_member ("section_id");
        } else{
            section_id = Constants.INACTIVE;
        }

        if (!node.get_object ().get_null_member ("parent_id")) {
            parent_id = node.get_object ().get_int_member ("parent_id");
        } else {
            parent_id = Constants.INACTIVE;
        }

        if (!node.get_object ().get_null_member ("completed_at")) {
            completed_at = node.get_object ().get_string_member ("completed_at");
        } else {
            completed_at = "";
        }

        if (!node.get_object ().get_null_member ("due")) {
            due.update_from_json (node.get_object ().get_object_member ("due"));
            // var due_object = object.get_object_member ("due");
            // var datetime = Planner.utils.get_todoist_datetime (
            //     due_object.get_string_member ("date")
            // );
            // i.due_date = datetime.to_string ();

            // if (due_object.get_null_member ("timezone") == false) {
            //     i.due_timezone = due_object.get_string_member ("timezone");
            // }

            // i.due_string = due_object.get_string_member ("string");
            // i.due_lang = due_object.get_string_member ("lang");
            // if (due_object.get_boolean_member ("is_recurring")) {
            //     i.due_is_recurring = 1;
            // }
        } else {
            due.reset ();
        }
    }

    public void set_section (Objects.Section section) {
        this._section = section;
    }

    public void set_project (Objects.Project project) {
        this._project = project;
    }

    public string get_add_json (string temp_id, string uuid) {
        var builder = new Json.Builder ();
        builder.begin_array ();
        builder.begin_object ();

        builder.set_member_name ("type");
        builder.add_string_value ("item_add");

        builder.set_member_name ("temp_id");
        builder.add_string_value (temp_id);

        builder.set_member_name ("uuid");
        builder.add_string_value (uuid);

        builder.set_member_name ("args");
            builder.begin_object ();

            builder.set_member_name ("content");
            builder.add_string_value (Util.get_default ().get_encode_text (content));

            builder.set_member_name ("description");
            builder.add_string_value (Util.get_default ().get_encode_text (description));

            builder.set_member_name ("project_id");
            builder.add_int_value (project_id);

            // builder.set_member_name ("priority");
            // builder.add_int_value (item.priority);

            // if (item.parent_id != 0) {
            //     builder.set_member_name ("parent_id");
            //     builder.add_int_value (item.parent_id);
            // }

            if (section_id != 0) {
                builder.set_member_name ("section_id");
                builder.add_int_value (section_id);
            }

            // if (item.due_date != "") {
            //     builder.set_member_name ("due");
            //     builder.begin_object ();

            //     builder.set_member_name ("date");
            //     if (Planner.utils.has_time_from_string (item.due_date)) {
            //         builder.add_string_value (Planner.utils.get_todoist_datetime_format (item.due_date));
            //     } else {
            //         builder.add_string_value (
            //             new GLib.DateTime.from_iso8601 (
            //                 item.due_date,
            //                 new GLib.TimeZone.local ()
            //             ).format ("%F")
            //         );
            //     }

            //     builder.end_object ();
            // }

            // if (labels != null) {
            //     builder.set_member_name ("labels");
            //     builder.begin_array ();
            //     foreach (Widgets.LabelItem label_item in labels) {
            //         if (label_item.label.is_todoist == 1) {
            //             builder.add_int_value (label_item.label.id);
            //         }
            //     }
            //     builder.end_array ();
            // }

            // if (item.parent_id != 0) {
            //     builder.set_member_name ("parent_id");
            //     builder.add_int_value (item.parent_id);
            // }
            
            builder.end_object ();
        builder.end_object ();
        builder.end_array ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);

        return generator.to_data (null);
    }

    public string get_check_json (string uuid, string type) {
        var builder = new Json.Builder ();
        builder.begin_array ();
        builder.begin_object ();

        // Set type
        builder.set_member_name ("type");
        builder.add_string_value (type);

        builder.set_member_name ("uuid");
        builder.add_string_value (uuid);

        builder.set_member_name ("args");
            builder.begin_object ();

            builder.set_member_name ("id");
            builder.add_int_value (id);

            builder.end_object ();
        builder.end_object ();
        builder.end_array ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);

        return generator.to_data (null);
    }
}