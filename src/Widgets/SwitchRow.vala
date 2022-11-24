public class Widgets.SwitchRow : Gtk.Grid {
    public string title { get; construct; }
    public string icon_name { get; construct; }
    public string lines { get; construct; }

    public Gtk.Switch enabled_switch;

    public signal void activated (bool active);

    public bool active {
        set {
            enabled_switch.active = value;
        }

        get {
            return enabled_switch.active;
        }
    }
    
    public SwitchRow (string title, string icon_name, string lines = "inset") {
        Object(
            margin_start: 6,
            margin_top: 6,
            margin_end: 6,
            title: title,
            icon_name: icon_name,
            lines: lines
        );
    }

    construct {
        var item_image = new Widgets.DynamicIcon ();
        item_image.size = 24;
        item_image.update_icon_name(icon_name);

        var item_title = new Gtk.Label (title);

        enabled_switch = new Gtk.Switch () {
            hexpand = true, 
            halign = Gtk.Align.END
        };

        var h_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);

        h_box.append(item_image);
        h_box.append(item_title);
        h_box.append(enabled_switch);

        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
            margin_top = 3
        };

        var v_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);

        v_box.append (h_box);
        v_box.append (separator);

        attach (v_box, 0, 0);

        if (lines == "none") {
            separator.visible = false;
        }

        enabled_switch.notify["active"].connect ((val) => {
            activated (active);
        });
    }
}