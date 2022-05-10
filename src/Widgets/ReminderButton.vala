public class Widgets.ReminderButton : Gtk.Button {
    public Objects.Item item { get; construct; }

    private Gtk.Label badge_label;
    private Gtk.Revealer badge_revealer;

    public signal void dialog_open (bool value);

    public ReminderButton (Objects.Item item) {
        Object (
            item: item,
            can_focus: false,
            valign: Gtk.Align.CENTER,
            halign: Gtk.Align.CENTER,
            tooltip_text: _("Add reminder(s)")
        );
    }

    construct {
        get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var button_image = new Widgets.DynamicIcon ();
        button_image.size = 19;
        button_image.update_icon_name ("planner-bell");

        badge_label = new Gtk.Label (null);
        badge_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        badge_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT
        };

        badge_revealer.add (badge_label);

        var button_grid = new Gtk.Grid () {
            column_spacing = 3,
            valign = Gtk.Align.CENTER
        };

        button_grid.add (button_image);
        button_grid.add (badge_revealer);

        add (button_grid);
        update_request ();

        clicked.connect (() => {
            var dialog = new Dialogs.ReminderPicker.ReminderPicker (item);

            dialog_open (true);
            dialog.popup ();

            dialog.destroy.connect (() => {
                dialog_open (false);
            });
        });

        item.reminder_added.connect (() => {
            update_request ();
        });

        item.reminder_deleted.connect (() => {
            update_request ();
        });
    }

    public void update_request () {
        badge_label.label = "%d".printf (item.reminders.size);
        badge_revealer.reveal_child = item.reminders.size > 0;
    }
}
