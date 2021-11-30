public class Dialogs.ContextMenu.MenuSeparator : Gtk.EventBox {
    construct {
        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
            margin_top = 6,
            margin_bottom = 6
        };

        add (separator);
    }
}