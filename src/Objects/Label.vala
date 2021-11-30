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

public class Objects.Label : Objects.BaseObject {
    public string name { get; set; default = ""; }
    public string color { get; set; default = ""; }
    public int item_order { get; set; default = 0; }
    public bool is_deleted { get; set; default = false; }
    public bool is_favorite { get; set; default = false; }
    public bool todoist { get; set; default = false; }

    construct {
        deleted.connect (() => {
            Planner.database.label_deleted (this);
        });
    }

    public Label.from_json (Json.Node node) {
        id = node.get_object ().get_int_member ("id");
        update_from_json (node);
        todoist = true;
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
}
