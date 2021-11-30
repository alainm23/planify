public class Widgets.DynamicIcon : Gtk.EventBox {
    public string icon_name { get; set; default = "planner-inbox"; }
    public int size { get; set; default = 16; }
    public bool dark { get; set; default = true; }
    
    private Gtk.Image icon;

    construct {
        icon = new Gtk.Image () {
            pixel_size = size,
            gicon = new ThemedIcon (icon_name),
            halign = Gtk.Align.CENTER,
            valign = Gtk.Align.CENTER
        };

        add (icon);

        notify["icon_name"].connect (() => {
            generate_icon ();
        });

        notify["size"].connect (() => {
            icon.pixel_size = size;
        });

        Planner.event_bus.theme_changed.connect ((is_dark) => {
            generate_icon (is_dark);
        });
    }

    public void update_icon_name (string icon_name) {
        this.icon_name = icon_name;
        generate_icon ();
    }

    private void generate_icon (bool is_dark=Planner.settings.get_enum ("appearance") != 1) {
        if (icon_name == null) {
            return;
        }

        if (dark) {
            icon.gicon = new ThemedIcon ("%s-%s".printf (icon_name, is_dark ? "dark" : "light"));   
        } else {
            icon.gicon = new ThemedIcon (icon_name);
        }
    }
}
