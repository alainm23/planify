public class Dialogs.Settings.SettingsContent : Gtk.EventBox {
    public string? title { get; construct; }

    private Gtk.Grid content_grid;

    public SettingsContent (string? title) {
        Object (
            title: title,
            margin: 12,
            margin_top: 0
        );
    }

    construct {
        var title_label = new Gtk.Label (title) {
            halign = Gtk.Align.START
        };
        title_label.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);
        title_label.get_style_context ().add_class (Granite.STYLE_CLASS_SMALL_LABEL);

        content_grid = new Gtk.Grid () {
            row_spacing = 6,
            orientation = Gtk.Orientation.VERTICAL,
            height_request = 32,
            hexpand =  true
        };

        unowned Gtk.StyleContext content_grid_context = content_grid.get_style_context ();
        content_grid_context.add_class ("picker-content");

        var main_grid = new Gtk.Grid () {
            expand = true,
            orientation = Gtk.Orientation.VERTICAL
        };
        
        if (title != null) {
            main_grid.add (title_label);
        }
        main_grid.add (content_grid);

        add (main_grid);
    }

    public void add_child (Gtk.Widget child) {
        content_grid.add (child);
        content_grid.show_all ();
    }
}