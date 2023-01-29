

public class Widgets.Placeholder : Gtk.Grid {
    private Widgets.DynamicIcon placeholder_image;
    private Gtk.Label title_label;
    private Gtk.Label description_label;

    public string? title {
        set {
            title_label.label = value;
        }

        get {
            return title_label.label;
        }
    }

    public string description {
        set {
            description_label.label = value;
        }

        get {
            return description_label.label;
        }
    }

    public string icon {
        set {
            placeholder_image.update_icon_name (value);
        }
    }

    public Placeholder (string? title, string description, string icon) {
        Object (
            title: title,
            description: description,
            icon: icon
        );
    }

    construct {
        placeholder_image = new Widgets.DynamicIcon () {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER
        };

        placeholder_image.size = 84;

        title_label = new Gtk.Label (null) {
            wrap = true
        };
        title_label.get_style_context ().add_class ("h2");
        title_label.get_style_context ().add_class ("font-bold");

        description_label = new Gtk.Label (null) {
            wrap = true
        };
        description_label.get_style_context ().add_class ("dim-label");

        var main_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            row_spacing = 6,
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER,
            margin_bottom = 64,
            vexpand = true,
            hexpand = true
        };

        main_grid.attach (placeholder_image, 0, 0);
        main_grid.attach (title_label, 0, 1);
        main_grid.attach (description_label, 0, 2);

        attach (main_grid, 0, 0);
    }
}