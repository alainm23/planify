public class Widgets.MenuItem : Gtk.MenuItem {
    private Gtk.Label _label;
    private Gtk.Image _image;

    public string icon {
        set {
            _image.gicon = new ThemedIcon (value);
        }
    }
    public string tooltip {
        set {
            tooltip_text = value;
        }
    }
    public string text {
        set {
            _label.label = value;
        }
    }
    

    public MenuItem (string _text, string _icon, string _tooltip) {
        Object (
            icon: _icon,
            text: _text,
            tooltip: _tooltip,
            expand: true
        );
    }

    construct {
        get_style_context ().add_class ("track-options");

        _label = new Gtk.Label (null);

        _image = new Gtk.Image ();
        _image.get_style_context ().add_class ("dim-label");
        _image.pixel_size = 16;
        
        var grid = new Gtk.Grid ();
        grid.column_spacing = 6;
        grid.add (_image);
        grid.add (_label);

        add (grid);
    }
}