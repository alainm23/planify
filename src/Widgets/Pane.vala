public class Widgets.Pane : Gtk.EventBox {
    private Gtk.Stack stack;
    public Widgets.New new_project;
    
    //private Widgets.ActionRow search_row;
    private Widgets.ActionRow inbox_row;
    private Widgets.ActionRow today_row;
    private Widgets.ActionRow upcoming_row;
    
    private Gtk.ListBox listbox;
    private Gtk.ListBox project_listbox;
    private Gtk.ListBox area_listbox;

    private Gtk.Button add_button;
    private Gtk.Button sync_button;

    private Gtk.Image sync_image;
    private Gtk.Image error_image;

    public signal void activated (int id);
    private uint timeout;

    private const Gtk.TargetEntry[] targetEntries = {
        {"PROJECTROW", Gtk.TargetFlags.SAME_APP, 0}
    };

    public bool sensitive_ui {
        set {
            if (value) {
                stack.visible_child_name = "scrolled";
            } else {
                stack.visible_child_name = "grid";
            }
        }
    }

    construct {
        //search_row = new Widgets.ActionRow (_("Quick Find"), "system-search-symbolic", "search", _("Your Inbox is the default place to add new tasks so you can get them out of your head quickly, then come back and make a plan to take care of them later. It’s a great way to declutter your mind so you can focus on whatever you’re doing right now."));
        inbox_row = new Widgets.ActionRow (_("Inbox"), "mail-mailbox-symbolic", "inbox", _("Your Inbox is the default place to add new tasks so you can get them out of your head quickly, then come back and make a plan to take care of them later. It’s a great way to declutter your mind so you can focus on whatever you’re doing right now."));

        string today_icon = "planner-today-day-symbolic";
        var hour = new GLib.DateTime.now_local ().get_hour ();
        if (hour >= 18 || hour <= 5) {
            today_icon = "planner-today-night-symbolic";
        }

        today_row = new Widgets.ActionRow (_("Today"), today_icon, "today", _("The Today view lets you see all the tasks due today across all your projects. Check in here every morning to make a realistic plan to tackle your day."));
        upcoming_row = new Widgets.ActionRow (_("Upcoming"), "x-office-calendar-symbolic", "upcoming", _("Plan your week ahead with the Upcoming view. It shows everything on your agenda for the coming days: scheduled to-dos and calendar events."));
        var back_row = new Widgets.ActionRow (_("Back-Pocket"), "user-trash-symbolic", "upcoming", _("Upcoming"));

        var add_icon = new Gtk.Image ();
        add_icon.valign = Gtk.Align.CENTER;
        add_icon.gicon = new ThemedIcon ("list-add-symbolic");
        add_icon.pixel_size = 16;

        add_button = new Gtk.Button ();
        add_button.image = add_icon;
        add_button.valign = Gtk.Align.CENTER;
        add_button.margin_bottom = 6;
        add_button.margin_start = 6;
        add_button.halign = Gtk.Align.START;
        add_button.always_show_image = true;
        add_button.can_focus = false;
        add_button.label = _("Add list");
        add_button.get_style_context ().add_class ("flat");
        add_button.get_style_context ().add_class ("font-bold");
        add_button.get_style_context ().add_class ("add-button");

        var add_revealer = new Gtk.Revealer ();
        add_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        add_revealer.reveal_child = true;
        add_revealer.add (add_button);

        listbox = new Gtk.ListBox  ();
        listbox.get_style_context ().add_class ("pane");
        listbox.get_style_context ().add_class ("welcome");
        listbox.activate_on_single_click = true;
        listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        listbox.hexpand = true;

        //listbox.add (search_row);
        listbox.add (inbox_row);
        listbox.add (today_row);
        listbox.add (upcoming_row);
        //listbox.add (back_row);

        var top_eventbox = new Gtk.EventBox ();
        top_eventbox.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);

        project_listbox = new Gtk.ListBox  ();
        project_listbox.get_style_context ().add_class ("pane");
        project_listbox.get_style_context ().add_class ("welcome");
        project_listbox.activate_on_single_click = true;
        project_listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        project_listbox.hexpand = true;
        
        area_listbox = new Gtk.ListBox  ();
        area_listbox.get_style_context ().add_class ("pane");
        area_listbox.get_style_context ().add_class ("welcome");
        area_listbox.activate_on_single_click = true;
        area_listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        area_listbox.hexpand = true;

        var listbox_grid = new Gtk.Grid ();
        listbox_grid.orientation = Gtk.Orientation.VERTICAL;
        listbox_grid.add (listbox);
        //listbox_grid.add (top_eventbox);
        listbox_grid.add (project_listbox);
        listbox_grid.add (area_listbox);

        var listbox_scrolled = new Gtk.ScrolledWindow (null, null);
        //listbox_scrolled.width_request = 246;
        listbox_scrolled.hexpand = true;
        listbox_scrolled.add (listbox_grid);

        new_project = new Widgets.New ();

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.expand = true;
        main_box.get_style_context ().add_class ("pane");
        //main_box.pack_start (profile_box, false, false, 0);
        main_box.pack_start (listbox_scrolled, true, true, 0);   
        main_box.pack_end (add_revealer, false, false, 0);  

        var overlay = new Gtk.Overlay ();
        overlay.add_overlay (new_project);
        overlay.add (main_box); 

        var grid = new Gtk.Grid ();
        grid.get_style_context ().add_class ("pane");
        grid.expand = true;

        stack = new Gtk.Stack ();
        stack.expand = true;
        stack.transition_type = Gtk.StackTransitionType.CROSSFADE;

        stack.add_named (overlay, "scrolled");
        stack.add_named (grid, "grid");

        //var main_revealer = new Gtk.Revealer ();
        //main_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
        //main_revealer.add (stack);
        
        add (stack);
        build_drag_and_drop ();
        check_network ();

        listbox.row_selected.connect ((row) => {
            if (row != null) {
                activated (row.get_index ());
                Planner.utils.pane_action_selected ();
                project_listbox.unselect_all ();

                var action = (Widgets.ActionRow) row;

                action.icon.get_style_context ().add_class ("active");

                Timeout.add (700, () => {
                    action.icon.get_style_context ().remove_class ("active");
                    return false;
                });
            }
        });

        project_listbox.row_selected.connect ((row) => {
            if (row != null) {
                var project = ((Widgets.ProjectRow) row).project;
                Planner.utils.pane_project_selected (project.id, 0);
            }
        });

        add_button.clicked.connect (() => {
            new_project.reveal = true;
        });
        
        Planner.database.area_added.connect ((area) => {
            var row = new Widgets.AreaRow (area);
            area_listbox.add (row);
            area_listbox.show_all ();

            row.set_focus = true;
        });

        Planner.utils.pane_project_selected.connect ((project_id, area_id) => {
            listbox.unselect_all ();

            if (area_id != 0) {
                project_listbox.unselect_all ();
            }
        });

        Planner.utils.select_pane_project.connect ((project_id) => {
            project_listbox.foreach ((widget) => {
                var row = (Widgets.ProjectRow) widget;

                print ("AAA-%s\n".printf (row.project.name));

                if (row.project.id == project_id) {
                    project_listbox.select_row (row);
                }
            });
        });

        Planner.database.project_added.connect ((project) => {
            if (project.inbox_project == 0 && project.area_id == 0) {
                var row = new Widgets.ProjectRow (project);
                project_listbox.add (row);
                project_listbox.show_all ();
            }
        });

        Planner.database.project_moved.connect ((project) => {
            Idle.add (() => {
                if (project.area_id == 0) {
                    var row = new Widgets.ProjectRow (project);
                    project_listbox.add (row);
                    project_listbox.show_all ();
                }

                return false;
            });
        });

        var network_monitor = GLib.NetworkMonitor.get_default ();
        network_monitor.network_changed.connect (() => {
            check_network ();
        });

        Planner.utils.drag_item_activated.connect ((value) => {
            if (value) {
                upcoming_row.title_name.label = _("Tomorrow");
            } else {
                upcoming_row.title_name.label = _("Upcoming");
            }
        });

        Planner.database.reset.connect (() => {
            stack.visible_child_name = "grid";

            project_listbox.foreach ((widget) => {
                Idle.add (() => {
                    widget.destroy ();
    
                    return false;
                });
            });

            area_listbox.foreach ((widget) => {
                Idle.add (() => {
                    widget.destroy ();
    
                    return false;
                });
            });
        });
    }

    private void check_network () {
        var available = GLib.NetworkMonitor.get_default ().network_available;

        if (available) {
            sync_button.tooltip_text = _("Sync");
            sync_button.image = sync_image;
        } else {
            sync_button.image = error_image;
            sync_button.tooltip_markup = "<b>%s</b>\n%s".printf (_("Offline mode is on"), _("Looks like you'are not connected to the\ninternet. Changes you make in offline\nmode will be synced when you reconnect"));
        }
    }

    private void build_drag_and_drop () {
        Gtk.drag_dest_set (project_listbox, Gtk.DestDefaults.ALL, targetEntries, Gdk.DragAction.MOVE);
        project_listbox.drag_data_received.connect (on_drag_data_received);
    }

    private void on_drag_data_received (Gdk.DragContext context, int x, int y, Gtk.SelectionData selection_data, uint target_type, uint time) {
        Widgets.ProjectRow target;
        Widgets.ProjectRow source;
        Gtk.Allocation alloc;

        target = (Widgets.ProjectRow) project_listbox.get_row_at_y (y);
        target.get_allocation (out alloc);
        
        var row = ((Gtk.Widget[]) selection_data.get_data ())[0];
        source = (Widgets.ProjectRow) row;
        
        if (target != null) {
            source.get_parent ().remove (source); 

            source.project.area_id = 0;

            project_listbox.insert (source, target.get_index () + 1);
            project_listbox.show_all ();

            update_project_order ();         
        }
    }
    
    public void add_all_projects () {
        foreach (var project in Planner.database.get_all_projects_no_area ()) {
            var row = new Widgets.ProjectRow (project);
            project_listbox.add (row);

            if (Planner.settings.get_boolean ("homepage-project")) {
                if (Planner.settings.get_int64 ("homepage-project-id") == project.id) {
                    timeout = Timeout.add (125, () => {
                        project_listbox.select_row (row);

                        Source.remove (timeout);
                        return false;
                    });
                }
            }
        }

        project_listbox.show_all ();
    }

    public void add_all_areas () {
        foreach (var area in Planner.database.get_all_areas ()) {
            var row = new Widgets.AreaRow (area);
            area_listbox.add (row);
        }

        area_listbox.show_all ();
    }

    private void update_project_order () {
        Timeout.add (150, () => {
            new Thread<void*> ("update_project_order", () => {
                project_listbox.foreach ((widget) => {
                    var row = (Gtk.ListBoxRow) widget;
                    int index = row.get_index ();
    
                    var project = ((ProjectRow) row).project;
                    Planner.database.update_project_item_order (project.id, 0, index);
                });
                
                return null;
            });

            return false;
        });
    }

    public void select_item (int id) {
        if (id == 0) {
            listbox.select_row (inbox_row);
        } else if (id == 1) {
            listbox.select_row (today_row);
        } else {
            listbox.select_row (upcoming_row);
        }
    }
}