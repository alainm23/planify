public class Views.Pinboard : Gtk.EventBox {
    public Gee.HashMap <string, Layouts.ItemRow> items;
    private Gtk.ListBox listbox;
    private Gtk.Stack listbox_stack;

    private bool has_items {
        get {
            return listbox.get_children ().length () > 0;
        }
    }

    construct {
        items = new Gee.HashMap <string, Layouts.ItemRow> ();

        var pin_icon = new Gtk.Image () {
            gicon = new ThemedIcon ("planner-pin-tack"),
            pixel_size = 24
        };

        var title_label = new Gtk.Label (_("Pinboard"));
        title_label.get_style_context ().add_class ("header-title");

        var menu_image = new Widgets.DynamicIcon ();
        menu_image.size = 19;
        menu_image.update_icon_name ("dots-horizontal");
        
        var menu_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            can_focus = false
        };

        menu_button.add (menu_image);
        menu_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var search_image = new Widgets.DynamicIcon ();
        search_image.size = 19;
        search_image.update_icon_name ("planner-search");
        
        var search_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            can_focus = false
        };
        search_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        search_button.add (search_image);
        search_button.clicked.connect (Util.get_default ().open_quick_find);
        
        var header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            valign = Gtk.Align.START,
            hexpand = true,
            margin_start = 20,
            margin_end = 6
        };

        header_box.pack_start (pin_icon, false, false, 0);
        header_box.pack_start (title_label, false, false, 6);
        header_box.pack_end (search_button, false, false, 0);

        var magic_button = new Widgets.MagicButton ();

        listbox = new Gtk.ListBox () {
            valign = Gtk.Align.START,
            activate_on_single_click = true,
            selection_mode = Gtk.SelectionMode.SINGLE,
            hexpand = true
        };

        unowned Gtk.StyleContext listbox_context = listbox.get_style_context ();
        listbox_context.add_class ("listbox-background");

        var listbox_grid = new Gtk.Grid () {
            margin_top = 6
        };
        listbox_grid.add (listbox);

        var listbox_placeholder = new Widgets.Placeholder (
            _("Pinboard"), _("No tasks with this filter at the moment"), "planner-pin-tack");

        listbox_stack = new Gtk.Stack () {
            expand = true,
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };

        listbox_stack.add_named (listbox_grid, "listbox");
        listbox_stack.add_named (listbox_placeholder, "placeholder");

        var content = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            expand = true,
            margin_start = 16,
            margin_end = 36,
            margin_bottom = 36,
            margin_top = 6
        };
        content.add (header_box);
        content.add (listbox_stack);

        var content_clamp = new Hdy.Clamp () {
            maximum_size = 720
        };

        content_clamp.add (content);

        var scrolled_window = new Gtk.ScrolledWindow (null, null) {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            expand = true
        };
        scrolled_window.add (content_clamp);
        var overlay = new Gtk.Overlay () {
            expand = true
        };
        overlay.add_overlay (magic_button);
        overlay.add (scrolled_window);

        add (overlay);
        add_items ();
        show_all ();

        Timeout.add (listbox_stack.transition_duration, () => {
            validate_placeholder ();
            return GLib.Source.REMOVE;
        });

        magic_button.clicked.connect (() => {
            prepare_new_item ();
        });

        Planner.database.item_added.connect (valid_add_item);
        Planner.database.item_deleted.connect (valid_delete_item);
        Planner.database.item_updated.connect (valid_update_item);

        Planner.event_bus.item_moved.connect ((item) => {
            if (items.has_key (item.id_string)) {
                items[item.id_string].update_request ();
            }
        });

        listbox.add.connect (() => {
            validate_placeholder ();
        });

        listbox.remove.connect (() => {
            validate_placeholder ();
        });

        scrolled_window.vadjustment.value_changed.connect (() => {
            if (scrolled_window.vadjustment.value > 20) {
                Planner.event_bus.view_header (true);
            } else {
                Planner.event_bus.view_header (false);
            }
        });
    }

    private void validate_placeholder () {
        listbox_stack.visible_child_name = has_items ? "listbox" : "placeholder";
    }

    public void prepare_new_item (string content = "") {
        Planner.event_bus.item_selected (null);

        var row = new Layouts.ItemRow.for_project (
            Planner.database.get_project (Planner.settings.get_int64 ("inbox-project-id"))
        );

        row.update_content (content);
        row.update_priority (Util.get_default ().get_default_priority ());
        row.update_pinned (true);
        
        row.item_added.connect (() => {
            item_added (row);
        });

        listbox.add (row);
        listbox.show_all ();
    }

    private void item_added (Layouts.ItemRow row) {
        bool insert = !row.item.pinned;

        if (!insert) {
            valid_add_itemrow (row);
            row.update_inserted_item ();
        }

        if (row.item.section_id != Constants.INACTIVE) {
            Planner.database.get_section (row.item.section_id)
                .add_item_if_not_exists (row.item);
        } else {
            Planner.database.get_project (row.item.project_id)
                .add_item_if_not_exists (row.item);
        }

        if (insert) {
            row.hide_destroy ();
        }
    }

    private void valid_add_itemrow (Layouts.ItemRow row) {
        if (!items.has_key (row.item.id_string) && row.item.pinned) {
            items [row.item.id_string] = row;
            listbox.add (items [row.item.id_string]);
            listbox.show_all ();
        }
    }

    private void valid_add_item (Objects.Item item, bool insert = true) {        
        if (!items.has_key (item.id_string) && item.pinned && !item.checked) {
            add_item (item);   
        }
    }

    private void valid_delete_item (Objects.Item item) {
        if (items.has_key (item.id_string)) {
            items[item.id_string].hide_destroy ();
            items.unset (item.id_string);
        }
    }

    private void valid_update_item (Objects.Item item) {
        if (items.has_key (item.id_string) && (!item.pinned || item.checked)) {
            items[item.id_string].hide_destroy ();
            items.unset (item.id_string);
        }

        valid_add_item (item);
    }

    private void add_items () {
        foreach (Objects.Item item in Planner.database.get_items_pinned (false)) {
            add_item (item);
        }
    }

    private void add_item (Objects.Item item) {
        items [item.id_string] = new Layouts.ItemRow (item);
        listbox.add (items [item.id_string]);
        listbox.show_all ();
    }
}
