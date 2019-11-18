public class Widgets.SectionRow : Gtk.ListBoxRow {
    public Objects.Section section { get; construct; }

    private Gtk.Button hidden_button;
    private Gtk.Label name_label; 
    private Gtk.Entry name_entry;
    private Gtk.Stack name_stack;
    private Gtk.Revealer main_revealer;

    private Gtk.Separator separator;
    private Gtk.Revealer motion_revealer;
    private Gtk.Revealer motion_section_revealer;

    private Gtk.ListBox listbox;
    private Gtk.Revealer listbox_revealer;
    private Gtk.Menu projects_menu;
    private Gtk.Menu menu = null;

    public bool set_focus {
        set {
            name_stack.visible_child_name = "name_entry";
            name_entry.grab_focus ();
        }
    }

    private const Gtk.TargetEntry[] targetEntries = {
        {"ITEMROW", Gtk.TargetFlags.SAME_APP, 0}
    };

    private const Gtk.TargetEntry[] targetEntriesMagicButton = {
        {"MAGICBUTTON", Gtk.TargetFlags.SAME_APP, 0}
    };

    private const Gtk.TargetEntry[] targetEntriesSection = {
        {"SECTIONROW", Gtk.TargetFlags.SAME_APP, 0}
    };

    public SectionRow (Objects.Section section) {
        Object (
            section: section
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

        name_label =  new Gtk.Label (section.name);
        name_label.halign = Gtk.Align.START;
        name_label.get_style_context ().add_class ("header-title");
        name_label.valign = Gtk.Align.CENTER;
        name_label.set_ellipsize (Pango.EllipsizeMode.END);

        name_entry = new Gtk.Entry ();
        name_entry.text = section.name;
        name_entry.hexpand = true;
        name_entry.valign = Gtk.Align.CENTER;
        name_entry.placeholder_text = _("Section name");
        name_entry.get_style_context ().add_class ("flat");
        name_entry.get_style_context ().add_class ("header-title");
        name_entry.get_style_context ().add_class ("header-entry");
        name_entry.get_style_context ().add_class ("content-entry");
        
        name_stack = new Gtk.Stack ();
        name_stack.transition_type = Gtk.StackTransitionType.NONE;
        name_stack.add_named (name_label, "name_label");
        name_stack.add_named (name_entry, "name_entry");

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

        var top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        top_box.pack_start (hidden_revealer, false, false, 0);
        top_box.pack_start (name_stack, false, true, 6);
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

        var motion_section_grid = new Gtk.Grid ();
        motion_section_grid.get_style_context ().add_class ("grid-motion");
        motion_section_grid.height_request = 24;
            
        motion_section_revealer = new Gtk.Revealer ();
        motion_section_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        motion_section_revealer.add (motion_section_grid);

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

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.margin_bottom = 6;
        main_box.hexpand = true;
        main_box.pack_start (motion_section_revealer, false, false, 0);
        main_box.pack_start (top_eventbox, false, false, 0);
        main_box.pack_start (separator, false, false, 0);
        main_box.pack_start (motion_revealer, false, false, 0);
        main_box.pack_start (listbox_revealer, false, false, 0);

        main_revealer = new Gtk.Revealer ();
        main_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        main_revealer.add (main_box);
        main_revealer.reveal_child = true;

        add (main_revealer);
        add_all_items ();

        Gtk.drag_source_set (this, Gdk.ModifierType.BUTTON1_MASK, targetEntriesSection, Gdk.DragAction.MOVE);
        drag_begin.connect (on_drag_begin);
        drag_data_get.connect (on_drag_data_get);
        drag_end.connect (clear_indicator);

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
                    new_item.has_index = true;
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

        Application.database.item_completed.connect ((item) => {
            if (item.checked == 0 && section.id == item.section_id && item.parent_id == 0) {
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

            settings_revealer.reveal_child = false;
            hidden_revealer.reveal_child = false;
            
            return true;
        });
        
        top_eventbox.event.connect ((event) => {
            if (event.type == Gdk.EventType.@2BUTTON_PRESS) {
                name_stack.visible_child_name = "name_entry";
                name_entry.grab_focus ();
            }

            return false;
        });

        top_eventbox.button_press_event.connect ((sender, evt) => {
            if (evt.type == Gdk.EventType.BUTTON_PRESS && evt.button == 3) {
                activate_menu ();
                return true;
            }

            return false;
        });

        name_entry.activate.connect (() =>{
            save_section ();
        });

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
        
        settings_button.clicked.connect (() => {
            activate_menu ();
        });

        Application.database.section_deleted.connect ((s) => {
            if (section.id == s.id) {
                destroy ();
            }
        });

        Application.todoist.section_deleted_started.connect ((id) => {
            if (section.id == id) {
                sensitive = false;
            }
        });

        Application.todoist.section_deleted_error.connect ((id, http_code, error_message) => {
            if (section.id == id) {
                sensitive = true;
            }
        });

        Application.todoist.section_moved_started.connect ((id) => {
            if (section.id == id) {
                sensitive = false;
            }
        });

        Application.todoist.section_moved_completed.connect ((id) => {
            if (section.id == id) {
                destroy ();
            }
        });

        Application.todoist.section_moved_error.connect ((id, http_code, error_message) => {
            if (section.id == id) {
                sensitive = true;
            }
        });

        /*
        Application.utils.drag_item_activated.connect ((value) => {
            if (value) {
                Gtk.drag_dest_set (name_stack, Gtk.DestDefaults.ALL, targetEntries, Gdk.DragAction.MOVE);
                name_stack.drag_data_received.connect (on_drag_item_received);
                name_stack.drag_motion.connect (on_drag_motion);
                name_stack.drag_leave.connect (on_drag_leave);
            } else {
                build_drag_and_drop (false);
            }
        });
        */
    }

    private void activate_menu () {
        if (menu == null) {
            build_context_menu (section);
        }

        foreach (var child in projects_menu.get_children ()) {
            child.destroy ();
        }
        
        var item_menu = new Widgets.ImageMenuItem (_("Inbox"), "mail-mailbox-symbolic");
        item_menu.activate.connect (() => {
            int64 inbox_id = Application.settings.get_int64 ("inbox-project");

            if (section.is_todoist == 0) {
                if (Application.database.move_section (section, inbox_id)) {
                    destroy ();
                }
            } else {
                Application.todoist.move_section (section, inbox_id);
            }
        });
        
        projects_menu.add (item_menu);

        foreach (var project in Application.database.get_all_projects ()) {
            if (section.is_todoist == project.is_todoist) {
                item_menu = new Widgets.ImageMenuItem (project.name, "planner-project-symbolic"); 
                item_menu.activate.connect (() => {
                    if (section.is_todoist == 0) {
                        if (Application.database.move_section (section, project.id)) {
                            destroy ();
                        }
                    } else {
                        Application.todoist.move_section (section, project.id);
                    }
                });

                projects_menu.add (item_menu);
            }
        }

        projects_menu.show_all ();

        menu.popup_at_pointer (null);
    }

    private void build_context_menu (Objects.Section section) {
        menu = new Gtk.Menu ();
        menu.width_request = 200;

        var add_menu = new Widgets.ImageMenuItem (_("Add task"), "list-add-symbolic");

        var edit_menu = new Widgets.ImageMenuItem (_("Edit section"), "edit-symbolic");

        var move_project_menu = new Widgets.ImageMenuItem (_("Move section"), "go-jump-symbolic");
        projects_menu = new Gtk.Menu ();
        move_project_menu.set_submenu (projects_menu);

        var delete_menu = new Widgets.ImageMenuItem (_("Delete section"), "user-trash-symbolic");

        menu.add (add_menu);
        menu.add (new Gtk.SeparatorMenuItem ());
        menu.add (edit_menu);
        menu.add (move_project_menu);
        menu.add (new Gtk.SeparatorMenuItem ());
        menu.add (delete_menu);

        menu.show_all (); 

        add_menu.activate.connect (() => {
            add_new_item (true);
        });

        edit_menu.activate.connect (() => {
            name_stack.visible_child_name = "name_entry";
            name_entry.grab_focus ();
        });

        delete_menu.activate.connect (() => {
            var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (
                _("Delete section"),
                _("Are you sure you want to delete <b>%s</b>?".printf (section.name)),
                "user-trash-full",
            Gtk.ButtonsType.CANCEL);

            var remove_button = new Gtk.Button.with_label (_("Delete"));
            remove_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
            message_dialog.add_action_widget (remove_button, Gtk.ResponseType.ACCEPT);

            message_dialog.show_all ();

            if (message_dialog.run () == Gtk.ResponseType.ACCEPT) {
                if (section.is_todoist == 0) {
                    Application.database.delete_section (section);
                } else {
                    Application.todoist.delete_section (section);
                }
            }

            message_dialog.destroy ();
        });
    }

    public void add_all_items () {            
        foreach (Objects.Item item in Application.database.get_all_items_by_section_no_parent (section)) {
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

        section.save_local ();
    }

    public void save_section () {
        name_label.label = name_entry.text;
        section.name = name_entry.text;

        section.save ();

        name_stack.visible_child_name = "name_label";
    }

    private void build_drag_and_drop (bool value) {
        name_stack.drag_data_received.disconnect (on_drag_item_received);
        name_stack.drag_data_received.disconnect (on_drag_magic_button_received);

        if (value) {
            Gtk.drag_dest_set (name_stack, Gtk.DestDefaults.ALL, targetEntriesMagicButton, Gdk.DragAction.MOVE);
            name_stack.drag_data_received.connect (on_drag_magic_button_received);
            name_stack.drag_motion.connect (on_drag_magicbutton_motion);
            name_stack.drag_leave.connect (on_drag_magicbutton_leave);
        } else {
            Gtk.drag_dest_set (this, Gtk.DestDefaults.MOTION, targetEntriesSection, Gdk.DragAction.MOVE);
            drag_motion.connect (on_drag_motion);
            drag_leave.connect (on_drag_leave); 
        }
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
            if (source.item.section_id != section.id) {
                source.item.section_id = section.id;
    
                if (source.item.is_todoist == 1) {
                    print ("Item para actualizar: %s\n".printf (source.item.content));
                    Application.todoist.move_item_to_section (source.item, section.id);
                }
            }
               
            source.get_parent ().remove (source); 
            listbox.insert (source, target.get_index () + 1);
            listbox.show_all ();

            update_item_order ();
        }
    }

    private void on_drag_magic_button_received (Gdk.DragContext context, int x, int y, Gtk.SelectionData selection_data, uint target_type, uint time) {
        add_new_item ();
    }

    private void add_new_item (bool last=false) {
        var new_item = new Widgets.NewItem (
            section.project_id,
            section.id, 
            section.is_todoist
        );

        if (last) {
            listbox.add (new_item);
        } else {
            new_item.has_index = true;
            new_item.index = 0;
            listbox.insert (new_item, 0);
        }

        listbox.show_all ();
        listbox_revealer.reveal_child = true;
    }

    private void on_drag_item_received (Gdk.DragContext context, int x, int y, Gtk.SelectionData selection_data, uint target_type) {
        Widgets.ItemRow source;
        var row = ((Gtk.Widget[]) selection_data.get_data ())[0];
        source = (Widgets.ItemRow) row;

        if (source.item.section_id != section.id) {
            source.item.section_id = section.id;

            if (source.item.is_todoist == 1) {
                print ("Item para actualizar: %s\n".printf (source.item.content));
                Application.todoist.move_item_to_section (source.item, section.id);
            }
        }

        source.get_parent ().remove (source); 
        listbox.insert (source, 0);
        listbox.show_all ();
    
        update_item_order ();

        listbox_revealer.reveal_child = true;
        section.collapsed = 1;

        save_section ();
    }

    public bool on_drag_motion (Gdk.DragContext context, int x, int y, uint time) {
        motion_section_revealer.reveal_child = true;
        return true;
    }
    
    public void on_drag_leave (Gdk.DragContext context, uint time) {
        motion_section_revealer.reveal_child = false;
    }

    public bool on_drag_magicbutton_motion (Gdk.DragContext context, int x, int y, uint time) {
        separator.visible = false;
        motion_revealer.reveal_child = true;
        return true;
    }
    
    public void on_drag_magicbutton_leave (Gdk.DragContext context, uint time) {
        separator.visible = true;
        motion_revealer.reveal_child = false;
    }

    private void update_item_order () {
        listbox.foreach ((widget) => {
            var row = (Gtk.ListBoxRow) widget;
            int index = row.get_index ();

            var item = ((Widgets.ItemRow) row).item;

            new Thread<void*> ("update_item_order", () => {
                Application.database.update_item_order (item, section.id, index);

                return null;
            });
        });
    }

    private void on_drag_begin (Gtk.Widget widget, Gdk.DragContext context) {
        var row = (Widgets.SectionRow) widget;

        Gtk.Allocation alloc;
        row.get_allocation (out alloc);

        var surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, alloc.width, alloc.height);
        var cr = new Cairo.Context (surface);
        cr.set_source_rgba (0, 0, 0, 0.3);
        cr.set_line_width (1);

        cr.move_to (0, 0);
        cr.line_to (alloc.width, 0);
        cr.line_to (alloc.width, alloc.height);
        cr.line_to (0, alloc.height);
        cr.line_to (0, 0);
        cr.stroke ();
  
        cr.set_source_rgba (255, 255, 255, 0.5);
        cr.rectangle (0, 0, alloc.width, alloc.height);
        cr.fill ();

        row.draw (cr);
        Gtk.drag_set_icon_surface (context, surface);
        main_revealer.reveal_child = false;
    }

    private void on_drag_data_get (Gtk.Widget widget, Gdk.DragContext context, Gtk.SelectionData selection_data, uint target_type, uint time) {
        uchar[] data = new uchar[(sizeof (Widgets.SectionRow))];
        ((Gtk.Widget[])data)[0] = widget;

        selection_data.set (
            Gdk.Atom.intern_static_string ("SECTIONROW"), 32, data
        );
    }

    public void clear_indicator (Gdk.DragContext context) {
        main_revealer.reveal_child = true;
    }
}