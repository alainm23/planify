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

public class Objects.Label : GLib.Object {
    public int64 id { get; set; default = 0; }
    public int64 item_label_id { get; set; default = 0; }
    public int64 project_id { get; set; default = 0; }
    public string name { get; set; default = ""; }
    public int color { get; set; default = GLib.Random.int_range (39, 50); }
    public int item_order { get; set; default = 0; }
    public int is_deleted { get; set; default = 0; }
    public int is_favorite { get; set; default = 0; }
    public int is_todoist { get; set; default = 0; }

    public string _id_string;
    public string id_string {
        get {
            _id_string = id.to_string ();
            return _id_string;
        }
    }

    public signal void deleted ();
    public signal void updated ();

    construct {
        deleted.connect (() => {
            Planner.database.label_deleted (this);
        });
    }

    public Label.from_json (Json.Node node) {
        id = node.get_object ().get_int_member ("id");
        update_from_json (node);
        is_todoist = 1;
    }

    public void update_from_json (Json.Node node) {
        name = node.get_object ().get_string_member ("name");

        if (!node.get_object ().get_null_member ("color")) {
            color = (int32) node.get_object ().get_int_member ("color");
        }
        
        if (!node.get_object ().get_null_member ("is_favorite")) {
            is_favorite = (int32) node.get_object ().get_int_member ("is_favorite");
        }

        if (!node.get_object ().get_null_member ("is_deleted")) {
            is_deleted = (int32) node.get_object ().get_int_member ("is_deleted");
        }
        
        if (!node.get_object ().get_null_member ("item_order")) {
            item_order = (int32) node.get_object ().get_int_member ("item_order");
        }
    }
}
