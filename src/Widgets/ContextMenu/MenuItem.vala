public class Widgets.ContextMenu.MenuItem : Gtk.Button {
    public string title {
        set {
            menu_title.label = value;
        }
    }

    public string icon {
        set {
            if (value != null) {
                menu_icon.update_icon_name (value);
            }
        }
    }

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

    public MenuItem (string title, string icon) {
        Object (
            title: title,
            icon: icon,
            hexpand: true,
            can_focus: false
        );
    }

    construct {
        add_css_class (Granite.STYLE_CLASS_FLAT);

        menu_icon = new Widgets.DynamicIcon () {
            valign = Gtk.Align.CENTER
        };
        menu_icon.size = 19;
        
        menu_title = new Gtk.Label (null);

        secondary_label = new Gtk.Label (null) {
            hexpand = true,
            halign = Gtk.Align.END,
            margin_end = 0
        };

        unowned Gtk.StyleContext secondary_label_context = secondary_label.get_style_context ();
        secondary_label_context.add_class (Granite.STYLE_CLASS_SMALL_LABEL);

        var loading_spinner = new Gtk.Spinner () {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER
        };
        loading_spinner.get_style_context ().add_class ("submit-spinner");
        loading_spinner.start ();

        loading_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT
        };
        loading_revealer.child = loading_spinner;

        var content_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            hexpand = true
        };

        content_box.append (menu_icon);
        content_box.append (menu_title);
        content_box.append (secondary_label);
        content_box.append (loading_revealer);

        child = content_box;

        clicked.connect (() => {
            activate_item ();
        });
    }
}