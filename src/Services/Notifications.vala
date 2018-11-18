public class Services.Notifications : GLib.Object {
    public weak MainWindow window { private get; construct; }
    private Notify.Notification notification;

    public signal void on_signal_highlight_task (Objects.Task task);
    public Notifications (MainWindow parent) {
        Object (
            window: parent
        );

        Notify.init ("Planner");
        start_notification ();
    }

    public void send_notification (string summary, string body) {
        var notification = new Notify.Notification (summary, body, "com.github.artegeek.planner");
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
                            var summary = "";
                            var body = task.content;

                            if (task.is_inbox == 1) {
                                summary = _("Inbox");
                            } else {
                                summary = Planner.database.get_project (task.project_id).name;
                            }

                            notification = new Notify.Notification (summary, body, "com.github.artegeek.planner");
                            notification.set_hint_string ("desktop-entry", "com.github.artegeek.planner");
                            notification.set_urgency (Notify.Urgency.CRITICAL);

                            notification.add_action ("view", _("View"), (notification, action) => {
                                on_signal_highlight_task (task);
                                window.present ();
                                window.present_with_time (0);

                                notification.close ();
                            });

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
