public class Widgets.NotificationRow : Gtk.ListBoxRow {
    public Objects.Notification notification { get; construct; }

    public NotificationRow (Objects.Notification _notification) {
        Object (
            notification: _notification
        );
    }

    construct {

    }
}
