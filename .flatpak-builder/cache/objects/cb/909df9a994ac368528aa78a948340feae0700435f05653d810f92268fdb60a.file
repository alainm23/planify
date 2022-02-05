public class Dialogs.ContextMenu.MenuItem : Gtk.Button {
    public string title { get; construct; }
    public string icon_name { get; construct; }

    private Widgets.DynamicIcon menu_icon;
    private Gtk.Label menu_title;
    private Gtk.Label secondary_label;
    private Gtk.Revealer loading_revealer;

    public signal void activate_item ();

    public string secondary_text {
        set {
            secondary_label.label = value;
        }
    }

    bool _is_loading;
    public bool is_loading {
        get {
            return _is_loading;
        }

        set {
            loading_revealer.reveal_child = value;
            _is_loading = value;
        }
    }

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
        menu_item_context.add_class (Gtk.STYLE_CLASS_FLAT);

        menu_icon = new Widgets.DynamicIcon ();
        menu_icon.size = 19;
        menu_icon.update_icon_name (icon_name);

        menu_title = new Gtk.Label (title);

        secondary_label = new Gtk.Label (null) {
            hexpand = true,
            halign = Gtk.Align.END,
            margin_end = 6
        };

        unowned Gtk.StyleContext secondary_label_context = secondary_label.get_style_context ();
        secondary_label_context.add_class (Granite.STYLE_CLASS_SMALL_LABEL);

        var loading_spinner = new Gtk.Spinner () {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER,
            margin_end = 3
        };
        loading_spinner.get_style_context ().add_class ("submit-spinner");
        loading_spinner.start ();

        loading_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT
        };
        loading_revealer.add (loading_spinner);

        var main_grid = new Gtk.Grid () {
            column_spacing = 6,
            hexpand = true
        };

        main_grid.add (menu_icon);
        main_grid.add (menu_title);
        main_grid.add (secondary_label);
        main_grid.add (loading_revealer);

        add (main_grid);

        clicked.connect (() => {
            activate_item ();
        });
    }
}