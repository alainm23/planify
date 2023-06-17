public class Widgets.SettingsHeader : Gtk.Grid {
    public string title_header { get; construct; }
    public bool show_back_button { get; construct; }

    public signal void done_activated ();
    public signal void back_activated ();

    public SettingsHeader (string title_header, bool show_back_button = true) {
        Object (
            title_header: title_header,
            show_back_button: show_back_button,
            hexpand: true
        );
    }

    construct {
        var back_image = new Widgets.DynamicIcon ();
        back_image.size = 19;
        back_image.update_icon_name ("chevron-left");

        var back_label = new Gtk.Label (_("Back"));

        var back_grid = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3);
        back_grid.append (back_image);
        back_grid.append (back_label);

        var back_button = new Gtk.Button () {
            can_focus = false,
            valign = Gtk.Align.CENTER
        };

        back_button.add_css_class (Granite.STYLE_CLASS_FLAT);
        back_button.add_css_class ("no-padding");
        back_button.child = back_grid;

        var title_label = new Gtk.Label (title_header);
        title_label.add_css_class (Granite.STYLE_CLASS_TITLE_LABEL);

        var content_box = new Gtk.CenterBox () {
            hexpand = true,
            margin_end = 6,
            margin_top = 6,
            margin_bottom = 6
        };

        if (show_back_button) {
            content_box.set_start_widget (back_button);
        }
        
        content_box.set_center_widget (title_label);

        attach (content_box, 0, 0);

        back_button.clicked.connect (() => {
            back_activated ();
        });
    }
}