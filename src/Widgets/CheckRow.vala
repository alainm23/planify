public class Widgets.CheckRow : Gtk.ListBoxRow {
    public Gtk.CheckButton checked_button;
    public Gtk.Entry name_entry;

    public string checklist_name { get; construct; }
    public bool checked { get; construct; }

    public CheckRow (string _name, bool _checked) {
        Object (
            checklist_name: _name,
            checked: _checked
        );
    }

    public string get_check () {
        string val;

        if (checked_button.active) {
            val = "1";
        } else {
            val = "0";
        }

        return val + name_entry.text + ";";
    }

    construct {
        get_style_context ().add_class ("task");
        tooltip_text = checklist_name;

        checked_button = new Gtk.CheckButton ();
        checked_button.valign = Gtk.Align.CENTER;
        checked_button.halign = Gtk.Align.CENTER;
        checked_button.active = checked;
        checked_button.get_style_context ().add_class ("planner-radio");

        name_entry = new Gtk.Entry ();
        name_entry.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        name_entry.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        name_entry.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);
        name_entry.get_style_context ().add_class ("planner-entry");
        name_entry.get_style_context ().add_class ("no-padding");
        name_entry.hexpand = true;
        name_entry.margin_bottom = 1;
        name_entry.margin_start = 3;
        name_entry.text = Application.utils.first_letter_to_up (checklist_name);
        name_entry.placeholder_text = _("Checklist");


        var remove_button = new Gtk.Button.from_icon_name ("window-close-symbolic", Gtk.IconSize.MENU);
        remove_button.can_focus = false;
        remove_button.focus_on_click = false;
        remove_button.valign = Gtk.Align.CENTER;
        remove_button.halign = Gtk.Align.CENTER;
        remove_button.get_style_context ().add_class ("button-overlay-circular");
        remove_button.get_style_context ().add_class ("planner-button-no-focus");

        var remove_revealer = new Gtk.Revealer ();
        remove_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
        remove_revealer.add (remove_button);
        remove_revealer.reveal_child = false;

        var main_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        main_box.expand = true;

        main_box.pack_start (checked_button, false, false, 0);
        main_box.pack_start (name_entry, true, true, 6);
        main_box.pack_end (remove_revealer, false, false, 0);

        var eventbox = new Gtk.EventBox ();
        eventbox.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        eventbox.add (main_box);

        add (eventbox);
        check_task_completed ();

        eventbox.enter_notify_event.connect ((event) => {
            remove_revealer.reveal_child = true;
            remove_button.get_style_context ().add_class ("closed");
            return false;
        });

        name_entry.changed.connect (() => {
            name_entry.text = Application.utils.first_letter_to_up (name_entry.text);
        });

        eventbox.leave_notify_event.connect ((event) => {
            if (event.detail == Gdk.NotifyType.INFERIOR) {
                return false;
            }

            remove_button.get_style_context ().remove_class ("closed");
            remove_revealer.reveal_child = false;
            return false;
        });

        checked_button.toggled.connect (() => {
            check_task_completed ();
		});

        remove_button.clicked.connect (() => {
            destroy ();
        });
    }

    private void check_task_completed () {
        if (checked_button.active) {
            name_entry.opacity = 0.7;
        } else {
            name_entry.opacity = 1;
        }
    }
}
