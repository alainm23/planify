public class Widgets.SettingsHeader : Adw.Bin {
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
        back_image.size = 16;
        back_image.update_icon_name ("go-previous-symbolic");

        // var back_label = new Gtk.Label (_("Back"));

        var back_grid = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3);
        back_grid.append (back_image);
        // back_grid.append (back_label);

        var back_button = new Gtk.Button () {
            can_focus = false,
            valign = Gtk.Align.CENTER,
            child = back_grid
        };

        back_button.add_css_class (Granite.STYLE_CLASS_FLAT);
        
        var title_label = new Gtk.Label (title_header);
        title_label.add_css_class (Granite.STYLE_CLASS_TITLE_LABEL);


        var headerbar = new Gtk.HeaderBar () {
			title_widget = title_label,
			show_title_buttons = true,
			hexpand = true
		};

        headerbar.add_css_class ("flat");

        if (show_back_button) {
            headerbar.pack_start (back_button);
        }

        child = headerbar;

        back_button.clicked.connect (() => {
            back_activated ();
        });
    }
}
