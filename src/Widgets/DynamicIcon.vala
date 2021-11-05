public class Widgets.DynamicIcon : Gtk.EventBox {
    public string icon_name { get; set; }
    public int size { get; set; }
    public bool dark { get; set; default = true; }
    
    private Gtk.Image icon;
    private Granite.Settings granite_settings;

    construct {
        granite_settings = Granite.Settings.get_default ();

        icon = new Gtk.Image () {
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

        granite_settings.notify["prefers-color-scheme"].connect (() => {
            generate_icon ();
        });
    }

    private void generate_icon () {
        if (icon_name != null && dark) {
            bool is_dark = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
            icon.gicon = new ThemedIcon ("%s-%s".printf (icon_name, is_dark ? "dark" : "light"));   
        } else {
            icon.gicon = new ThemedIcon (icon_name);
        }
    }
}