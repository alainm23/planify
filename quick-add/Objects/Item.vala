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

public class Objects.Item : GLib.Object {
    public int64 id { get; set; default = Constants.INACTIVE; }
    public string content { get; set; default = ""; }
    public string description { get; set; default = ""; }
    public Objects.DueDate due { get; set; default = new Objects.DueDate (); }
    public string added_at { get; set; default = ""; }
    public string completed_at { get; set; default = ""; }
    public string updated_at { get; set; default = ""; }
    public int64 section_id { get; set; default = Constants.INACTIVE; }
    public int64 project_id { get; set; default = Constants.INACTIVE; }
    public int64 parent_id { get; set; default = Constants.INACTIVE; }
    
    public int priority { get; set; default = Constants.INACTIVE; }
    public string priority_icon {
        get {
            if (priority == Constants.PRIORITY_1) {
                return "planner-priority-1";
            } else if (priority == Constants.PRIORITY_2) {
                return "planner-priority-2";
            } else if (priority == Constants.PRIORITY_3) {
                return "planner-priority-3";
            } else {
                return "planner-flag";
            }
        }
    }

    string _id_string;
    public string id_string {
        get {
            _id_string = id.to_string ();
            return _id_string;
        }
    }

    public int child_order { get; set; default = Constants.INACTIVE; }
    public int day_order { get; set; default = Constants.INACTIVE; }
    public int due_is_recurring { get; set; default = Constants.INACTIVE; }
    public bool checked { get; set; default = false; }
    public bool is_deleted { get; set; default = false; }
    public bool collapsed { get; set; default = false; }

    public bool pinned { get; set; default = false; }
    public string pinned_icon {
        get {
            return pinned ? "planner-pinned-activated" : "planner-pinned";
        }
    }

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

    public bool has_section {
        get {
            return section_id != Constants.INACTIVE;
        }
    }

    Json.Builder _builder;
    public Json.Builder builder {
        get {
            if (_builder == null) {
                _builder = new Json.Builder ();
            }

            return _builder;
        }
    }

    Gee.HashMap<string, Objects.ItemLabel> _labels = null;
    public Gee.HashMap<string, Objects.ItemLabel> labels {
        get {
            if (_labels == null) {
                _labels = new Gee.HashMap<string, Objects.ItemLabel> ();
            }
            return _labels;
        }
        set {
            _labels = value;
        }
    }

    Objects.Project? _project;
    public Objects.Project project {
        get {
            _project = Services.Database.get_default ().get_project (project_id);
            return _project;
        }
    }

    Objects.Section? _section;
    public Objects.Section section {
        get {
            _section = Services.Database.get_default ().get_section (section_id);
            return _section;
        }
    }

    public string get_add_json (string uuid, string? temp_id = null) {
        builder.reset ();

        builder.begin_array ();
        builder.begin_object ();

        builder.set_member_name ("type");
        builder.add_string_value (temp_id == null ? "item_update" : "item_add");

        builder.set_member_name ("uuid");
        builder.add_string_value (uuid);

        if (temp_id != null) {
            builder.set_member_name ("temp_id");
            builder.add_string_value (temp_id);
        }

        builder.set_member_name ("args");
            builder.begin_object ();

            if (temp_id == null) {
                builder.set_member_name ("id");
                builder.add_int_value (id);
            }

            if (temp_id != null) {
                builder.set_member_name ("project_id");
                builder.add_int_value (project_id);
                
                if (parent_id != Constants.INACTIVE) {
                    builder.set_member_name ("parent_id");
                    builder.add_int_value (parent_id);
                }

                if (section_id != Constants.INACTIVE) {
                    builder.set_member_name ("section_id");
                    builder.add_int_value (section_id);
                }
            }

            builder.set_member_name ("content");
            builder.add_string_value (QuickAddUtil.get_encode_text (content));

            builder.set_member_name ("description");
            builder.add_string_value (QuickAddUtil.get_encode_text (description));

            builder.set_member_name ("priority");
            if (priority == Constants.INACTIVE) {
                builder.add_int_value (Constants.PRIORITY_4);
            } else {
                builder.add_int_value (priority);
            }

            if (has_due) {
                builder.set_member_name ("due");
                builder.begin_object ();

                builder.set_member_name ("date");
                builder.add_string_value (due.date);

                builder.set_member_name ("is_recurring");
                builder.add_boolean_value (due.is_recurring);

                builder.set_member_name ("string");
                builder.add_string_value (due.text);

                builder.set_member_name ("lang");
                builder.add_string_value (due.lang);

                builder.end_object ();
            } else {
                builder.set_member_name ("due");
                builder.add_null_value ();
            }

            //  builder.set_member_name ("labels");
            //      builder.begin_array ();
            //      foreach (Objects.ItemLabel item_label in labels.values) {
            //          builder.add_string_value (item_label.label.name);
            //      }
            //      builder.end_array ();
            //  builder.end_object ();
        builder.end_object ();
        builder.end_array ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);

        return generator.to_data (null);
    }

    public string to_string () {
        return "";
    }

    public void update_local_labels (Gee.HashMap<string, Objects.Label> new_labels) {
        labels.clear ();

        foreach (var entry in new_labels.entries) {
            Objects.ItemLabel item_label = new Objects.ItemLabel ();
            item_label.id = QuickAddUtil.generate_id ();
            item_label.label_id = entry.value.id;
            item_label.item_id = id;

            _labels [item_label.label_id.to_string ()] = item_label;
        }
    }
}
