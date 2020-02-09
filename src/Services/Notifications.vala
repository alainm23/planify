public class Services.Notifications : GLib.Object {
    public signal void send_notification (int type, string message);

    private const string MOVE_TEMPLATE = "<b>%s</b> moved to <b>%s</b>";
    private const string DELETE_TEMPLATE = "(%i) %s deleted";

    construct {
        init_server ();

        Planner.database.show_toast_delete.connect ((count) => {
            string t = _("task");
            if (count > 1) {
                t = _("tasks");
            }

            send_notification (
                1,
                DELETE_TEMPLATE.printf (count, t)
            );
        });

        Planner.database.item_moved.connect ((item, project_id, old_project_id) => {
            Idle.add (() => {
                send_notification (
                    0,
                    MOVE_TEMPLATE.printf (
                        item.content,
                        Planner.database.get_project_by_id (project_id).name
                    )
                );

                return false;
            });
        });

        Planner.database.section_moved.connect ((section) => {
            Idle.add (() => {
                send_notification (
                    0,
                    MOVE_TEMPLATE.printf (
                        section.name,
                        Planner.database.get_project_by_id (section.project_id).name
                    )
                );

                return false;
            });
        });
    }

    private void init_server () {
        Timeout.add_seconds (1 * 60, () => {
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
