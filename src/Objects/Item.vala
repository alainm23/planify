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

    Gee.HashMap<string, Objects.ItemLabel> _labels = null;
    public Gee.HashMap<string, Objects.ItemLabel> labels {
        get {
            if (_labels == null) {
                _labels = Planner.database.get_labels_by_item (this);
            }
            return _labels;
        }
        set {
            _labels = value;
        }
    }

    public signal void item_label_added (Objects.ItemLabel item_label);

    construct {
        deleted.connect (() => {
            Planner.database.item_deleted (this);
        });
    }

    public Item.from_json (Json.Node node) {
        id = node.get_object ().get_int_member ("id");
        update_from_json (node);
        update_local_labels (get_labels_from_json (node));
    }

    public void update_labels_from_json (Json.Node node) {
        update_labels_async (get_labels_from_json (node), null);
    }

    public Gee.HashMap<string, Objects.Label> get_labels_from_json (Json.Node node) {
        Gee.HashMap<string, Objects.Label> return_value = new Gee.HashMap<string, Objects.Label> ();
        foreach (unowned Json.Node element in node.get_object ().get_array_member ("labels").get_elements ()) {
            Objects.Label label = Planner.database.get_label_by_name (element.get_string ());
            return_value [label.id_string] = label;
        }
        return return_value;
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

    public override string get_add_json (string temp_id, string uuid) {
        return get_update_json (uuid, temp_id);
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

    public void update_local () {
        Planner.database.update_item (this, Constants.INACTIVE);
    }

    public void update (int64 update_id = Constants.INACTIVE) {
        if (update_timeout_id != 0) {
            Source.remove (update_timeout_id);
        }

        update_timeout_id = Timeout.add (Constants.UPDATE_TIMEOUT, () => {
            update_timeout_id = 0;

            Planner.database.update_item (this, update_id);
            if (project.todoist) {
                Planner.todoist.update.begin (this, (obj, res) => {
                    Planner.todoist.update.end (res);
                });
            }

            return GLib.Source.REMOVE;
        });
    }

    public void update_async_timeout (int64 update_id = Constants.INACTIVE, Widgets.LoadingButton? loading_button = null) {
        if (update_timeout_id != 0) {
            Source.remove (update_timeout_id);
        }

        update_timeout_id = Timeout.add (Constants.UPDATE_TIMEOUT, () => {
            update_timeout_id = 0;

            if (loading_button != null) {
                loading_button.is_loading = true;
            }
            
            Planner.database.update_item (this, update_id);
            if (project.todoist) {
                Planner.todoist.update.begin (this, (obj, res) => {
                    Planner.todoist.update.end (res);
                    if (loading_button != null) {
                        loading_button.is_loading = false;
                    }
                });
            } else {
                loading_button.is_loading = false;
            }

            return GLib.Source.REMOVE;
        });
    }

    public void update_async (int64 update_id = Constants.INACTIVE, Widgets.LoadingButton? loading_button = null) {
        if (loading_button != null) {
            loading_button.is_loading = true;
        }
        
        Planner.database.update_item (this, update_id);
        if (project.todoist) {
            Planner.todoist.update.begin (this, (obj, res) => {
                Planner.todoist.update.end (res);
                if (loading_button != null) {
                    loading_button.is_loading = false;
                }
            });
        } else {
            loading_button.is_loading = false;
        }
    }

    public void update_local_labels (Gee.HashMap<string, Objects.Label> new_labels) {
        labels.clear ();

        foreach (var entry in new_labels.entries) {
            Objects.ItemLabel item_label = new Objects.ItemLabel ();
            item_label.id = Util.get_default ().generate_id ();
            item_label.label_id = entry.value.id;
            item_label.item_id = id;

            _labels [item_label.label_id.to_string ()] = item_label;
        }
    }

    public void insert_local_labels () {
        foreach (var entry in labels.entries) {
            entry.value.item_id = id;
            Planner.database.insert_item_label (entry.value);
        }
    }

    public void update_labels_async (Gee.HashMap<string, Objects.Label> new_labels,
        Widgets.LoadingButton? loading_button = null) {
        foreach (var entry in new_labels.entries) {
            if (!labels.has_key (entry.value.id_string)) {
                add_label_if_not_exists (entry.value);
            }
        }

        Gee.ArrayList <Objects.ItemLabel> labels_delete = new Gee.ArrayList <Objects.ItemLabel> ();
        foreach (var entry in labels.entries) {
            if (!new_labels.has_key (entry.key)) {
                labels_delete.add (entry.value);
            }
        }

        foreach (Objects.ItemLabel item_label in labels_delete) {
            delete_item_label (item_label);
        }

        if (project.todoist) {
            update_async (Constants.INACTIVE, loading_button);
        } else {
            update_local ();
        }
    }

    public Objects.ItemLabel add_label_if_not_exists (Objects.Label label) {
        Objects.ItemLabel? return_value = null;
        lock (_labels) {
            return_value = get_label (label.id);
            if (return_value == null) {
                return_value = new Objects.ItemLabel ();
                return_value.id = Util.get_default ().generate_id ();
                return_value.item_id = id;
                return_value.label_id = label.id;

                Planner.database.insert_item_label (return_value);
                add_item_label (return_value);
            }
            return return_value;
        }
    }

    public Objects.ItemLabel? get_label (int64 id) {
        Objects.ItemLabel? return_value = null;
        lock (_labels) {
            foreach (var entry in labels.entries) {
                if (entry.value.label_id == id) {
                    return_value = entry.value;
                    break;
                }
            }
        }
        return return_value;
    }

    public void add_item_label (Objects.ItemLabel item_label) {
        _labels [item_label.label_id.to_string ()] = item_label;
        item_label_added (item_label);
    }

    public void delete_item_label (Objects.ItemLabel item_label) {
        _labels.unset (item_label.label_id.to_string ());
        Planner.database.delete_item_label (item_label);
    }

    public string get_move_item (string uuid, string type, int64 move_id) {
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
            builder.add_int_value (move_id);
            
            builder.end_object ();
        builder.end_object ();
        builder.end_array ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);

        return generator.to_data (null);
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
                builder.add_int_value (id);
            }

            if (temp_id != null) {
                builder.set_member_name ("project_id");
                builder.add_int_value (project_id);
    
                if (section_id != Constants.INACTIVE) {
                    builder.set_member_name ("section_id");
                    builder.add_int_value (section_id);
                }
            }

            builder.set_member_name ("content");
            builder.add_string_value (Util.get_default ().get_encode_text (content));

            builder.set_member_name ("description");
            builder.add_string_value (Util.get_default ().get_encode_text (description));

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

            builder.set_member_name ("labels");
                builder.begin_array ();
                foreach (Objects.ItemLabel item_label in labels.values) {
                    builder.add_string_value (item_label.label.name);
                }
                builder.end_array ();
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

    public void delete (Layouts.ItemRow? itemrow = null) {
        if (project.todoist) {
            if (itemrow != null) {
                itemrow.is_loading = true;
            }

            Planner.todoist.delete.begin (this, (obj, res) => {
                if (Planner.todoist.delete.end (res)) {
                    Planner.database.delete_item (this);
                } else {
                    if (itemrow != null) {
                        itemrow.is_loading = false;
                    }
                }
            });
        } else {
            Planner.database.delete_item (this);
        }
    }
}
