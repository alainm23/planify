public class Widgets.SubItems : Gtk.EventBox {
    public Objects.Item item_parent { get; construct; }
    
    private Gtk.ListBox listbox;
    private Gtk.ListBox checked_listbox;
    private Gtk.Revealer checked_revealer;
    private Gtk.Revealer main_revealer;

    public Gee.HashMap <string, Layouts.ItemRow> items;
    public Gee.HashMap <string, Layouts.ItemRow> items_checked;

    public bool has_children {
        get {
            return listbox.get_children ().length () > 0 || (checked_listbox.get_children ().length () > 0 && item_parent.project.show_completed);
        }
    }

    public bool is_creating {
        get {
            return item_parent.id == Constants.INACTIVE;
        }
    }

    public SubItems (Objects.Item item_parent) {
        Object (
            item_parent: item_parent
        );
    }

    construct {
        items = new Gee.HashMap <string, Layouts.ItemRow> ();
        items_checked = new Gee.HashMap <string, Layouts.ItemRow> ();

        listbox = new Gtk.ListBox () {
            valign = Gtk.Align.START,
            activate_on_single_click = true,
            selection_mode = Gtk.SelectionMode.SINGLE,
            hexpand = true
        };

        unowned Gtk.StyleContext listbox_context = listbox.get_style_context ();
        listbox_context.add_class ("listbox-background");

        var listbox_grid = new Gtk.Grid () {
            margin_left = 21
        };

        listbox_grid.add (listbox);
        
        checked_listbox = new Gtk.ListBox () {
            valign = Gtk.Align.START,
            activate_on_single_click = true,
            selection_mode = Gtk.SelectionMode.SINGLE,
            expand = true
        };

        unowned Gtk.StyleContext checked_listbox_context = checked_listbox.get_style_context ();
        checked_listbox_context.add_class ("listbox-background");

        var checked_listbox_grid = new Gtk.Grid () {
            margin_left = 21
        };
        checked_listbox_grid.add (checked_listbox);

        checked_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            reveal_child = item_parent.project.show_completed
        };

        checked_revealer.add (checked_listbox_grid);

        var main_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            hexpand = true
        };

        main_grid.add (listbox_grid);
        main_grid.add (checked_revealer);

        main_revealer = new Gtk.Revealer ();
        main_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        main_revealer.add (main_grid);
        
        add (main_revealer);

        if (!is_creating) {
            add_items ();
        }

        Timeout.add (main_revealer.transition_duration, () => {
            main_revealer.reveal_child = true;
            return GLib.Source.REMOVE;
        });

        item_parent.item_added.connect (add_item);

        listbox.add.connect (() => {
            main_revealer.reveal_child = has_children;
        });

        listbox.remove.connect (() => {
            main_revealer.reveal_child = has_children;
        });

        Planner.database.item_updated.connect ((item, update_id) => {
            if (items.has_key (item.id_string)) {
                if (items [item.id_string].update_id != update_id) {
                    items [item.id_string].update_request ();
                }
            }

            if (items_checked.has_key (item.id_string)) {
                items_checked [item.id_string].update_request ();
            }
        });

        Planner.database.item_deleted.connect ((item) => {
            if (items.has_key (item.id_string)) {
                items [item.id_string].hide_destroy ();
                items.unset (item.id_string);
            }

            if (items_checked.has_key (item.id_string)) {
                items_checked [item.id_string].hide_destroy ();
                items_checked.unset (item.id_string);
            }
        });

        Planner.event_bus.item_moved.connect ((item, old_project_id, old_section_id, old_parent_id, insert) => {
            if (old_parent_id == item_parent.id) {
                if (items.has_key (item.id_string)) {
                    items [item.id_string].hide_destroy ();
                    items.unset (item.id_string);
                }

                if (items_checked.has_key (item.id_string)) {
                    items_checked [item.id_string].hide_destroy ();
                    items_checked.unset (item.id_string);
                }
            }

            if (item.parent_id == item_parent.id) {
                add_item (item);
            }
        });

        Planner.event_bus.checked_toggled.connect ((item, old_checked) => {
            if (item.parent.id == item_parent.id) {
                if (!old_checked) {
                    if (items.has_key (item.id_string)) {
                        items [item.id_string].hide_destroy ();
                        items.unset (item.id_string);
                    }

                    if (!items_checked.has_key (item.id_string)) {
                        items_checked [item.id_string] = new Layouts.ItemRow (item);
                        checked_listbox.insert (items_checked [item.id_string], 0);
                        checked_listbox.show_all ();
                    }
                } else {
                    if (items_checked.has_key (item.id_string)) {
                        items_checked [item.id_string].hide_destroy ();
                        items_checked.unset (item.id_string);
                    }

                    if (!items.has_key (item.id_string)) {
                        items [item.id_string] = new Layouts.ItemRow (item);
                        listbox.add (items [item.id_string]);
                        listbox.show_all ();
                    }
                }
            }
        });

        item_parent.project.show_completed_changed.connect (() => {
            if (item_parent.project.show_completed) {
                add_completed_items ();
                checked_revealer.reveal_child = item_parent.project.show_completed;
            } else {
                items_checked.clear ();
                foreach (unowned Gtk.Widget child in checked_listbox.get_children ()) {
                    child.destroy ();
                }

                checked_revealer.reveal_child = item_parent.project.show_completed;
            }
        });
    }

    private void add_items () {
        items.clear ();

        foreach (unowned Gtk.Widget child in listbox.get_children ()) {
            child.destroy ();
        }

        foreach (Objects.Item item in item_parent.items) {
            add_item (item);
        }

        if (item_parent.project.show_completed) {
            add_completed_items ();
        }

        main_revealer.reveal_child = has_children;
    }

    public void add_completed_items () {
        items_checked.clear ();

        foreach (unowned Gtk.Widget child in checked_listbox.get_children ()) {
            child.destroy ();
        }

        foreach (Objects.Item item in item_parent.items) {
            add_complete_item (item);
        }
    }

    public void add_complete_item (Objects.Item item) {
        if (item_parent.project.show_completed && item.checked) {
            if (!items_checked.has_key (item.id_string)) {
                items_checked [item.id_string] = new Layouts.ItemRow (item);
                checked_listbox.add (items_checked [item.id_string]);
                checked_listbox.show_all ();
            }
        }
    }

    public void add_item (Objects.Item item) {
        if (!item.checked && !items.has_key (item.id_string)) {
            items [item.id_string] = new Layouts.ItemRow (item);
            listbox.add (items [item.id_string]);
            listbox.show_all ();
        }
    }

    public void prepare_new_item (string content = "") {
        Planner.event_bus.item_selected (null);
        
        Layouts.ItemRow row = new Layouts.ItemRow.for_parent (item_parent);
        row.update_content (content);

        row.item_added.connect (() => {
            items [row.item.id_string] = row;
            row.update_inserted_item ();
            item_parent.add_item_if_not_exists (row.item);
        });

        listbox.add (row);
        listbox.show_all ();
    }
}