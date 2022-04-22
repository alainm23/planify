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

    GLib.DateTime _added_datetime;
    public GLib.DateTime added_datetime {
        get {
            _added_datetime = new GLib.DateTime.from_iso8601 (added_at, new GLib.TimeZone.local ());
            return _added_datetime;
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

    Objects.Item? _parent;
    public Objects.Item parent {
        get {
            _parent = Planner.database.get_item (parent_id);
            return _parent;
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

    Gee.ArrayList<Objects.Item> _items;
    public Gee.ArrayList<Objects.Item> items {
        get {
            _items = Planner.database.get_subitems (this);
            return _items;
        }
    }

    Gee.ArrayList<Objects.Reminder> _reminders;
    public Gee.ArrayList<Objects.Reminder> reminders {
        get {
            _reminders = Planner.database.get_reminders_by_item (this);
            return _reminders;
        }
    }

    public signal void item_label_added (Objects.ItemLabel item_label);
    public signal void item_added (Objects.Item item);
    public signal void reminder_added (Objects.Reminder reminder);

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
        _section = section;
    }

    public void set_parent (Objects.Item item) {
        _parent = item;
    }

    public void set_project (Objects.Project project) {
        _project = project;
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

    public void update_async_timeout (int64 update_id = Constants.INACTIVE, Layouts.ItemRow? loading_button = null) {
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

    public void update_async (int64 update_id = Constants.INACTIVE, Layouts.ItemRow? loading_button = null) {
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
        Layouts.ItemRow? loading_button = null) {
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

    public string to_move_json (string type, int64 move_id) {
        builder.reset ();
        
        builder.begin_object ();
        
        builder.set_member_name ("id");
        builder.add_int_value (id);

        builder.set_member_name ("type");
        builder.add_string_value (type);

        builder.set_member_name (type);
        if (Planner.database.curTempIds_exists (move_id)) {
            builder.add_string_value (Planner.database.get_temp_id (move_id));
        } else {
            builder.add_int_value (move_id);
        }
        
        builder.end_object ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);

        return generator.to_data (null);
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

    public override string to_json () {
        builder.reset ();
        
        builder.begin_object ();
        
        builder.set_member_name ("id");
        builder.add_int_value (id);

        builder.set_member_name ("project_id");
        if (Planner.database.curTempIds_exists (project_id)) {
            builder.add_string_value (Planner.database.get_temp_id (project_id));
        } else {
            builder.add_int_value (project_id);
        }

        if (section_id != Constants.INACTIVE) {
            builder.set_member_name ("section_id");
            if (Planner.database.curTempIds_exists (section_id)) {
                builder.add_string_value (Planner.database.get_temp_id (section_id));
            } else {
                builder.add_int_value (section_id);
            }
        }

        if (section_id != Constants.INACTIVE) {
            builder.set_member_name ("parent_id");
            if (Planner.database.curTempIds_exists (parent_id)) {
                builder.add_string_value (Planner.database.get_temp_id (parent_id));
            } else {
                builder.add_int_value (parent_id);
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

        //  builder.set_member_name ("labels");
        //      builder.begin_array ();
        //      foreach (Objects.ItemLabel item_label in labels.values) {
        //          builder.add_string_value (item_label.label.name);
        //      }
        //      builder.end_array ();
        builder.end_object ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);

        return generator.to_data (null);
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

    public Objects.Item add_item_if_not_exists (Objects.Item new_item, bool insert=true) {
        Objects.Item? return_value = null;
        lock (_items) {
            return_value = get_item (new_item.id);
            if (return_value == null) {
                new_item.set_parent (this);
                add_item (new_item);
                Planner.database.insert_item (new_item, insert);
                return_value = new_item;
            }
            return return_value;
        }
    }

    public Objects.Item? get_item (int64 id) {
        Objects.Item? return_value = null;
        lock (_items) {
            foreach (var item in items) {
                if (item.id == id) {
                    return_value = item;
                    break;
                }
            }
        }
        return return_value;
    }

    public void add_item (Objects.Item item) {
        _items.add (item);
    }
}
