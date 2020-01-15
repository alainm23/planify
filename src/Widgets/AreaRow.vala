public class Widgets.AreaRow : Gtk.ListBoxRow {
    public Objects.Area area { get; construct; }

    private Gtk.Button hidden_button;
    //private Gtk.Label count_label;
    private Gtk.Label name_label; 
    private Gtk.Entry name_entry;
    private Gtk.Stack name_stack;
    private Gtk.EventBox top_eventbox;
    private Gtk.ListBox listbox;
    private Gtk.Revealer listbox_revealer;
    private Gtk.Revealer motion_revealer;
    private Gtk.Revealer action_revealer;
    private Gtk.Menu menu = null;

    private uint timeout;

    private const Gtk.TargetEntry[] targetEntries = {
        {"PROJECTROW", Gtk.TargetFlags.SAME_APP, 0}
    };

    public bool set_focus {
        set {
            action_revealer.reveal_child = true;
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
        area_image.halign = Gtk.Align.CENTER;
        area_image.valign = Gtk.Align.CENTER;
        area_image.gicon = new ThemedIcon ("planner-work-area-symbolic");
        area_image.get_style_context ().add_class ("text-color");
        area_image.get_style_context ().add_class ("dim-label");
        area_image.pixel_size = 16;

        hidden_button = new Gtk.Button.from_icon_name ("pan-end-symbolic", Gtk.IconSize.MENU);
        hidden_button.can_focus = false;
        hidden_button.halign = Gtk.Align.CENTER;
        hidden_button.valign = Gtk.Align.CENTER;
        hidden_button.get_style_context ().remove_class ("button");
        hidden_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        hidden_button.get_style_context ().add_class ("hidden-button");
        hidden_button.get_style_context ().add_class ("dim-label");

        var stack = new Gtk.Stack ();
        stack.margin_start = 9;
        stack.halign = Gtk.Align.CENTER;
        stack.transition_type = Gtk.StackTransitionType.CROSSFADE;

        stack.add_named (area_image, "area_image");
        stack.add_named (hidden_button, "hidden_button");

        name_label =  new Gtk.Label (area.name);
        name_label.halign = Gtk.Align.START;
        name_label.get_style_context ().add_class ("pane-area");
        name_label.valign = Gtk.Align.CENTER;
        name_label.set_ellipsize (Pango.EllipsizeMode.END);

        var count_label = new Gtk.Label ("<small>%s</small>".printf (""));
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

        if (area.collapsed == 1) {
            hidden_button.get_style_context ().add_class ("opened");
        }

        /*
        var hidden_revealer = new Gtk.Revealer ();
        hidden_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        hidden_revealer.add (hidden_button);
        hidden_revealer.reveal_child = false;
        */

        var top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3);
        top_box.pack_start (stack, false, false, 0);
        top_box.pack_start (name_stack, false, true, 0);
        //top_box.pack_end (hidden_revealer, false, false, 0);

        var submit_button = new Gtk.Button.with_label (_("Save"));
        submit_button.sensitive = false;
        submit_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        submit_button.get_style_context ().add_class ("new-item-action-button");

        var cancel_button = new Gtk.Button.with_label (_("Cancel"));
        cancel_button.get_style_context ().add_class ("new-item-action-button");

        var action_grid = new Gtk.Grid ();
        action_grid.halign = Gtk.Align.START;
        action_grid.column_homogeneous = true;
        action_grid.column_spacing = 6;
        action_grid.margin_start = 40;
        action_grid.margin_top = 6;
        action_grid.add (cancel_button);
        action_grid.add (submit_button);

        action_revealer = new Gtk.Revealer ();
        action_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        action_revealer.add (action_grid);
        action_revealer.reveal_child = false;

        top_eventbox = new Gtk.EventBox ();
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
        main_box.pack_start (action_revealer, false, false, 0);
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
                Planner.utils.pane_project_selected (project.id, area.id);
            }
        });

        name_entry.activate.connect (() =>{
            save_area ();
        });

        name_entry.changed.connect (() => {
            if (name_entry.text != "") {
                submit_button.sensitive = true;
            } else {
                submit_button.sensitive = false;
            }
        });
        
        name_entry.key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                save_area ();
            }

            return false;
        });

        submit_button.clicked.connect (() => {
            save_area ();
        });
        
        cancel_button.clicked.connect (() => {
            action_revealer.reveal_child = false;
            name_stack.visible_child_name = "name_label";
        });

        top_eventbox.event.connect ((event) => {
            if (event.type == Gdk.EventType.@2BUTTON_PRESS) {
                action_revealer.reveal_child = true;
                name_stack.visible_child_name = "name_entry";

                name_entry.grab_focus_without_selecting ();

                if (name_entry.cursor_position < name_entry.text.length) {
                    name_entry.move_cursor (Gtk.MovementStep.BUFFER_ENDS, 0, false);
                }
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
            stack.visible_child_name = "hidden_button";
            return true;
        });

        top_eventbox.leave_notify_event.connect ((event) => {
            if (event.detail == Gdk.NotifyType.INFERIOR) {
                return false;
            }

            stack.visible_child_name = "area_image";
            
            return true;
        });

        Planner.database.project_added.connect ((project) => {
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

        Planner.database.project_moved.connect ((project) => {
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

        Planner.utils.pane_project_selected.connect ((project_id, area_id) => {
            if (area.id != area_id || area_id == 0) {
                listbox.unselect_all ();
            }
        });

        Planner.utils.pane_action_selected.connect (() => {
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
        foreach (Objects.Project project in Planner.database.get_all_projects_by_area (area.id)) {
            if (project.inbox_project == 0) {
                var row = new Widgets.ProjectRow (project);
                listbox.add (row);

                if (Planner.settings.get_boolean ("homepage-project")) {
                    if (Planner.settings.get_int64 ("homepage-project-id") == project.id) {
                        timeout = Timeout.add (125, () => {
                            listbox.select_row (row);
    
                            Source.remove (timeout);
                            return false;
                        });
                    }
                }
            }
            
        }

        listbox.show_all ();
    }

    public void save_area () {
        if (name_entry.text != "") {
            area.name = name_entry.text;
            name_label.label = area.name;

            area.save ();
            action_revealer.reveal_child = false;
            name_stack.visible_child_name = "name_label";
        }
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
                Planner.database.update_project_item_order (project.id, area.id, index);

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

        var edit_menu = new Widgets.ImageMenuItem (_("Edit area"), "edit-symbolic");

        var delete_menu = new Widgets.ImageMenuItem (_("Delete area"), "user-trash-symbolic");

        menu.add (edit_menu);
        menu.add (delete_menu);

        menu.show_all ();

        edit_menu.activate.connect (() => {
            action_revealer.reveal_child = true;
            name_stack.visible_child_name = "name_entry";
            
            name_entry.grab_focus_without_selecting ();

            if (name_entry.cursor_position < name_entry.text.length) {
                name_entry.move_cursor (Gtk.MovementStep.BUFFER_ENDS, 0, false);
            }
        }); 

        delete_menu.activate.connect (() => {
            var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (
                _("Delete area"),
                _("Are you sure you want to delete <b>%s</b>?".printf (area.name)),
                "user-trash-full",
                Gtk.ButtonsType.CLOSE
            );
            
            Gtk.CheckButton custom_widget = null;
            if (Planner.database.projects_area_exists (area.id)) {
                custom_widget = new Gtk.CheckButton.with_label (_("Delete projects"));
                custom_widget.show ();
                message_dialog.custom_bin.add (custom_widget);
            }

            var remove_button = new Gtk.Button.with_label (_("Delete"));
            remove_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
            message_dialog.add_action_widget (remove_button, Gtk.ResponseType.ACCEPT);

            message_dialog.show_all ();

            if (message_dialog.run () == Gtk.ResponseType.ACCEPT) {
                if (Planner.database.delete_area (area)) {
                    if (custom_widget != null && custom_widget.active) {
                        delete_projects ();
                    } else {
                        move_projects ();
                    }
                }
            }

            message_dialog.destroy ();
        });
    }

    private void move_projects () {
        foreach (Objects.Project project in Planner.database.get_all_projects_by_area (area.id)) {
            Planner.database.move_project (project, 0);
        }

        destroy ();
    }

    private void delete_projects () {
        foreach (Objects.Project project in Planner.database.get_all_projects_by_area (area.id)) {
            Planner.database.delete_project (project.id);
            if (project.is_todoist == 1) {
                Planner.todoist.delete_project (project);
            }
        }

        destroy ();
    }
}