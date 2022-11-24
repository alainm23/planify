public class Dialogs.ContextMenu.MenuSeparator : Gtk.Grid {
    construct {
        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
            margin_top = 6,
            margin_bottom = 6,
            hexpand = true
        };

        attach (separator, 0, 0);
    }
}