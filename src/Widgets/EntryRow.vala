public class Widgets.EntryRow : Gtk.Grid {
    public Gtk.Entry entry;
    
    public string lines { get; construct; }

    public EntryRow (string lines = "inset") {
        Object(
            margin_start: 6,
            margin_top: 3,
            margin_end: 6,
            lines: lines
        );
    }

    construct {
        entry = new Gtk.Entry () {
            placeholder_text = _("Give your project a name")
        };

        entry.add_css_class (Granite.STYLE_CLASS_FLAT);

        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);

        var v_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
            hexpand = true
        };

        v_box.append(entry);
        v_box.append(separator);

        attach(v_box, 0, 0);
    }
}