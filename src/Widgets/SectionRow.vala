public class Widgets.SectionRow : Gtk.ListBoxRow {
    public Objects.Section section { get; construct; }
    public int is_todoist { get; construct; }

    private Gtk.Button hidden_button;
    private Gtk.Entry name_entry;

    private Gtk.Separator separator;
    private Gtk.Revealer motion_revealer;

    private Gtk.ListBox listbox;
    private Gtk.Revealer listbox_revealer;
    private Gtk.Menu menu = null;

    private bool has_new_item = false;

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

    public SectionRow (Objects.Section section, int is_todoist) {
        Object (
            section: section,
            is_todoist: is_todoist
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
        
        if (section.collapsed == 1) {
            hidden_button.get_style_context ().add_class ("opened");
        }

        var hidden_revealer = new Gtk.Revealer ();
        hidden_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        hidden_revealer.add (hidden_button);
        hidden_revealer.reveal_child = false;

        name_entry = new Gtk.Entry ();
        name_entry.text = section.name;
        name_entry.hexpand = true;
        name_entry.valign = Gtk.Align.CENTER;
        name_entry.placeholder_text = _("Section name");
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

        var settings_revealer = new Gtk.Revealer ();
        settings_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        settings_revealer.add (settings_button);
        settings_revealer.reveal_child = false;

        var top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        top_box.pack_start (hidden_revealer, false, false, 0);
        top_box.pack_start (name_entry, false, true, 0);
        top_box.pack_end (settings_revealer, false, true, 0);

        var top_eventbox = new Gtk.EventBox ();
        top_eventbox.margin_end = 24;
        top_eventbox.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        top_eventbox.add (top_box);

        separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator.margin_start = 41;
        separator.margin_end = 32;
        separator.margin_bottom = 6;

        var motion_grid = new Gtk.Grid ();
        motion_grid.get_style_context ().add_class ("grid-motion");
        motion_grid.height_request = 24;
            
        motion_revealer = new Gtk.Revealer ();
        motion_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        motion_revealer.add (motion_grid);

        listbox = new Gtk.ListBox  ();
        listbox.valign = Gtk.Align.START;
        listbox.get_style_context ().add_class ("listbox");
        listbox.activate_on_single_click = true;
        listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        listbox.hexpand = true;

        Gtk.drag_dest_set (listbox, Gtk.DestDefaults.ALL, targetEntries, Gdk.DragAction.MOVE);
        listbox.drag_data_received.connect (on_drag_data_received);

        listbox_revealer = new Gtk.Revealer ();
        listbox_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        listbox_revealer.add (listbox);
        listbox_revealer.reveal_child = true;

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.margin_bottom = 6;
        main_box.hexpand = true;
        main_box.pack_start (top_eventbox, false, false, 0);
        main_box.pack_start (separator, false, false, 0);
        main_box.pack_start (motion_revealer, false, false, 0);
        main_box.pack_start (listbox_revealer, false, false, 0);

        add (main_box);
        add_all_projects ();
        
        build_drag_and_drop (false);

        if (section.collapsed == 1) {
            listbox_revealer.reveal_child = true;
        }

        Application.utils.magic_button_activated.connect ((project_id, section_id, is_todoist, last, index) => {
            if (section.project_id == project_id && section.id == section_id) {
                var new_item = new Widgets.NewItem (
                    project_id,
                    section_id, 
                    is_todoist
                );

                if (last) {
                    listbox.add (new_item);
                } else {
                    new_item.index = index;
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
            if (section.id == item.section_id && item.parent_id == 0) {
                var row = new Widgets.ItemRow (item);
                listbox.add (row);
                listbox.show_all ();
            }
        });

        Application.database.item_added_with_index.connect ((item, index) => {
            if (section.id == item.section_id && item.parent_id == 0) {
                var row = new Widgets.ItemRow (item);
                listbox.insert (row, index);
                listbox.show_all ();
            }
        });

        Application.utils.drag_magic_button_activated.connect ((value) => {
            build_drag_and_drop (value);
        });

        hidden_button.clicked.connect (() => {
            toggle_hidden ();
        });

        top_eventbox.enter_notify_event.connect ((event) => {
            hidden_revealer.reveal_child = true;
            settings_revealer.reveal_child = true;

            return true;
        });

        top_eventbox.leave_notify_event.connect ((event) => {
            if (event.detail == Gdk.NotifyType.INFERIOR) {
                return false;
            }

            hidden_revealer.reveal_child = false;
            settings_revealer.reveal_child = false;
            
            return true;
        });
        
        /*
        name_stack.event.connect ((event) => {
            if (event.type == Gdk.EventType.BUTTON_PRESS) {
                name_stack.visible_child_name = "name_entry";
                name_entry.grab_focus ();
            }

            return false;
        });

        name_entry.activate.connect (() =>{
            save_section ();
        });
        */

        name_entry.changed.connect (() => {
            save_section ();
        });

        /*
        name_entry.focus_out_event.connect (() => {
            save_section ();
            return false;
        });

        name_entry.key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                save_section ();
            }

            return false;
        });
        */

        settings_button.clicked.connect (() => {
            activate_menu ();
        });
    }

    private void activate_menu () {
        if (menu == null) {
            build_context_menu (section);
        }

        menu.popup_at_pointer (null);
    }

    private void build_context_menu (Objects.Section section) {
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
        foreach (Objects.Item item in Application.database.get_all_items_by_section_no_parent (section.id)) {
            var row = new Widgets.ItemRow (item);
            listbox.add (row);
        }

        listbox.show_all ();
    }
        
    private void toggle_hidden () {
        if (listbox_revealer.reveal_child) {
            listbox_revealer.reveal_child = false;
            hidden_button.get_style_context ().remove_class ("opened");
            section.collapsed = 0;
        } else {
            listbox_revealer.reveal_child = true;
            hidden_button.get_style_context ().add_class ("opened");
            section.collapsed = 1;
        }

        save_section ();
    }

    public void save_section () {
        section.name = name_entry.text;
        section.save ();
    }

    private void build_drag_and_drop (bool value) {
        name_entry.drag_data_received.disconnect (on_drag_item_received);
        name_entry.drag_data_received.disconnect (on_drag_magic_button_received);

        if (value) {
            Gtk.drag_dest_set (name_entry, Gtk.DestDefaults.ALL, targetEntriesMagicButton, Gdk.DragAction.MOVE);
            name_entry.drag_data_received.connect (on_drag_magic_button_received);
        } else {
            Gtk.drag_dest_set (name_entry, Gtk.DestDefaults.ALL, targetEntries, Gdk.DragAction.MOVE);
            name_entry.drag_data_received.connect (on_drag_item_received);
        }

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
        if (has_new_item == false) {
            var new_item = new Widgets.NewItem (
                section.project_id,
                section.id, 
                is_todoist
            );

            new_item.destroy.connect (() => {
                has_new_item = false;
            });

            new_item.index = 0;
            listbox.insert (new_item, 0);
            listbox.show_all ();

            has_new_item = true;
        }
    }

    private void on_drag_item_received (Gdk.DragContext context, int x, int y, Gtk.SelectionData selection_data, uint target_type) {
        Widgets.ItemRow source;
        var row = ((Gtk.Widget[]) selection_data.get_data ())[0];
        source = (Widgets.ItemRow) row;

        source.item.section_id = section.id;

        source.get_parent ().remove (source); 
        listbox.insert (source, 0);
        listbox.show_all ();
    
        update_item_order ();

        listbox_revealer.reveal_child = true;
        section.collapsed = 1;

        save_section ();
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
                Application.database.update_item_order (item.id, section.id, index);

                return null;
            });
        });
    }
}