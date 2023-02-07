public class Views.Filter : Gtk.Grid {
    public Gee.HashMap <string, Layouts.ItemRow> items;

    private Widgets.DynamicIcon filter_icon;
    private Gtk.Label title_label;
    private Gtk.ListBox listbox;
    private Gtk.Stack listbox_stack;

    Objects.BaseObject _filter;
    public Objects.BaseObject filter {
        get {
            return _filter;
        }

        set {
            _filter = value;
            update_request ();
            add_items ();
        }
    }

    private bool has_items {
        get {
            return items.size > 0;
        }
    }

    construct {
        items = new Gee.HashMap <string, Layouts.ItemRow> ();

        filter_icon = new Widgets.DynamicIcon () {
            valign = Gtk.Align.CENTER
        };
        filter_icon.size = 32;

        title_label = new Gtk.Label (null);
        title_label.add_css_class ("header-title");

        var menu_image = new Widgets.DynamicIcon ();
        menu_image.size = 19;
        menu_image.update_icon_name ("dots-horizontal");
        
        var menu_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            can_focus = false
        };

        menu_button.child = menu_image;
        menu_button.add_css_class (Granite.STYLE_CLASS_FLAT);
        
        var header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            valign = Gtk.Align.START,
            hexpand = true,
            margin_top = 1
        };

        header_box.append (filter_icon);
        header_box.append (title_label);

        var magic_button = new Widgets.MagicButton ();

        listbox = new Gtk.ListBox () {
            valign = Gtk.Align.START,
            activate_on_single_click = true,
            selection_mode = Gtk.SelectionMode.SINGLE,
            hexpand = true
        };

        listbox.add_css_class ("listbox-background");

        var listbox_grid = new Gtk.Grid () {
            margin_top = 12
        };

        listbox_grid.attach (listbox, 0, 0);

        var listbox_placeholder = new Widgets.Placeholder (
            _("Pinboard"), _("No tasks with this filter at the moment"), "planner-pin-tack");

        listbox_stack = new Gtk.Stack () {
            hexpand = true,
            vexpand = true,
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };

        listbox_stack.add_named (listbox_grid, "listbox");
        listbox_stack.add_named (listbox_placeholder, "placeholder");

        var content = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            hexpand = true,
            vexpand = true
        };

        content.append (header_box);
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

        var overlay = new Gtk.Overlay () {
            hexpand = true,
            vexpand = true
        };

        // overlay.add_overlay (magic_button);
        overlay.child = scrolled_window;

        attach (overlay, 0, 0);
        add_items ();

        Timeout.add (listbox_stack.transition_duration, () => {
            // validate_placeholder ();
            return GLib.Source.REMOVE;
        });

        magic_button.clicked.connect (() => {
            // prepare_new_item ();
        });

        Services.Database.get_default ().item_added.connect (valid_add_item);
        Services.Database.get_default ().item_deleted.connect (valid_delete_item);
        Services.Database.get_default ().item_updated.connect (valid_update_item);
        Planner.event_bus.checked_toggled.connect (valid_checked_item);

        Planner.event_bus.item_moved.connect ((item) => {
            if (items.has_key (item.id_string)) {
                items[item.id_string].update_request ();
            }
        });

        //  scrolled_window.vadjustment.value_changed.connect (() => {
        //      if (scrolled_window.vadjustment.value > 20) {
        //          Planner.event_bus.view_header (true);
        //      } else {
        //          Planner.event_bus.view_header (false);
        //      }
        //  });
    }

    private void update_request () {
        if (filter is Objects.Priority) {
            Objects.Priority priority = ((Objects.Priority) filter);
            filter_icon.update_icon_name (Util.get_default ().get_priority_icon (priority.priority));
            title_label.label = priority.name;
            listbox.set_header_func (null);
            listbox_stack.margin_start = 3;
        } else if (filter is Objects.Completed) {
            filter_icon.update_icon_name ("planner-completed");
            title_label.label = _("Completed");
            listbox.set_header_func (header_completed_function);
            listbox_stack.margin_start = 6;
        }
    }

    private void add_items () {        
        foreach (Layouts.ItemRow row in items.values) {
            listbox.remove (row);
        }

        items.clear ();

        if (filter is Objects.Priority) {
            Objects.Priority priority = ((Objects.Priority) filter);
            foreach (Objects.Item item in Services.Database.get_default ().get_items_by_priority (priority.priority, false)) {
                add_item (item);
            }
        } else if (filter is Objects.Completed) {
            foreach (Objects.Item item in Services.Database.get_default ().get_items_completed ()) {
                add_item (item);
            }
        }
    }

    private void add_item (Objects.Item item) {
        items [item.id_string] = new Layouts.ItemRow (item);
        listbox.append (items [item.id_string]);
    }

    private void valid_add_item (Objects.Item item, bool insert = true) {
        if (filter is Objects.Priority) {
            Objects.Priority priority = ((Objects.Priority) filter);
            
            if (!items.has_key (item.id_string) && item.priority == priority.priority && insert) {
                add_item (item);   
            }
        } else if (filter is Objects.Completed) {
            if (!items.has_key (item.id_string) && item.checked && insert) {
                add_item (item);   
            }
        }
    }

    private void valid_delete_item (Objects.Item item) {
        if (items.has_key (item.id_string)) {
            items[item.id_string].hide_destroy ();
            items.unset (item.id_string);
        }
    }

    private void valid_update_item (Objects.Item item) {
        if (filter is Objects.Priority) {
            Objects.Priority priority = ((Objects.Priority) filter);

            if (items.has_key (item.id_string) && item.priority != priority.priority) {
                items[item.id_string].hide_destroy ();
                items.unset (item.id_string);
            }

            if (items.has_key (item.id_string) && !item.checked) {
                items[item.id_string].hide_destroy ();
                items.unset (item.id_string);
            }
    
            valid_add_item (item);
        } else if (filter is Objects.Completed) {
            if (items.has_key (item.id_string) && item.checked) {
                items[item.id_string].hide_destroy ();
                items.unset (item.id_string);
            }
    
            valid_add_item (item);
        }
    }

    private void valid_checked_item (Objects.Item item, bool old_checked) {
        if (filter is Objects.Priority) {
            if (!old_checked) { // -> False 
                if (items.has_key (item.id_string) && item.completed) {
                    items[item.id_string].hide_destroy ();
                    items.unset (item.id_string);
                }
            } else { // true ->
                valid_update_item (item);
            }
        } else if (filter is Objects.Completed) {
            if (!old_checked) { // -> False 
                valid_update_item (item);
            } else { // true ->
                if (items.has_key (item.id_string) && !item.completed) {
                    items[item.id_string].hide_destroy ();
                    items.unset (item.id_string);
                }
            }
        }
    }

    private void header_completed_function (Gtk.ListBoxRow lbrow, Gtk.ListBoxRow? lbbefore) {
        var row = (Layouts.ItemRow) lbrow;
        if (row.item.completed_at == "") {
            return;
        }

        if (lbbefore != null) {
            var before = (Layouts.ItemRow) lbbefore;
            var comp_before = Util.get_default ().get_date_from_string (before.item.completed_at);
            if (comp_before.compare (Util.get_default ().get_date_from_string (row.item.completed_at)) == 0) {
                return;
            }
        }

        var header_label = new Gtk.Label (Util.get_default ().get_relative_date_from_date (
            Util.get_default ().get_date_from_string (row.item.completed_at)
        ));
        header_label.get_style_context ().add_class ("font-bold");
        header_label.halign = Gtk.Align.START;

        var header_separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
            hexpand = true,
            margin_bottom = 6
        };

        var header_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
            margin_top = 16
        };
        header_box.append (header_label);
        header_box.append (header_separator);

        row.set_header (header_box);
    }
}