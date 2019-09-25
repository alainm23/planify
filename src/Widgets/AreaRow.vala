public class Widgets.AreaRow : Gtk.ListBoxRow {
    public Objects.Area area { get; construct; }

    private Gtk.Label name_label; 
    private Gtk.Label count_label;
    private Gtk.Entry name_entry;
    private Gtk.Stack name_stack;
    private Gtk.EventBox top_eventbox;
    private Gtk.ListBox listbox;
    private Gtk.Revealer listbox_revealer;
    private Gtk.Revealer motion_revealer;
    private Gtk.Menu menu = null;
    private string count = "";
    private Gee.ArrayList<Objects.Project?> all;

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
        all = Application.database.get_all_projects_by_area (area.id);

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

        name_entry = new Gtk.Entry (); 
        name_entry.placeholder_text = _("Task name");
        name_entry.get_style_context ().add_class ("flat");
        name_entry.get_style_context ().add_class ("pane-area");
        name_entry.get_style_context ().add_class ("pane-entry");

        name_entry.text = area.name;
        name_entry.hexpand = true;

        name_stack = new Gtk.Stack ();
        name_stack.transition_type = Gtk.StackTransitionType.NONE;
        name_stack.add_named (name_label, "name_label");
        name_stack.add_named (name_entry, "name_entry");

        var name_eventbox = new Gtk.EventBox ();
        name_eventbox.add (name_stack);

        var options_button = new Gtk.Button.from_icon_name ("view-more-symbolic", Gtk.IconSize.MENU);
        options_button.valign = Gtk.Align.CENTER;
        options_button.can_focus = false;
        options_button.tooltip_text = _("Options");
        options_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        options_button.get_style_context ().add_class ("delete-check-button");
        options_button.get_style_context ().add_class ("dim-label");

        var options_revealer = new Gtk.Revealer ();
        options_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        options_revealer.add (options_button);

        var top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        top_box.margin_start = 7;
        top_box.pack_start (area_image, false, false, 0);
        top_box.pack_start (name_eventbox, false, true, 0);
        top_box.pack_end (options_revealer, false, false, 0);

        top_eventbox = new Gtk.EventBox ();
        top_eventbox.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        top_eventbox.add (top_box);
        if (area.defaul_area == 1) {
            top_box.visible = false;
            top_box.no_show_all = true;
        }

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

        if (area.reveal == 1) {
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

        top_eventbox.event.connect ((event) => {
            if (event.type == Gdk.EventType.BUTTON_PRESS) {
                toggle_hidden ();
            }

            return false;
        });

        top_eventbox.enter_notify_event.connect ((event) => {
            options_revealer.reveal_child = true;

            return false;
        });

        top_eventbox.leave_notify_event.connect ((event) => {
            if (event.detail == Gdk.NotifyType.INFERIOR) {
                return false;
            }

            options_revealer.reveal_child = false;
            return false;
        });

        options_button.clicked.connect (() => {
            activate_menu ();
        });

        Application.database.project_added.connect ((project) => {
            Idle.add (() => {
                if (project.inbox_project == 0 && project.area_id == area.id) {
                    var row = new Widgets.ProjectRow (project);
                    listbox.add (row);
                    listbox.show_all ();

                    listbox_revealer.reveal_child = true;
                    area.reveal = 1;

                    save_area ();

                    all.add (project);

                    count = "";
                    if (all.size > 0) {
                        count = "%i".printf (all.size);
                    }
                    count_label.label = count;
                }

                return false;
            });
        });

        Application.database.project_deleted.connect ((project) => {
            if (project.area_id == area.id) {
                all.remove (project);
                count_label.label = "%i".printf (all.size);

                count = "";
                if (all.size > 0) {
                    count = "%i".printf (all.size);
                }
                
                count_label.label = count;
            }
        });

        Application.utils.pane_project_selected.connect ((project_id, area_id) => {
            if (area.id != area_id) {
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
            area.reveal = 0;
        } else {
            listbox_revealer.reveal_child = true;
            area.reveal = 1;
        }

        save_area ();
    }

    public void add_all_projects () {            
        foreach (Objects.Project project in all) {
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
            listbox.insert (source, target.get_index () + 1);
            listbox.show_all ();

            update_project_order ();         
        } else {
            source.get_parent ().remove (source); 
            listbox.insert (source, (int) listbox.get_children ().length);
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
        area.reveal = 1;

        save_area ();
    }

    public bool on_drag_motion (Gdk.DragContext context, int x, int y, uint time) {
        motion_revealer.reveal_child = true;
        return true;
    }
    
    public void on_drag_leave (Gdk.DragContext context, uint time) {
        print ("Salio \n");
        motion_revealer.reveal_child = false;
    }

    private void update_project_order () {
        listbox.foreach ((widget) => {
            var row = (Gtk.ListBoxRow) widget;
            int index = row.get_index ();

            var project = ((ProjectRow) row).project;

            new Thread<void*> ("update_project_order", () => {
                Application.database.update_project_child_order (project.id, area.id, index);

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
        
        var edit_menu = new Widgets.MenuItem (_("Edit area"), "edit-symbolic", _("Edit area"));
        var delete_menu = new Widgets.MenuItem (_("Delete area"), "edit-delete-symbolic", _("Delete area"));

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