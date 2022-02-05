public class Dialogs.Settings.SettingsHeader : Hdy.HeaderBar {
    public string title_header { get; construct; }
    public bool show_back_button { get; construct; }

    public signal void done_activated ();
    public signal void back_activated ();

    public SettingsHeader (string title_header, bool show_back_button = true) {
        Object (
            title_header: title_header,
            show_back_button: show_back_button
        );
    }

    construct {
        get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var back_image = new Widgets.DynamicIcon ();
        back_image.size = 19;
        back_image.update_icon_name ("chevron-left");

        var back_label = new Gtk.Label (_("Back"));

        var back_grid = new Gtk.Grid () {
            column_spacing = 3
        };

        back_grid.add (back_image);
        back_grid.add (back_label);

        var back_button = new Gtk.Button () {
            can_focus = false,
            valign = Gtk.Align.CENTER
        };

        back_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        back_button.add (back_grid);

        var title_label = new Gtk.Label (title_header);
        title_label.get_style_context ().add_class (Gtk.STYLE_CLASS_TITLE);

        var done_button = new Gtk.Button.with_label (_("Done")) {
            can_focus = false
        };
        done_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            margin = 3,
            hexpand = true
        };

        if (show_back_button) {
            header_box.pack_start (back_button, false, false, 0);
        }
        
        header_box.set_center_widget (title_label);
        header_box.pack_end (done_button, false, false, 0);

        set_custom_title (header_box);

        done_button.clicked.connect (() => {
            done_activated ();
        });

        back_button.clicked.connect (() => {
            back_activated ();
        });
    }
}
