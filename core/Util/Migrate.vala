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
}