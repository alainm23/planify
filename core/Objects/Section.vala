/*
* Copyright © 2023 Alain M. (https://github.com/alainm23/planify)
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

public class Objects.Section : Objects.BaseObject {
    public string project_id { get; set; default = ""; }
    public string archived_at { get; set; default = ""; }
    public string added_at { get; set; default = new GLib.DateTime.now_local ().to_string (); }
    public int section_order { get; set; default = 0; }
    public bool collapsed { get; set; default = true; }
    public bool is_deleted { get; set; default = false; }
    public bool is_archived { get; set; default = false; }

    // Tmp
    public bool activate_name_editable { get; set; default = false; }

    string _short_name;
    public string short_name {
        get {
            _short_name = Util.get_default ().get_short_name (name);
            return _short_name;
        }
    }

    Objects.Project? _project;
    public Objects.Project project {
        get {
            _project = Services.Database.get_default ().get_project (project_id);
            return _project;
        }
    }

    Gee.ArrayList<Objects.Item> _items;
    public Gee.ArrayList<Objects.Item> items {
        get {
            _items = Services.Database.get_default ().get_item_by_baseobject (this);
            _items.sort ((a, b) => {
                if (a.child_order > b.child_order) {
                    return 1;
                } if (a.child_order == b.child_order) {
                    return 0;
                }
                
                return -1;
            });
            return _items;
        }
    }

    public signal void item_added (Objects.Item item);

    int? _section_count = null;
    public int section_count {
        get {
            if (_section_count == null) {
                _section_count = update_section_count ();
            }

            return _section_count;
        }

        set {
            _section_count = value;
        }
    }

    public signal void section_count_updated ();

    construct {
        deleted.connect (() => {
            Idle.add (() => {
                Services.Database.get_default ().section_deleted (this);
                return false;
            });
        });
        

        Services.EventBus.get_default ().checked_toggled.connect ((item) => {
            if (item.section_id == id) {
                _section_count = update_section_count ();
                section_count_updated ();
            }
        });

        Services.Database.get_default ().item_deleted.connect ((item) => {
            if (item.section_id == id) {
                _section_count = update_section_count ();
                section_count_updated ();
            }
        });

        Services.Database.get_default ().item_added.connect ((item) => {
            if (item.section_id == id) {
                _section_count = update_section_count ();
                section_count_updated ();
            }
        });
    }

    public Section.from_json (Json.Node node) {
        id = node.get_object ().get_string_member ("id");
        update_from_json (node);
    }

    public Section.from_import_json (Json.Node node) {
        id = node.get_object ().get_string_member ("id");
        name = node.get_object ().get_string_member ("name");
        archived_at = node.get_object ().get_string_member ("archived_at");
        added_at = node.get_object ().get_string_member ("added_at");
        project_id = node.get_object ().get_string_member ("project_id");
        section_order = (int32) node.get_object ().get_int_member ("section_order");
        collapsed = node.get_object ().get_boolean_member ("collapsed");
        is_deleted = node.get_object ().get_boolean_member ("is_deleted");
        is_archived = node.get_object ().get_boolean_member ("is_archived");
    }

    public void update_from_json (Json.Node node) {
        project_id = node.get_object ().get_string_member ("project_id");
        name = node.get_object ().get_string_member ("name");
        added_at = node.get_object ().get_string_member ("added_at");
        section_order = (int32) node.get_object ().get_int_member ("section_order");
        is_deleted = node.get_object ().get_boolean_member ("is_deleted");
        is_archived = node.get_object ().get_boolean_member ("is_archived");
        collapsed = node.get_object ().get_boolean_member ("collapsed");

        if (!node.get_object ().get_null_member ("archived_at")) {
            archived_at = node.get_object ().get_string_member ("archived_at");
        }
    }

    public void set_project (Objects.Project project) {
        this._project = project;
    }

    public Objects.Item add_item_if_not_exists (Objects.Item new_item, bool insert=true) {
        Objects.Item? return_value = null;
        lock (_items) {
            return_value = get_item (new_item.id);
            if (return_value == null) {
                new_item.set_section (this);
                add_item (new_item);
                Services.Database.get_default ().insert_item (new_item, insert);
                return_value = new_item;
            }
            return return_value;
        }
    }

    public Objects.Item? get_item (string id) {
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
        this._items.add (item);
    }

    public void update (bool cloud=true) {
        if (update_timeout_id != 0) {
            Source.remove (update_timeout_id);
        }

        update_timeout_id = Timeout.add (Constants.UPDATE_TIMEOUT, () => {
            update_timeout_id = 0;

            Services.Database.get_default ().update_section (this);
            if (project.backend_type == BackendType.TODOIST && cloud) {
                Services.Todoist.get_default ().update.begin (this, (obj, res) => {
                    Services.Todoist.get_default ().update.end (res);
                });
            }

            return GLib.Source.REMOVE;
        });
    }

    public override string get_update_json (string uuid, string? temp_id = null) {
        var builder = new Json.Builder ();
        builder.begin_array ();
        builder.begin_object ();

        // Set type
        builder.set_member_name ("type");
        builder.add_string_value (temp_id == null ? "section_update" : "section_add");

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
            }

            builder.set_member_name ("name");
            builder.add_string_value (Util.get_default ().get_encode_text (name));

            builder.end_object ();

        builder.end_object ();
        builder.end_array ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);

        return generator.to_data (null);
    }

    public override string get_add_json (string temp_id, string uuid) {
        return get_update_json (uuid, temp_id);
    }

    public override string to_json () {
        var builder = new Json.Builder ();
        builder.begin_object ();
        
        builder.set_member_name ("id");
        builder.add_string_value (id);

        builder.set_member_name ("project_id");
        if (Services.Database.get_default ().curTempIds_exists (project_id)) {
            builder.add_string_value (Services.Database.get_default ().get_temp_id (project_id));
        } else {
            builder.add_string_value (project_id);
        }
        
        builder.set_member_name ("name");   
        builder.add_string_value (Util.get_default ().get_encode_text (name));

        builder.end_object ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);

        return generator.to_data (null);
    }

    public override string get_move_json (string uuid, string new_project_id) {
        var builder = new Json.Builder ();
        builder.begin_array ();
        builder.begin_object ();

        // Set type
        builder.set_member_name ("type");
        builder.add_string_value ("section_move");

        builder.set_member_name ("uuid");
        builder.add_string_value (uuid);

        builder.set_member_name ("args");
            builder.begin_object ();
            
            builder.set_member_name ("id");
            builder.add_string_value (id);

            builder.set_member_name ("project_id");
            builder.add_string_value (new_project_id);

            builder.end_object ();
        builder.end_object ();
        builder.end_array ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);

        return generator.to_data (null); 
    }

    private int update_section_count () {
        int returned = 0;
        foreach (Objects.Item item in Services.Database.get_default ().get_item_by_baseobject (this)) {
            if (!item.checked) {
                returned++;
            }
        }
        return returned;
    }
}