public class Dialogs.ContextMenu.MenuItemSelector : Gtk.EventBox {
    public string title { get; construct; }
    public bool has_scroll { get; construct; }
    private Gtk.ListBox listbox;
    
    public signal void activate_item (Gtk.ListBoxRow row);
    
    public MenuItemSelector (string title, bool has_scroll = false) {
        Object (
            title: title,
            has_scroll: has_scroll,
            hexpand: true,
            can_focus: false
        );
    }

    construct {
        var menu_icon = new Widgets.DynamicIcon ();
        menu_icon.size = 19;
        menu_icon.update_icon_name ("chevron-right");

        var menu_title = new Gtk.Label (title);

        var arrow_icon = new Gtk.Image () {
            gicon = new ThemedIcon ("pan-end-symbolic"),
            pixel_size = 14
        };

        var arrow_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.END,
            hexpand = true,
            can_focus = false,
            image = arrow_icon,
        };

        unowned Gtk.StyleContext arrow_button_context = arrow_button.get_style_context ();
        arrow_button_context.add_class (Gtk.STYLE_CLASS_FLAT);
        arrow_button_context.add_class ("no-padding");
        arrow_button_context.add_class ("hidden-button");
        arrow_button_context.add_class ("dim-label");

        var itemselector_grid = new Gtk.Grid () {
            column_spacing = 6,
            hexpand = true
        };

        itemselector_grid.add (menu_icon);
        itemselector_grid.add (menu_title);
        itemselector_grid.add (arrow_button);

        var itemselector_button = new Gtk.Button () {
            can_focus = false
        };
        itemselector_button.add (itemselector_grid);

        unowned Gtk.StyleContext projectselector_context = itemselector_button.get_style_context ();
        projectselector_context.add_class ("menu-item");
        projectselector_context.add_class ("flat");
        projectselector_context.add_class ("transition");

        listbox = new Gtk.ListBox () {
            valign = Gtk.Align.START,
            activate_on_single_click = true,
            selection_mode = Gtk.SelectionMode.SINGLE,
            expand = true
        };

        unowned Gtk.StyleContext listbox_context = listbox.get_style_context ();
        listbox_context.add_class ("listbox-background");

        var listbox_grid = new Gtk.Grid () {
            margin_start = 12
        };
        listbox_grid.add (listbox);

        Gtk.ScrolledWindow listbox_scrolled;
        if (has_scroll) {
            listbox_scrolled = new Gtk.ScrolledWindow (null, null) {
                hscrollbar_policy = Gtk.PolicyType.NEVER,
                expand = true,
                height_request = 128
            };
            listbox_scrolled.expand = true;
            listbox_scrolled.add (listbox_grid);
        }

        var listbox_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };
        
        if (has_scroll) {
            listbox_revealer.add (listbox_scrolled);
        } else {
            listbox_revealer.add (listbox_grid);
        }

        var main_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            hexpand = true
        };

        main_grid.add (itemselector_button);
        main_grid.add (listbox_revealer);

        add (main_grid);

        itemselector_button.clicked.connect (() => {
            listbox_revealer.reveal_child = !listbox_revealer.reveal_child;
            if (listbox_revealer.reveal_child) {
                arrow_button.get_style_context ().add_class ("opened");
            } else {
                arrow_button.get_style_context ().remove_class ("opened");
            }
        });

        listbox.row_activated.connect ((row) => {
            activate_item (row);
        });
    }

    public void add_item (Gtk.Widget row, int position=-1) {
        listbox.insert (row, position);
        listbox.show_all ();
    }
}