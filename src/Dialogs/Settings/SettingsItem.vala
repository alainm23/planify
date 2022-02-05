public class Dialogs.Settings.SettingsItem : Gtk.EventBox {
    private Gtk.Image item_icon;
    private Gtk.Label title_label;
    private Gtk.Label description_label;

    string _icon;
    public string icon {
        get {
            return _icon;
        }

        set {
            _icon = value;
            item_icon.gicon = new ThemedIcon (_icon);
        }
    }

    string _title;
    public string title {
        get {
            return _title;
        }
        set {
            _title = value;
            title_label.label = _title;
        }
    }

    string _description;
    public string description {
        get {
            return _description;
        }
        set {
            _description = value;
            description_label.label = _description;
        }
    }

    public signal void activated ();

    public SettingsItem (string icon, string title, string description) {
        Object (
            icon: icon,
            title: title,
            description: description,
            hexpand: true
        );
    }

    construct {
        item_icon = new Gtk.Image () {
            pixel_size = 27
        };

        title_label = new Gtk.Label (null) {
            halign = Gtk.Align.START,
            valign = Gtk.Align.END
        };

        description_label = new Gtk.Label (null) {
            halign = Gtk.Align.START,
            valign = Gtk.Align.START,
            wrap = true,
            xalign = 0
        };

        description_label.get_style_context ().add_class (Granite.STYLE_CLASS_SMALL_LABEL);
        description_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        var forward_image = new Widgets.DynamicIcon () {
            hexpand = true,
            halign = Gtk.Align.END,
            margin_end = 6
        };
        forward_image.size = 19;
        forward_image.update_icon_name ("chevron-right");
        forward_image.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        var main_grid = new Gtk.Grid () {
            column_spacing = 6,
            row_homogeneous = true
        };

        main_grid.attach (item_icon, 0, 0, 1, 2);
        main_grid.attach (title_label, 1, 0, 1, 1);
        main_grid.attach (description_label, 1, 1, 1, 1);
        main_grid.attach (forward_image, 2, 0, 2, 2);

        add (main_grid);

        button_press_event.connect ((sender, evt) => {
            if (evt.type == Gdk.EventType.BUTTON_PRESS && evt.button == 1) {
                activated ();
            }

            return false;
        });
    }
}