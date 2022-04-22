public class Dialogs.Settings.SettingsSelect : Gtk.EventBox {
    public string title { get; construct; }
    public Gee.ArrayList<string> items { get; construct; }

    private Gtk.Label title_label;
    private Gtk.Label selected_label;

    public signal void activated (int active);

    int _selected_index = 0;
    public int selected_index {
        set {
            _selected_index = value;
            selected_label.label = items [_selected_index];
        }

        get {
            return _selected_index;
        }
    }

    public SettingsSelect (string title, Gee.ArrayList<string> items) {
        Object (
            title: title,
            items: items
        );
    }

    construct {
        hexpand = true;

        title_label = new Gtk.Label (title) {
            halign = Gtk.Align.START
        };

        selected_label = new Gtk.Label (null) {
            halign = Gtk.Align.START
        };

        selected_label.get_style_context ().add_class (Granite.STYLE_CLASS_SMALL_LABEL);
        selected_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        var forward_image = new Widgets.DynamicIcon ();
        forward_image.size = 19;
        forward_image.update_icon_name ("chevron-right");
        forward_image.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        var main_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            margin = 3
        };

        main_box.pack_start (title_label, false, true, 0);
        main_box.pack_end (forward_image, false, false, 0);
        main_box.pack_end (selected_label, false, false, 6);

        add (main_box);

        var popover_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            margin = 3,
            row_spacing = 3
        };

        var popover = new Gtk.Popover (forward_image) {
            position = Gtk.PositionType.BOTTOM
        };
        popover.add (popover_grid);
        
        foreach (string item in items) {
            var menu_item = new Dialogs.ContextMenu.MenuItem (item, null);
            
            menu_item.clicked.connect (() => {
                popover.popdown ();
                activated (items.index_of (item));
            });

            popover_grid.add (menu_item);
        }

        popover_grid.show_all ();

        button_press_event.connect ((sender, evt) => {
            if (evt.type == Gdk.EventType.BUTTON_PRESS && evt.button == 1) {
                popover.popup ();
            }

            return Gdk.EVENT_PROPAGATE;
        });
    }
}
