public class Widgets.Popovers.NotificationActionPopover : Gtk.Popover {
    private Gtk.Label title_label;
    private Gtk.Label description_label;
    private Gtk.Image image;

    public NotificationActionPopover (Gtk.Widget relative) {
        Object (
            relative_to: relative,
            modal: false,
            position: Gtk.PositionType.BOTTOM
        );
    }

    construct {
        image = new Gtk.Image ();
        image.valign = Gtk.Align.START;

        title_label = new Gtk.Label (null);
        title_label.halign = Gtk.Align.START;
        title_label.use_markup = true;
        title_label.max_width_chars = 40;
        title_label.wrap = true;
        title_label.wrap_mode = Pango.WrapMode.WORD_CHAR;
        title_label.xalign = 0;

        description_label = new Gtk.Label (null);
        description_label.halign = Gtk.Align.START;
        description_label.use_markup = true;

        var close_button = new Gtk.Button.from_icon_name ("window-close-symbolic", Gtk.IconSize.MENU);
        close_button.can_focus = false;
        close_button.valign = Gtk.Align.CENTER;
        close_button.halign = Gtk.Align.CENTER;
        close_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var main_grid = new Gtk.Grid ();
        main_grid.margin = 6;
        main_grid.column_spacing = 12;

        main_grid.attach (image, 0, 0, 1, 2);
        main_grid.attach (title_label, 1, 0, 1, 1);
        main_grid.attach (description_label, 1, 1, 1, 1);
        main_grid.attach (close_button, 2, 0, 2, 2);

        var eventbox = new Gtk.EventBox ();
        eventbox.expand = true;
        eventbox.add (main_grid);

        add (eventbox);

        close_button.clicked.connect (() => {
            popdown ();
        });

        eventbox.event.connect ((event) => {
            if (event.type == Gdk.EventType.BUTTON_PRESS) {
                popdown ();
            }

            return false;
        });
    }

    public void send_local_notification (string title, string description, string icon_name) {
        title_label.label = "<b>%s</b>".printf (title);

        description_label.label = description;

        image.gicon = new ThemedIcon (icon_name);
        image.pixel_size = 32;
        image.no_show_all = false;

        Timeout.add (500, () => {
            popup ();
            show_all ();
            return false;
        });

        Timeout.add_seconds (5, () => {
            popdown ();
            return false;
        });
    }
}
