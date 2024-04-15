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

public class Services.Notification : GLib.Object {
    private static Notification? _instance;
    public static Notification get_default () {
        if (_instance == null) {
            _instance = new Notification ();
        }

        return _instance;
    }

    private Gee.HashMap<string, string> reminders;

    construct {
        regresh ();
    }

    public void regresh () {
        if (reminders == null) {
            reminders = new Gee.HashMap<string, string> ();
        } else {
            reminders.clear ();
        }

        foreach (var reminder in Services.Database.get_default ().reminders) {
            reminder_added (reminder);
        }

        Services.Database.get_default ().reminder_added.connect ((reminder) => {
            reminder_added (reminder);
        });

        Services.Database.get_default ().reminder_deleted.connect ((reminder) => {
            if (reminders.has_key (reminder.id_string)) {
                reminders.unset (reminder.id_string);
            }
        });
    }

    private void reminder_added (Objects.Reminder reminder) {
        if (reminder.due.datetime.compare (new GLib.DateTime.now_local ()) <= 0) {
            GLib.Notification notification = build_notification (reminder);
            Planify.instance.send_notification (reminder.id, notification);
            Services.Database.get_default ().delete_reminder (reminder);
        } else if (Granite.DateTime.is_same_day (reminder.due.datetime, new GLib.DateTime.now_local ())) {
            var interval = (uint) time_until_now (reminder.due.datetime);
            var uid = "%u-%u".printf (interval, GLib.Random.next_int ());
            reminders.set (reminder.id_string, uid);
            
            Timeout.add_seconds (interval, () => {
                queue_reminder_notification (reminder, uid);
                return GLib.Source.REMOVE;
            });
        }
    }

    private TimeSpan time_until_now (GLib.DateTime dt) {
        var now = new DateTime.now_local ();
        return dt.difference (now) / TimeSpan.SECOND;
    }

    public void queue_reminder_notification (Objects.Reminder reminder, string uid) {
        if (reminders.values.contains (uid) == false) {
            return;
        }

        GLib.Notification notification = build_notification (reminder);
        Planify.instance.send_notification (uid, notification);
        Services.Database.get_default ().delete_reminder (reminder);
    }

    public GLib.Notification build_notification (Objects.Reminder reminder) {
        var notification = new GLib.Notification (reminder.item.project.short_name);
        notification.set_body (reminder.item.content);
        notification.set_icon (new ThemedIcon ("io.github.alainm23.planify"));
        notification.set_priority (GLib.NotificationPriority.URGENT);
        notification.set_default_action_and_target_value ("show-item", new Variant.string (reminder.item_id));
        
        return notification;
    }
}
