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

public class Services.Backups : Object {
    private Json.Generator generator;
    private Json.Builder builder;
    private Json.Parser parser;
    private string path;

    private static Backups? _instance;
    public static Backups get_default () {
        if (_instance == null) {
            _instance = new Backups ();
        }

        return _instance;
    }

    Gee.ArrayList<Objects.Backup> _backups = null;
    public Gee.ArrayList<Objects.Backup> backups {
        get {
            if (_backups == null) {
                _backups = get_backups_collection ();
            }

            return _backups;
        }
    }

    public signal void backup_added (Objects.Backup backup);

    construct {
        generator = new Json.Generator ();
        generator.pretty = true;

        builder = new Json.Builder ();
        parser = new Json.Parser ();
        path = Environment.get_user_data_dir () + "/io.github.alainm23.planify/backups";
    }

    public Gee.ArrayList<Objects.Backup> get_backups_collection () {
        Gee.ArrayList<Objects.Backup> return_value = new Gee.ArrayList<Objects.Backup> ();

        File directory = File.new_for_path (path);

        try {
            var children = directory.enumerate_children ("standard::*," + FileAttribute.STANDARD_CONTENT_TYPE + "," + FileAttribute.STANDARD_IS_HIDDEN + "," + FileAttribute.STANDARD_IS_SYMLINK + "," + FileAttribute.STANDARD_SYMLINK_TARGET, GLib.FileQueryInfoFlags.NONE);
            FileInfo file_info = null;

            while ((file_info = children.next_file ()) != null) {
                if (file_info.get_is_hidden ()) {
                    continue;
                }

                if (file_info.get_is_symlink ()) {
                    continue;
                } else if (file_info.get_file_type () == FileType.DIRECTORY) {
                    continue;
                } else {
                    string mime_type = file_info.get_content_type ();
                    string uri = directory.get_uri () + "/" + file_info.get_name ().replace ("#", "%23");

                    if (is_backup_file (mime_type)) {
                        var file = File.new_for_uri (uri);
                        var backup = new Objects.Backup.from_file (file);
                        return_value.add (backup);
                    }
                }
            }

            children.close ();
            children.dispose ();
        } catch (Error err) {
            warning ("%s\n", err.message);
        }

        directory.dispose ();

        return return_value;
    }

    public static bool is_backup_file (string mime_type) {
        return mime_type == "application/json";
    }

