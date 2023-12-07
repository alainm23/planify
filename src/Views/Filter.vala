public class Views.Filter : Adw.Bin {
    private Layouts.HeaderBar headerbar;
    private Gtk.ListBox listbox;
    private Gtk.Grid listbox_grid;
    private Gtk.Stack listbox_stack;

    public Gee.HashMap <string, Layouts.ItemRow> items;

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

        headerbar = new Layouts.HeaderBar ();

        listbox = new Gtk.ListBox () {
            valign = Gtk.Align.START,
            activate_on_single_click = true,
            selection_mode = Gtk.SelectionMode.SINGLE,
            hexpand = true
        };

        listbox.add_css_class ("listbox-background");

        listbox_grid = new Gtk.Grid ();
        listbox_grid.attach (listbox, 0, 0);

        var listbox_placeholder = new Widgets.Placeholder (
            _("Press 'a' or tap the plus button to create a new to-do"), "planner-check-circle"
        );

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

        content.append (listbox_stack);

        var content_clamp = new Adw.Clamp () {
            maximum_size = 1024,
            tightening_threshold = 800,
            margin_start = 24,
            margin_end = 24
        };

        content_clamp.child = content;

        var scrolled_window = new Gtk.ScrolledWindow () {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            hexpand = true,
            vexpand = true
        };

        scrolled_window.child = content_clamp;

        var toolbar_view = new Adw.ToolbarView ();
		toolbar_view.add_top_bar (headerbar);
		toolbar_view.content = scrolled_window;

        child = toolbar_view;

        Timeout.add (listbox_stack.transition_duration, () => {
            validate_placeholder ();
            return GLib.Source.REMOVE;
        });

        Services.Database.get_default ().item_added.connect (valid_add_item);
        Services.Database.get_default ().item_deleted.connect (valid_delete_item);
        Services.Database.get_default ().item_updated.connect (valid_update_item);
        Services.EventBus.get_default ().checked_toggled.connect (valid_checked_item);

        Services.EventBus.get_default ().item_moved.connect ((item) => {
            if (items.has_key (item.id_string)) {
                items[item.id_string].update_request ();
            }
        });
    }

    private void update_request () {
        if (filter is Objects.Priority) {
            Objects.Priority priority = ((Objects.Priority) filter);
            headerbar.title = priority.name;
            listbox.set_header_func (null);
            listbox_grid.margin_top = 12;
        } else if (filter is Objects.Completed) {
            headerbar.title = _("Completed");
            listbox.set_header_func (header_completed_function);
            listbox_grid.margin_top = 0;
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

        validate_placeholder ();
    }

    private void valid_checked_item (Objects.Item item, bool old_checked) {
        if (filter is Objects.Priority) {
            if (!old_checked) {
                if (items.has_key (item.id_string) && item.completed) {
                    items[item.id_string].hide_destroy ();
                    items.unset (item.id_string);
                }
            } else {
                valid_update_item (item);
            }
        } else if (filter is Objects.Completed) {
            if (!old_checked) {
                valid_update_item (item);
            } else {
                if (items.has_key (item.id_string) && !item.completed) {
                    items[item.id_string].hide_destroy ();
                    items.unset (item.id_string);
                }
            }
        }

        validate_placeholder ();
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
        header_label.add_css_class ("font-bold");
        header_label.halign = Gtk.Align.START;
        header_label.margin_start = 3;

        var header_separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
            hexpand = true,
            margin_bottom = 6,
            margin_start = 3
        };

        var header_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
            margin_top = 12
        };
        header_box.append (header_label);
        header_box.append (header_separator);

        row.set_header (header_box);
    }

    private void validate_placeholder () {
        listbox_stack.visible_child_name = has_items ? "listbox" : "placeholder";
    }
}
