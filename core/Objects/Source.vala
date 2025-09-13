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
    public string display_name { get; set; default = ""; }

    Objects.SourceTodoistData _todoist_data;
    public Objects.SourceTodoistData todoist_data {
        get {
            _todoist_data = data as Objects.SourceTodoistData;
            return _todoist_data;
        }
    }

    Objects.SourceCalDAVData _caldav_data;
    public Objects.SourceCalDAVData caldav_data {
        get {
            _caldav_data = data as Objects.SourceCalDAVData;
            return _caldav_data;
        }
    }

    public string header_text {
        get {
            return display_name;
        }
    }

    string _subheader_text;
    public string subheader_text {
        get {
            if (source_type == SourceType.TODOIST) {
                return _("Todoist");
            }

            if (source_type == SourceType.CALDAV) {
                _subheader_text = caldav_data.caldav_type.title ();
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
    public signal void sync_failed ();

    public Source.from_import_json (Json.Node node) {
        id = node.get_object ().get_string_member ("id");
        source_type = SourceType.parse (node.get_object ().get_string_member ("source_type"));
        added_at = node.get_object ().get_string_member ("added_at");
        updated_at = node.get_object ().get_string_member ("updated_at");
        is_visible = node.get_object ().get_boolean_member ("is_visible");
        child_order = (int32) node.get_object ().get_int_member ("is_visible");
        sync_server = node.get_object ().get_boolean_member ("sync_server");
        last_sync = node.get_object ().get_string_member ("last_sync");
        display_name = node.get_object ().get_string_member ("display_name");

        if (source_type == SourceType.TODOIST) {
            data = new Objects.SourceTodoistData.from_json (node.get_object ().get_string_member ("data"));
        } else if (source_type == SourceType.CALDAV) {
            data = new Objects.SourceCalDAVData.from_json (node.get_object ().get_string_member ("data"));
        }
    }

    public void run_server () {
        if (source_type == SourceType.LOCAL) {
            return;
        }

        _run_server ();

        server_timeout = Timeout.add_seconds (15 * 60, () => {
            if (sync_server) {
                _run_server ();
                return true;
            }

            return false; // Don't repeat timeout if sync server isn't active
        });
    }

    private void _run_server () {
        if (source_type == SourceType.TODOIST) {
            Services.Todoist.get_default ().sync.begin (this);
        } else if (source_type == SourceType.CALDAV) {
            Services.CalDAV.Core.get_default ().sync.begin (this);
        }
    }

    public void remove_sync_server () {
        // Remove server_timeout
        GLib.Source.remove (server_timeout);
        server_timeout = 0;
    }

    public void save () {
        updated_at = new GLib.DateTime.now_local ().to_string ();
        Services.Store.instance ().update_source (this);
    }

    public void delete_source () {
        // Remove server_timeout
        remove_sync_server ();

        // Remove DB
        Services.Store.instance ().delete_source (this);
    }

    public string to_string () {
        return """
        _________________________________
            ID: %s
            DATA: %s
            TYPE: %s
            SYNC_SERVER: %s
            DISPLAY_NAME: %s
            UPDATED_AT: %s
            IS_VISIBLE: %s
            CHILD_ORDER: %d
            LAST_SYNC: %s
        ---------------------------------
        """.printf (
            id,
            data.to_json (),
            source_type.to_string (),
            sync_server.to_string (),
            display_name,
            updated_at,
            is_visible.to_string (),
            child_order,
            last_sync
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
    string _server_url;
    public string server_url {
        set {
            _server_url = value;
        }

        get {
            if (!_server_url.has_suffix ("/")) {
                _server_url += "/";
            }

            return _server_url;
        }
    }
    public string username { get; set; default = ""; }
    public string password { get; set; default = ""; }
    public string user_displayname { get; set; default = ""; }
    public string user_email { get; set; default = ""; }

    string _calendar_home_url;
    public string calendar_home_url {
        set {
            _calendar_home_url = value;
        }

        get {
            if (_calendar_home_url == null || _calendar_home_url == "") {
                _calendar_home_url = Path.build_filename (server_url, "calendars", username);
                if (!_calendar_home_url.has_suffix ("/")) {
                    _calendar_home_url += "/";
                }
            }

            return _calendar_home_url;
        }
    }
    
    public CalDAVType caldav_type { get; set; default = CalDAVType.GENERIC; }
    public bool ignore_ssl { get; set; default = false; }

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

            if (object.has_member ("password")) {
                password = object.get_string_member ("password");
            }

            if (object.has_member ("user_displayname")) {
                user_displayname = object.get_string_member ("user_displayname");
            }

            if (object.has_member ("user_email")) {
                user_email = object.get_string_member ("user_email");
            }

            if (object.has_member ("calendar_home_url")) {
                calendar_home_url = object.get_string_member ("calendar_home_url");
            }

            if (object.has_member ("caldav_type")) {
                caldav_type = CalDAVType.parse (object.get_string_member ("caldav_type"));
            }

            if (object.has_member ("ignore_ssl")) {
                ignore_ssl = object.get_boolean_member ("ignore_ssl");
            }

            if (object.has_member ("credentials")) {
                var decoded = (string) Base64.decode (object.get_string_member ("credentials"));

                var parts = decoded.split (":", 2);
                if (parts.length == 2) {
                    password = parts[1];
                }
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

        builder.set_member_name ("password");
        builder.add_string_value (password);

        builder.set_member_name ("caldav_type");
        builder.add_string_value (caldav_type.to_string ());

        builder.set_member_name ("user_displayname");
        builder.add_string_value (user_displayname);

        builder.set_member_name ("user_email");
        builder.add_string_value (user_email);

        builder.set_member_name ("calendar_home_url");
        builder.add_string_value (calendar_home_url);

        builder.set_member_name ("ignore_ssl");
        builder.add_boolean_value (ignore_ssl);

        builder.end_object ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);

        return generator.to_data (null);
    }
}
