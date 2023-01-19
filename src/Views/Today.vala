public class Views.Today : Gtk.Grid {
    private Widgets.EventsList event_list;

    private Gtk.ListBox listbox;
    private Gtk.Revealer today_revealer;
    private Gtk.ListBox overdue_listbox;
    private Gtk.Revealer overdue_revealer;
    private Gtk.Revealer event_list_revealer;
    private Gtk.Grid listbox_grid;

    private Gtk.Label date_label;

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
        
        var today_icon = new Gtk.Image () {
            gicon = new ThemedIcon ("planner-today"),
            pixel_size = 32
        };

        var title_label = new Gtk.Label (_("Today"));
        title_label.add_css_class ("header-title");


        date_label = new Gtk.Label (null) {
            margin_top = 2
        };

        date_label.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);
        
        var header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            valign = Gtk.Align.START,
            hexpand = true,
            margin_top = 28
        };

        header_box.append (today_icon);
        header_box.append (title_label);
        header_box.append (date_label);

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

        var overdue_header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            margin_start = 3
        };
        overdue_header_box.append (overdue_label);
        overdue_header_box.append (reschedule_button);

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

        var overdue_separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
            margin_start = 3
        };

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
        
        var today_header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            margin_start = 3
        };

        today_header_box.append (today_label);

        var today_separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
            margin_start = 3
        };

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

        content.append (header_box);
        content.append (event_list_revealer);
        content.append (overdue_revealer);
        content.append (today_revealer);
        content.append (listbox_grid);

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

        overlay.add_overlay (magic_button);
        overlay.child = scrolled_window;

        attach (overlay, 0, 0);
        update_today_label ();
        add_today_items ();

        Planner.event_bus.day_changed.connect (() => {
            update_today_label ();
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
    }

    private void add_overdue_item (Objects.Item item) {
        overdue_items [item.id_string] = new Layouts.ItemRow (item);
        overdue_listbox.append (overdue_items [item.id_string]);
        update_headers ();
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
    }

    private void update_today_label () {
        date = new GLib.DateTime.now_local ();
        date_label.label = "%s %s".printf (date.format ("%a"),
            date.format (
            Granite.DateTime.get_default_date_format (false, true, false)
        ));
    }

    public void prepare_new_item (string content = "") {
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