

public class Widgets.Placeholder : Gtk.Grid {
    private Widgets.DynamicIcon placeholder_image;
    private Gtk.Label description_label;

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

    public Placeholder (string description, string icon) {
        Object (
            description: description,
            icon: icon
        );
    }

    construct {
        placeholder_image = new Widgets.DynamicIcon () {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER
        };
        placeholder_image.add_css_class ("icon-dropshadow");
        placeholder_image.size = 96;
        placeholder_image.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);

        description_label = new Gtk.Label (null) {
            wrap = true,
            max_width_chars = 24,
            justify = Gtk.Justification.CENTER
        };
        description_label.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);

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
        main_grid.attach (description_label, 0, 2);

        attach (main_grid, 0, 0);
    }
}