public class Widgets.AreaRow : Gtk.ListBoxRow {
    public Objects.Area area { get; construct; }

    private Gtk.Button hidden_button;
    private Gtk.Label name_label; 
    private Gtk.Label count_label;
    private Gtk.Entry name_entry;
    private Gtk.Stack name_stack;
    private Gtk.EventBox top_eventbox;
    private Gtk.ListBox listbox;
    private Gtk.Revealer listbox_revealer;
    private Gtk.Revealer motion_revealer;
    private Gtk.Menu menu = null;

    private const Gtk.TargetEntry[] targetEntries = {
        {"PROJECTROW", Gtk.TargetFlags.SAME_APP, 0}
    };

    public bool set_focus {
        set {
            name_stack.visible_child_name = "name_entry";
            name_entry.grab_focus ();
        }
    }

    public AreaRow (Objects.Area area) {
        Object (
            area: area
        );
    }

    construct {
        can_focus = false;
        get_style_context ().add_class ("area-row");

        var area_image = new Gtk.Image ();
        area_image.halign = Gtk.Align.START;
        area_image.valign = Gtk.Align.CENTER;
        area_image.gicon = new ThemedIcon ("planner-work-area-symbolic");
        area_image.get_style_context ().add_class ("text-color");
        area_image.pixel_size = 16;

        name_label =  new Gtk.Label (area.name);
        name_label.halign = Gtk.Align.START;
        name_label.get_style_context ().add_class ("pane-area");
        name_label.valign = Gtk.Align.CENTER;
        name_label.set_ellipsize (Pango.EllipsizeMode.END);

        var count_label = new Gtk.Label ("<small>%s</small>".printf ("8"));
        count_label.valign = Gtk.Align.CENTER;
        count_label.margin_top = 3;
        count_label.get_style_context ().add_class ("dim-label");
        count_label.use_markup = true;

        var info_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        info_box.pack_start (name_label, false, false, 0);
        info_box.pack_start (count_label, false, true, 0);

        name_entry = new Gtk.Entry (); 
        name_entry.placeholder_text = _("Task name");
        name_entry.get_style_context ().add_class ("flat");
        name_entry.get_style_context ().add_class ("pane-area");
        name_entry.get_style_context ().add_class ("pane-entry");

        name_entry.text = area.name;
        name_entry.hexpand = true;

        name_stack = new Gtk.Stack ();
        name_stack.transition_type = Gtk.StackTransitionType.NONE;
        name_stack.add_named (info_box, "name_label");
        name_stack.add_named (name_entry, "name_entry");

        hidden_button = new Gtk.Button.from_icon_name ("pan-end-symbolic", Gtk.IconSize.MENU);
        hidden_button.can_focus = false;
        hidden_button.get_style_context ().remove_class ("button");
        hidden_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        hidden_button.get_style_context ().add_class ("hidden-button");
        hidden_button.get_style_context ().add_class ("dim-label");

        if (area.collapsed == 1) {
            hidden_button.get_style_context ().add_class ("opened");
        }

        var hidden_revealer = new Gtk.Revealer ();
        hidden_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        hidden_revealer.add (hidden_button);
        hidden_revealer.reveal_child = false;

        var top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        top_box.margin_start = 6;
        top_box.margin_end = 2;
        top_box.pack_start (area_image, false, false, 0);
        top_box.pack_start (name_stack, false, true, 0);
        top_box.pack_end (hidden_revealer, false, false, 0);

        top_eventbox = new Gtk.EventBox ();
        top_eventbox.margin_start = 6;
        top_eventbox.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        top_eventbox.add (top_box);
 
        listbox = new Gtk.ListBox  ();
        listbox.valign = Gtk.Align.START;
        listbox.get_style_context ().add_class ("pane");
        listbox.activate_on_single_click = true;
        listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        listbox.hexpand = true;
 
        listbox_revealer = new Gtk.Revealer ();
        listbox_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        listbox_revealer.add (listbox);
        listbox_revealer.reveal_child = false;

        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator.margin_start = 6;
        separator.margin_end = 6;
        
        var motion_grid = new Gtk.Grid ();
        motion_grid.height_request = 24;
        motion_grid.get_style_context ().add_class ("grid-motion");
            
        motion_revealer = new Gtk.Revealer ();
        motion_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        motion_revealer.add (motion_grid);

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.hexpand = true;
        main_box.margin_bottom = 6;
        main_box.pack_start (top_eventbox, false, false, 0);
        main_box.pack_start (motion_revealer, false, false, 0);
        main_box.pack_start (listbox_revealer, false, false, 0);

        add (main_box);
        add_all_projects ();
        build_drag_and_drop ();

        if (area.collapsed == 1) {
            listbox_revealer.reveal_child = true;
        }

        listbox.row_selected.connect ((row) => {
            if (row != null) {
                var project = ((Widgets.ProjectRow) row).project;
                Application.utils.pane_project_selected (project.id, area.id);
            }
        });

        name_entry.activate.connect (() =>{
            save_area ();
        });

        name_entry.focus_out_event.connect (() => {
            save_area ();
            return false;
        });

        name_entry.key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                save_area ();
            }

