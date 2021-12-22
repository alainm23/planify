public class Widgets.DynamicIcon : Gtk.EventBox {
    public string icon_name { get; set; default = null; }
    public int size { get; set; default = 16; }
    
    private Gtk.Image icon;

    construct {
        icon = new Gtk.Image () {
            halign = Gtk.Align.CENTER,
            valign = Gtk.Align.CENTER
        };

        add (icon);

        notify["size"].connect (() => {
            generate_icon ();
        });

        // Planner.settings.changed.connect ((key) => {
        //     if (key == "appearance") {
        //         generate_icon ();
        //     }
        // });

        Planner.event_bus.theme_changed.connect (() => {
            generate_icon ();
        });
    }

    public void update_icon_name (string icon_name) {
        this.icon_name = icon_name;
        generate_icon ();
    }

    private void generate_icon () {
        if (icon_name == null) {
            return;
        }

        if (Util.get_default ().is_dynamic_icon (icon_name)) {
            icon.gicon = new ThemedIcon ("%s-%s".printf (
                icon_name, Planner.settings.get_enum ("appearance") != 0 ? "dark" : "light"
            ));  
            icon.pixel_size = size; 
        } else {
            icon.gicon = new ThemedIcon (icon_name);
            icon.pixel_size = size;
        }
    }
}
