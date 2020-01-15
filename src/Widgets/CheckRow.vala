public class Widgets.CheckRow : Gtk.ListBoxRow {
    public Objects.Item item { get; construct; }

    private Gtk.CheckButton checked_button;
    private Gtk.Entry content_entry;

    private uint checked_timeout = 0;

    public signal void hide_item ();

    public CheckRow (Objects.Item item) {
        Object (
            item: item
        );
    }

    construct {
        tooltip_text = item.content;
        can_focus = false;
        get_style_context ().add_class ("item-row");

        checked_button = new Gtk.CheckButton ();
        checked_button.margin_start = 6;
        checked_button.can_focus = false;
        checked_button.valign = Gtk.Align.CENTER;
        checked_button.halign = Gtk.Align.CENTER;
        checked_button.get_style_context ().add_class ("checklist-button");
        checked_button.get_style_context ().add_class ("checklist-check");

        content_entry = new Gtk.Entry ();
        content_entry.placeholder_text = _("Task name");
        content_entry.get_style_context ().add_class ("flat");
        content_entry.get_style_context ().add_class ("check-entry");
        content_entry.get_style_context ().add_class ("active");
        //content_entry.get_style_context ().add_class ("label");
        content_entry.margin_bottom = 2;
        content_entry.text = item.content;
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

        var main_revealer = new Gtk.Revealer ();
        main_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
        main_revealer.reveal_child = true;
        main_revealer.add (handle);

        add (main_revealer);

        if (item.checked == 1) {
            checked_button.active = true;
        } else {
            checked_button.active = false;
        }

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
            return false;
        });

        content_entry.focus_in_event.connect (() => {
            return false;
        });

        checked_button.toggled.connect (() => {
            if (checked_button.active) {
                item.checked = 1;
                item.date_completed = new GLib.DateTime.now_local ().to_string ();

                Planner.database.update_item_completed (item);
                if (item.is_todoist == 1) {
                    Planner.todoist.item_complete (item);
                }
            } else {
                item.checked = 0;
                item.date_completed = "";

                Planner.database.update_item_completed (item);
                if (item.is_todoist == 1) {
                    Planner.todoist.item_uncomplete (item);
                }
            }
        });

        delete_button.clicked.connect (() => {
            Planner.database.delete_item (item);
            if (item.is_todoist == 1) {
                Planner.todoist.add_delete_item (item);
            }
        });

        Planner.database.item_deleted.connect ((i) => {
            if (item.id == i.id) {
                destroy ();
            }
        });

        Planner.database.item_id_updated.connect ((current_id, new_id) => {
            Idle.add (() => {
                if (item.id == current_id) {
                    item.id = new_id;
                }

                return false;
            });
        });

        Planner.database.project_id_updated.connect ((current_id, new_id) => {
            Idle.add (() => {
                if (item.project_id == current_id) {
                    item.project_id = new_id;
                }

                return false;
            });
        });

        Planner.database.section_id_updated.connect ((current_id, new_id) => {
            Idle.add (() => {
                if (item.section_id == current_id) {
                    item.section_id = new_id;
                }

                return false;
            });
        });
    }

    private void save () {
        item.content = content_entry.text;
        tooltip_text = item.content;
        
        item.save ();
    }
}