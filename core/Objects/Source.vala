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

public class Objects.Source : Objects.BaseObject {
    public BackendType source_type { get; set; default = BackendType.NONE; }
    public string added_at { get; set; default = new GLib.DateTime.now_local ().to_string (); }
    public string updated_at { get; set; default = ""; }
    public bool is_visible { get; set; default = true; }
    public int child_order { get; set; default = 0; }
    public bool sync_server { get; set; default = false; }
    public string last_sync { get; set; default = ""; }
    public Objects.SourceData data { get; set; }
    public bool legacy { get; set; default = false; }

    Objects.SourceTodoistData _todoist_data;
    public Objects.SourceTodoistData todoist_data {
        get {
            _todoist_data = data as Objects.SourceTodoistData ;
            return _todoist_data;
        }
    }

    public string header_text {
        get {
            if (source_type == BackendType.TODOIST) {
                return todoist_data.user_email;
            }

            if (source_type == BackendType.LOCAL) {
                return _("On This Computer");
            }

            return "";
        }
    }

    public string? subheader_text {
        get {
            if (source_type == BackendType.TODOIST) {
                return _("Todoist");
            }

            return null;
        }
    }

    public string avatar_path {
        get {
            if (legacy) {
                return "todoist-user";
            }

            return todoist_data.user_image_id;
        }
    }

    private uint server_timeout = 0;

    public signal void sync_started ();
	public signal void sync_finished ();

    construct {
        deleted.connect (() => {
            Idle.add (() => {
                Services.Database.get_default ().source_deleted (this);
                return false;
            });
        });
    }

    public void run_server () {
		Services.Todoist.get_default ().sync.begin (this);

		server_timeout = Timeout.add_seconds (15 * 60, () => {
			if (sync_server) {
				Services.Todoist.get_default ().sync.begin (this);
			}

			return true;
		});
	}

    public void save () {
        if (source_type == BackendType.TODOIST && legacy) {
            Services.Settings.get_default ().settings.set_string ("todoist-sync-token", todoist_data.sync_token);
            Services.Settings.get_default ().settings.set_string ("todoist-last-sync", last_sync);
            Services.Settings.get_default ().settings.set_string ("todoist-user-email", todoist_data.user_email);
            Services.Settings.get_default ().settings.set_string ("todoist-user-name", todoist_data.user_name);
            Services.Settings.get_default ().settings.set_string ("todoist-user-avatar", todoist_data.user_avatar);
            Services.Settings.get_default ().settings.set_string ("todoist-user-image-id", todoist_data.user_image_id);
            Services.Settings.get_default ().settings.set_boolean ("todoist-sync-server", sync_server);
            Services.Settings.get_default ().settings.set_boolean ("todoist-user-is-premium", todoist_data.user_is_premium);
            return;
        }

        if (source_type == BackendType.TODOIST && !legacy) {

        }
    }

    public void delete_source (Gtk.Window window) {
        var dialog = new Adw.AlertDialog (
            _("Delete Source?"),
            _("This can not be undone")
        );

        dialog.add_response ("cancel", _("Cancel"));
        dialog.add_response ("delete", _("Delete"));
        dialog.close_response = "cancel";
        dialog.set_response_appearance ("delete", Adw.ResponseAppearance.DESTRUCTIVE);
        dialog.present (window);

        dialog.response.connect ((response) => {
            if (response == "delete") {
                if (legacy) {
                    _delete_source ();
                    return;
                }
                
                Services.Database.get_default ().delete_source (this);
            }
        });
    }

    private void _delete_source () {
        Services.Settings.get_default ().settings.set_string ("todoist-sync-token", "");
		Services.Settings.get_default ().settings.set_string ("todoist-access-token", "");
		Services.Settings.get_default ().settings.set_string ("todoist-last-sync", "");
		Services.Settings.get_default ().settings.set_string ("todoist-user-email", "");
		Services.Settings.get_default ().settings.set_string ("todoist-user-name", "");
		Services.Settings.get_default ().settings.set_string ("todoist-user-avatar", "");
		Services.Settings.get_default ().settings.set_string ("todoist-user-image-id", "");
		Services.Settings.get_default ().settings.set_boolean ("todoist-sync-server", false);
		Services.Settings.get_default ().settings.set_boolean ("todoist-user-is-premium", false);

		// Delete all projects, sections and items
		foreach (var project in Services.Database.get_default ().get_projects_by_source (id)) {
			Services.Database.get_default ().delete_project (project);
		}

		// Delete all labels;
		//  foreach (var label in Services.Database.get_default ().get_all_labels_by_todoist ()) {
		//  	Services.Database.get_default ().delete_label (label);
		//  }

		// Clear Queue
		Services.Database.get_default ().clear_queue ();

		// Clear CurTempIds
		Services.Database.get_default ().clear_cur_temp_ids ();

        deleted ();
    }
}

public class Objects.SourceData : GLib.Object {
    Json.Builder _builder;
    public Json.Builder builder {
        get {
            if (_builder == null) {
                _builder = new Json.Builder ();
            }

            return _builder;
        }
    }
    
    public virtual string to_json () {
        return "";
    }
}

public class Objects.SourceTodoistData : Objects.SourceData {
    public string access_token { get; set; default = ""; }
    public string sync_token { get; set; default = ""; }
    public string user_image_id { get; set; default = ""; }
    public string user_email { get; set; default = ""; }
    public string user_name { get; set; default = ""; }
    public string user_avatar { get; set; default = ""; }
    public bool user_is_premium { get; set; default = false; }

    public SourceTodoistData.from_json (string json) {
        Json.Parser parser = new Json.Parser ();
                
        try {
            parser.load_from_data (json, -1);
            var object = parser.get_root ().get_object ();

            if (object.has_member ("access_token")) {
                access_token = object.get_string_member ("access_token");
            }

            if (object.has_member ("sync_token")) {
                sync_token = object.get_string_member ("sync_token");
            }

            if (object.has_member ("user_image_id")) {
                user_image_id = object.get_string_member ("user_image_id");
            }

            if (object.has_member ("user_email")) {
                user_email = object.get_string_member ("user_email");
            }

            if (object.has_member ("user_name")) {
                user_name = object.get_string_member ("user_name");
            }

            if (object.has_member ("user_avatar")) {
                user_avatar = object.get_string_member ("user_avatar");
            }

            if (object.has_member ("user_is_premium")) {
                user_is_premium = object.get_boolean_member ("user_is_premium");
            }
        } catch (Error e) {
            debug (e.message);
        }
    }
    
    public override string to_json () {
        builder.reset ();
        
        builder.begin_object ();
        
        builder.set_member_name ("access_token");
        builder.add_string_value (access_token);

        builder.set_member_name ("sync_token");
        builder.add_string_value (sync_token);

        builder.set_member_name ("user_image_id");
        builder.add_string_value (user_image_id);

        builder.set_member_name ("user_email");
        builder.add_string_value (user_email);

        builder.set_member_name ("user_name");
        builder.add_string_value (user_name);

        builder.set_member_name ("user_avatar");
        builder.add_string_value (user_avatar);

        builder.set_member_name ("user_is_premium");
        builder.add_boolean_value (user_is_premium);

        builder.end_object ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);

        return generator.to_data (null);
    }
}