public class Widgets.ModelButton : Gtk.Button {
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
    
    public int color {
        set {
            if (value == 0) {
                var hour = new GLib.DateTime.now_local ().get_hour ();
                if (hour >= 18 || hour <= 6) {
                    item_image.get_style_context ().add_class ("today-night-icon");
                } else {
                    item_image.get_style_context ().add_class ("today-day-icon");
                }
            } else if (value == 1) {
                item_image.get_style_context ().add_class ("upcoming-icon");
            } else {
                item_image.get_style_context ().add_class ("due-clear");
            }
        }
    }

    public bool due_label {
        set {
            if (value) {
                item_label.get_style_context ().add_class ("due-label");
            }
        }
    }

    public ModelButton (string text, string icon, string tooltip = "") {
        Object (
            icon: icon,
            text: text,
            tooltip: tooltip,
            expand: true
        );
    }

    construct {
        get_style_context ().remove_class ("button");
        get_style_context ().add_class ("flat");
        get_style_context ().add_class ("menuitem");
        can_focus = false;

        item_image = new Gtk.Image ();
        item_image.valign = Gtk.Align.CENTER;
        item_image.halign = Gtk.Align.CENTER;
        item_image.pixel_size = 16;

        item_label = new Gtk.Label (null);

        var grid = new Gtk.Grid ();
        grid.column_spacing = 6;
        grid.add (item_image);
        grid.add (item_label);

        add (grid);
    }
}

public class Widgets.ImageMenuItem : Gtk.MenuItem {
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
    
    public int color {
        set {
            if (value == 0) {
                var hour = new GLib.DateTime.now_local ().get_hour ();
                if (hour >= 18 || hour <= 6) {
                    item_image.get_style_context ().add_class ("today-night-icon");
                } else {
                    item_image.get_style_context ().add_class ("today-day-icon");
                }
            } else if (value == 1) {
                item_image.get_style_context ().add_class ("upcoming-icon");
            } else {
                item_image.get_style_context ().add_class ("due-clear");
            }
        }
    }

    public bool due_label {
        set {
            if (value) {
                item_label.get_style_context ().add_class ("due-label");
            }
        }
    }

    public ImageMenuItem (string text, string icon, string tooltip = "") {
        Object (
            icon: icon,
            text: text,
            tooltip: tooltip,
            expand: true
        );
    }

    construct {
        get_style_context ().remove_class ("button");
        get_style_context ().add_class ("flat");
        get_style_context ().add_class ("menuitem");
        can_focus = false;

        item_image = new Gtk.Image ();
        item_image.valign = Gtk.Align.CENTER;
        item_image.halign = Gtk.Align.CENTER;
        item_image.pixel_size = 16;
        item_image.get_style_context ().add_class ("dim-label");

        item_label = new Gtk.Label (null);

        var grid = new Gtk.Grid ();
        grid.margin_start = 3;
        grid.column_spacing = 6;
        grid.add (item_image);
        grid.add (item_label);

        add (grid);
    }
}