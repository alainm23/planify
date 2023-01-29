public class Widgets.ReminderButton : Gtk.Button {
    public Objects.Item item { get; construct; }

    private Gtk.Label badge_label;
    private Gtk.Revealer badge_revealer;

    private Widgets.ReminderPicker.ReminderPicker reminder_picker;

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
        add_css_class (Granite.STYLE_CLASS_FLAT);
        add_css_class ("p3");

        var button_image = new Widgets.DynamicIcon ();
        button_image.size = 19;
        button_image.update_icon_name ("planner-bell");

        badge_label = new Gtk.Label (null);
        badge_label.get_style_context ().add_class (Granite.STYLE_CLASS_DIM_LABEL);

        badge_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT
        };

        badge_revealer.child = badge_label;

        var button_grid = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            valign = Gtk.Align.CENTER
        };

        button_grid.append (button_image);
        button_grid.append (badge_revealer);

        child = button_grid;
        update_request ();

        var gesture = new Gtk.GestureClick ();
        gesture.set_button (1);
        add_controller (gesture);

        gesture.pressed.connect ((n_press, x, y) => {
            gesture.set_state (Gtk.EventSequenceState.CLAIMED);

            if (reminder_picker == null) {
                reminder_picker = new Widgets.ReminderPicker.ReminderPicker (item);
                reminder_picker.set_parent (this);
            }
            
            reminder_picker.popup ();
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