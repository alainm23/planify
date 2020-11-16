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
    public signal void send_notification (string message, NotificationStyle style=NotificationStyle.NORMAL);
    public signal void send_undo_notification (string message, string query);

    private Gee.HashMap<string, string> reminders;
    private GLib.TimeSpan time;

    public void init_server () {
        time = time_until_tomorrow ();
        load_today_reminders ();
        Timeout.add_seconds (((uint) time) + 1, () => {
            time = time_until_tomorrow ();
            Planner.event_bus.day_changed ();
            reminders.clear ();
            load_today_reminders ();
            return true;
        });
    }

    private void load_today_reminders () {
        reminders = new Gee.HashMap<string, string> ();
        foreach (var reminder in Planner.database.get_reminders ()) {
            reminder_added (reminder);
        }

        Planner.database.reminder_added.connect ((reminder) => {
            reminder_added (reminder);
        });

        Planner.database.reminder_deleted.connect ((id) => {
            if (reminders.has_key (id.to_string ())) {
                reminders.unset (id.to_string ());
            }
        });
    }

    private void reminder_added (Objects.Reminder reminder) {
        if (reminder.datetime.compare (new GLib.DateTime.now_local ()) <= 0) {
            var notification = new Notification (reminder.project_name);
            notification.set_body (reminder.content);
            notification.set_icon (new ThemedIcon ("com.github.alainm23.planner"));
            notification.set_priority (GLib.NotificationPriority.URGENT);

            notification.set_default_action_and_target_value (
                "app.show-item",
                new Variant.int64 (reminder.item_id)
            );

            Planner.instance.send_notification (reminder.id.to_string (), notification);
            Planner.database.delete_reminder (reminder.id);
        } else if (Granite.DateTime.is_same_day (reminder.datetime, new GLib.DateTime.now_local ())) {
            var interval = (uint) time_until_now (reminder.datetime);
            var uid = "%u-%u".printf (interval, GLib.Random.next_int ());
            reminders.set (reminder.id.to_string (), uid);
            
            Timeout.add_seconds (interval, () => {
                queue_reminder_notification (reminder.id, uid);
                return GLib.Source.REMOVE;
            });
        }
    }

    public void queue_reminder_notification (int64 reminder_id, string uid) {
        if (reminders.values.contains (uid) == false) {
            return;
        }

        var reminder = Planner.database.get_reminder_by_id (reminder_id);
        var notification = new Notification (reminder.project_name);
        notification.set_body (reminder.content);
        notification.set_icon (new ThemedIcon ("com.github.alainm23.planner"));
        notification.set_priority (GLib.NotificationPriority.URGENT);

        notification.set_default_action_and_target_value (
            "app.show-item",
            new Variant.int64 (reminder.item_id)
        );

        Planner.instance.send_notification (uid, notification);
        Planner.database.delete_reminder (reminder.id);
    }

    private TimeSpan time_until_now (GLib.DateTime dt) {
        var now = new DateTime.now_local ();
        return dt.difference (now) / TimeSpan.SECOND;
    }

    private TimeSpan time_until_tomorrow () {
        var now = new DateTime.now_local ();
        var tomorrow = new DateTime.local (
            now.add_days (1).get_year (),
            now.add_days (1).get_month (),
            now.add_days (1).get_day_of_month (),
            0,
            0,
            0
        );

        return tomorrow.difference (now) / TimeSpan.SECOND;
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
