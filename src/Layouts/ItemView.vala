public class Layouts.ItemView : Gtk.Grid {
    public ItemView () {
        Object (
            vexpand: true,
            width_request: 350,
            margin_end: 24,
            margin_bottom: 24,
            margin_start: 3,
            margin_top: 3
        );
    }

    construct {
        add_css_class ("card");
        add_css_class ("task-view");

        var close_button = new Gtk.Button.from_icon_name ("window-close-symbolic") {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER,
        };
        close_button.add_css_class ("close-button");

        var headerbox = new Gtk.Box (HORIZONTAL, 0) {
            hexpand = true,
            halign = Gtk.Align.END
        };
        headerbox.append (close_button);

        var content_box = new Gtk.Box (VERTICAL, 0) {
            margin_top = 12,
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 12,
            hexpand = true,
            vexpand =  true
        };

        content_box.append (headerbox);

        attach (content_box, 0, 0);

        close_button.clicked.connect (() => {
            Services.EventBus.get_default ().close_item_view ();
        });
    }
}
