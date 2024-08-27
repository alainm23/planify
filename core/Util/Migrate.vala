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

public class Utils.AccountMigrate {
	public static Objects.SourceTodoistData get_data_from_todoist () {
		Objects.SourceTodoistData return_value = new Objects.SourceTodoistData ();

		return_value.sync_token = Services.Settings.get_default ().settings.get_string ("todoist-sync-token");
		return_value.access_token = Services.Settings.get_default ().settings.get_string ("todoist-access-token");
		return_value.user_email = Services.Settings.get_default ().settings.get_string ("todoist-user-email");
		return_value.user_name = Services.Settings.get_default ().settings.get_string ("todoist-user-name");
		return_value.user_avatar = Services.Settings.get_default ().settings.get_string ("todoist-user-avatar");
		return_value.user_image_id = Services.Settings.get_default ().settings.get_string ("todoist-user-image-id");
		return_value.user_is_premium = Services.Settings.get_default ().settings.get_boolean ("todoist-user-is-premium");

		return return_value;
	}

	public static Objects.SourceCalDAVData get_data_from_caldav () {
		Objects.SourceCalDAVData return_value = new Objects.SourceCalDAVData ();

		string _server_url = "";
		var uri = GLib.Uri.parse (Services.Settings.get_default ().settings.get_string ("caldav-server-url"), GLib.UriFlags.NONE);
		_server_url = "%s://%s".printf (uri.get_scheme (), uri.get_host ());

		return_value.server_url = "%s/remote.php/dav".printf (_server_url);
		return_value.username = Services.Settings.get_default ().settings.get_string ("caldav-username");
		return_value.credentials = get_credential ();
		return_value.user_displayname = Services.Settings.get_default ().settings.get_string ("caldav-user-displayname");
		return_value.user_email = Services.Settings.get_default ().settings.get_string ("caldav-user-email");
		return_value.caldav_type = CalDAVType.NEXTCLOUD;

		return return_value;
	}

	private static string get_credential () throws Error {
		Secret.Schema schema = new Secret.Schema ("io.github.alainm23.planify", Secret.SchemaFlags.NONE,
		                                          "username", Secret.SchemaAttributeType.STRING,
		                                          "server_url", Secret.SchemaAttributeType.STRING
		                                          );

		string username = Services.Settings.get_default ().settings.get_string ("caldav-username");

		GLib.HashTable <string, string> attributes = new GLib.HashTable <string, string> (str_hash, str_equal);
		attributes["username"] = username;
		attributes["server_url"] = Services.Settings.get_default ().settings.get_string ("caldav-server-url");

		string password = Secret.password_lookupv_sync (schema, attributes, null);
		string credentials = "%s:%s".printf (username, password);
		string base64_credentials = Base64.encode (credentials.data);

		return base64_credentials;
	}
}
