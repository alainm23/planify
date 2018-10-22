public class Widgets.ItemRow : Gtk.ListBoxRow {
    public string icon_name  { get; construct; }
    public string item_name { get; construct; }
    public Gtk.Label number_label;

    public ItemRow (string _name, string _icon) {
        Object (
            icon_name: _icon,
            item_name: _name,
            margin_left: 6,
            margin_top: 6,
            margin_right: 6
        );
    }

    construct {
        get_style_context ().add_class ("item-row");

        var icon = new Gtk.Image.from_icon_name (icon_name, Gtk.IconSize.LARGE_TOOLBAR);

        var title_name = new Gtk.Label ("<b>" + item_name + "</b>");
        title_name.use_markup = true;

        number_label = new Gtk.Label (null);
        number_label.valign = Gtk.Align.CENTER;
        number_label.margin_end = 6;
        //number_label.get_style_context ().add_class (Granite.STYLE_CLASS_BADGE);

        var main_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        main_box.margin = 6;

        main_box.pack_start (icon, false, false, 0);
        main_box.pack_start (title_name, false, false, 12);
        main_box.pack_end (number_label, false, false, 0);

        add (main_box);
    }
}