            return false;
        });

        event.connect ((event) => {
            if (event.type == Gdk.EventType.@2BUTTON_PRESS) {
                name_stack.visible_child_name = "name_entry";
                name_entry.grab_focus ();
            }

            return false;
        });

        button_press_event.connect ((sender, evt) => {
            if (evt.type == Gdk.EventType.BUTTON_PRESS && evt.button == 3) {
                activate_menu ();
                return true;
            }

            return false;
        });

        hidden_button.clicked.connect (() => {
            toggle_hidden ();
        });

        top_eventbox.enter_notify_event.connect ((event) => {
            hidden_revealer.reveal_child = true;
            return true;
        });

        top_eventbox.leave_notify_event.connect ((event) => {
            if (event.detail == Gdk.NotifyType.INFERIOR) {
                return false;
            }

            hidden_revealer.reveal_child = false;
            
            return true;
        });

        Application.database.project_added.connect ((project) => {
            Idle.add (() => {
                if (project.inbox_project == 0 && project.area_id == area.id) {
                    var row = new Widgets.ProjectRow (project);
                    listbox.add (row);
                    listbox.show_all ();

                    listbox_revealer.reveal_child = true;
                    area.collapsed = 1;

                    save_area ();
                }

                return false;
            });
        });

        Application.database.project_moved.connect ((project) => {
            Idle.add (() => {
                if (project.area_id == area.id) {
                    var row = new Widgets.ProjectRow (project);
                    listbox.add (row);
                    listbox.show_all ();

                    listbox_revealer.reveal_child = true;
                    area.collapsed = 1;

                    save_area ();
                }

                return false;
            });
        });

        Application.utils.pane_project_selected.connect ((project_id, area_id) => {
            if (area.id != area_id || area_id == 0) {
                listbox.unselect_all ();
            }
        });

        Application.utils.pane_action_selected.connect (() => {
            listbox.unselect_all ();
        });
    }

    private void toggle_hidden () {
        if (listbox_revealer.reveal_child) {
            listbox_revealer.reveal_child = false;
            hidden_button.get_style_context ().remove_class ("opened");
            area.collapsed = 0;
        } else {
            listbox_revealer.reveal_child = true;
            hidden_button.get_style_context ().add_class ("opened");
            area.collapsed = 1;
        }

        save_area ();
    }

    public void add_all_projects () {            
        foreach (Objects.Project project in Application.database.get_all_projects_by_area (area.id)) {
            if (project.inbox_project == 0) {
                var row = new Widgets.ProjectRow (project);
                listbox.add (row);
            }
            
        }

        listbox.show_all ();
    }

    public void save_area () {
        area.name = name_entry.text;
        name_label.label = area.name;

        area.save ();
        name_stack.visible_child_name = "name_label";
    }

    private void build_drag_and_drop () {
        Gtk.drag_dest_set (listbox, Gtk.DestDefaults.ALL, targetEntries, Gdk.DragAction.MOVE);
        listbox.drag_data_received.connect (on_drag_data_received);

        Gtk.drag_dest_set (top_eventbox, Gtk.DestDefaults.ALL, targetEntries, Gdk.DragAction.MOVE);
        top_eventbox.drag_data_received.connect (on_drag_project_received);
        top_eventbox.drag_motion.connect (on_drag_motion);
        top_eventbox.drag_leave.connect (on_drag_leave);
    }
    
    private void on_drag_data_received (Gdk.DragContext context, int x, int y, Gtk.SelectionData selection_data, uint target_type, uint time) {
        Widgets.ProjectRow target;
        Widgets.ProjectRow source;
        Gtk.Allocation alloc;

        target = (Widgets.ProjectRow ) listbox.get_row_at_y (y);
        target.get_allocation (out alloc);
        
        var row = ((Gtk.Widget[]) selection_data.get_data ())[0];
        source = (Widgets.ProjectRow ) row;
        
        print ("-----------\n");
        print ("TARGET: %s\n".printf (target.project.name));
        print ("SOURCE: %s\n".printf (source.project.name));
        print ("-----------\n");

        if (target != null) {
            source.get_parent ().remove (source); 

            source.project.area_id = area.id;

            listbox.insert (source, target.get_index () + 1);
            listbox.show_all ();

            update_project_order ();         
        }
    }

    private void on_drag_project_received (Gdk.DragContext context, int x, int y, Gtk.SelectionData selection_data, uint target_type) {
        Widgets.ProjectRow source;
        var row = ((Gtk.Widget[]) selection_data.get_data ())[0];
        source = (Widgets.ProjectRow) row;

        source.get_parent ().remove (source); 
        listbox.insert (source, 0);
        listbox.show_all ();
    
        update_project_order ();

        listbox_revealer.reveal_child = true;
        area.collapsed = 1;

        save_area ();
    }

    public bool on_drag_motion (Gdk.DragContext context, int x, int y, uint time) {
        motion_revealer.reveal_child = true;
        return true;
    }
    
    public void on_drag_leave (Gdk.DragContext context, uint time) {
        motion_revealer.reveal_child = false;
    }

    private void update_project_order () {
        listbox.foreach ((widget) => {
            var row = (Gtk.ListBoxRow) widget;
            int index = row.get_index ();

            var project = ((ProjectRow) row).project;

            new Thread<void*> ("update_project_order", () => {
                Application.database.update_project_item_order (project.id, area.id, index);

                return null;
            });
        });
    }

    private void activate_menu () {
        if (menu == null) {
            build_context_menu (area);
        }

        menu.popup_at_pointer (null);
    }

    private void build_context_menu (Objects.Area area) {
        menu = new Gtk.Menu ();
        menu.width_request = 200;

        var edit_menu = new Widgets.ImageMenuItem (_("Edit Work Area"), "edit-symbolic");

        var delete_menu = new Widgets.ImageMenuItem (_("Delete Work Area"), "edit-delete-symbolic");

        menu.add (edit_menu);
        menu.add (delete_menu);

        menu.show_all ();

        edit_menu.activate.connect (() => {
            name_stack.visible_child_name = "name_entry";
            name_entry.grab_focus ();
        }); 

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
}