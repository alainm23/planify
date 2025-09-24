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
    public string description { get; set; default = ""; }
    public bool hidded { get; set; default = false; }

    // Tmp
    public bool activate_name_editable { get; set; default = false; }

    string _short_name;
    public string short_name {
        get {
            _short_name = Util.get_default ().get_short_name (name);
            return _short_name;
        }
    }

    Objects.Project ? _project;
    public Objects.Project project {
        get {
            _project = Services.Store.instance ().get_project (project_id);
            return _project;
        }
    }

    Gee.ArrayList<Objects.Item> _items;
    public Gee.ArrayList<Objects.Item> items {
        get {
            _items = Services.Store.instance ().get_items_by_baseobject (this);
            _items.sort ((a, b) => {
                if (a.child_order > b.child_order) {
                    return 1;
                }
                if (a.child_order == b.child_order) {
                    return 0;
                }

                return -1;
            });
            return _items;
        }
    }

    int ? _section_count = null;
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

    public signal void item_added (Objects.Item item);
    public signal void item_deleted (Objects.Item item);

    construct {
        Services.EventBus.get_default ().checked_toggled.connect ((item) => {
            if (item.section_id == id) {
                update_count ();
            }
        });

        item_deleted.connect ((item) => {
            update_count ();
        });

        item_added.connect ((item) => {
            update_count ();
        });

        Services.EventBus.get_default ().item_moved.connect ((item, old_project_id, old_section_id) => {
            if (item.project_id == project_id) {
                update_count ();
            }
        });

        Services.Store.instance ().item_deleted.connect ((item) => {
            if (item.project_id == project_id) {
                update_count ();
            }
        });

        Services.Store.instance ().item_added.connect ((item) => {
            if (item.project_id == project_id) {
                update_count ();
            }
        });

        Services.Store.instance ().item_moved.connect ((item, old_project_id, old_section_id, old_parent_id) => {
            if (item.project_id == project_id) {
                update_count ();
            }
        });
    }

    public void update_count () {
        _section_count = update_section_count ();
        section_count_updated ();
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

    public Objects.Item add_item_if_not_exists (Objects.Item new_item, bool insert = true) {
        Objects.Item ? return_value = null;
        lock (_items) {
            return_value = get_item (new_item.id);
            if (return_value == null) {
                new_item.set_section (this);
                add_item (new_item);
                Services.Store.instance ().insert_item (new_item, insert);
                return_value = new_item;
            }
            return return_value;
        }
    }

    public Objects.Item ? get_item (string id) {
        Objects.Item ? return_value = null;
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

    public void update (bool cloud = true) {
        if (update_timeout_id != 0) {
            GLib.Source.remove (update_timeout_id);
        }

        update_timeout_id = Timeout.add (Constants.UPDATE_TIMEOUT, () => {
            update_timeout_id = 0;

            Services.Store.instance ().update_section (this);
            if (project.source_type == SourceType.TODOIST && cloud) {
                Services.Todoist.get_default ().update.begin (this, (obj, res) => {
                    Services.Todoist.get_default ().update.end (res);
                });
            }

            return GLib.Source.REMOVE;
        });
    }

    public void update_local () {
        Services.Store.instance ().update_section (this);
    }

    public override string get_update_json (string uuid, string ? temp_id = null) {
        var builder = new Json.Builder ();
        builder.begin_object ();
        builder.set_member_name ("commands");
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
        builder.end_object ();

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
        builder.begin_object ();
        builder.set_member_name ("commands");
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
        builder.end_object ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);

        return generator.to_data (null);
    }

    private int update_section_count () {
        int pending_tasks = 0;
        var items = id == "" ? Services.Store.instance ().get_items_by_baseobject (project) : Services.Store.instance ().get_items_by_baseobject (this);
        foreach (Objects.Item item in items) {
            if (!item.checked && !item.was_archived ()) {
                pending_tasks++;
                pending_tasks += get_subitem_size (item);
            }
        }

        return pending_tasks;
    }

    private int get_subitem_size (Objects.Item item) {
        int size = item.items_uncomplete.size;

        if (size <= 0) {
            return 0;
        }

        int count = size;

        foreach (Objects.Item subitem in item.items_uncomplete) {
            count += get_subitem_size (subitem);
        }

        return count;
    }

    public Objects.Section duplicate () {
        var new_section = new Objects.Section ();
        new_section.name = name;
        new_section.color = color;
        new_section.description = description;
        return new_section;
    }

    public void delete_section (Gtk.Window window) {
        var dialog = new Adw.AlertDialog (
            _ ("Delete Section %s".printf (name)),
            _ ("This can not be undone")
        );

        dialog.add_response ("cancel", _ ("Cancel"));
        dialog.add_response ("delete", _ ("Delete"));
        dialog.set_response_appearance ("delete", Adw.ResponseAppearance.DESTRUCTIVE);
        dialog.present (window);

        dialog.response.connect ((response) => {
            if (response == "delete") {
                loading = true;
                if (project.source_type == SourceType.TODOIST) {
                    Services.Todoist.get_default ().delete.begin (this, (obj, res) => {
                        Services.Todoist.get_default ().delete.end (res);
                        Services.Store.instance ().delete_section (this);
                    });
                } else {
                    Services.Store.instance ().delete_section (this);
                }
            }
        });
    }

    public void archive_section (Gtk.Window window) {
        var dialog = new Adw.AlertDialog (
            _ ("Archive?"),
            _ ("This will archive %s and all its tasks.".printf (name))
        );

        dialog.add_response ("cancel", _ ("Cancel"));
        dialog.add_response ("archive", _ ("Archive"));
        dialog.close_response = "cancel";
        dialog.set_response_appearance ("archive", Adw.ResponseAppearance.DESTRUCTIVE);
        dialog.present (window);

        dialog.response.connect ((response) => {
            if (response == "archive") {
                is_archived = true;
                Services.Store.instance ().archive_section (this);
            }
        });
    }

    public void unarchive_section () {
        is_archived = false;
        Services.Store.instance ().archive_section (this);
    }

    public bool was_archived () {
        if (project.is_archived) {
            return true;
        }

        return is_archived;
    }
}
