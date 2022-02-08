public class Dialogs.ContextMenu.MenuSwitch : Gtk.Button {
    public string title { get; construct; }
    public string icon_name { get; construct; }

    private Widgets.DynamicIcon menu_icon;
    private Gtk.Label menu_title;
    private Gtk.Switch menu_switch;

    public bool active {
        get {
            return !menu_switch.active;
        }

        set {
            menu_switch.active = value;
        }
    }

    public signal void activate_item ();

    public MenuSwitch (string title, string icon_name, bool active) {
        Object (
            title: title,
            icon_name: icon_name,
            active: active,
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

        menu_switch = new Gtk.Switch () {
            hexpand = true,
            halign = Gtk.Align.END,
            can_focus = false
        };
        menu_switch.get_style_context ().add_class ("planner-switch");

        var main_grid = new Gtk.Grid () {
            column_spacing = 6,
            hexpand = true
        };

        main_grid.add (menu_icon);
        main_grid.add (menu_title);
        main_grid.add (menu_switch);

        add (main_grid);

        button_release_event.connect (() => {
            menu_switch.activate ();
            activate_item ();     
            return Gdk.EVENT_STOP;
        });
    }
}
