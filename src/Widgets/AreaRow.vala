public class Widgets.AreaRow : Gtk.ListBoxRow {
    public Objects.Area area { get; construct; }

    private Gtk.Label name_label; 
    private Gtk.Label count_label;
    private Gtk.Entry name_entry;
    private Gtk.Stack name_stack;
    private Gtk.Button hidden_button;
    private Gtk.ListBox listbox;
    private Gtk.Revealer listbox_revealer;
    private Gtk.Revealer motion_revealer;

    private const Gtk.TargetEntry[] targetEntries = {
        {"PROJECTROW", Gtk.TargetFlags.SAME_APP, 0}
    };

    public AreaRow (Objects.Area area) {
        Object (
            area: area
        );
    }

    construct {
        //margin_top = 6;
        can_focus = false;
        get_style_context ().add_class ("area-row");

        var area_image = new Gtk.Image ();
        area_image.halign = Gtk.Align.START;
        area_image.valign = Gtk.Align.CENTER;
        area_image.gicon = new ThemedIcon ("planner-work-area-symbolic");
        area_image.get_style_context ().add_class ("text-color");
        area_image.pixel_size = 16;

        count_label =  new Gtk.Label ("4");
        count_label.get_style_context ().add_class ("css");
        count_label.valign = Gtk.Align.CENTER;

        name_label =  new Gtk.Label (area.name);
        name_label.halign = Gtk.Align.START;
        name_label.get_style_context ().add_class ("pane-item");
        name_label.valign = Gtk.Align.CENTER;
        name_label.set_ellipsize (Pango.EllipsizeMode.END);

        var name_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        name_box.pack_start (name_label, false, false, 0);
        name_box.pack_start (count_label, false, true, 0);

        name_entry = new Gtk.Entry (); 
        name_entry.placeholder_text = _("Task name");
        name_entry.get_style_context ().add_class ("flat");
        name_entry.get_style_context ().add_class ("pane-item");
        name_entry.get_style_context ().add_class ("pane-entry");

        name_entry.text = area.name;
        name_entry.hexpand = true;

        name_stack = new Gtk.Stack ();
        name_stack.transition_type = Gtk.StackTransitionType.NONE;
        name_stack.add_named (name_box, "name_label");
        name_stack.add_named (name_entry, "name_entry");

        var name_eventbox = new Gtk.EventBox ();
        name_eventbox.add (name_stack);

        hidden_button = new Gtk.Button.from_icon_name ("pan-end-symbolic", Gtk.IconSize.MENU);
        hidden_button.can_focus = false;
        hidden_button.get_style_context ().remove_class ("button");
        hidden_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        hidden_button.get_style_context ().add_class ("hidden-button");

        var top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        top_box.margin_start = 7;
        top_box.pack_start (area_image, false, false, 0);
        top_box.pack_start (name_eventbox, false, true, 0);
        top_box.pack_end (hidden_button, false, false, 0);

        var top_eventbox = new Gtk.EventBox ();
        top_eventbox.add (top_box);

        var topbox_revealer = new Gtk.Revealer ();
        topbox_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
        topbox_revealer.add (top_eventbox);
        
        if (area.defaul_area == 0) {
            topbox_revealer.reveal_child = true;
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
        motion_grid.get_style_context ().add_class ("grid-motion");
        motion_grid.height_request = 24;
            
        motion_revealer = new Gtk.Revealer ();
        motion_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
        motion_revealer.add (motion_grid);

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.hexpand = true;
        main_box.margin_top = 6;
        main_box.pack_start (topbox_revealer, false, false, 0);
        main_box.pack_start (motion_revealer, false, false, 0);
        main_box.pack_start (listbox_revealer, false, false, 0);
        
        add (main_box);
        add_all_projects (area.id);
        build_drag_and_drop ();

        if (area.reveal == 1) {
            listbox_revealer.reveal_child = true;
            hidden_button.get_style_context ().add_class ("opened");
        }

        Application.database.project_added.connect ((project) => {
            Idle.add (() => {
                if (project.inbox_project == 0 && project.area_id == area.id) {
                    var row = new Widgets.ProjectRow (project);
                    listbox.add (row);
                    listbox.show_all ();

                    listbox_revealer.reveal_child = true;
                    hidden_button.get_style_context ().add_class ("opened");
                    area.reveal = 1;

                    save_area ();
                }

                return false;
            });
        });

        hidden_button.clicked.connect (() => {
            toggle_hidden ();
        });

        listbox.row_selected.connect ((row) => {
            if (row != null) {
                var project = ((Widgets.ProjectRow) row).project;
                Application.utils.pane_project_selected (project.id, area.id);
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

        name_eventbox.event.connect ((event) => {
            if (event.type == Gdk.EventType.@2BUTTON_PRESS) {
                name_stack.visible_child_name = "name_entry";
                name_entry.grab_focus ();
            }

            return false;
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
    }

    private void toggle_hidden () {
        if (listbox_revealer.reveal_child) {
            listbox_revealer.reveal_child = false;
            hidden_button.get_style_context ().remove_class ("opened");
            area.reveal = 0;
        } else {
            listbox_revealer.reveal_child = true;
            hidden_button.get_style_context ().add_class ("opened");
            area.reveal = 1;
        }

        save_area ();
    }

    public void add_all_projects (int64 id) {            
        foreach (Objects.Project project in Application.database.get_all_projects_by_area (id)) {
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
        if (area.save ()) {
            name_stack.visible_child_name = "name_label";
        }
    }

    private void build_drag_and_drop () {
        Gtk.drag_dest_set (listbox, Gtk.DestDefaults.ALL, targetEntries, Gdk.DragAction.MOVE);
        listbox.drag_data_received.connect (on_drag_data_received);

        Gtk.drag_dest_set (this, Gtk.DestDefaults.ALL, targetEntries, Gdk.DragAction.MOVE);
        this.drag_data_received.connect (on_drag_project_received);
        this.drag_motion.connect (on_drag_motion);
        this.drag_leave.connect (on_drag_leave);
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
            listbox.insert (source, target.get_index ());
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

        if (get_listbox_size () <= 0) {
            source.get_parent ().remove (source); 
            listbox.insert (source, (int) listbox.get_children ().length);
            listbox.show_all ();
        
            update_project_order ();

            listbox_revealer.reveal_child = true;
            hidden_button.get_style_context ().add_class ("opened");
            area.reveal = 1;

            save_area ();
        }
    }

    public bool on_drag_motion (Gdk.DragContext context, int x, int y, uint time) {
        if (get_listbox_size () <= 0) {
            motion_revealer.reveal_child = true;
        }

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
                Application.database.update_project_child_order (project.id, area.id, index);

                return null;
            });
        });
    }

    private int get_listbox_size () {
        int c = 0;
        listbox.foreach ((widget) => {
            c++;
        });

        return c;
    }
}