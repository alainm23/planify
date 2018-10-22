public class Widgets.CheckRow : Gtk.ListBoxRow {
    public Gtk.CheckButton checked_button;
    public Gtk.Entry name_entry;
    public Gtk.Label name_label;

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

        checked_button = new Gtk.CheckButton ();
        checked_button.valign = Gtk.Align.CENTER;
        checked_button.halign = Gtk.Align.CENTER;
        checked_button.active = checked;
        checked_button.get_style_context ().add_class ("planner-radio");

        name_label = new Gtk.Label (checklist_name);
        name_label.halign = Gtk.Align.START;
        name_label.hexpand = true;
        name_label.use_markup = true;
        name_label.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);

        var name_eventbox = new Gtk.EventBox ();
        name_eventbox.margin_start = 3;
        name_eventbox.margin_bottom = 1;
        name_eventbox.add (name_label);

        name_entry = new Gtk.Entry ();
        name_entry.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        name_entry.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        name_entry.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);
        name_entry.get_style_context ().add_class ("planner-entry");
        name_entry.get_style_context ().add_class ("no-padding");
        name_entry.hexpand = true;
        name_entry.no_show_all = true;
        name_entry.margin_bottom = 1;
        name_entry.margin_start = 3;
        name_entry.max_length = 50;
        name_entry.text = checklist_name;
        name_entry.placeholder_text = _("Checklist");

        var remove_button = new Gtk.Button.from_icon_name ("window-close-symbolic", Gtk.IconSize.MENU);
        remove_button.can_focus = false;
        remove_button.focus_on_click = false;
        remove_button.valign = Gtk.Align.CENTER;
        remove_button.halign = Gtk.Align.CENTER;
        remove_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var remove_revealer = new Gtk.Revealer ();
        remove_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        remove_revealer.add (remove_button);
        remove_revealer.reveal_child = false;

        var main_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        main_box.expand = true;

        main_box.pack_start (checked_button, false, false, 0);
        main_box.pack_start (name_entry, true, true, 6);
        main_box.pack_start (name_eventbox, true, true, 6);
        main_box.pack_end (remove_revealer, false, false, 0);

        var eventbox = new Gtk.EventBox ();
        eventbox.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        eventbox.add (main_box);

        add (eventbox);

        eventbox.enter_notify_event.connect ((event) => {
            remove_revealer.reveal_child = true;
            return false;
        });


        eventbox.leave_notify_event.connect ((event) => {
            if (event.detail == Gdk.NotifyType.INFERIOR) {
                return false;
            }

            remove_revealer.reveal_child = false;
            return false;
        });

        name_eventbox.event.connect ((event) => {
            if (event.type == Gdk.EventType.BUTTON_PRESS) {
                name_eventbox.visible = false;
                name_entry.visible = true;

                Timeout.add (200, () => {
				    name_entry.grab_focus ();
				    return false;
			    });
            }

            return false;
        });

        name_entry.focus_out_event.connect (() => {
            name_eventbox.visible = true;
            name_entry.visible = false;
            return false;
        });

        name_entry.changed.connect (() => {
            name_label.label = name_entry.text;
        });

        checked_button.toggled.connect (() => {
            check_task_completed ();
		});

        remove_button.clicked.connect (() => {
            Timeout.add (25, () => {
                this.opacity = this.opacity - 0.1;

                if (this.opacity <= 0) {
                    destroy ();
                    return false;
                }

                return true;
            });
        });
    }

    private void check_task_completed () {
        if (checked_button.active) {
            name_label.label = "<s>%s</s>".printf(name_label.label);
        } else {
            name_label.label = name_entry.text;
        }
    }
}
