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

public class Objects.BaseObject : GLib.Object {
    public string id { get; set; default = ""; }
    public string name { get; set; default = ""; }
    public string keywords { get; set; default = ""; }
    public signal void deleted ();
    public signal void updated ();

    public uint update_timeout_id { get; set; default = Constants.INACTIVE; }

    string _id_string;
    public string id_string {
        get {
            _id_string = id.to_string ();
            return _id_string;
        }
    }

    public string type_delete {
        get {
            if (this is Objects.Item) {
                return "item_delete";
            } else if (this is Objects.Project) {
                return "project_delete";
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
            } else {
                return "";
            }
        }
    }

    public ObjectType object_type {
        get {
            if (this is Objects.Project) {
                return ObjectType.PROJECT;
            } else if (this is Objects.Item) {
                return ObjectType.ITEM;
            } else {
                return ObjectType.FILTER;
            }
        }
    }

    public string object_type_string {
        get {
            if (this is Objects.Project) {
                return "project";
            } else if (this is Objects.Item) {
                return "item";
            } else {
                return "filter";
            }
        }
    }

    public string table_name {
        get {
            if (this is Objects.Item) {
                return "Items";
            } else if (this is Objects.Project) {
                return "Projects";
            } else {
                return "";
            }
        }
    }

    public string column_order_name {
        get {
            if (this is Objects.Item) {
                return "child_order";
            } else if (this is Objects.Project) {
                return "child_order";
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

    public virtual string get_move_json (string uuid, int64 new_project_id) {
        return "";
    }

    public virtual string to_json () {
        return "";
    }
}