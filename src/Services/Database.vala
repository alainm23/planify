/*
* Copyright © 2019 Alain M. (https://github.com/alainm23/planner)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
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
* Authored by: Alain M. <alain23@protonmail.com>
*/

public class Services.Database : GLib.Object {
    private Json.Node node;
    private string db_path;

    // Project events
    public signal void project_added (Objects.Project project);
    public signal void project_updated (Objects.Project project);
    public signal void project_deleted (int64 id);
    
    public signal void start_create_projects ();
    
    // User
    public signal void user_added (Objects.User user);

    public Database () {
        var parser = new Json.Parser ();
        db_path = Environment.get_home_dir () + "/.local/share/com.github.alainm23.planner/database.json";

        if (File.new_for_path (db_path).query_exists () == false) {
            generate_db ();
        } else {
            try {
                parser.load_from_file (db_path);
                node = parser.get_root ();
            } catch (Error e) {
                stderr.printf ("Failed to connect to database service.\n");
            }
        }
    }

    private void generate_db () {
        var builder = new Json.Builder ();
        builder.begin_object ();

            builder.set_member_name ("user");
            builder.add_null_value ();

            builder.set_member_name ("projects");
            builder.begin_array ();
            builder.end_array ();

            builder.set_member_name ("items");
            builder.begin_array ();
            builder.end_array ();

        builder.end_object ();

        var generator = new Json.Generator ();
        generator.set_root (builder.get_root ());
        
        node = builder.get_root ();
        try {
            generator.to_file (db_path);
        } catch (Error e) {
            print ("Error: %s\n", e.message);
        }
    }

    public bool user_exists () {
        if (node.get_object ().get_object_member ("user") == null) {
            return false;
        }

        return true;
    }

    public bool create_user (Objects.User user) {
        var object = new Json.Object ();

        object.set_int_member ("id", user.id);
        object.set_int_member ("inbox_project", user.inbox_project);
        object.set_boolean_member ("is_todoist", user.is_todoist);
        object.set_boolean_member ("is_premium", user.is_premium);
        object.set_string_member ("full_name", user.full_name);
        object.set_string_member ("email", user.email);
        object.set_string_member ("todoist_token", user.todoist_token);
        object.set_string_member ("github_token", "");
        object.set_string_member ("join_date", user.join_date);
        object.set_string_member ("avatar", user.avatar);
        object.set_string_member ("sync_token", user.sync_token);

        node.get_object ().set_object_member ("user", object);

        Json.Generator generator = new Json.Generator ();
	    generator.set_root (node);

        try {
            if (generator.to_file (db_path)) {
                user_added (user);
            }
            
            return generator.to_file (db_path);
        } catch (Error e) {
            print ("Error: %s\n", e.message);
            return false;
        }
    }

    public Objects.User get_user () {
        var object = node.get_object ().get_object_member ("user");
        var user = new Objects.User ();
        
        user.id = object.get_int_member ("id");
        user.inbox_project = object.get_int_member ("inbox_project");
        user.is_todoist = object.get_boolean_member ("is_todoist");
        user.is_premium = object.get_boolean_member ("is_premium");
        user.full_name = object.get_string_member ("full_name");
        user.email = object.get_string_member ("email");
        user.todoist_token = object.get_string_member ("todoist_token");
        user.github_token = object.get_string_member ("github_token");
        user.sync_token = object.get_string_member ("sync_token");
        user.avatar = object.get_string_member ("avatar");
        user.join_date = object.get_string_member ("join_date");

        return user;        
    }

    public bool add_project (Objects.Project project) {
        var object = new Json.Object ();

        object.set_int_member ("id", project.id);
        object.set_string_member ("name", project.name);
        object.set_string_member ("note", project.note);
        object.set_int_member ("color", project.color);
        object.set_string_member ("due", project.due);
        object.set_boolean_member ("is_todoist", project.is_todoist);
        object.set_boolean_member ("inbox_project", project.inbox_project);
        object.set_boolean_member ("team_inbox", project.team_inbox);
        object.set_string_member ("note", project.note);
        object.set_int_member ("child_order", (int32) project.child_order);
        object.set_int_member ("is_deleted", (int32) project.is_deleted);
        object.set_int_member ("is_archived", (int32) project.is_archived);
        object.set_int_member ("is_favorite", (int32) project.is_favorite);

        node.get_object ().get_array_member ("projects").add_object_element (object);

        Json.Generator generator = new Json.Generator ();
	    generator.set_root (node);

        try {
            if (generator.to_file (db_path)) {
                project_added (project);
            }
            
            return generator.to_file (db_path);
        } catch (Error e) {
            print ("Error: %s\n", e.message);
            return false;
        }
    }

    public Gee.ArrayList<Objects.Project?> get_all_projects () {
        unowned Json.Array array = node.get_object ().get_array_member ("projects");
        
        var all = new Gee.ArrayList<Objects.Project?> ();

        foreach (unowned Json.Node item in array.get_elements ()) {
            var object = item.get_object ();

            var project = new Objects.Project ();

            project.id = object.get_int_member ("id");
            project.name = object.get_string_member ("name");
            project.note = object.get_string_member ("note");
            project.color = (int32) object.get_int_member ("color");
            project.due = object.get_string_member ("due");
            project.is_todoist = object.get_boolean_member ("is_todoist");
            project.team_inbox = object.get_boolean_member ("team_inbox");
            project.inbox_project = object.get_boolean_member ("inbox_project");
            project.child_order = (int32) object.get_int_member ("child_order");
            project.is_deleted = (int32) object.get_int_member ("is_deleted");
            project.is_archived = (int32) object.get_int_member ("is_archived");
            project.is_favorite = (int32) object.get_int_member ("is_favorite");

            all.add (project);
        }

        return all;
    }

    public bool update_project (Objects.Project project) {
        unowned Json.Array array = node.get_object ().get_array_member ("projects");

        foreach (unowned Json.Node item in array.get_elements ()) {
            var object = item.get_object ();

            if (object.get_int_member ("id") == project.id) {
                object.set_string_member ("name", project.name);
                object.set_int_member ("color", project.color);
                object.set_int_member ("is_favorite", project.is_favorite);

                Json.Generator generator = new Json.Generator ();
                generator.set_root (node);

                try {
                    if (generator.to_file (db_path)) {
                        project_updated (project);
                    }
                    
                    return generator.to_file (db_path);
                } catch (Error e) {
                    print ("Error: %s\n", e.message);
                    return false;
                }
            }
        }

        return false;
    }

    public bool delete_project (int64 id) {
        int index = 0;
        unowned Json.Array array = node.get_object ().get_array_member ("projects");

        foreach (unowned Json.Node item in array.get_elements ()) {
            var object = item.get_object ();

            if (object.get_int_member ("id") == id) {
                array.remove_element (index);

                Json.Generator generator = new Json.Generator ();
                generator.set_root (node);

                try {
                    if (generator.to_file (db_path)) {
                        project_deleted (id);
                    }
                    
                    return generator.to_file (db_path);
                } catch (Error e) {
                    print ("Error: %s\n", e.message);
                    return false;
                }
            }

            index = index + 1;
        }

        return false;
    }
}