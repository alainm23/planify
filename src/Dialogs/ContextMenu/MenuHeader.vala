public class Dialogs.ContextMenu.MenuHeader : Gtk.EventBox {
    public string title { get; construct; }

    private Gtk.Label title_label;

    public MenuHeader (string title) {
        Object (
            title: title
        );
    }

    construct {
        title_label = new Gtk.Label (title) {
            halign = Gtk.Align.START,
            margin_start = 6
        };

        title_label.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);
        title_label.get_style_context ().add_class (Granite.STYLE_CLASS_SMALL_LABEL);

        add (title_label);
    }
}
