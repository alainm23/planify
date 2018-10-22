public class Widgets.ModelButton : Gtk.Button {
    public string icon { get; construct; }
    public string text { get; construct; }
    public string tooltip { get; construct; }

    public ModelButton (string _text, string _icon, string _tooltip) {
        Object (
            icon: _icon,
            text: _text,
            tooltip: _tooltip,
            expand: true
        );
    }

    construct {
        get_style_context ().remove_class ("button");
        get_style_context ().add_class ("menuitem");

        tooltip_text = tooltip;
        var label = new Gtk.Label (text);
        var image = new Gtk.Image.from_icon_name (icon, Gtk.IconSize.SMALL_TOOLBAR);

        var grid = new Gtk.Grid ();
        grid.column_spacing = 6;
        grid.add (image);
        grid.add (label);

        add (grid);
    }
}
