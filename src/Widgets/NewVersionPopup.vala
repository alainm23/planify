public class Widgets.NewVersionPopup : Adw.Bin {
    private Gtk.Label version_label;
    private Gtk.Label description_label;
    private Gtk.Image star_icon;
    private string _version;

    public signal void dismissed ();

    public string version {
        get {
            return _version;
        }
        set {
            _version = value;
            version_label.label = "v" + value;
        }
    }

    public string description {
        set {
            description_label.label = value;
        }
    }

    public void show_with_animation () {
        star_icon.add_css_class ("fancy-bounce-turn-animation");
        
        Timeout.add (800, () => {
            star_icon.remove_css_class ("fancy-bounce-turn-animation");
            return Source.REMOVE;
        });
    }

    construct {
        star_icon = new Gtk.Image.from_icon_name ("star-outline-thick-symbolic") {
            valign = CENTER,
            pixel_size = 32
        };
        star_icon.add_css_class ("view-icon");
        Util.get_default ().set_widget_color ("#3584e4", star_icon);

        var title_label = new Gtk.Label (_("New version available!")) {
            halign = START,
            valign = END,
            xalign = 0
        };
        title_label.add_css_class ("font-bold");

        version_label = new Gtk.Label (null) {
            halign = START,
            valign = START,
            xalign = 0
        };
        version_label.add_css_class ("dimmed");
        version_label.add_css_class ("caption");

        var header_grid = new Gtk.Grid () {
            column_spacing = 6,
            row_spacing = 3
        };

        header_grid.attach (star_icon, 0, 0, 1, 2);
        header_grid.attach (title_label, 1, 0, 1, 1);
        header_grid.attach (version_label, 1, 1, 1, 1);

        description_label = new Gtk.Label (_("Update now to enjoy the latest improvements, bug fixes, and new features that make Planify even better")) {
            wrap = true,
            margin_top = 6,
            xalign = 0
        };
        description_label.add_css_class ("dimmed");

        var update_button = new Gtk.Button.with_label (_("Update Now")) {
            hexpand = true,
            margin_top = 6
        };
        update_button.add_css_class ("suggested-action");

        update_button.clicked.connect (() => {
            try {
                AppInfo.launch_default_for_uri (Constants.FLATHUB_URL, null);
            } catch (Error e) {
                warning ("Error opening URL: %s", e.message);
            }

            dismissed ();
        });

        var content_box = new Gtk.Box (VERTICAL, 6);
        content_box.append (header_grid);
        content_box.append (description_label);
        content_box.append (update_button);

        var card = new Adw.Bin () {
            margin_top = 12,
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 12,
            child = content_box
        };
        card.add_css_class ("card");
        card.add_css_class ("version-popup");

        var close_button = new Gtk.Button () {
            child = new Gtk.Image.from_icon_name ("cross-large-circle-filled-symbolic") {
                pixel_size = 20
            },
            halign = END,
            valign = START,
            tooltip_text = _("Close")
        };
        close_button.add_css_class ("flat");
        close_button.add_css_class ("circular");

        close_button.clicked.connect (() => {
            dismissed ();
        });

        var overlay = new Gtk.Overlay () {
            child = card
        };
        overlay.add_overlay (close_button);

        child = overlay;
    }
}