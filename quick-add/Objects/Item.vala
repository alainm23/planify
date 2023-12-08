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
    public string added_at { get; set; default = new GLib.DateTime.now_local ().to_string (); }
    public string completed_at { get; set; default = ""; }
    public string updated_at { get; set; default = ""; }
    public string section_id { get; set; default = ""; }
    public string project_id { get; set; default = ""; }
    public string parent_id { get; set; default = ""; }
    
    public int priority { get; set; default = 0; }

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

    public string priority_color {
        get {
            if (priority == Constants.PRIORITY_1) {
                return "#ff7066";
            } else if (priority == Constants.PRIORITY_2) {
                return "#ff9914";
            } else if (priority == Constants.PRIORITY_3) {
                return "#5297ff";
            } else {
                return "@text_color";
            }
        }
    }

    public string priority_text {
        get {
            if (priority == Constants.PRIORITY_1) {
                return _("Priority 1: high");
            } else if (priority == Constants.PRIORITY_2) {
                return _("Priority 2: medium");
            } else if (priority == Constants.PRIORITY_3) {
                return _("Priority 3: low");
            } else {
                return _("Priority 4: none");
            }
        }
    }

    public int child_order { get; set; default = 0; }
    public int day_order { get; set; default = 0; }
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
            return section_id != "";
        }
    }

    GLib.DateTime _added_datetime;
    public GLib.DateTime added_datetime {
        get {
            _added_datetime = new GLib.DateTime.from_iso8601 (added_at, new GLib.TimeZone.local ());
            return _added_datetime;
        }
    }

    GLib.DateTime _updated_datetime;
    public GLib.DateTime updated_datetime {
        get {
            _updated_datetime = new GLib.DateTime.from_iso8601 (updated_at, new GLib.TimeZone.local ());
            return _updated_datetime;
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

    Objects.Project? _project;
    public Objects.Project project {
        get {
            _project = Services.Database.get_default ().get_project (project_id);
            return _project;
        }
    }

    construct {

    }

    public override string get_add_json (string temp_id, string uuid) {
        return get_update_json (uuid, temp_id);
    }

    public override string get_update_json (string uuid, string? temp_id = null) {
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
                builder.add_string_value (id);
            }

            if (temp_id != null) {
                builder.set_member_name ("project_id");
                builder.add_string_value (project_id);
                
                if (parent_id != "") {
                    builder.set_member_name ("parent_id");
                    builder.add_string_value (parent_id);
                }

                if (section_id != "") {
                    builder.set_member_name ("section_id");
                    builder.add_string_value (section_id);
                }
            }

            builder.set_member_name ("content");
            builder.add_string_value (Util.get_default ().get_encode_text (content));

            builder.set_member_name ("description");
            builder.add_string_value (Util.get_default ().get_encode_text (description));

            builder.set_member_name ("priority");
            if (priority == 0) {
                builder.add_int_value (Constants.PRIORITY_4);
            } else {
                builder.add_int_value (priority);
            }

            if (has_due) {
                builder.set_member_name ("due");
                builder.begin_object ();

                builder.set_member_name ("date");
                builder.add_string_value (due.date);

                builder.end_object ();
            } else {
                builder.set_member_name ("due");
                builder.add_null_value ();
            }

            builder.set_member_name ("labels");
                builder.begin_array ();
                builder.end_array ();
            builder.end_object ();
        builder.end_object ();
        builder.end_array ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);

        print ("%s\n".printf (generator.to_data (null)));
        return generator.to_data (null);
    }
}