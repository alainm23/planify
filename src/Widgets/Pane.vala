public class Widgets.Pane : Gtk.EventBox {
    private Gtk.Stack stack;
    private Widgets.ActionRow inbox_row;
    private Widgets.ActionRow today_row;
    private Widgets.ActionRow upcoming_row;
    
    private Gtk.ListBox listbox;
    private Gtk.ListBox area_listbox;
    
    public signal void activated (int id);

    public bool sensitive_ui {
        set {
            if (value) {
                stack.visible_child_name = "scrolled";
            } else {
                stack.visible_child_name = "grid";
            }
        }
    }
    public Pane () {
        
    }

    construct {
        inbox_row = new Widgets.ActionRow (_("Inbox"), "mail-mailbox-symbolic", "inbox", _("Create new task"));
        inbox_row.primary_text = "3";

        string today_icon = "planner-today-day-symbolic";
        if (new GLib.DateTime.now_local ().get_hour () >= 18) {
            today_icon = "planner-today-night-symbolic";
        }

        today_row = new Widgets.ActionRow (_("Today"), today_icon, "today", _("Create new task"));
        today_row.primary_text = "4";
        
        upcoming_row = new Widgets.ActionRow (_("Upcoming"), "x-office-calendar-symbolic", "upcoming", _("Create new task"));
        //upcoming_row.primary_text = "10";

        // Menu
        var username = GLib.Environment.get_user_name ();
        var iconfile = @"/var/lib/AccountsService/icons/$username";

        var user_avatar = new Granite.Widgets.Avatar.from_file (iconfile, 19);

        var username_label = new Gtk.Label (Application.settings.get_string ("user-name"));
        username_label.get_style_context ().add_class ("pane-item");
        username_label.margin_top = 1;
        username_label.halign = Gtk.Align.CENTER;
        username_label.valign = Gtk.Align.CENTER;
        username_label.use_markup = true;

        // Search Button
        var search_button = new Gtk.Button ();
        search_button.can_focus = false;
        search_button.tooltip_text = _("Quick Search");
        search_button.valign = Gtk.Align.CENTER;
        search_button.halign = Gtk.Align.CENTER;
        search_button.get_style_context ().add_class ("settings-button");
        search_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        search_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        var search_image = new Gtk.Image ();
        search_image.gicon = new ThemedIcon ("edit-find-symbolic");
        search_image.pixel_size = 14;
        search_button.image = search_image;

        var settings_button = new Gtk.Button ();
        settings_button.margin_end = 1;
        settings_button.can_focus = false;
        settings_button.tooltip_text = _("Preferences");
        settings_button.valign = Gtk.Align.CENTER;
        settings_button.halign = Gtk.Align.CENTER;
        settings_button.get_style_context ().add_class ("settings-button");
        settings_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        settings_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        var settings_image = new Gtk.Image ();
        settings_image.gicon = new ThemedIcon ("open-menu-symbolic");
        settings_image.pixel_size = 14;
        settings_button.image = settings_image;

        var sync_button = new Gtk.Button ();
        sync_button.can_focus = false;
        sync_button.tooltip_text = _("Sync");
        sync_button.valign = Gtk.Align.CENTER;
        sync_button.halign = Gtk.Align.CENTER;
        sync_button.get_style_context ().add_class ("settings-button");
        sync_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        sync_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        var sync_image = new Gtk.Image ();
        sync_image.gicon = new ThemedIcon ("emblem-synchronizing-symbolic");
        sync_image.get_style_context ().add_class ("sync-image-rotate");
        sync_image.pixel_size = 16;
        sync_button.image = sync_image;

        var profile_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3);
        profile_box.margin_start = 2;
        profile_box.margin_end = 2;
        profile_box.get_style_context ().add_class ("pane");
        profile_box.get_style_context ().add_class ("welcome");
        profile_box.pack_start (user_avatar, false, false, 0);
        profile_box.pack_start (username_label, false, false, 0);
        profile_box.pack_end (settings_button, false, false, 0);
        profile_box.pack_end (sync_button, false, false, 0);
        profile_box.pack_end (search_button, false, false, 0);

        // Search Entry
        var search_entry = new Gtk.SearchEntry ();
        search_entry.margin = 6;
        search_entry.valign = Gtk.Align.CENTER;
        search_entry.hexpand = true;
        search_entry.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
        search_entry.get_style_context ().add_class ("quick-find");
        search_entry.placeholder_text = _("Quick find");

        var search_entry_grid = new Gtk.Grid ();
        search_entry_grid.orientation = Gtk.Orientation.VERTICAL;
        search_entry_grid.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        search_entry_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        search_entry_grid.add (search_entry);
        search_entry_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));

        var HAND_cursor = new Gdk.Cursor.for_display (Gdk.Display.get_default (), Gdk.CursorType.HAND1);
        var ARROW_cursor = new Gdk.Cursor.for_display (Gdk.Display.get_default (), Gdk.CursorType.ARROW);
        var window = Gdk.Screen.get_default ().get_root_window ();

        var add_button = new Gtk.Button.from_icon_name ("list-add-symbolic", Gtk.IconSize.MENU);
        add_button.valign = Gtk.Align.CENTER;
        add_button.halign = Gtk.Align.START;
        add_button.always_show_image = true;
        add_button.label = _("Add");
        add_button.get_style_context ().add_class ("flat");
        add_button.get_style_context ().add_class ("font-bold");
        add_button.get_style_context ().add_class ("add-button");

        var add_revealer = new Gtk.Revealer ();
        add_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        add_revealer.reveal_child = true;
        add_revealer.add (add_button);

        listbox = new Gtk.ListBox  ();
        listbox.margin_top = 3;
        listbox.get_style_context ().add_class ("pane");
        listbox.get_style_context ().add_class ("welcome");
        listbox.activate_on_single_click = true;
        listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        listbox.hexpand = true;
        
        listbox.add (inbox_row);
        listbox.add (today_row);
        listbox.add (upcoming_row);
    
        area_listbox = new Gtk.ListBox  ();
        area_listbox.get_style_context ().add_class ("pane");
        area_listbox.get_style_context ().add_class ("welcome");
        area_listbox.activate_on_single_click = true;
        area_listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        area_listbox.hexpand = true;

        var listbox_grid = new Gtk.Grid ();
        listbox_grid.orientation = Gtk.Orientation.VERTICAL;
        listbox_grid.add (listbox);
        listbox_grid.add (area_listbox);

        var listbox_scrolled = new Gtk.ScrolledWindow (null, null);
        listbox_scrolled.width_request = 246;
        listbox_scrolled.hexpand = true;
        listbox_scrolled.add (listbox_grid);

        var new_project = new Widgets.New ();

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.expand = true;
        main_box.get_style_context ().add_class ("pane");
        main_box.pack_start (profile_box, false, false, 0);
        //main_box.pack_start (search_entry_grid, false, false, 0);
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

        add (stack);
        add_all_areas ();

        listbox.row_selected.connect ((row) => {
            if (row != null) {
                activated (row.get_index ());
                Application.utils.pane_action_selected ();

                var action = (ActionRow) row;

                action.icon.get_style_context ().add_class ("active");
                action.secondary_label.get_style_context ().add_class ("text_color");

                Timeout.add (700, () => {
                    action.icon.get_style_context ().remove_class ("active");
                    return false;
                });
            }
        });

        add_button.clicked.connect (() => {
            new_project.reveal = true;
        });
        
        new_project.reveal_activated.connect ((val) => {
            add_revealer.reveal_child = !val;
        });

        Application.todoist.first_sync_finished.connect (() => {
            username_label.label = Application.settings.get_string ("user-name");
        });

        Application.todoist.avatar_downloaded.connect (() => {
            try {
                user_avatar.pixbuf = new Gdk.Pixbuf.from_file_at_size (
                    GLib.Path.build_filename (Application.utils.AVATARS_FOLDER, ("avatar.jpg")),
                    16,
                    16);
            } catch (Error e) {
                stderr.printf ("Error setting default avatar icon: %s ", e.message);
            }
        });

        Application.database.area_added.connect ((area) => {
            var row = new Widgets.AreaRow (area);
            area_listbox.add (row);
            area_listbox.show_all ();
        });

        Application.utils.pane_project_selected.connect ((id, area) => {
            listbox.unselect_all ();
        });
    } 

    public void add_all_areas () {
        foreach (Objects.Area area in Application.database.get_all_areas ()) {
            var row = new Widgets.AreaRow (area);
            area_listbox.add (row);
        }

        area_listbox.show_all ();
    }
}