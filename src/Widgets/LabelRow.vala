public class Widgets.LabelRow : Gtk.ListBoxRow {
    public weak MainWindow window { get; construct; }
    public Objects.Label label { get; construct; }

    public const string COLOR_CSS = """
        .label-list-%i {
            background-image:
              linear-gradient(
                    to bottom,
                    shade (
                    %s,
                        1.3
                    ),
                    %s
                );
            border: 1px solid shade (%s, 0.9);
            border-radius: 6px;
            box-shadow:
                inset 0 0 0 1px alpha (#fff, 0.05),
                inset 0 1px 0 0 alpha (#fff, 0.25),
                inset 0 -1px 0 0 alpha (#fff, 0.1),
                0 1px 2px alpha (#000, 0.3);
            margin: 2px;
        }
    """;
    public LabelRow (Objects.Label _label) {
        Object (
            label: _label
        );
    }

    construct {
        can_focus = true;

        var label_color = new Gtk.Label (null);
        label_color.get_style_context ().add_class ("label-list-%i".printf (label.id));
        label_color.valign = Gtk.Align.CENTER;

        label_color.width_request = 32;

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
        action_box.halign = Gtk.Align.END;
        action_box.hexpand = true;
        action_box.pack_start (edit_button, false, false, 0);
        action_box.pack_start (remove_button, false, false, 0);

        var action_revealer = new Gtk.Revealer ();
        action_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        action_revealer.add (action_box);
        action_revealer.reveal_child = false;

        var main_grid = new Gtk.Grid ();
        main_grid.column_spacing = 12;
        main_grid.row_spacing = 3;
        main_grid.margin = 6;

        main_grid.add (label_color);
        main_grid.add (name_label);
        main_grid.add (action_revealer);

        var eventbox = new Gtk.EventBox ();
        eventbox.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        eventbox.add (main_grid);

        add (eventbox);

        var provider = new Gtk.CssProvider ();

        try {
            var colored_css = COLOR_CSS.printf (label.id, label.color, label.color, label.color);
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
