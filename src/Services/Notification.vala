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
    private static Notification ? _instance;
    public static Notification get_default () {
        if (_instance == null) {
            _instance = new Notification ();
        }

        return _instance;
    }

    private Gee.HashMap<string, string> reminders;

    construct {
        regresh ();

        Services.Settings.get_default ().settings.changed["automatic-reminders-enabled"].connect (() => {
            automatic_reminders_changed ();
        });
    }

    public void regresh () {
        if (reminders == null) {
            reminders = new Gee.HashMap<string, string> ();
        } else {
            reminders.clear ();
        }

        // Iterate over a copy: reminder_added () can delete reminders from the Store's list.
        var all_reminders = new Gee.ArrayList<Objects.Reminder> ();
        all_reminders.add_all (Services.Store.instance ().reminders);
        foreach (var reminder in all_reminders) {
            reminder_added (reminder);
        }

        Services.Store.instance ().reminder_added.connect ((reminder) => {
            reminder_added (reminder);
        });

        Services.Store.instance ().reminder_deleted.connect ((reminder) => {
            if (reminders.has_key (reminder.id)) {
                reminders.unset (reminder.id);
            }
        });
    }

    private bool is_muted (Objects.Reminder reminder) {
        return reminder.reminder_type == ReminderType.RELATIVE &&
               !Services.Settings.get_default ().get_boolean ("automatic-reminders-enabled");
    }

    private void automatic_reminders_changed () {
        var relative_reminders = new Gee.ArrayList<Objects.Reminder> ();
        foreach (var reminder in Services.Store.instance ().reminders) {
            if (reminder.reminder_type == ReminderType.RELATIVE) {
                relative_reminders.add (reminder);
            }
        }

        foreach (var reminder in relative_reminders) {
            if (is_muted (reminder)) {
                reminders.unset (reminder.id);
            } else if (!reminders.has_key (reminder.id)) {
                // Reminders whose time passed while muted are dropped by reminder_added ().
                reminder_added (reminder, true);
            }
        }
    }

    private void reminder_added (Objects.Reminder reminder, bool drop_past = false) {
        bool is_past = reminder.datetime.compare (new GLib.DateTime.now_local ()) <= 0;

        if (is_muted (reminder) || (drop_past && is_past)) {
            // An automatic reminder that came due while reminders were off is
            // consumed without a notification, so it doesn't fire later.
            if (is_past) {
                Services.Store.instance ().delete_reminder (reminder);
            }

            return;
        }

        if (is_past) {
            GLib.Notification notification = build_notification (reminder);
            Planify.instance.send_notification (reminder.id, notification);
            Services.Store.instance ().delete_reminder (reminder);
        } else if (Utils.Datetime.is_same_day (reminder.datetime, new GLib.DateTime.now_local ())) {
            uint interval = (uint) time_until_now (reminder.datetime);
            string uid = "%u-%u".printf (interval, GLib.Random.next_int ());
            reminders.set (reminder.id, uid);

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

    private void queue_reminder_notification (Objects.Reminder reminder, string uid) {
        if (reminders.values.contains (uid) == false) {
            return;
        }

        GLib.Notification notification = build_notification (reminder);
        Planify.instance.send_notification (uid, notification);
        Services.Store.instance ().delete_reminder (reminder);
    }

    private GLib.Notification build_notification (Objects.Reminder reminder) {
        var notification = new GLib.Notification (reminder.item.project.name);
        notification.set_body (reminder.item.content);
        notification.set_icon (new ThemedIcon ("io.github.alainm23.planify"));
        notification.set_priority (GLib.NotificationPriority.URGENT);
        notification.set_default_action_and_target_value ("show-item", new Variant.string (reminder.item_id));
        notification.add_button_with_target_value (_("Complete"), "app.complete", new Variant.string (reminder.item_id));
        // TRANSLATORS: Short label for reminder notification button to snooze for 10 minutes. Please keep the number/duration at the beginning (e.g. "10m Snooze") to prevent button text truncation in compact notification dialogs.
        notification.add_button_with_target_value (_("10m Snooze"), "app.snooze-10", new Variant.string (reminder.item_id));
        // TRANSLATORS: Short label for reminder notification button to snooze for 30 minutes. Please keep the number/duration at the beginning (e.g. "30m Snooze") to prevent button text truncation in compact notification dialogs.
        notification.add_button_with_target_value (_("30m Snooze"), "app.snooze-30", new Variant.string (reminder.item_id));
        // TRANSLATORS: Short label for reminder notification button to snooze for 1 hour. Please keep the number/duration at the beginning (e.g. "1h Snooze") to prevent button text truncation in compact notification dialogs.
        notification.add_button_with_target_value (_("1h Snooze"), "app.snooze-60", new Variant.string (reminder.item_id));

        return notification;
    }
}
