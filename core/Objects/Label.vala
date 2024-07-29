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

public class Objects.Label : Objects.BaseObject {
    public string color { get; set; default = ""; }
    public int item_order { get; set; default = 0; }
    public bool is_deleted { get; set; default = false; }
    public bool is_favorite { get; set; default = false; }
    public SourceType backend_type { get; set; default = SourceType.NONE; }
    public string source_id { get; set; default = SourceType.LOCAL.to_string (); }

    Objects.Source? _source;
    public Objects.Source source {
        get {
            _source = Services.Store.instance ().get_source (source_id);
            return _source;
        }
    }
    
    public SourceType source_type {
        get {
            return source.source_type;
        }
    }

    int? _label_count = null;
    public int label_count {
        get {
            if (_label_count == null) {
                _label_count = update_label_count ();
            }

            return _label_count;
        }

        set {
            _label_count = value;
        }
    }

    string _short_name;
    public string short_name {
        get {
            _short_name = Util.get_default ().get_short_name (name);
            return _short_name;
        }
    }

    public signal void label_count_updated ();

    construct {
        Services.Store.instance ().item_added.connect ((item) => {
            if (item.get_label (id) != null) {
                _label_count = update_label_count ();
                label_count_updated ();
            }
        });

        Services.Store.instance ().item_deleted.connect ((item) => {
            if (item.get_label (id) != null) {
                _label_count = update_label_count ();
                label_count_updated ();
            }
        });

        Services.Store.instance ().item_updated.connect ((item) => {
            if (item.get_label (id) != null) {
                _label_count = update_label_count ();
                label_count_updated ();
            }
        });

        Services.Store.instance ().item_label_added.connect ((label) => {
            if (label.id == id) {
                _label_count = update_label_count ();
                label_count_updated ();   
            }
        });

        Services.Store.instance ().item_label_deleted.connect ((label) => {
            if (label.id == id) {
                _label_count = update_label_count ();
                label_count_updated ();   
            }
        });
    }

    private int update_label_count () {
        return Services.Store.instance ().get_items_by_label (this, false).size;
    }

    public Label.from_json (Json.Node node) {
        id = node.get_object ().get_string_member ("id");
        update_from_json (node);
        backend_type = SourceType.TODOIST;
    }

    public Label.from_import_json (Json.Node node) {
        id = node.get_object ().get_string_member ("id");
        name = node.get_object ().get_string_member ("name");
        color = node.get_object ().get_string_member ("color");
        backend_type = SourceType.parse (node.get_object ().get_string_member ("backend_type"));
        is_deleted = node.get_object ().get_boolean_member ("is_deleted");
        is_favorite = node.get_object ().get_boolean_member ("is_favorite");
        source_id = backend_type.to_string ();

        if (node.get_object ().has_member ("source_id")) {
            source_id = node.get_object ().get_string_member ("source_id");
        }
    }

    public void update_from_json (Json.Node node) {
        name = node.get_object ().get_string_member ("name");

        if (!node.get_object ().get_null_member ("color")) {
            color = node.get_object ().get_string_member ("color");
        }
        
        if (!node.get_object ().get_null_member ("is_favorite")) {
            is_favorite = node.get_object ().get_boolean_member ("is_favorite");
        }

        if (!node.get_object ().get_null_member ("is_deleted")) {
            is_deleted = node.get_object ().get_boolean_member ("is_deleted");
        }
        
        if (!node.get_object ().get_null_member ("item_order")) {
            item_order = (int32) node.get_object ().get_int_member ("item_order");
        }
    }

    public override string get_add_json (string temp_id, string uuid) {
        return get_update_json (uuid, temp_id);
    }
    public override string get_update_json (string uuid, string? temp_id = null) {
        var builder = new Json.Builder ();
        builder.begin_object ();
            builder.set_member_name ("commands");
            builder.begin_array ();
                builder.begin_object ();

                // Set type
                builder.set_member_name ("type");
                builder.add_string_value (temp_id == null ? "label_update" : "label_add");

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

                    builder.set_member_name ("name");
                    builder.add_string_value (name);

                    builder.set_member_name ("color");
                    builder.add_string_value (color);

                    builder.set_member_name ("item_order");
                    builder.add_int_value (item_order);

                    builder.set_member_name ("is_favorite");
                    builder.add_boolean_value (is_favorite);

                    builder.end_object ();
                builder.end_object ();
                builder.end_array ();
        builder.end_object ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);

        return generator.to_data (null);
    }
}
