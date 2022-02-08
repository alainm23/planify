public class Widgets.Placeholder : Gtk.EventBox {
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
        placeholder_image.size = 64;

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
            margin_bottom = 64
        };

        main_grid.add (placeholder_image);
        main_grid.add (title_label);
        main_grid.add (description_label);

        add (main_grid);
    }
}