public class Widgets.MenuItem : Gtk.MenuItem {
    private Gtk.Label item_label;
    private Gtk.Image item_image;

    public string icon {
        set {
            item_image.gicon = new ThemedIcon (value);
        }
    }
    public string tooltip {
        set {
            tooltip_text = value;
        }
    }
    public string text {
        set {
            item_label.label = value;
        }
    }
    

    public MenuItem (string text, string icon, string tooltip) {
        Object (
            icon: icon,
            text: text,
            tooltip: tooltip,
            expand: true
        );
    }

    construct {
        get_style_context ().add_class ("track-options");

        item_image = new Gtk.Image ();
        item_image.get_style_context ().add_class ("dim-label");
        item_image.pixel_size = 16;

        item_label = new Gtk.Label (null);

        var grid = new Gtk.Grid ();
        grid.margin_start = 17;
        grid.column_spacing = 6;
        grid.add (item_image);
        grid.add (item_label);

        add (grid);
    }
}