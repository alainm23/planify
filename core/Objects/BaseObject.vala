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

public class Objects.BaseObject : GLib.Object {
    public string id { get; set; default = ""; }
    public string name { get; set; default = ""; }
    public string keywords { get; set; default = ""; }
    public string icon_name { get; set; default = ""; }
    public signal void deleted ();
    public signal void updated ();

    public uint update_timeout_id { get; set; default = 0; }

    public Gee.HashMap <string, Objects.Filters.FilterItem> filters = new Gee.HashMap <string, Objects.Filters.FilterItem> ();
    public signal void filter_added (Objects.Filters.FilterItem filters);
    public signal void filter_removed (Objects.Filters.FilterItem filters);
    public signal void filter_updated (Objects.Filters.FilterItem filters);

    string _id_string;
    public string id_string {
        get {
            _id_string = id.to_string ();
            return _id_string;
        }
    }

    public string view_id { get; set; default = ""; }

    public string type_delete {
        get {
            if (this is Objects.Item) {
                return "item_delete";
            } else if (this is Objects.Project) {
                return "project_delete";
            } else if (this is Objects.Section) {
                return "section_delete";
            } else if (this is Objects.Label) {
                return "label_delete";
            } else if (this is Objects.Reminder) {
                return "reminder_delete";
            } else {
                return "";
            }
        }
    }

    public string type_add {
        get {
            if (this is Objects.Item) {
                return "item_add";
            } else if (this is Objects.Project) {
                return "project_add";
            } else if (this is Objects.Section) {
                return "section_add";
            } else if (this is Objects.Label) {
                return "label_add";
            } else {
                return "";
            }
        }
    }

    public string type_update {
        get {
            if (this is Objects.Item) {
                return "item_update";
            } else if (this is Objects.Project) {
                return "project_update";
            } else if (this is Objects.Section) {
                return "section_update";
            } else if (this is Objects.Label) {
                return "label_update";
            } else {
                return "";
            }
        }
    }

    public ObjectType object_type {
        get {
            if (this is Objects.Project) {
                return ObjectType.PROJECT;
            } else if (this is Objects.Section) {
                return ObjectType.SECTION;
            } else if (this is Objects.Item) {
                return ObjectType.ITEM;
            } else if (this is Objects.Label) {
                return ObjectType.LABEL;
            } else {
                return ObjectType.FILTER;
            }
        }
    }

    public string object_type_string {
        get {
            if (this is Objects.Project) {
                return "project";
            } else if (this is Objects.Section) {
                return "section";
            } else if (this is Objects.Item) {
                return "item";
            } else if (this is Objects.Label) {
                return "label";
            } else {
                return "filter";
            }
        }
    }
    
    public string table_name {
        get {
            if (this is Objects.Item) {
                return "Items";
            } else if (this is Objects.Section) {
                return "Sections";
            } else if (this is Objects.Project) {
                return "Projects";
            } else if (this is Objects.Label) {
                return "Labels";
            } else {
                return "";
            }
        }
    }

    public string column_order_name {
        get {
            if (this is Objects.Item) {
                return "child_order";
            } else if (this is Objects.Section) {
                return "section_order";
            } else if (this is Objects.Project) {
                return "child_order";
            } else if (this is Objects.Label) {
                return "item_order";
            } else {
                return "";
            }
        }
    }

    public virtual string get_update_json (string uuid, string? temp_id = null) {
        return "";
    }

    public virtual string get_add_json (string temp_id, string uuid) {
        return "";
    }

    public virtual string get_move_json (string uuid, string new_project_id) {
        return "";
    }

    public virtual string to_json () {
        return "";
    }
    
    public void add_filter (Objects.Filters.FilterItem filter) {
        if (!filters.has_key (filter.id)) {
            filters[filter.id] = filter;
            filter_added (filters[filter.id]);
        }
    }

    public void remove_filter (Objects.Filters.FilterItem filter) {
        if (filters.has_key (filter.id)) {
            filters.unset (filter.id);
            filter_removed (filter);
        }
    }

    public void update_filter (Objects.Filters.FilterItem filter) {
        if (filters.has_key (filter.id)) {
            filters[filter.id] = filter;
            filter_updated (filter);
        }
    }

    public Objects.Filters.FilterItem? get_filter (string id) {
        if (filters.has_key (id)) {
            return filters.get (id);
        }

        return null;
    }
}
