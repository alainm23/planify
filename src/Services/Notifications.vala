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

public class Services.Notifications : GLib.Object {
    public signal void on_signal_weather_update ();
    public signal void on_signal_location_manual ();

    public signal void on_signal_highlight_task (Objects.Task task);
    public signal void send_local_notification (string title,
                                                string description,
                                                string icon_name,
                                                int    time,
                                                bool   remove_clipboard_task);

    public Notifications () {
        start_notification ();
    }

    public void send_notification (string title, string body, string icon) {
        var notification = new Notification (title);
        notification.set_body (body);
        notification.set_icon (new ThemedIcon (icon));
        notification.set_priority (GLib.NotificationPriority.NORMAL);
                            
        notification.set_default_action ("app.show-window");

        Application.instance.send_notification ("com.github.alainm23.planner", notification);
    }

    public void send_task_notification (string title, Objects.Task task, string icon) {                            
        var notification = new Notification (title);
        notification.set_body (task.content);
        notification.set_icon (new ThemedIcon (icon));
        notification.set_priority (GLib.NotificationPriority.URGENT);
                            
        notification.set_default_action_and_target_value (
            "app.show-task", 
            new Variant.int32 (task.id)
        );

        Application.instance.send_notification ("com.github.alainm23.planner", notification);
    }

    public void start_notification () {
        GLib.Timeout.add (1000 * 15, () => {
            var all_tasks = new Gee.ArrayList<Objects.Task?> ();
            all_tasks = Application.database.get_all_reminder_tasks ();

            foreach (Objects.Task task in all_tasks) {
                var now_date = new GLib.DateTime.now_local ();
                var reminder_date = new GLib.DateTime.from_iso8601 (task.reminder_time, new GLib.TimeZone.local ());

                if (Application.utils.is_today (reminder_date)) {
                    if (now_date.get_hour () == reminder_date.get_hour ()) {
                        if (now_date.get_minute () == reminder_date.get_minute ()) {
                            var title = "";
                            var body = task.content;
                            
                            if (task.is_inbox == 1) {
                                title = _("Inbox");
                            } else {
                                title = Application.database.get_project (task.project_id).name;
                            }

                            var notification = new Notification (title);
                            notification.set_body (body);
                            notification.set_icon (new ThemedIcon ("com.github.alainm23.planner"));
                            notification.set_priority (GLib.NotificationPriority.URGENT);
                            
                            notification.set_default_action_and_target_value (
                                "app.show-task", 
                                new Variant.int32 (task.id)
                            );

                            Application.instance.send_notification ("com.github.alainm23.planner", notification);
                            
                            task.was_notified = 1;
                            Application.database.update_task (task);
                        }
                    }
                }
            }

            return true;
        });
    }
}
