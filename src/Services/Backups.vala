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

    private static Backups ? _instance;
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
        return Services.Backup.get_default ().export_to_json ();
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
                _backups.add (backup);
            }
        } catch (Error e) {
            debug ("Error: %s\n", e.message);
        }
    }

    public void delete_backup (Objects.Backup backup) {
        var dialog = new Adw.AlertDialog (
            _("Delete Backup"),
            _("This can not be undone")
        );

        dialog.add_response ("cancel", _("Cancel"));
        dialog.add_response ("delete", _("Delete"));
        dialog.set_response_appearance ("delete", Adw.ResponseAppearance.DESTRUCTIVE);
        dialog.present ((Gtk.Window) Planify.instance.main_window);

        dialog.response.connect ((response) => {
            if (response == "delete") {
                File db_file = File.new_for_path (backup.path);
                if (db_file.query_exists ()) {
                    try {
                        if (db_file.delete ()) {
                            backup.deleted ();
                            _backups.remove (backup);
                        }
                    } catch (Error err) {
                        warning (err.message);
                    }
                }
            }
        });
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

    public async GLib.File ? choose_backup_file () {
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
        Services.Settings.get_default ().settings.set_string ("local-inbox-project-id", backup.local_inbox_project_id);

        // Clear Database
        Services.Database.get_default ().clear_database ();
        Services.Database.get_default ().init_database ();
        Util.get_default ().create_local_source ();

        // Create Sources
        foreach (Objects.Source source in backup.sources) {
            Services.Store.instance ().insert_source (source);
        }

        // Create Labels
        foreach (Objects.Label item in backup.labels) {
            Services.Store.instance ().insert_label (item);
        }

        // Create Projects
        foreach (Objects.Project item in backup.projects) {
            if (item.parent_id != "") {
                Objects.Project ? project = Services.Store.instance ().get_project (item.parent_id);
                if (project != null) {
                    project.add_subproject_if_not_exists (item);
                }
            } else {
                Services.Store.instance ().insert_project (item);
            }
        }

        // Create Sections
        foreach (Objects.Section item in backup.sections) {
            Objects.Project ? project = Services.Store.instance ().get_project (item.project_id);
            if (project != null) {
                project.add_section_if_not_exists (item);
            }
        }

        // Create Items
        foreach (Objects.Item item in backup.items) {
            if (item.has_parent) {
                Objects.Item ? _item = Services.Store.instance ().get_item (item.parent_id);
                if (_item != null) {
                    _item.add_item_if_not_exists (item);
                }
            } else {
                if (item.section_id != "") {
                    Objects.Section ? section = Services.Store.instance ().get_section (item.section_id);
                    if (section != null) {
                        section.add_item_if_not_exists (item);
                    }
                } else {
                    Objects.Project ? project = Services.Store.instance ().get_project (item.project_id);
                    if (project != null) {
                        project.add_item_if_not_exists (item);
                    }
                }
            }
        }

        show_message ();
    }

    private void show_message () {
        var dialog = new Adw.AlertDialog (
            _("Backup Successfully Imported"),
            _("Planify will restart to apply the changes")
        );

        dialog.add_response ("ok", _("Restart Now"));
        dialog.present (Planify._instance.main_window);

        dialog.response.connect ((response) => {
            restart_application ();
        });
    }

    private void restart_application () {
        Planify._instance.recreate_main_window ();
    }

    private void add_filters (Gtk.FileDialog file_dialog) {
        var filter = new Gtk.FileFilter ();
        filter.set_filter_name (_("Planify Backup Files"));
        filter.add_pattern ("*.json");
        
        var filters = new ListStore (typeof (Gtk.FileFilter));
        filters.append (filter);
        file_dialog.filters = filters;
        file_dialog.default_filter = filter;
    }
}
