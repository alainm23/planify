public class Widgets.LabelRow : Gtk.ListBoxRow {
    public weak MainWindow window { get; construct; }
    public Objects.Label label { get; construct; }

    public const string COLOR_CSS = """
        .label-list-%i {
            color: %s;
            background-color: %s;
            border-radius: 6px;
            padding: 2px;
        }
    """;
    public LabelRow (Objects.Label _label) {
        Object (
            label: _label
        );
    }

    construct {
        get_style_context ().add_class ("item-row");
        can_focus = true;

        var icon_label = new Gtk.Image.from_icon_name ("planner-label-symbolic", Gtk.IconSize.MENU);
        icon_label.valign = Gtk.Align.CENTER;
        icon_label.get_style_context ().add_class ("label-list-%i".printf (label.id));

        var name_label = new Gtk.Label ("<b>%s</b>".printf(label.name));
        name_label.ellipsize = Pango.EllipsizeMode.END;
        name_label.valign = Gtk.Align.CENTER;
        name_label.halign = Gtk.Align.START;
        name_label.use_markup = true;

        var edit_button = new Gtk.Button.from_icon_name ("edit-symbolic", Gtk.IconSize.MENU);
        edit_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var remove_button = new Gtk.Button.from_icon_name ("user-trash-symbolic", Gtk.IconSize.MENU);
        remove_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var action_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        //action_box.pack_start (edit_button, false, false, 0);
        action_box.pack_start (remove_button, false, false, 0);

        var action_revealer = new Gtk.Revealer ();
        action_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        action_revealer.add (action_box);
        action_revealer.reveal_child = false;

        var main_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        main_box.hexpand = true;
        main_box.margin = 3;
        main_box.pack_start (icon_label, false, false, 3);
        main_box.pack_start (name_label, true, true, 6);
        main_box.pack_end (action_revealer, false, false, 0);

        var eventbox = new Gtk.EventBox ();
        eventbox.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        eventbox.add (main_box);

        add (eventbox);

        var provider = new Gtk.CssProvider ();

        try {
            var colored_css = COLOR_CSS.printf (
                label.id,
                Planner.utils.convert_invert (label.color),
                label.color
            );
            provider.load_from_data (colored_css, colored_css.length);

            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (GLib.Error e) {
            return;
        }

        eventbox.enter_notify_event.connect ((event) => {
            action_revealer.reveal_child = true;
            return false;
        });

        eventbox.leave_notify_event.connect ((event) => {
            if (event.detail == Gdk.NotifyType.INFERIOR) {
                return false;
            }

            action_revealer.reveal_child = false;
            return false;
        });

        remove_button.clicked.connect (() => {
            var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (
                _("Are you sure you want to delete this project?"),
                _("It contains 26 elements that are also deleted, this operation can be undone"),
                "dialog-warning",
            Gtk.ButtonsType.CANCEL);
            message_dialog.transient_for = window;

            var remove = new Gtk.Button.with_label (_("Remove"));
            remove.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
            message_dialog.add_action_widget (remove, Gtk.ResponseType.ACCEPT);

            message_dialog.show_all ();
            if (message_dialog.run () == Gtk.ResponseType.ACCEPT) {
                if (Planner.database.remove_label (label) == Sqlite.DONE) {
                    destroy ();
                }
            }

            message_dialog.destroy ();
        });
    }
}
