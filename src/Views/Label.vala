public class Views.Label : Gtk.Grid {
    Objects.Label _label;
    public Objects.Label label {
        get {
            return _label;
        }

        set {
            _label = value;
            update_request ();
            add_items ();
        }
    }

    public Gee.HashMap <string, Layouts.ItemRow> items;
    private Gtk.ListBox listbox;
    private Gtk.Grid widget_color;
    private Gtk.Label title_label;
    private Gtk.Stack listbox_stack;

    private bool has_items {
        get {
            return items.size > 0;
        }
    }

    construct {
        items = new Gee.HashMap <string, Layouts.ItemRow> ();

        var sidebar_image = new Widgets.DynamicIcon ();
        sidebar_image.size = 19;

        if (Planner.settings.get_boolean ("slim-mode")) {
            sidebar_image.update_icon_name ("sidebar-left");
        } else {
            sidebar_image.update_icon_name ("sidebar-right");
        }
        
        var sidebar_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER
        };

        sidebar_button.add_css_class (Granite.STYLE_CLASS_FLAT);
        sidebar_button.child = sidebar_image;

        widget_color = new Gtk.Grid () {
            valign = Gtk.Align.CENTER,
            height_request = 16,
            width_request = 16
        };

        unowned Gtk.StyleContext widget_color_context = widget_color.get_style_context ();
        widget_color_context.add_class ("label-color");

        title_label = new Gtk.Label (null) {
            margin_bottom = 3
        };
        title_label.get_style_context ().add_class ("header-title");

        // Menu Button
        var menu_image = new Widgets.DynamicIcon ();
        menu_image.size = 21;
        menu_image.update_icon_name ("dots-horizontal");
        
        var menu_button = new Gtk.MenuButton () {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER
            // popover = build_context_menu ()
        };

        menu_button.child = menu_image;
        menu_button.add_css_class (Granite.STYLE_CLASS_FLAT);

        // Add Button
        var add_image = new Widgets.DynamicIcon ();
        add_image.size = 21;
        add_image.update_icon_name ("planner-plus-circle");
        
        var add_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER,
            tooltip_text = _("Add Tasks")
        };

        add_button.child = add_image;
        add_button.add_css_class (Granite.STYLE_CLASS_FLAT);

        // Search Icon
        var search_image = new Widgets.DynamicIcon ();
        search_image.size = 19;
        search_image.update_icon_name ("planner-search");
        
        var search_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER
        };

        search_button.add_css_class (Granite.STYLE_CLASS_FLAT);
        search_button.child = search_image;

        var headerbar = new Adw.HeaderBar () {
            title_widget = new Gtk.Label (null),
            hexpand = true
        };

        headerbar.add_css_class ("flat");
        headerbar.pack_start (sidebar_button);
        headerbar.pack_start (widget_color);
        headerbar.pack_start (title_label);
        headerbar.pack_end (menu_button);
        headerbar.pack_end (search_button);
        headerbar.pack_end (new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
            margin_start = 3,
            margin_end = 3,
            opacity = 0
        });
        // headerbar.pack_end (add_button);
        //  headerbar.pack_end (new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
        //      margin_start = 3,
        //      margin_end = 3,
        //      opacity = 0
        //  });

        listbox = new Gtk.ListBox () {
            valign = Gtk.Align.START,
            activate_on_single_click = true,
            selection_mode = Gtk.SelectionMode.SINGLE,
            hexpand = true
        };

        listbox.add_css_class ("listbox-background");

        var listbox_grid = new Gtk.Grid () {
            margin_top = 20
        };

        listbox_grid.attach (listbox, 0, 0);

        var listbox_placeholder = new Widgets.Placeholder (
            _("No to-dos for this filter yet."), "planner-check-circle"
        );

        listbox_stack = new Gtk.Stack () {
            vexpand = true,
            hexpand = true,
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };

        listbox_stack.add_named (listbox_grid, "listbox");
        listbox_stack.add_named (listbox_placeholder, "placeholder");


        var content = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            hexpand = true,
            vexpand = true
        };

        content.append (listbox_stack);

        var content_clamp = new Adw.Clamp () {
            maximum_size = 720
        };

        content_clamp.child = content;

        var scrolled_window = new Gtk.ScrolledWindow () {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            hexpand = true,
            vexpand = true
        };

        scrolled_window.child = content_clamp;

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            hexpand = true,
            vexpand = true
        };

        content_box.append (headerbar);
        content_box.append (scrolled_window);

        attach (content_box, 0, 0);

        Timeout.add (listbox_stack.transition_duration, () => {
            validate_placeholder ();
            return GLib.Source.REMOVE;
        });

        Services.Database.get_default ().item_added.connect (valid_add_item);
        Services.Database.get_default ().item_deleted.connect (valid_delete_item);
        Services.Database.get_default ().item_updated.connect (valid_update_item);

        scrolled_window.vadjustment.value_changed.connect (() => {
            if (scrolled_window.vadjustment.value > 50) {
                Planner.event_bus.view_header (true);
            } else {
                Planner.event_bus.view_header (false);
            }
        });

        add_button.clicked.connect (() => {
            // prepare_new_item ();
        });

        search_button.clicked.connect (() => {
            var dialog = new Dialogs.QuickFind.QuickFind ();
            dialog.show ();
        });

        sidebar_button.clicked.connect (() => {
            Planner._instance.main_window.show_hide_sidebar ();
        });
    }

    private void validate_placeholder () {
        listbox_stack.visible_child_name = has_items ? "listbox" : "placeholder";
    }

    private void valid_add_item (Objects.Item item, bool insert = true) {
        if (!items.has_key (item.id_string) && item.labels.has_key (label.id_string)
            && insert) {
            add_item (item);   
        }

        validate_placeholder ();
    }

    private void valid_delete_item (Objects.Item item) {
        if (items.has_key (item.id_string)) {
            items[item.id_string].hide_destroy ();
            items.unset (item.id_string);
        }

        validate_placeholder ();
    }

    private void valid_update_item (Objects.Item item) {
        if (items.has_key (item.id_string) && !item.labels.has_key (label.id_string)) {
            items[item.id_string].hide_destroy ();
            items.unset (item.id_string);
        }

        valid_add_item (item);
    }

    private void add_items () {        
        foreach (Layouts.ItemRow row in items.values) {
            listbox.remove (row);
        }

        items.clear ();

        foreach (Objects.Item item in Services.Database.get_default ().get_items_by_label (label, false)) {
            add_item (item);
        }

        validate_placeholder ();
    }

    private void add_item (Objects.Item item) {
        items [item.id_string] = new Layouts.ItemRow (item);
        listbox.append (items [item.id_string]);
    }

    public void update_request () { 
        title_label.label = label.name;
        Util.get_default ().set_widget_color (Util.get_default ().get_color (label.color), widget_color);
    }
}