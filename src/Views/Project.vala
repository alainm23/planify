public class Views.Project : Gtk.EventBox {
    public Objects.Project project { get; construct; }

    private Gtk.TextView note_textview;
    private Gtk.Label note_placeholder;

    private Gtk.ListBox listbox;
    private Gtk.ListBox header_listbox;
    private Widgets.NewItem new_item_widget;
    private Gtk.Revealer motion_revealer;

    private const Gtk.TargetEntry[] targetEntries = {
        {"ITEMROW", Gtk.TargetFlags.SAME_APP, 0}
    };

    public Project (Objects.Project project) {
        Object (
            project: project
        );
    }

    construct {
        var edit_button = new Gtk.Button.from_icon_name ("edit-symbolic", Gtk.IconSize.MENU);
        edit_button.valign = Gtk.Align.CENTER;
        edit_button.valign = Gtk.Align.CENTER;
        edit_button.can_focus = false;
        edit_button.margin_start = 6;
        edit_button.get_style_context ().add_class ("flat");
        edit_button.get_style_context ().add_class ("dim-label");
        
        var edit_revealer = new Gtk.Revealer ();
        edit_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        edit_revealer.add (edit_button);
        edit_revealer.reveal_child = false;

        var grid_color = new Gtk.Grid ();
        grid_color.set_size_request (16, 16);
        grid_color.valign = Gtk.Align.CENTER;
        grid_color.halign = Gtk.Align.CENTER;
        grid_color.get_style_context ().add_class ("project-%s".printf (project.id.to_string ()));

        var name_label = new Gtk.Label (project.name);
        name_label.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
        name_label.get_style_context ().add_class ("font-bold");
        name_label.use_markup = true;

        var settings_popover = new Widgets.Popovers.ProjectSettings ();

        var search_button = new Gtk.Button.from_icon_name ("edit-find-symbolic", Gtk.IconSize.MENU);
        search_button.valign = Gtk.Align.CENTER;
        search_button.valign = Gtk.Align.CENTER;
        search_button.can_focus = false;
        search_button.margin_start = 6;
        search_button.get_style_context ().add_class ("flat");
        search_button.get_style_context ().add_class ("dim-label");

        var settings_button = new Gtk.MenuButton ();
        settings_button.can_focus = false;
        settings_button.valign = Gtk.Align.CENTER;
        settings_button.tooltip_text = _("Project Options");
        settings_button.popover = settings_popover;
        settings_button.image = new Gtk.Image.from_icon_name ("view-more-symbolic", Gtk.IconSize.MENU);
        settings_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        settings_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        var top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        top_box.hexpand = true;
        top_box.valign = Gtk.Align.START;
        top_box.margin_end = 24;

        top_box.pack_start (edit_revealer, false, false, 0);
        top_box.pack_start (grid_color, false, false, 0);
        top_box.pack_start (name_label, false, false, 12);
        top_box.pack_end (settings_button, false, false, 0);
        top_box.pack_end (search_button, false, false, 0);

        var top_eventbox = new Gtk.EventBox ();
        top_eventbox.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        top_eventbox.hexpand = true;
        top_eventbox.add (top_box);

        note_textview = new Gtk.TextView ();
        note_textview.hexpand = true;
        note_textview.margin_top = 6;
        note_textview.wrap_mode = Gtk.WrapMode.WORD;
        note_textview.get_style_context ().add_class ("project-textview");
        note_textview.margin_start = 37;

        note_placeholder = new Gtk.Label (_("Add note"));
        note_placeholder.opacity = 0.7;
        note_textview.add (note_placeholder);
        
        note_textview.buffer.text = project.note;

        if (project.note != "") {
            note_placeholder.visible = false;
            note_placeholder.no_show_all = true;
        } else {
            note_placeholder.visible = true;
            note_placeholder.no_show_all = false;
        }

        listbox = new Gtk.ListBox  ();
        listbox.valign = Gtk.Align.START;
        listbox.margin_top = 6;
        listbox.get_style_context ().add_class ("welcome");
        listbox.get_style_context ().add_class ("listbox");
        listbox.activate_on_single_click = true;
        listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        listbox.hexpand = true;

        var motion_grid = new Gtk.Grid ();
        motion_grid.get_style_context ().add_class ("grid-motion");
        motion_grid.height_request = 24;
            
        motion_revealer = new Gtk.Revealer ();
        motion_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
        motion_revealer.add (motion_grid);

        bool is_todoist = false;
        if (project.is_todoist == 1) {
            is_todoist = true;
        }

        new_item_widget = new Widgets.NewItem (project.id, is_todoist);

        header_listbox = new Gtk.ListBox  ();
        header_listbox.valign = Gtk.Align.START;
        header_listbox.get_style_context ().add_class ("welcome");
        header_listbox.get_style_context ().add_class ("listbox");
        header_listbox.activate_on_single_click = true;
        header_listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        header_listbox.hexpand = true;

        var header_01 = new Widgets.HeaderRow ();
        var header_02 = new Widgets.HeaderRow ();

        header_listbox.add (header_01);
        header_listbox.add (header_02);
        
        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.expand = true;
        main_box.pack_start (top_eventbox, false, false, 0);
        main_box.pack_start (note_textview, false, true, 0);
        main_box.pack_start (listbox, false, false, 0);
        main_box.pack_start (motion_revealer, false, false, 0);
        main_box.pack_start (new_item_widget, false, false, 0);
        //main_box.pack_start (header_listbox, false, false, 0);
        
        var main_scrolled = new Gtk.ScrolledWindow (null, null);
        main_scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        main_scrolled.width_request = 246;
        main_scrolled.expand = true;
        main_scrolled.add (main_box);

        add (main_scrolled);
        add_all_items (project.id);
        build_drag_and_drop ();
        show_all ();

        top_eventbox.enter_notify_event.connect ((event) => {
            edit_revealer.reveal_child = true;

            return true;
        });

        top_eventbox.leave_notify_event.connect ((event) => {
            if (event.detail == Gdk.NotifyType.INFERIOR) {
                return false;
            }
            
            edit_revealer.reveal_child = false;

            return true;
        });

        top_eventbox.event.connect ((event) => {
            if (event.type == Gdk.EventType.@2BUTTON_PRESS) {
                var edit_dialog = new Dialogs.ProjectSettings (project);
                edit_dialog.destroy.connect (Gtk.main_quit);
                edit_dialog.show_all ();
            }

            return false;
        });

        edit_button.clicked.connect (() => {
            if (project != null) {
                var edit_dialog = new Dialogs.ProjectSettings (project);
                edit_dialog.destroy.connect (Gtk.main_quit);
                edit_dialog.show_all ();
            }
        });

        note_textview.focus_in_event.connect (() => {
            note_placeholder.visible = false;
            note_placeholder.no_show_all = true;

            return false;
        });

        note_textview.focus_out_event.connect (() => {
            if (note_textview.buffer.text == "") {
                note_placeholder.visible = true;
                note_placeholder.no_show_all = false;
            }

            return false;
        });

        note_textview.buffer.changed.connect (() => {
            save ();
        });

        listbox.row_activated.connect ((row) => {
            var item = ((Widgets.ItemRow) row);
            item.reveal_child = true;
        });

        Application.database.item_added.connect (item => {
            if (item.project_id == project.id && item.header_id == 0) {
                var row = new Widgets.ItemRow (item);
                listbox.add (row);
                listbox.show_all ();
            }
        });

        Application.database.project_updated.connect ((p) => {
            if (project != null && p.id == project.id) {
                project = p;
            }
        });
    }

    private void save () {
        if (project != null) {
            project.note = note_textview.buffer.text;
            project.save ();
        }
    }

    private void apply_styles (string color) {
        string COLOR_CSS = """
            .project-color-%s {
                color: %s
            }
        """;

        var provider = new Gtk.CssProvider ();

        try {
            var colored_css = COLOR_CSS.printf (
                project.id.to_string (),
                color
            );

            provider.load_from_data (colored_css, colored_css.length);

            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (GLib.Error e) {
            return;
        }
    }

    private void add_all_items (int64 project_id) {
        listbox.foreach ((widget) => {
            widget.destroy (); 
        });

        var all_items = Application.database.get_all_items_by_project (project_id);

        foreach (var item in all_items) {
            var row = new Widgets.ItemRow (item);
            listbox.add (row);
            listbox.show_all ();
        }
    }

    private void build_drag_and_drop () {
        Gtk.drag_dest_set (listbox, Gtk.DestDefaults.ALL, targetEntries, Gdk.DragAction.MOVE);
        listbox.drag_data_received.connect (on_drag_data_received);
 
        Gtk.drag_dest_set (new_item_widget, Gtk.DestDefaults.ALL, targetEntries, Gdk.DragAction.MOVE);
        new_item_widget.drag_motion.connect (on_drag_motion);
        new_item_widget.drag_leave.connect (on_drag_leave);
        new_item_widget.drag_data_received.connect (on_drag_item_received);
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
            if (target.get_index () != source.get_index ()) {
                source.get_parent ().remove (source); 
                listbox.insert (source, target.get_index ());
                listbox.show_all ();

                update_item_order ();
            }   
        } else {
            source.get_parent ().remove (source); 
            listbox.insert (source, (int) listbox.get_children ().length);
            listbox.show_all ();
    
            update_item_order ();
        }
    }

    private void on_drag_item_received (Gdk.DragContext context, int x, int y, Gtk.SelectionData selection_data, uint target_type, uint time) {
        Widgets.ItemRow source;
        var row = ((Gtk.Widget[]) selection_data.get_data ())[0];
        source = (Widgets.ItemRow) row;

        source.get_parent ().remove (source); 
        listbox.insert (source, (int) listbox.get_children ().length);
        listbox.show_all ();
    
        update_item_order ();
    }

    public bool on_drag_motion (Gdk.DragContext context, int x, int y, uint time) {
        motion_revealer.reveal_child = true;
        return true;
    }

    public void on_drag_leave (Gdk.DragContext context, uint time) {
        motion_revealer.reveal_child = false;
    }

    private void update_item_order () {
        listbox.foreach ((widget) => {
            var row = (Gtk.ListBoxRow) widget;
            int index = row.get_index ();

            var item = ((Widgets.ItemRow) row).item;

            new Thread<void*> ("update_item_order", () => {
                Application.database.update_item_order (item.id, index);

                return null;
            });
        });
    }
}