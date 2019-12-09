public class Widgets.ReminderRow : Gtk.ListBoxRow {
    public Objects.Reminder reminder { get; construct; }

    public ReminderRow (Objects.Reminder reminder) {
        Object (
            reminder: reminder
        );
    }

    construct {
        get_style_context ().add_class ("item-row");

        var icon = new Gtk.Image ();
        icon.gicon = new ThemedIcon ("alarm-symbolic");
        icon.pixel_size = 16;

        var date_label = new Gtk.Label ("%s %s".printf (
            Planner.utils.get_relative_date_from_string (reminder.due_date),
            Planner.utils.get_relative_time_from_string (reminder.due_date)
        ));
        date_label.get_style_context ().add_class ("h4");

        var delete_button = new Gtk.Button.from_icon_name ("window-close-symbolic");
        delete_button.valign = Gtk.Align.CENTER;
        delete_button.can_focus = false;
        delete_button.get_style_context ().add_class ("flat");
        delete_button.get_style_context ().add_class ("delete-check-button");
        delete_button.get_style_context ().add_class ("dim-label");

        var delete_revealer = new Gtk.Revealer ();
        delete_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        delete_revealer.add (delete_button);

        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        box.margin_start = 6;
        box.hexpand = true;
        box.pack_start (icon, false, false, 0);
        box.pack_start (date_label, false, true, 0);
        box.pack_end (delete_revealer, false, true, 0);

        var handle = new Gtk.EventBox ();
        handle.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        handle.add (box);

        add (handle);

        handle.enter_notify_event.connect ((event) => {
            delete_revealer.reveal_child = true;

            return true;
        });

        handle.leave_notify_event.connect ((event) => {
            if (event.detail == Gdk.NotifyType.INFERIOR) {
                return false;
            }
            
            delete_revealer.reveal_child = false;

            return true;
        });

        delete_button.clicked.connect (() => {
            Planner.database.delete_reminder (reminder.id);
        });

        Planner.database.reminder_deleted.connect ((id) => {
            if (reminder.id == id) {
                destroy ();
            }
        });

        Planner.settings.changed.connect ((key) => {
            if (key == "time-format") {
                date_label.label = "%s %s".printf (
                    Planner.utils.get_relative_date_from_string (reminder.due_date),
                    Planner.utils.get_relative_time_from_string (reminder.due_date)
                );
            }
        });
    }
}