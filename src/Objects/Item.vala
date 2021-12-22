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
    public int64 section_id { get; set; default = Constants.INACTIVE; }
    public int64 project_id { get; set; default = Constants.INACTIVE; }
    public int64 parent_id { get; set; default = Constants.INACTIVE; }
    public int priority { get; set; default = Constants.INACTIVE; }
    public int child_order { get; set; default = Constants.INACTIVE; }
    public int day_order { get; set; default = Constants.INACTIVE; }
    public int due_is_recurring { get; set; default = Constants.INACTIVE; }
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
        builder.reset ();

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

            if (has_due) {
                builder.set_member_name ("due");
                builder.begin_object ();

                builder.set_member_name ("date");
                if (Util.get_default ().has_time_from_string (due.date)) {
                    builder.add_string_value (
                        Util.get_default ().get_todoist_datetime_format (due.date)
                    );
                } else {
                    builder.add_string_value (
                        new GLib.DateTime.from_iso8601 (
                            due.date,
                            new GLib.TimeZone.local ()
                        ).format ("%F")
                    );
                }

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
        builder.reset ();

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

    public void update (int64 update_id = Constants.INACTIVE) {
        if (update_timeout_id != 0) {
            Source.remove (update_timeout_id);
        }

        update_timeout_id = Timeout.add (Constants.UPDATE_TIMEOUT, () => {
            update_timeout_id = 0;

            Planner.database.update_item (this, update_id);
            if (project.todoist) {
                Planner.todoist.update_item.begin (this, (obj, res) => {
                    Planner.todoist.update_item.end (res);
                });
            }

            return GLib.Source.REMOVE;
        });
    }

    public void update_async (int64 update_id = Constants.INACTIVE, Widgets.LoadingButton loading_button) {
        if (update_timeout_id != 0) {
            Source.remove (update_timeout_id);
        }

        update_timeout_id = Timeout.add (Constants.UPDATE_TIMEOUT, () => {
            update_timeout_id = 0;
            loading_button.is_loading = true;
            Planner.database.update_item (this, update_id);
            if (project.todoist) {
                Planner.todoist.update_item.begin (this, (obj, res) => {
                    Planner.todoist.update_item.end (res);
                    loading_button.is_loading = false;
                });
            }

            return GLib.Source.REMOVE;
        });
    }

    public string get_move_item (string uuid, string type, int64 id) {
        builder.reset ();

        builder.begin_array ();
        builder.begin_object ();

        builder.set_member_name ("type");
        builder.add_string_value ("item_move");

        builder.set_member_name ("uuid");
        builder.add_string_value (uuid);

        builder.set_member_name ("args");
            builder.begin_object ();

            builder.set_member_name ("id");
            builder.add_int_value (id);

            builder.set_member_name (type);
            builder.add_int_value (id);
            
            builder.end_object ();
        builder.end_object ();
        builder.end_array ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);

        return generator.to_data (null);
    }

    public string get_update_json (string uuid) {
        builder.reset ();

        builder.begin_array ();
        builder.begin_object ();

        builder.set_member_name ("type");
        builder.add_string_value ("item_update");

        builder.set_member_name ("uuid");
        builder.add_string_value (uuid);

        builder.set_member_name ("args");
            builder.begin_object ();

            builder.set_member_name ("id");
            builder.add_int_value (id);

            builder.set_member_name ("content");
            builder.add_string_value (Util.get_default ().get_encode_text (content));

            builder.set_member_name ("description");
            builder.add_string_value (Util.get_default ().get_encode_text (description));

            builder.set_member_name ("priority");
            if (priority == Constants.INACTIVE) {
                builder.add_int_value (1);
            } else {
                builder.add_int_value (priority);
            }

            if (has_due) {
                builder.set_member_name ("due");
                builder.begin_object ();

                builder.set_member_name ("date");
                if (Util.get_default ().has_time_from_string (due.date)) {
                    builder.add_string_value (
                        Util.get_default ().get_todoist_datetime_format (due.date)
                    );
                } else {
                    builder.add_string_value (
                        new GLib.DateTime.from_iso8601 (
                            due.date,
                            new GLib.TimeZone.local ()
                        ).format ("%F")
                    );
                }

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

            // if (Planner.settings.get_boolean ("todoist-sync-labels")) {
            //     builder.set_member_name ("labels");
            //     builder.begin_array ();
            //     foreach (var label in Planner.database.get_labels_by_item (item.id)) {
            //         if (label.is_todoist == 1) {
            //             builder.add_int_value (label.id);
            //         }
            //     }
            //     builder.end_array ();
            // }
            builder.end_object ();
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

    public void delete () {
        if (project.todoist) {
            Planner.todoist.delete.begin (this, (obj, res) => {
                Planner.todoist.delete.end (res);
                Planner.database.delete_item (this);
            });
        } else {
            Planner.database.delete_item (this);
        }
    }
}