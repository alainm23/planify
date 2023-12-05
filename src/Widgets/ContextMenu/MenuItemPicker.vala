public class Widgets.ContextMenu.MenuItemPicker : Gtk.Grid {
    public string title {
        set {
            menu_title.label = value;
        }
    }

    public string icon {
        set {
            if (value != null) {
                menu_icon_revealer.reveal_child = true;
                menu_icon.update_icon_name (value);
            } else {
                menu_icon_revealer.reveal_child = false;
            }
        }
    }

    public bool has_scroll { get; construct; }

    private Widgets.DynamicIcon menu_icon;
    private Gtk.Revealer menu_icon_revealer;
    private Gtk.Label menu_title;
    private Gtk.ListBox listbox;
    
    public signal void activate_item (Gtk.ListBoxRow row);
    
    public MenuItemPicker (string title, string? icon = null, bool has_scroll = false) {
        Object (
            title: title,
            icon: icon,
            has_scroll: has_scroll,
            hexpand: true,
            can_focus: false
        );
    }

    construct {
        menu_icon = new Widgets.DynamicIcon () {
            valign = Gtk.Align.CENTER
        };
        menu_icon.size = 16;

        menu_icon_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT,
            reveal_child = true
        };
        
        menu_icon_revealer.child = menu_icon;

        menu_title = new Gtk.Label (null);
        menu_title.use_markup = true;

        var arrow_icon = new Gtk.Image () {
            gicon = new ThemedIcon ("pan-end-symbolic"),
            pixel_size = 14
        };

        var arrow_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.END,
            hexpand = true,
            can_focus = false
        };

        arrow_button.child = arrow_icon;
        arrow_button.add_css_class (Granite.STYLE_CLASS_FLAT);
        arrow_button.add_css_class ("no-padding");
        arrow_button.add_css_class ("hidden-button");
        arrow_button.add_css_class ("dim-label");

        var itemselector_grid = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            hexpand = true
        };

        itemselector_grid.append (menu_icon_revealer);
        itemselector_grid.append (menu_title);
        itemselector_grid.append (arrow_button);

        var itemselector_button = new Gtk.Button ();
        itemselector_button.child = itemselector_grid;
        itemselector_button.add_css_class (Granite.STYLE_CLASS_FLAT);
        itemselector_button.add_css_class ("transition");

        listbox = new Gtk.ListBox () {
            valign = Gtk.Align.START,
            activate_on_single_click = true,
            selection_mode = Gtk.SelectionMode.SINGLE,
            hexpand = true
        };

        listbox.add_css_class ("listbox-background");

        var listbox_grid = new Gtk.Grid () {
            margin_start = 12
        };
        listbox_grid.attach (listbox, 0, 0);

        Gtk.ScrolledWindow listbox_scrolled;
        if (has_scroll) {
            listbox_scrolled = new Gtk.ScrolledWindow () {
                hscrollbar_policy = Gtk.PolicyType.NEVER,
                hexpand = true,
                vexpand = true,
                height_request = 128
            };
            listbox_scrolled.child = listbox_grid;
        }

        var listbox_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };
        
        if (has_scroll) {
            listbox_revealer.child = listbox_scrolled;
        } else {
            listbox_revealer.child = listbox_grid;
        }

        var main_grid = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            hexpand = true
        };

        main_grid.append (itemselector_button);
        main_grid.append (listbox_revealer);

        attach (main_grid, 0, 0);

        itemselector_button.clicked.connect (() => {
            listbox_revealer.reveal_child = !listbox_revealer.reveal_child;
            if (listbox_revealer.reveal_child) {
                arrow_button.add_css_class ("opened");
            } else {
                arrow_button.remove_css_class ("opened");
            }
        });

        listbox.row_activated.connect ((row) => {
            activate_item (row);
        });
    }

    public void add_item (Gtk.Widget row, int position = -1) {
        listbox.insert (row, position);
    }
}