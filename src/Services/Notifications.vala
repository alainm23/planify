public class Services.Notifications : GLib.Object {

    public Notifications () {
        Notify.init ("Planner");
        start_notification ();
    }

    public void send_notification (string title, string body) {
        var notification = new Notify.Notification (title, body, "com.github.artegeek.planner");
        notification.set_hint_string ("desktop-entry", "com.github.artegeek.planner");
        notification.set_urgency (Notify.Urgency.LOW);

        try {
            notification.show ();
        } catch (GLib.Error e) {
            warning ("Failed to show notification: %s", e.message);
        }
    }

    public void start_notification () {
        GLib.Timeout.add_seconds (15, () => {
            var all_tasks = new Gee.ArrayList<Objects.Task?> ();
            all_tasks = Planner.database.get_all_reminder_tasks ();

            foreach (Objects.Task task in all_tasks) {
                var now_date = new GLib.DateTime.now_local ();
                var reminder_date = new GLib.DateTime.from_iso8601 (task.reminder_time, new GLib.TimeZone.local ());

                if (Granite.DateTime.is_same_day (now_date, reminder_date)) {
                    if (now_date.get_hour () == reminder_date.get_hour ()) {
                        if (now_date.get_minute () == reminder_date.get_minute ()) {

                            var notification = new Notify.Notification (task.content, task.note, "com.github.artegeek.planner");
                            notification.set_hint_string ("desktop-entry", "com.github.artegeek.planner");
                            notification.set_urgency (Notify.Urgency.CRITICAL);

                            try {
                                notification.show ();
                                task.was_notified = 1;
                                Planner.database.update_task (task);
                            } catch (GLib.Error e) {
                                warning ("Failed to show notification: %s", e.message);
                            }
                        }
                    }
                }
            }

            return true;
        });
    }
}
