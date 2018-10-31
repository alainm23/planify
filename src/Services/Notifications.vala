public class Services.Notifications : GLib.Object {
    public weak Planner application { get; construct; }
    public Notifications (Planner _application) {
        Object (
			application: _application
		);


    }

    construct {
        start_notification ();
    }

    public void start_notification () {
        GLib.Timeout.add_seconds (10, () => {
            var all_tasks = new Gee.ArrayList<Objects.Task?> ();
            all_tasks = Planner.database.get_all_reminder_tasks ();

            foreach (Objects.Task task in all_tasks) {
                var now_date = new GLib.DateTime.now_local ();
                var reminder_date = new GLib.DateTime.from_iso8601 (task.reminder_time, new GLib.TimeZone.local ());

                if (Granite.DateTime.is_same_day (now_date, reminder_date) && task.was_notified == 0) {
                    if (now_date.get_hour () == reminder_date.get_hour ()) {
                        if (now_date.get_minute () == reminder_date.get_minute ()) {
                            var notification = new Notification (task.content);
                            notification.set_body (task.note);
                            notification.add_button ("action", "action");
                            notification.set_priority (GLib.NotificationPriority.URGENT);

                            application.send_notification ("com.github.artegeek.planner", notification);
                            task.was_notified = 1;

                            Planner.database.update_task (task);
                        }
                    }
                }
            }
            return true;
        });
    }
}
