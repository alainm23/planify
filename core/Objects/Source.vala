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
    public SourceType source_type { get; set; default = SourceType.NONE; }
    public string added_at { get; set; default = new GLib.DateTime.now_local ().to_string (); }
    public string updated_at { get; set; default = ""; }
    public bool is_visible { get; set; default = true; }
    public int child_order { get; set; default = 0; }
    public bool sync_server { get; set; default = false; }
    public string last_sync { get; set; default = ""; }
    public Objects.SourceData data { get; set; }

    Objects.SourceTodoistData _todoist_data;
    public Objects.SourceTodoistData todoist_data {
        get {
            _todoist_data = data as Objects.SourceTodoistData ;
            return _todoist_data;
        }
    }

    Objects.SourceCalDAVData _caldav_data;
    public Objects.SourceCalDAVData caldav_data {
        get {
            _caldav_data = data as Objects.SourceCalDAVData ;
            return _caldav_data;
        }
    }

    public string header_text {
        get {
            if (source_type == SourceType.LOCAL) {
                return _("On This Computer");
            }

            if (source_type == SourceType.TODOIST) {
                return todoist_data.user_email;
            }

            if (source_type == SourceType.CALDAV) {
                return caldav_data.user_email;
            }

            return "";
        }
    }

    string _subheader_text;
    public string subheader_text {
        get {
            if (source_type == SourceType.TODOIST) {
                return _("Todoist");
            }

            if (source_type == SourceType.CALDAV) {
                _subheader_text = _("CalDAV - ") + caldav_data.caldav_type.title ();
                return _subheader_text;
            }

            return "";
        }
    }

    public string avatar_path {
        get {
            return todoist_data.user_image_id;
        }
    }

    public string user_displayname {
        get {
            if (source_type == SourceType.TODOIST) {
                return todoist_data.user_name;
            }

            if (source_type == SourceType.CALDAV) {
                return caldav_data.user_displayname;
            }

            return "";
        }
    }

    public string user_email {
        get {
            if (source_type == SourceType.TODOIST) {
                return todoist_data.user_email;
            }

            if (source_type == SourceType.CALDAV) {
                return caldav_data.user_email;
            }

            return "";
        }
    }

    private uint server_timeout = 0;

    public signal void sync_started ();
	public signal void sync_finished ();

    construct {
        deleted.connect (() => {
            Idle.add (() => {
                Services.Store.instance ().source_deleted (this);
                return false;
            });
        });
    }

    public void run_server () {
		Services.Todoist.get_default ().sync.begin (this);

		server_timeout = Timeout.add_seconds (15 * 60, () => {
			if (sync_server) {
                if (source_type == SourceType.TODOIST) {
                    Services.Todoist.get_default ().sync.begin (this);
                } else if (source_type == SourceType.CALDAV) {
                    Services.CalDAV.Core.get_default ().sync.begin (this);
                }
			}

			return true;
		});
	}

    public void save () {
        updated_at = new GLib.DateTime.now_local ().to_string ();
        Services.Store.instance ().update_source (this);
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
                Services.Store.instance ().delete_source (this);
            }
        });
    }

    public string to_string () {
        return """
        _________________________________
            ID: %s
            DATA: %s
            TYPE: %s
        ---------------------------------
        """.printf (
            id,
            data.to_json (),
            source_type.to_string ()
        );
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

public class Objects.SourceCalDAVData : Objects.SourceData {
    public string server_url { get; set; default = ""; }
    public string username { get; set; default = ""; }
    public string credentials { get; set; default = ""; }
    public string user_displayname { get; set; default = ""; }
    public string user_email { get; set; default = ""; }
    public CalDAVType caldav_type { get; set; default = CalDAVType.NEXTCLOUD; }

    public SourceCalDAVData.from_json (string json) {
        Json.Parser parser = new Json.Parser ();
                
        try {
            parser.load_from_data (json, -1);
            var object = parser.get_root ().get_object ();

            if (object.has_member ("server_url")) {
                server_url = object.get_string_member ("server_url");
            }

            if (object.has_member ("username")) {
                username = object.get_string_member ("username");
            }

            if (object.has_member ("credentials")) {
                credentials = object.get_string_member ("credentials");
            }

            if (object.has_member ("user_displayname")) {
                user_displayname = object.get_string_member ("user_displayname");
            }

            if (object.has_member ("user_email")) {
                user_email = object.get_string_member ("user_email");
            }

            if (object.has_member ("caldav_type")) {
                caldav_type = CalDAVType.parse (object.get_string_member ("caldav_type"));
            }
        } catch (Error e) {
            debug (e.message);
        }
    }

    public override string to_json () {
        builder.reset ();
        
        builder.begin_object ();
        
        builder.set_member_name ("server_url");
        builder.add_string_value (server_url);

        builder.set_member_name ("username");
        builder.add_string_value (username);

        builder.set_member_name ("credentials");
        builder.add_string_value (credentials);

        builder.set_member_name ("caldav_type");
        builder.add_string_value (caldav_type.to_string ());

        builder.set_member_name ("user_displayname");
        builder.add_string_value (user_displayname);

        builder.set_member_name ("user_email");
        builder.add_string_value (user_email);

        builder.end_object ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);

        return generator.to_data (null);
    }
}