    public string export_to_json () {
        builder.begin_object ();

        builder.set_member_name ("version");
        builder.add_string_value (Constants.BACKUP_VERSION);

        builder.set_member_name ("date");
        builder.add_string_value (new GLib.DateTime.now_local ().to_string ());

        // Preferences
        builder.set_member_name ("settings");
        builder.begin_object ();
        
        builder.set_member_name ("default-inbox");
        builder.add_int_value (Services.Settings.get_default ().settings.get_enum ("default-inbox"));

        builder.set_member_name ("inbox-project-id");
        builder.add_string_value (Services.Settings.get_default ().settings.get_string ("inbox-project-id"));

        builder.set_member_name ("local-inbox-project-id");
        builder.add_string_value (Services.Settings.get_default ().settings.get_string ("local-inbox-project-id"));

        builder.set_member_name ("todoist-inbox-project-id");
        builder.add_string_value (Services.Settings.get_default ().settings.get_string ("todoist-inbox-project-id"));

        builder.set_member_name ("todoist-access-token");
        builder.add_string_value (Services.Settings.get_default ().settings.get_string ("todoist-access-token"));

        builder.set_member_name ("todoist-sync-token");
        builder.add_string_value (Services.Settings.get_default ().settings.get_string ("todoist-sync-token"));

        builder.set_member_name ("todoist-user-name");
        builder.add_string_value (Services.Settings.get_default ().settings.get_string ("todoist-user-name"));

        builder.set_member_name ("todoist-user-email");
        builder.add_string_value (Services.Settings.get_default ().settings.get_string ("todoist-user-email"));

        builder.set_member_name ("todoist-user-image-id");
        builder.add_string_value (Services.Settings.get_default ().settings.get_string ("todoist-user-image-id"));

        builder.set_member_name ("todoist-user-avatar");
        builder.add_string_value (Services.Settings.get_default ().settings.get_string ("todoist-user-avatar"));

        builder.set_member_name ("todoist-user-is-premium");
        builder.add_boolean_value (Services.Settings.get_default ().settings.get_boolean ("todoist-user-is-premium"));

        builder.end_object ();

        // Labels
        builder.set_member_name ("labels");
        builder.begin_array ();

        foreach (Objects.Label label in Services.Database.get_default ().labels) {
            builder.begin_object ();
            
            builder.set_member_name ("id");
            builder.add_string_value (label.id);

            builder.set_member_name ("name");
            builder.add_string_value (label.name);

            builder.set_member_name ("color");
            builder.add_string_value (label.color);

            builder.set_member_name ("backend_type");
            builder.add_string_value (label.backend_type.to_string ());

            builder.set_member_name ("is_deleted");
            builder.add_boolean_value (label.is_deleted);

            builder.set_member_name ("is_favorite");
            builder.add_boolean_value (label.is_favorite);

            builder.end_object ();
        }

        builder.end_array ();

        // Projects
        builder.set_member_name ("projects");
        builder.begin_array ();
        foreach (Objects.Project project in Services.Database.get_default ().projects) {
            builder.begin_object ();

            builder.set_member_name ("id");
            builder.add_string_value (project.id);
            
            builder.set_member_name ("name");
            builder.add_string_value (project.name);

            builder.set_member_name ("color");
            builder.add_string_value (project.color);

            builder.set_member_name ("backend_type");
            builder.add_string_value (project.backend_type.to_string ());

            builder.set_member_name ("inbox_project");
            builder.add_boolean_value (project.inbox_project);

            builder.set_member_name ("team_inbox");
            builder.add_boolean_value (project.team_inbox);

            builder.set_member_name ("child_order");
            builder.add_int_value (project.child_order);

            builder.set_member_name ("is_deleted");
            builder.add_boolean_value (project.is_deleted);

            builder.set_member_name ("is_archived");
            builder.add_boolean_value (project.is_archived);

            builder.set_member_name ("is_favorite");
            builder.add_boolean_value (project.is_favorite);

            builder.set_member_name ("shared");
            builder.add_boolean_value (project.shared);

            builder.set_member_name ("view_style");
            builder.add_string_value (project.view_style.to_string ());

            builder.set_member_name ("sort_order");
            builder.add_int_value (project.sort_order);

            builder.set_member_name ("parent_id");
            builder.add_string_value (project.parent_id);

            builder.set_member_name ("collapsed");
            builder.add_boolean_value (project.collapsed);

            builder.set_member_name ("icon_style");
            builder.add_string_value (project.icon_style.to_string ());

            builder.set_member_name ("emoji");
            builder.add_string_value (project.emoji);

            builder.set_member_name ("show_completed");
            builder.add_boolean_value (project.show_completed);

            builder.set_member_name ("description");
            builder.add_string_value (project.description);

            builder.set_member_name ("due_date");
            builder.add_string_value (project.due_date);

            builder.end_object ();
        }
        builder.end_array ();

        // Sections
        builder.set_member_name ("sections");
        builder.begin_array ();
        foreach (Objects.Section section in Services.Database.get_default ().sections) {
            builder.begin_object ();

            builder.set_member_name ("id");
            builder.add_string_value (section.id);

            builder.set_member_name ("name");
            builder.add_string_value (section.name);

            builder.set_member_name ("archived_at");
            builder.add_string_value (section.archived_at);

            builder.set_member_name ("added_at");
            builder.add_string_value (section.added_at);

            builder.set_member_name ("project_id");
            builder.add_string_value (section.project_id);

            builder.set_member_name ("section_order");
            builder.add_int_value (section.section_order);

            builder.set_member_name ("collapsed");
            builder.add_boolean_value (section.collapsed);

            builder.set_member_name ("is_deleted");
            builder.add_boolean_value (section.is_deleted);

            builder.set_member_name ("is_archived");
            builder.add_boolean_value (section.is_archived);

            builder.end_object ();
        }
        builder.end_array ();

        // Items
        builder.set_member_name ("items");
        builder.begin_array ();
        foreach (Objects.Item item in Services.Database.get_default ().items) {
            builder.begin_object ();

            builder.set_member_name ("id");
            builder.add_string_value (item.id);

            builder.set_member_name ("content");
            builder.add_string_value (item.content);

            builder.set_member_name ("description");
            builder.add_string_value (item.description);

            builder.set_member_name ("due");
            builder.add_string_value (item.due.to_string ());

            builder.set_member_name ("added_at");
            builder.add_string_value (item.added_at);

            builder.set_member_name ("completed_at");
            builder.add_string_value (item.completed_at);

            builder.set_member_name ("updated_at");
            builder.add_string_value (item.updated_at);

            builder.set_member_name ("section_id");
            builder.add_string_value (item.section_id);

            builder.set_member_name ("project_id");
            builder.add_string_value (item.project_id);

            builder.set_member_name ("parent_id");
            builder.add_string_value (item.parent_id);

            builder.set_member_name ("priority");
            builder.add_int_value (item.priority);

            builder.set_member_name ("child_order");
            builder.add_int_value (item.child_order);

            builder.set_member_name ("checked");
            builder.add_boolean_value (item.checked);

            builder.set_member_name ("is_deleted");
            builder.add_boolean_value (item.is_deleted);
            
            builder.set_member_name ("day_order");
            builder.add_int_value (item.day_order);

            builder.set_member_name ("collapsed");
            builder.add_boolean_value (item.collapsed);

            builder.set_member_name ("pinned");
            builder.add_boolean_value (item.pinned);

            builder.set_member_name ("labels");
            builder.begin_array ();
            foreach (Objects.Label label in item.labels) {
                builder.add_string_value (label.name);
            }
            builder.end_array ();
        builder.end_object ();

            builder.end_object ();
        }
        builder.end_array ();

        builder.end_object ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);

