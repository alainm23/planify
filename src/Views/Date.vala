public class Views.Date : Gtk.EventBox {
    public GLib.DateTime date { get; set; }
    public bool is_today_view { get; construct; }

    private Gtk.ListBox overdue_listbox;
    private Gtk.ListBox listbox;
    private Gtk.Stack listbox_stack;
    private Gtk.Revealer main_revealer;
    private Gtk.Revealer overdue_revealer;
    private Gtk.Revealer today_label_revealer;

    public Gee.HashMap <string, Layouts.ItemRow> overdue_items;
    public Gee.HashMap <string, Layouts.ItemRow> items;

    private bool overdue_has_children {
        get {
            return overdue_listbox.get_children ().length () > 0;
        }
    }

    private bool has_children {
        get {
            return listbox.get_children ().length () > 0;
        }
    }

    public Date (bool is_today_view = false) {
        Object (
            is_today_view: is_today_view
        );
    }

    construct {
        overdue_items = new Gee.HashMap <string, Layouts.ItemRow> ();
        items = new Gee.HashMap <string, Layouts.ItemRow> ();

        var overdue_label = new Gtk.Label (_("Overdue")) {
            halign = Gtk.Align.START,
            valign = Gtk.Align.CENTER,
            hexpand = true,
            margin_start = 6,
            margin_bottom = 6
        };
        overdue_label.get_style_context ().add_class ("font-bold");

        overdue_listbox = new Gtk.ListBox () {
            valign = Gtk.Align.START,
            activate_on_single_click = true,
            selection_mode = Gtk.SelectionMode.SINGLE,
            hexpand = true
        };

        unowned Gtk.StyleContext overdue_listbox_context = overdue_listbox.get_style_context ();
        overdue_listbox_context.add_class ("listbox-background");

        var overdue_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            margin_bottom = 12
        };
        overdue_grid.add (overdue_label);
        overdue_grid.add (overdue_listbox);
        
        overdue_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };
        overdue_revealer.add (overdue_grid);

        var today_label = new Gtk.Label (_("Today")) {
            halign = Gtk.Align.START,
            valign = Gtk.Align.CENTER,
            hexpand = true,
            margin_start = 6,
            margin_bottom = 6
        };
        today_label.get_style_context ().add_class ("font-bold");

        today_label_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };
        today_label_revealer.add (today_label);

        listbox = new Gtk.ListBox () {
            valign = Gtk.Align.START,
            activate_on_single_click = true,
            selection_mode = Gtk.SelectionMode.SINGLE
        };

        if (!is_today_view) {
            listbox.set_placeholder (get_placeholder ());
        }

        unowned Gtk.StyleContext listbox_context = listbox.get_style_context ();
        listbox_context.add_class ("listbox-background");

        var listbox_grid = new Gtk.Grid () {
            valign = Gtk.Align.START
        };
        listbox_grid.add (listbox);

        var listbox_placeholder = new Widgets.Placeholder (
            is_today_view ? _("Today") : _("Scheduled"),
            _("No tasks with this filter at the moment"),
            is_today_view ? "planner-today" : "planner-scheduled");

        listbox_stack = new Gtk.Stack () {
            expand = true,
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };

        listbox_stack.add_named (listbox_grid, "listbox");
        listbox_stack.add_named (listbox_placeholder, "placeholder");
        
        var main_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            expand = true
        };

        main_grid.add (overdue_revealer);
        main_grid.add (today_label_revealer);
        main_grid.add (listbox_stack);

        main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };
        main_revealer.add (main_grid);
        
        add (main_revealer);

        Timeout.add (main_revealer.transition_duration, () => {
            validate_placeholder ();
            main_revealer.reveal_child = true;
            return GLib.Source.REMOVE;
        });

        notify ["date"].connect (() => {
            if (date != null) {
                if (is_today_view) {
                    add_today_items ();
                } else {
                    add_items (date);
                }
            }
        });

        if (is_today_view) {
            date = new GLib.DateTime.now_local ();
        }

        overdue_listbox.add.connect (update_headers);
        overdue_listbox.remove.connect (update_headers);
        listbox.add.connect (update_headers);
        listbox.remove.connect (update_headers);

        Planner.database.item_added.connect (valid_add_item);
        Planner.database.item_deleted.connect (valid_delete_item);
        Planner.database.item_updated.connect (valid_update_item);
        Planner.event_bus.item_moved.connect ((item) => {
            if (items.has_key (item.id_string)) {
                items[item.id_string].update_request ();
            }

            if (overdue_items.has_key (item.id_string)) {
                items[item.id_string].update_request ();
            }
        });

        listbox.add.connect (validate_placeholder);
        listbox.remove.connect (validate_placeholder);
        overdue_listbox.add.connect (validate_placeholder);
        overdue_listbox.remove.connect (validate_placeholder);
    }

    private void validate_placeholder () {
        if (is_today_view) {
            listbox_stack.visible_child_name = overdue_has_children || has_children ? "listbox" : "placeholder";
        } else {
            listbox_stack.visible_child_name = has_children ? "listbox" : "placeholder";
        }
    }

    private void valid_add_item (Objects.Item item, bool insert = true) {
        if (!items.has_key (item.id_string) &&
            Planner.database.valid_item_by_date (item, date, false)) {
            add_item (item);   
        }

        if (is_today_view && !overdue_items.has_key (item.id_string) &&
            Planner.database.valid_item_by_overdue (item, date, false)) {
            add_overdue_item (item);
        }
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
            if (!Planner.database.valid_item_by_date (item, date, false)) {
                items[item.id_string].hide_destroy ();
                items.unset (item.id_string);
            }
        }

        if (overdue_items.has_key (item.id_string) && item.has_due) {
            if (!Planner.database.valid_item_by_overdue (item, date, false)) {
                overdue_items[item.id_string].hide_destroy ();
                overdue_items.unset (item.id_string);
            }
        }

        if (item.has_due) {
            valid_add_item (item);
        }
    }

    private void add_items (GLib.DateTime date) {
        items.clear ();
        
        foreach (unowned Gtk.Widget child in listbox.get_children ()) {
            child.destroy ();
        }

        foreach (Objects.Item item in Planner.database.get_items_by_date (date, false)) {
            add_item (item);
        }
    }

    private void add_today_items () {
        items.clear ();

        foreach (unowned Gtk.Widget child in listbox.get_children ()) {
            child.destroy ();
        }

        foreach (Objects.Item item in Planner.database.get_items_by_date (date, false)) {
            add_item (item);
        }

        overdue_items.clear ();

        foreach (unowned Gtk.Widget child in overdue_listbox.get_children ()) {
            child.destroy ();
        }

        foreach (Objects.Item item in Planner.database.get_items_by_overdeue_view (false)) {
            add_overdue_item (item);
        }

        update_headers ();
    }

    private void update_headers () {
        overdue_revealer.reveal_child = is_today_view && overdue_has_children;
        today_label_revealer.reveal_child = overdue_revealer.reveal_child && has_children;
    }

    private void add_item (Objects.Item item) {
        items [item.id_string] = new Layouts.ItemRow (item);
        listbox.add (items [item.id_string]);
        listbox.show_all ();
    }

    private void add_overdue_item (Objects.Item item) {
        overdue_items [item.id_string] = new Layouts.ItemRow (item);
        overdue_listbox.add (overdue_items [item.id_string]);
        overdue_listbox.show_all ();
    }

    private Gtk.Widget get_placeholder () {
        var calendar_image = new Widgets.DynamicIcon () {
            opacity = 0.1
        };
        calendar_image.size = 96;

        calendar_image.update_icon_name ("planner-calendar");
        if (is_today_view) {
            calendar_image.update_icon_name ("planner-star");
        }

        var grid = new Gtk.Grid () {
            margin_top = 128,
            halign = Gtk.Align.CENTER
        };
        grid.add (calendar_image);
        grid.show_all ();

        return grid;
    }

    public void prepare_new_item () {
        Planner.event_bus.item_selected (null);

        var row = new Layouts.ItemRow.for_project (
            Planner.database.get_project (Planner.settings.get_int64 ("inbox-project-id"))
        );
        row.update_due (Util.get_default ().get_format_date (date));
        row.item_added.connect (() => {
            item_added (row);
        });

        listbox.add (row);
        listbox.show_all ();
    }

    private void item_added (Layouts.ItemRow row) {
        bool insert = true;
        if (row.item.has_due) {
            insert = !Util.get_default ().is_same_day (date, row.item.due.datetime);
        }

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
        if (is_today_view) {
            if (!items.has_key (row.item.id_string) &&
                Planner.database.valid_item_by_date (row.item, date, false)) {
                items [row.item.id_string] = row;
                listbox.add (items [row.item.id_string]);
                listbox.show_all (); 
            }

            if (is_today_view && !overdue_items.has_key (row.item.id_string) &&
                Planner.database.valid_item_by_overdue (row.item, date, false)) {
                overdue_items [row.item.id_string] = row;
                overdue_listbox.add (overdue_items [row.item.id_string]);
                overdue_listbox.show_all ();
            }
        } else {
            if (!items.has_key (row.item.id_string)) {
                items [row.item.id_string] = row;
                listbox.add (items [row.item.id_string]);
                listbox.show_all ();
            }
        } 
    }

    //  private void header_function (Gtk.ListBoxRow lbrow, Gtk.ListBoxRow? lbbefore) {
    //      if (!(lbrow is Layouts.ItemRow)) {
    //          return;
    //      }

    //      Layouts.ItemRow row = (Layouts.ItemRow) lbrow;

    //      if (!row.item.has_due) {
    //          return;
    //      }

    //      if (lbbefore != null) {
    //          Layouts.ItemRow before = (Layouts.ItemRow) lbbefore;

    //          if (before.item.due.datetime.compare (row.item.due.datetime) == 0) {
    //              return;
    //          }
    //      }

    //      var header_label = new Granite.HeaderLabel (
    //          Util.get_default ()._get_relative_date_from_date (row.item.due.datetime)
    //      ) {
    //          ellipsize = Pango.EllipsizeMode.MIDDLE
    //      };

    //      row.set_header (header_label);
    //  }
}
