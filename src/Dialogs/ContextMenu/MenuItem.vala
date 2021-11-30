public class Dialogs.ContextMenu.MenuItem : Gtk.Button {
    public string title { get; construct; }
    public string icon_name { get; construct; }

    private Widgets.DynamicIcon menu_icon;
    private Gtk.Label menu_title;

    public signal void activate_item ();

    public MenuItem (string title, string icon_name) {
        Object (
            title: title,
            icon_name: icon_name,
            hexpand: true,
            can_focus: false
        );
    }

    construct {
        unowned Gtk.StyleContext menu_item_context = get_style_context ();
        menu_item_context.add_class ("menu-item");
        menu_item_context.add_class ("flat");

        menu_icon = new Widgets.DynamicIcon ();
        menu_icon.size = 19;
        menu_icon.update_icon_name (icon_name);

        menu_title = new Gtk.Label (title);

        var main_grid = new Gtk.Grid () {
            column_spacing = 6,
            hexpand = true
        };

        main_grid.add (menu_icon);
        main_grid.add (menu_title);

        add (main_grid);

        clicked.connect (() => {
            activate_item ();
        });
    }
}