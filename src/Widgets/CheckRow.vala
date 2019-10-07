public class Widgets.CheckRow : Gtk.ListBoxRow {
    public Objects.Check check { get; construct; }

    private Gtk.CheckButton checked_button;
    private Gtk.Entry content_entry;

    public signal void hide_item ();

    public CheckRow (Objects.Check check) {
        Object (
            check: check
        );
    }

    construct {
        can_focus = false;
        get_style_context ().add_class ("item-row");

        checked_button = new Gtk.CheckButton ();
        checked_button.margin_start = 6;
        checked_button.can_focus = false;
        checked_button.valign = Gtk.Align.CENTER;
        checked_button.halign = Gtk.Align.CENTER;
        checked_button.get_style_context ().add_class ("checklist-button");

        if (check.checked == 1) {
            checked_button.active = true;
            get_style_context ().add_class ("dim-label");
        } else {
            checked_button.active = false;
        }

        content_entry = new Gtk.Entry ();
        content_entry.margin_bottom = 1;
        content_entry.placeholder_text = _("Task name");
        content_entry.get_style_context ().add_class ("flat");
        content_entry.get_style_context ().add_class ("check-entry");
        content_entry.text = check.content;
        content_entry.hexpand = true;

        var delete_button = new Gtk.Button.from_icon_name ("window-close-symbolic");
        delete_button.valign = Gtk.Align.CENTER;
        delete_button.can_focus = false;
        delete_button.get_style_context ().add_class ("flat");
        delete_button.get_style_context ().add_class ("delete-check-button");

        var delete_revealer = new Gtk.Revealer ();
        delete_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
        delete_revealer.add (delete_button);

        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        box.get_style_context ().add_class ("transition");
        box.hexpand = true;
        box.margin_top = 3;
        box.margin_bottom = 2;
        box.pack_start (checked_button, false, false, 0);
        box.pack_start (content_entry, false, true, 6);
        box.pack_end (delete_revealer, false, true, 0);

        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.hexpand = true;
        main_box.pack_start (separator, false, false, 0);
        main_box.pack_start (box, false, false, 0);

        var handle = new Gtk.EventBox ();
        handle.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        handle.expand = true;
        handle.above_child = false;
        handle.add (main_box);

        add (handle);

        handle.enter_notify_event.connect ((event) => {
            delete_revealer.reveal_child = true;
            delete_button.get_style_context ().add_class ("closed");

            return false;
        });

        handle.leave_notify_event.connect ((event) => {
            if (event.detail == Gdk.NotifyType.INFERIOR) {
                return false;
            }

            delete_revealer.reveal_child = false;
            delete_button.get_style_context ().remove_class ("closed");

            return false;
        });

        content_entry.changed.connect (() => {
            save ();
        }); 

        content_entry.key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                hide_item ();
            }

            return false;
        });

        content_entry.focus_out_event.connect (() => {
            box.get_style_context ().remove_class ("check-eventbox");
            return false;
        });

        content_entry.focus_in_event.connect (() => {
            box.get_style_context ().add_class ("check-eventbox");
            return false;
        });

        checked_button.toggled.connect (() => {
            if (checked_button.active) {
                get_style_context ().add_class ("dim-label");

                check.checked = 1;
                check.date_completed = new GLib.DateTime.now_local ().to_string ();
            } else {
                get_style_context ().remove_class ("dim-label");

                check.checked = 0;
                check.date_completed = "";
            }

            save ();
        });

        delete_button.clicked.connect (() => {
            Application.database.delete_check (check);
        });

        Application.database.check_deleted.connect ((c) => {
            if (check.id == c.id) {
                destroy ();
            }
        });
    }

    private void save () {
        check.content = content_entry.text;
        check.save ();
    }
}