public class Widgets.DynamicIcon : Gtk.Grid {
    public string icon_name { get; set; default = null; }
    public int size { get; set; default = 16; }
    
    private Gtk.Image icon;

    public DynamicIcon () {
        Object(
            halign: Gtk.Align.CENTER,
            valign: Gtk.Align.CENTER
        );
    }

    construct {
        icon = new Gtk.Image () {
            halign = Gtk.Align.CENTER,
            valign = Gtk.Align.CENTER
        };

        attach (icon, 0, 0, 1, 1);

        notify["size"].connect (() => {
            generate_icon ();
        });

        Services.EventBus.get_default ().theme_changed.connect (() => {
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

        bool dark_mode = Services.Settings.get_default ().settings.get_boolean ("dark-mode");
        if (Services.Settings.get_default ().settings.get_boolean ("system-appearance")) {
            dark_mode = Granite.Settings.get_default ().prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
        }
        
        if (Util.get_default ().is_dynamic_icon (icon_name)) {
            icon.gicon = new ThemedIcon ("%s-%s".printf (
                icon_name, dark_mode ? "dark" : "light"
            ));  
            icon.pixel_size = size; 
        } else {
            icon.gicon = new ThemedIcon (icon_name);
            icon.pixel_size = size;
        }
    }
}