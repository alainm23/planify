public class Widgets.HeaderRow : Gtk.ListBoxRow {
    public Objects.Header header { get; construct; }

    private Gtk.Button hidden_button;
    private Gtk.Entry name_entry;
    private Gtk.EventBox top_eventbox;

    private Gtk.Separator separator;
    private Gtk.Revealer motion_revealer;

    private Gtk.ListBox listbox;
    private Gtk.Revealer listbox_revealer;
    private Gtk.Menu menu = null;

    public bool set_focus {
        set {
            name_entry.grab_focus ();
        }
    }

    private const Gtk.TargetEntry[] targetEntries = {
        {"ITEMROW", Gtk.TargetFlags.SAME_APP, 0}
    };

    private const Gtk.TargetEntry[] targetEntriesMagicButton = {
        {"MAGICBUTTON", Gtk.TargetFlags.SAME_APP, 0}
    };

    public HeaderRow (Objects.Header header) {
        Object (
            header: header
        );
    }

    construct {
        can_focus = false;
        get_style_context ().add_class ("area-row");

        hidden_button = new Gtk.Button.from_icon_name ("pan-end-symbolic", Gtk.IconSize.MENU);
        hidden_button.can_focus = false;
        hidden_button.margin_start = 6;
        hidden_button.get_style_context ().remove_class ("button");
        hidden_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        hidden_button.get_style_context ().add_class ("hidden-button");
        if (header.reveal == 1) {
            hidden_button.get_style_context ().add_class ("opened");
        }
        
        name_entry = new Gtk.Entry ();
        name_entry.text = header.name;
        name_entry.hexpand = true;
        name_entry.valign = Gtk.Align.CENTER;
        name_entry.placeholder_text = _("Header name");
        name_entry.get_style_context ().add_class ("flat");
        name_entry.get_style_context ().add_class ("header-title");
        name_entry.get_style_context ().add_class ("header-entry");
        name_entry.get_style_context ().add_class ("content-entry");
        
        var settings_button = new Gtk.Button ();
        settings_button.can_focus = false;
        settings_button.valign = Gtk.Align.CENTER;
        settings_button.tooltip_text = _("More");
        settings_button.image = new Gtk.Image.from_icon_name ("view-more-symbolic", Gtk.IconSize.MENU);
        settings_button.get_style_context ().remove_class ("button");
        settings_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        settings_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
        settings_button.get_style_context ().add_class ("hidden-button");

        var top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        top_box.margin_end = 24;
        top_box.pack_start (hidden_button, false, false, 0);
        top_box.pack_start (name_entry, false, true, 0);
        top_box.pack_end (settings_button, false, true, 0);

        separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator.margin_start = 41;
        separator.margin_end = 24;

        if (header.default_header == 1) {
            top_box.visible = false;
            top_box.no_show_all = true;

            separator.visible = false;
            separator.no_show_all = true;
        }

        var motion_grid = new Gtk.Grid ();
        motion_grid.get_style_context ().add_class ("grid-motion");
        motion_grid.height_request = 24;
            
        motion_revealer = new Gtk.Revealer ();
        motion_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        motion_revealer.add (motion_grid);

        listbox = new Gtk.ListBox  ();
        listbox.margin_top = 6;
        listbox.valign = Gtk.Align.START;
        listbox.get_style_context ().add_class ("listbox");
        listbox.activate_on_single_click = true;
        listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        listbox.hexpand = true;

        listbox_revealer = new Gtk.Revealer ();
        listbox_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        listbox_revealer.add (listbox);
        listbox_revealer.reveal_child = true;

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.margin_bottom = 6;
        main_box.hexpand = true;
        main_box.pack_start (top_box, false, false, 0);
        main_box.pack_start (separator, false, false, 0);
        main_box.pack_start (motion_revealer, false, false, 0);
        main_box.pack_start (listbox_revealer, false, false, 0);

        add (main_box);
        add_all_projects ();
        build_drag_and_drop (false);

        if (header.reveal == 1) {
            listbox_revealer.reveal_child = true;
        }

        Application.utils.magic_button_activated.connect ((project_id, header_id, is_todoist, last, index) => {
            if (header.id == header_id) {
                var new_item = new Widgets.NewItem (
                    project_id,
                    header_id, 
                    is_todoist
                );

                if (last) {
                    listbox.add (new_item);
                } else {
                    listbox.insert (new_item, index);
                }

                listbox.show_all ();
            }
        });

        listbox.row_activated.connect ((row) => {
            var item = ((Widgets.ItemRow) row);
            item.reveal_child = true;
        });
        
        Application.database.item_added.connect ((item) => {
            if (header.id == item.header_id) {
                var row = new Widgets.ItemRow (item);
                listbox.add (row);
                listbox.show_all ();
            }
        });

        Application.utils.drag_magic_button_activated.connect ((value) => {
            //build_drag_and_drop (value);
        });

        hidden_button.clicked.connect (() => {
            toggle_hidden ();
        });

        /*
        name_stack.event.connect ((event) => {
            if (event.type == Gdk.EventType.BUTTON_PRESS) {
                /name_stack.visible_child_name = "name_entry";
                name_entry.grab_focus ();
            }

            return false;
        });
        */

        name_entry.activate.connect (() =>{
            save_header ();
        });

        name_entry.changed.connect (() => {
            save_header ();
        });

        name_entry.focus_out_event.connect (() => {
            save_header ();
            return false;
        });

        name_entry.key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                save_header ();
            }

            return false;
        });

        settings_button.clicked.connect (() => {
            activate_menu ();
        });
    }

    private void activate_menu () {
        if (menu == null) {
            build_context_menu (header);
        }

        menu.popup_at_pointer (null);
    }

    private void build_context_menu (Objects.Header header) {
        menu = new Gtk.Menu ();
        
        var delete_menu = new Gtk.ImageMenuItem.with_label (_("Delete Header"));
        delete_menu.always_show_image = true;
        delete_menu.image = new Gtk.Image.from_icon_name ("edit-delete-symbolic", Gtk.IconSize.MENU);

        menu.add (delete_menu);

        menu.show_all (); 

        delete_menu.activate.connect (() => {
            var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (
                _("Are you sure to eliminate this Work Area"),
                "",
                "dialog-warning",
            Gtk.ButtonsType.CANCEL);

            var remove_button = new Gtk.Button.with_label (_("Delete Project"));
            remove_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
            message_dialog.add_action_widget (remove_button, Gtk.ResponseType.ACCEPT);

            message_dialog.show_all ();

            if (message_dialog.run () == Gtk.ResponseType.ACCEPT) {
                
            }

            message_dialog.destroy ();
        });
    }

    public void add_all_projects () {            
        foreach (Objects.Item item in Application.database.get_all_items_by_header (header.id)) {
            var row = new Widgets.ItemRow (item);
            listbox.add (row);
        }

        listbox.show_all ();
    }
        
    private void toggle_hidden () {
        if (listbox_revealer.reveal_child) {
            listbox_revealer.reveal_child = false;
            hidden_button.get_style_context ().remove_class ("opened");
            header.reveal = 0;
        } else {
            listbox_revealer.reveal_child = true;
            hidden_button.get_style_context ().add_class ("opened");
            header.reveal = 1;
        }

        save_header ();
    }

    public void save_header () {
        header.name = name_entry.text;
        header.save ();
    }

    private void build_drag_and_drop (bool is_magic_button_active) {
        Gtk.drag_dest_set (listbox, Gtk.DestDefaults.ALL, targetEntries, Gdk.DragAction.MOVE);
        listbox.drag_data_received.connect (on_drag_data_received);

        Gtk.drag_dest_set (name_entry, Gtk.DestDefaults.ALL, targetEntries, Gdk.DragAction.MOVE);
        name_entry.drag_data_received.connect (on_drag_item_received);
        name_entry.drag_motion.connect (on_drag_motion);
        name_entry.drag_leave.connect (on_drag_leave);
    }

    private void on_drag_data_received (Gdk.DragContext context, int x, int y, Gtk.SelectionData selection_data, uint target_type, uint time) {
        Widgets.ItemRow target;
        Widgets.ItemRow source;
        Gtk.Allocation alloc;

        target = (Widgets.ItemRow) listbox.get_row_at_y (y);
        target.get_allocation (out alloc);
        
        var row = ((Gtk.Widget[]) selection_data.get_data ())[0];
        source = (Widgets.ItemRow) row;

        if (target != null) {         
            source.get_parent ().remove (source); 
            listbox.insert (source, target.get_index () + 1);
            listbox.show_all ();

            update_item_order ();
        }
    }

    private void on_drag_magic_button_received (Gdk.DragContext context, int x, int y, Gtk.SelectionData selection_data, uint target_type, uint time) {
        Widgets.ItemRow target;
        Gtk.Allocation alloc;

        target = (Widgets.ItemRow) listbox.get_row_at_y (y);
        target.get_allocation (out alloc);

        print ("Inde to put: %i".printf (target.get_index ()));
    }

    private void on_drag_item_received (Gdk.DragContext context, int x, int y, Gtk.SelectionData selection_data, uint target_type) {
        Widgets.ItemRow source;
        var row = ((Gtk.Widget[]) selection_data.get_data ())[0];
        source = (Widgets.ItemRow) row;

        source.get_parent ().remove (source); 
        listbox.insert (source, 0);
        listbox.show_all ();
    
        update_item_order ();

        listbox_revealer.reveal_child = true;
        header.reveal = 1;

        save_header ();
    }

    public bool on_drag_motion (Gdk.DragContext context, int x, int y, uint time) {
        separator.visible = false;
        motion_revealer.reveal_child = true;
        return true;
    }
    
    public void on_drag_leave (Gdk.DragContext context, uint time) {
        separator.visible = true;
        motion_revealer.reveal_child = false;
    }

    private void update_item_order () {
        listbox.foreach ((widget) => {
            var row = (Gtk.ListBoxRow) widget;
            int index = row.get_index ();

            var item = ((Widgets.ItemRow) row).item;

            new Thread<void*> ("update_item_order", () => {
                Application.database.update_item_order (item.id, header.id, index);

                return null;
            });
        });
    }
}