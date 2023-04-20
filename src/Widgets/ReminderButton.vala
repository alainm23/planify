public class Widgets.ReminderButton : Gtk.Grid {
    public Objects.Item item { get; construct; }

    private Gtk.Label badge_label;
    private Gtk.Revealer badge_revealer;

    public ReminderButton (Objects.Item item) {
        Object (
            item: item,
            valign: Gtk.Align.CENTER,
            halign: Gtk.Align.CENTER,
            tooltip_text: _("Add reminder(s)")
        );
    }

    construct {
        var reminder_picker = new Widgets.ReminderPicker.ReminderPicker (item);

        var bell_image = new Widgets.DynamicIcon ();
        bell_image.size = 19;
        bell_image.update_icon_name ("planner-bell");

        badge_label = new Gtk.Label (null);
        badge_label.get_style_context ().add_class (Granite.STYLE_CLASS_DIM_LABEL);

        badge_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT
        };

        badge_revealer.child = badge_label;

        var button_grid = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            valign = Gtk.Align.CENTER
        };

        button_grid.append (bell_image);
        button_grid.append (badge_revealer);

        var button = new Gtk.MenuButton () {
            child = button_grid,
            popover = reminder_picker
        };

        button.add_css_class (Granite.STYLE_CLASS_FLAT);

        attach (button, 0, 0);
        update_request ();

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