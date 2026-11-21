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
    // Snoozes are one-off: they are deleted after firing even on recurring tasks.
    private Gee.HashSet<string> one_shot_reminders = new Gee.HashSet<string> ();

    public void mark_one_shot (Objects.Reminder reminder) {
        one_shot_reminders.add (reminder.id);
    }

    construct {
        regresh ();

        Services.Settings.get_default ().settings.changed["automatic-reminders-enabled"].connect (() => {
            automatic_reminders_changed ();
        });

        // The reminder moved (e.g. a recurring task went to its next occurrence):
        // cancel its pending timer and schedule it again with the new time.
        Services.Store.instance ().reminder_updated.connect ((reminder) => {
            reminders.unset (reminder.id);
            reminder_added (reminder);
        });
    }

    // Recurring tasks keep their reminders so they also fire on the next occurrences.
    // Todoist keeps reminders on its server, so it keeps the previous behavior.
    private bool keeps_after_firing (Objects.Reminder reminder) {
        var item = reminder.item;
        return item != null && item.project != null &&
               item.project.source_type != SourceType.TODOIST &&
               item.due.is_recurring && !item.due.is_recurrency_end &&
               !one_shot_reminders.contains (reminder.id);
    }

    // Mark the reminder as used: deleted, or remembered for recurring tasks.
    private void consume_reminder (Objects.Reminder reminder) {
        if (keeps_after_firing (reminder)) {
            // Saved, so it doesn't fire again after restarting, and the views
            // show it as waiting for the next occurrence.
            reminder.fired_at = reminder.datetime.to_string ();
            Services.Store.instance ().update_reminder (reminder);
        } else {
            one_shot_reminders.remove (reminder.id);
            Services.Store.instance ().delete_reminder (reminder);
        }
    }

    private void fire_reminder (Objects.Reminder reminder, string notification_id) {
        GLib.Notification notification = build_notification (reminder);
        Planify.instance.send_notification (notification_id, notification);
        consume_reminder (reminder);
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
        // A completed task doesn't need a reminder.
        if (reminder.item == null || reminder.item.checked) {
            return;
        }

        if (reminder.has_fired) {
            return;
        }

        bool is_past = reminder.datetime.compare (new GLib.DateTime.now_local ()) <= 0;

        if (is_muted (reminder) || (drop_past && is_past)) {
            // An automatic reminder that came due while reminders were off is
            // consumed without a notification, so it doesn't fire later.
            if (is_past) {
                consume_reminder (reminder);
            }

            return;
        }

        if (is_past) {
            fire_reminder (reminder, reminder.id);
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

        reminders.unset (reminder.id);

        // The task may have been completed while waiting.
        if (reminder.item == null || reminder.item.checked) {
            return;
        }

        fire_reminder (reminder, uid);
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