        return generator.to_data (null);
    }

    public void create_backup () {
        var datetime = new GLib.DateTime.now_local ();
        var file_name = "Planify backup %s.json".printf (datetime.format ("%c"));
        var path = path + "/" + file_name;

        var file = File.new_for_path (path);

        try {
            var stream = file.create (FileCreateFlags.NONE, null);
            stream.write (export_to_json ().data, null);
            stream.close (null);
    
            var file_path = File.new_for_path (path);
            if (file_path.query_exists ()) {
                var backup = new Objects.Backup.from_file (file_path);
                backup_added (backup);
            }
        } catch (Error e) {
            debug ("Error: %s\n", e.message);
        }
    }

    public void save_file_as (Objects.Backup backup) {
        var dialog = new Gtk.FileDialog ();
        dialog.initial_name = "Planify backup %s.json".printf (backup.title);
        add_filters (dialog);

        dialog.save.begin (Planify._instance.main_window, null, (obj, res) => {
            try {
                var file = dialog.save.end (res);

                if (!file.get_basename ().down ().has_suffix (".json")) {
                    file = File.new_for_path (file.get_path () + ".json");
                }

                var source_file = File.new_for_path (backup.path);
                if (source_file.query_exists ()) {
                    source_file.copy (file, GLib.FileCopyFlags.OVERWRITE);
                } else {
                    debug ("Error during save backup");
                }
            } catch (Error e) {
                debug ("Error during save backup: %s".printf (e.message));
            }
        });
    }

    public async GLib.File? import_backup () {
        var dialog = new Gtk.FileDialog ();
        add_filters (dialog);

        try {
            var file = yield dialog.open (Planify._instance.main_window, null);
            return file;
        } catch (Error e) {
            debug ("Error during import backup: %s".printf (e.message));
        }

        return null;
    }

    public void patch_backup (Objects.Backup backup) {
        Services.Settings.get_default ().reset_settings ();

        Services.Settings.get_default ().settings.set_enum ("default-inbox", backup.default_inbox);
        Services.Settings.get_default ().settings.set_string ("inbox-project-id", backup.inbox_project_id);
        Services.Settings.get_default ().settings.set_string ("local-inbox-project-id", backup.local_inbox_project_id);
        
        if (backup.todoist_backend) {
            Services.Settings.get_default ().settings.set_string ("todoist-inbox-project-id", backup.todoist_inbox_project_id);
            Services.Settings.get_default ().settings.set_string ("todoist-sync-token", backup.todoist_sync_token);
            Services.Settings.get_default ().settings.set_string ("todoist-access-token", backup.todoist_access_token);
            Services.Settings.get_default ().settings.set_string ("todoist-user-image-id", backup.todoist_user_image_id);
            Services.Settings.get_default ().settings.set_string ("todoist-user-avatar", backup.todoist_user_avatar);
            Services.Settings.get_default ().settings.set_string ("todoist-user-name", backup.todoist_user_name);
            Services.Settings.get_default ().settings.set_string ("todoist-user-email", backup.todoist_user_email);
            Services.Settings.get_default ().settings.set_string ("todoist-last-sync", new GLib.DateTime.now_local ().to_string ());
            Services.Settings.get_default ().settings.set_boolean ("todoist-user-is-premium", backup.todoist_user_is_premium);
            Services.Settings.get_default ().settings.set_boolean ("todoist-sync-server", true);
        }

        // Clear Database
        Services.Database.get_default ().clear_database ();
        Services.Database.get_default ().init_database ();

        // Create Labels
        foreach (Objects.Label item in backup.labels) {
            Services.Database.get_default ().insert_label (item);
        }

        // Create Projects
        foreach (Objects.Project item in backup.projects) {
            if (item.parent_id != "") {
                Objects.Project? project = Services.Database.get_default ().get_project (item.parent_id);
                if (project != null) {
                    project.add_subproject_if_not_exists (item);
                }
            } else {
                Services.Database.get_default ().insert_project (item);
            }
        }

        // Create Sections
        foreach (Objects.Section item in backup.sections) {
            Objects.Project? project = Services.Database.get_default ().get_project (item.project_id);
            if (project != null) {
                project.add_section_if_not_exists (item);
            }
        }

        // Create Items
        foreach (Objects.Item item in backup.items) {
            if (item.has_parent ()) {
                Objects.Item? _item = Services.Database.get_default ().get_item (item.parent_id);
                if (_item != null) {
                    _item.add_item_if_not_exists (item);
                }
            } else {
                if (item.section_id != "") {
                    Objects.Section? section = Services.Database.get_default ().get_section (item.section_id);
                    if (section != null) {
                        section.add_item_if_not_exists (item);
                    }
                } else {
                    Objects.Project? project = Services.Database.get_default ().get_project (item.project_id);
                    if (project != null) {
                        project.add_item_if_not_exists (item);
                    }
                }
            }
        }

        if (backup.todoist_user_avatar != null) {
            Util.get_default ().download_profile_image (
                "todoist-user", backup.todoist_user_avatar
                );
        }

        show_message ();
    }

    private void show_message () {
        var dialog = new Adw.MessageDialog (Planify._instance.main_window,
            _("Backup Successfully Imported"),
            _("Process completed, you need to start Planify again")
        );

        dialog.modal = true;
        dialog.add_response ("ok", _("Ok"));
        dialog.show ();

        dialog.response.connect ((response) => {
            Planify._instance.main_window.destroy ();
        });
    }

    private void add_filters (Gtk.FileDialog file_dialog) {
        Gtk.FileFilter filter = new Gtk.FileFilter ();
        filter.add_pattern ("*.json");
        filter.set_filter_name (_("Planify Backup Files"));
        file_dialog.default_filter = filter;
    }
}
