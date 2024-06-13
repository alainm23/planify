/*
* Copyright © 2024 Alain M. (https://github.com/alainm23/planify)
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

public class Objects.ObjectEvent : GLib.Object {
    public int64 id { get; set; default = 0; }
    public string event_date { get; set; default = ""; }
    public string event_type { get; set; default = ""; }
    public string extra_data { get; set; default = ""; }
    public string object_id { get; set; default = ""; }
    public string object_type { get; set; default = ""; }
    public string parent_item_id { get; set; default = ""; }
    public string parent_project_id { get; set; default = ""; }

    public static Objects.ObjectEvent for_add_item (Objects.Item item) {
        Objects.ObjectEvent return_value = new Objects.ObjectEvent ();

        return_value.event_date = new GLib.DateTime.now_local ().to_string ();
        return_value.event_type = "added";
        return_value.object_type = "item";
        return_value.object_id = item.id;
        return_value.parent_project_id = item.project_id;
        return_value.extra_data = generate_extradata ("content", item.content, item.project.name, item.project.color);
        
        return return_value;
    }

    public static Objects.ObjectEvent for_update_item (Objects.Item item, string key) {
        Objects.ObjectEvent return_value = new Objects.ObjectEvent ();

        return_value.event_date = new GLib.DateTime.now_local ().to_string ();
        return_value.event_type = "updated";
        return_value.object_type = "item";
        return_value.object_id = item.id;
        return_value.parent_project_id = item.project_id;
        return_value.extra_data = generate_extradata ("content", item.content, item.project.name, item.project.color);
        
        return return_value;
    }

    public static string generate_extradata (string key, string value, string parent_project_name, string parent_project_color) {
        var builder = new Json.Builder ();

        builder.begin_object ();
        
        builder.set_member_name ("client");
        builder.add_string_value ("Planify");

        builder.set_member_name (key);
        builder.add_string_value (value);

        builder.set_member_name ("parent_project_color");
        builder.add_string_value (parent_project_color);

        builder.set_member_name ("parent_project_name");
        builder.add_string_value (parent_project_name);

        builder.end_object ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);

        return generator.to_data (null);
    }

    public static string _generate_extradata (Objects.Item item, string key) {
        var builder = new Json.Builder ();

        builder.begin_object ();
        
        builder.set_member_name ("client");
        builder.add_string_value ("Planify");

        builder.set_member_name ("content");
        builder.add_string_value (item.content);

        builder.set_member_name ("parent_project_color");
        builder.add_string_value (item.project.color);

        builder.set_member_name ("parent_project_name");
        builder.add_string_value (item.project.name);

        builder.end_object ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);

        return generator.to_data (null);
    }
}