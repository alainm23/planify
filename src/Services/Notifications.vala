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

public class Services.Notifications : GLib.Object {
    public signal void send_notification (string message);
    public signal void send_undo_notification (string message, string query);

    private uint server_timeout = 0;

    construct {
        Planner.database.reset.connect (() => {
            if (server_timeout != 0) {
                Source.remove (server_timeout);
            }
        });
    }

    public void init_server () {
        server_timeout = Timeout.add_seconds (1 * 60, () => {
            server_timeout = 0;

            foreach (var reminder in Planner.database.get_reminders ()) {
                if (reminder.datetime.compare (new GLib.DateTime.now_local ()) <= 0) {
                    var notification = new Notification (reminder.project_name);
                    notification.set_body (reminder.content);
                    notification.set_icon (new ThemedIcon ("com.github.alainm23.planner"));
                    notification.set_priority (GLib.NotificationPriority.URGENT);

                    notification.set_default_action_and_target_value (
                        "app.show-item",
                        new Variant.int64 (reminder.item_id)
                    );

                    Planner.instance.send_notification ("com.github.alainm23.planner", notification);
                    Planner.database.delete_reminder (reminder.id);
                }
            }

            return true;
        });
    }

    public void send_system_notification (string title, string body,
        string icon_name, GLib.NotificationPriority priority) {
        var notification = new Notification (title);
        notification.set_body (body);
        notification.set_icon (new ThemedIcon (icon_name));
        notification.set_priority (priority);

        Planner.instance.send_notification ("com.github.alainm23.planner", notification);
    }
}
