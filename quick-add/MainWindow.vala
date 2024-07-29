public class MainWindow : Adw.ApplicationWindow {
    private Layouts.QuickAdd quick_add_widget;

    public MainWindow (QuickAdd application) {
        Object (
            application: application,
            icon_name: "io.github.alainm23.planify",
            title: _("Planify - Quick Add"),
            resizable: false,
            width_request: 600,
            halign: Gtk.Align.START
        );
    }

    static construct {
        weak Gtk.IconTheme default_theme = Gtk.IconTheme.get_for_display (Gdk.Display.get_default ());
        default_theme.add_resource_path ("/io/github/alainm23/planify/");
    }

    construct {
        Services.Database.get_default ().init_database ();
        
        quick_add_widget = new Layouts.QuickAdd (true);
        set_content (quick_add_widget);

        quick_add_widget.hide_destroy.connect (hide_destroy);
        quick_add_widget.send_interface_id.connect (send_interface_id);
        quick_add_widget.add_item_db.connect ((add_item_db));
    }

    private void add_item_db (Objects.Item item, Gee.ArrayList<Objects.Reminder> reminders) {
        Services.Store.instance ().insert_item (item);

        if (reminders.size > 0) {
            quick_add_widget.is_loading = true;

            foreach (Objects.Reminder reminder in reminders) {
                item.add_reminder (reminder);
            }
        }

        if (Services.Settings.get_default ().get_boolean ("automatic-reminders-enabled") && item.has_time) {
            var reminder = new Objects.Reminder ();
            reminder.mm_offset = Util.get_reminders_mm_offset ();
            reminder.reminder_type = ReminderType.RELATIVE;
            item.add_reminder (reminder);
        }

        send_interface_id (item.id);
        quick_add_widget.added_successfully ();
    }

    private void send_interface_id (string id) {
        try {
            DBusClient.get_default ().interface.add_item (id);
        } catch (Error e) {
            debug (e.message);
        }
    }

    public void hide_destroy () {
        hide ();

        Timeout.add (500, () => {
            destroy ();
            return GLib.Source.REMOVE;
        });
    }
}
