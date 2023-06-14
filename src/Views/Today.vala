public class Views.Today : Gtk.Grid {
    private Widgets.EventsList event_list;

    private Gtk.ListBox listbox;
    private Gtk.Revealer today_revealer;
    private Gtk.ListBox overdue_listbox;
    private Gtk.Revealer overdue_revealer;
    private Gtk.Revealer event_list_revealer;
    private Gtk.Grid listbox_grid;
    private Gtk.ScrolledWindow scrolled_window;
    private Gtk.Stack listbox_placeholder_stack;

    public Gee.HashMap <string, Layouts.ItemRow> overdue_items;
    public Gee.HashMap <string, Layouts.ItemRow> items;

    public GLib.DateTime date { get; set; default = new GLib.DateTime.now_local (); }

    private bool overdue_has_children {
        get {
            return overdue_items.size > 0;
        }
    }

    private bool today_has_children {
        get {
            return items.size > 0;
        }
    }

    construct {
        overdue_items = new Gee.HashMap <string, Layouts.ItemRow> ();
        items = new Gee.HashMap <string, Layouts.ItemRow> ();
        
        var headerbar = new Widgets.FilterHeader (Objects.Today.get_default ());

        event_list = new Widgets.EventsList.for_day (date) {
            margin_top = 12
        };

        event_list_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            reveal_child = event_list.has_items
        };

        event_list_revealer.child = event_list;
        
        event_list.change.connect (() => {
            event_list_revealer.reveal_child = event_list.has_items;
        });

        var magic_button = new Widgets.MagicButton ();

        var overdue_label = new Gtk.Label (_("Overdue")) {
            halign = Gtk.Align.START,
            valign = Gtk.Align.CENTER,
            hexpand = true
        };

        overdue_label.add_css_class ("font-bold");
        
        var reschedule_button = new Gtk.Button.with_label (_("Reschedule")) {
            hexpand = true,
            halign = Gtk.Align.END
        };

        reschedule_button.add_css_class (Granite.STYLE_CLASS_FLAT);

        var overdue_header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        overdue_header_box.append (overdue_label);
        // overdue_header_box.append (reschedule_button);

        overdue_listbox = new Gtk.ListBox () {
            valign = Gtk.Align.START,
            activate_on_single_click = true,
            selection_mode = Gtk.SelectionMode.SINGLE,
            hexpand = true
        };

        overdue_listbox.add_css_class ("listbox-background");

        var overdue_listbox_grid = new Gtk.Grid () {
            margin_top = 6
        };

        overdue_listbox_grid.attach (overdue_listbox, 0, 0);

        var overdue_separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);

        var overdue_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            margin_top = 12
        };

        overdue_box.append (overdue_header_box);
        overdue_box.append (overdue_separator);
        overdue_box.append (overdue_listbox_grid);

        overdue_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };
        overdue_revealer.child = overdue_box;

        var today_label = new Gtk.Label (_("Today")) {
            halign = Gtk.Align.START,
            valign = Gtk.Align.CENTER,
            hexpand = true
        };

        today_label.add_css_class ("font-bold");
        
        var today_header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);

        today_header_box.append (today_label);

        var today_separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);

        var today_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
            margin_top = 12
        };
        today_box.append (today_header_box);
        today_box.append (today_separator);

        today_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };
        today_revealer.child = today_box;

        listbox = new Gtk.ListBox () {
            valign = Gtk.Align.START,
            activate_on_single_click = true,
            selection_mode = Gtk.SelectionMode.SINGLE,
            hexpand = true
        };

        listbox.add_css_class ("listbox-background");

        listbox_grid = new Gtk.Grid () {
            margin_top = 6
        };

        listbox_grid.attach (listbox, 0, 0);

        var content = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            hexpand = true,
            vexpand = true
        };

        content.append (event_list_revealer);
        content.append (overdue_revealer);
        content.append (today_revealer);
        content.append (listbox_grid);

        var listbox_placeholder = new Widgets.Placeholder (
            _("Press 'a' or tap the plus button to create a new to-do"), "planner-check-circle"
        );

        listbox_placeholder_stack = new Gtk.Stack () {
            vexpand = true,
            hexpand = true,
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };

        listbox_placeholder_stack.add_named (content, "listbox");
        listbox_placeholder_stack.add_named (listbox_placeholder, "placeholder");

        var content_clamp = new Adw.Clamp () {
            maximum_size = 720,
            margin_start = 12,
            margin_end = 12
        };

        content_clamp.child = listbox_placeholder_stack;

        scrolled_window = new Gtk.ScrolledWindow () {
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
        headerbar.update_today_label ();
        add_today_items ();

        Timeout.add (listbox_placeholder_stack.transition_duration, () => {
            check_placeholder ();
            return GLib.Source.REMOVE;
        });

        Planner.event_bus.day_changed.connect (() => {
            headerbar.update_today_label ();
        });

        Services.Database.get_default ().item_added.connect (valid_add_item);
        Services.Database.get_default ().item_deleted.connect (valid_delete_item);
        Services.Database.get_default ().item_updated.connect (valid_update_item);

        Planner.event_bus.item_moved.connect ((item) => {
            if (items.has_key (item.id_string)) {
                items[item.id_string].update_request ();
            }

            if (overdue_items.has_key (item.id_string)) {
                items[item.id_string].update_request ();
            }
        });

        headerbar.prepare_new_item.connect (() => {
            prepare_new_item ();
        });
    }

    private void check_placeholder () {
        if (overdue_has_children || today_has_children) {
            listbox_placeholder_stack.visible_child_name = "listbox";
        } else {
            listbox_placeholder_stack.visible_child_name = "placeholder";
        }
    }

    private void add_today_items () {
        items.clear ();

        foreach (unowned Gtk.Widget child in Util.get_default ().get_children (listbox) ) {
            listbox.remove (child);
        }

        foreach (Objects.Item item in Services.Database.get_default ().get_items_by_date (date, false)) {
            add_item (item);
        }

        overdue_items.clear ();

        foreach (unowned Gtk.Widget child in Util.get_default ().get_children (overdue_listbox) ) {
            overdue_listbox.remove (child);
        }

        foreach (Objects.Item item in Services.Database.get_default ().get_items_by_overdeue_view (false)) {
            add_overdue_item (item);
        }

        update_headers ();
    }

    private void add_item (Objects.Item item) {
        items [item.id_string] = new Layouts.ItemRow (item);
        listbox.append (items [item.id_string]);
        update_headers ();
        check_placeholder ();
    }

    private void add_overdue_item (Objects.Item item) {
        overdue_items [item.id_string] = new Layouts.ItemRow (item);
        overdue_listbox.append (overdue_items [item.id_string]);
        update_headers ();
        check_placeholder ();
    }

    private void valid_add_item (Objects.Item item, bool insert = true) {
        if (!items.has_key (item.id_string) &&
            Services.Database.get_default ().valid_item_by_date (item, date, false)) {
            add_item (item);   
        }

        if (!overdue_items.has_key (item.id_string) &&
            Services.Database.get_default ().valid_item_by_overdue (item, date, false)) {
            add_overdue_item (item);
        }

        update_headers ();
        check_placeholder ();
    }

    private void valid_delete_item (Objects.Item item) {
        if (items.has_key (item.id_string)) {
            items[item.id_string].hide_destroy ();
            items.unset (item.id_string);
        }

        if (overdue_items.has_key (item.id_string)) {
            overdue_items[item.id_string].hide_destroy ();
            overdue_items.unset (item.id_string);
        }

        update_headers ();
        check_placeholder ();
    }

    private void valid_update_item (Objects.Item item) {
        if (items.has_key (item.id_string)) {
            items[item.id_string].update_request ();
        }

        if (overdue_items.has_key (item.id_string)) {
            overdue_items[item.id_string].update_request ();
        }

        if (items.has_key (item.id_string) && !item.has_due) {
            items[item.id_string].hide_destroy ();
            items.unset (item.id_string);
        }

        if (overdue_items.has_key (item.id_string) && !item.has_due) {
            overdue_items[item.id_string].hide_destroy ();
            overdue_items.unset (item.id_string);
        }

        if (items.has_key (item.id_string) && item.has_due) {
            if (!Services.Database.get_default ().valid_item_by_date (item, date, false)) {
                items[item.id_string].hide_destroy ();
                items.unset (item.id_string);
            }
        }

        if (overdue_items.has_key (item.id_string) && item.has_due) {
            if (!Services.Database.get_default ().valid_item_by_overdue (item, date, false)) {
                overdue_items[item.id_string].hide_destroy ();
                overdue_items.unset (item.id_string);
            }
        }

        if (item.has_due) {
            valid_add_item (item);
        }

        update_headers ();
        check_placeholder ();
    }

    public void prepare_new_item (string content = "") {
        listbox_placeholder_stack.visible_child_name = "listbox";
        Timeout.add (225, () => {
            scrolled_window.vadjustment.value = 0;
            return GLib.Source.REMOVE;
        });

        Planner.event_bus.item_selected (null);

        var row = new Layouts.ItemRow.for_project (
            Services.Database.get_default ().get_project (Planner.settings.get_string ("inbox-project-id"))
        );

        row.update_due (Util.get_default ().get_format_date (date));
        row.update_content (content);
        row.update_priority (Util.get_default ().get_default_priority ());

        row.item_added.connect (() => {
            item_added (row);
        });

        row.widget_destroyed.connect (() => {
            check_placeholder ();
        });

        if (today_has_children) {
            listbox.insert (row, 0);
        } else {
            listbox.append (row);
        }
    }

    private void item_added (Layouts.ItemRow row) {
        bool insert = true;
        if (row.item.has_due) {
            insert = !Util.get_default ().is_same_day (date, row.item.due.datetime);
        }

        if (!insert) {
            if (!items.has_key (row.item.id_string)) {
                items [row.item.id_string] = row;
            }

            row.update_inserted_item ();
        }

        if (row.item.section_id != "") {
            Services.Database.get_default ().get_section (row.item.section_id)
                .add_item_if_not_exists (row.item);
        } else {
            Services.Database.get_default ().get_project (row.item.project_id)
                .add_item_if_not_exists (row.item);
        }

        update_headers ();
        check_placeholder ();

        if (insert) {
            row.hide_destroy ();
        }
    }

    private void update_headers () {
        if (overdue_has_children) {
            overdue_revealer.reveal_child = true;
            today_revealer.reveal_child = today_has_children;
            listbox_grid.margin_top = 6;
        } else {
            overdue_revealer.reveal_child = false;
            today_revealer.reveal_child = false;
            listbox_grid.margin_top = 12;
        }
    }

    public void build_content_menu () {
        //  Planner.event_bus.unselect_all ();

        //  var menu = new Dialogs.ContextMenu.Menu ();

        //  var show_completed_item = new Dialogs.ContextMenu.MenuItem (
        //      Planner.settings.get_boolean ("show-today-completed") ? _("Hide completed tasks") : _("Show completed tasks"),
        //      "planner-check-circle"
        //  );

        //  menu.add_item (show_completed_item);
        //  menu.popup ();

        //  show_completed_item.activate_item.connect (() => {
        //      menu.hide_destroy ();
        //      Planner.settings.set_boolean ("show-today-completed", !Planner.settings.get_boolean ("show-today-completed"));
        //  });
    }
}