public class Widgets.Pane : Gtk.EventBox {
    private Gtk.Stack stack;
    private Widgets.ActionRow inbox_row;
    private Widgets.ActionRow today_row;
    private Widgets.ActionRow upcoming_row;

    private Gtk.ListBox listbox;

    public signal void activated (string type, int? id);

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

        today_row = new Widgets.ActionRow (_("Today"), "user-bookmarks-symbolic", "today", _("Create new task"));
        today_row.primary_text = "4";
        
        upcoming_row = new Widgets.ActionRow (_("Upcoming"), "x-office-calendar-symbolic", "upcoming", _("Create new task"));
        //upcoming_row.primary_text = "10";
        upcoming_row.margin_bottom = 6;

        // Menu
        var username = GLib.Environment.get_user_name ();
        var iconfile = @"/var/lib/AccountsService/icons/$username";
        var user_avatar = new Granite.Widgets.Avatar.from_file (iconfile, 16);

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

        var profile_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 2);
        profile_box.margin_start = 2;
        profile_box.margin_end = 2;
        profile_box.get_style_context ().add_class ("pane");
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

        var add_image = new Gtk.Image ();
        add_image.valign = Gtk.Align.CENTER;
        add_image.gicon = new ThemedIcon ("list-add-symbolic");
        add_image.get_style_context ().add_class ("add-project-image");
        add_image.pixel_size = 14;

        var add_label = new Gtk.Label (_("New Project"));
        add_label.get_style_context ().add_class ("pane-item");
        add_label.get_style_context ().add_class ("add-project-label");
        add_label.margin_bottom = 1;
        add_label.use_markup = true;

        var add_grid = new Gtk.Grid ();
        add_grid.margin_bottom = 6;
        add_grid.margin_top = 6;
        add_grid.margin_start = 8;
        add_grid.column_spacing = 6;
        add_grid.add (add_image);
        add_grid.add (add_label);

        var add_eventbox = new Gtk.EventBox ();
        add_eventbox.valign = Gtk.Align.CENTER;
        add_eventbox.add (add_grid);

        var add_revealer = new Gtk.Revealer ();
        add_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        add_revealer.reveal_child = true;
        add_revealer.add (add_eventbox);

        listbox = new Gtk.ListBox  ();
        listbox.margin_top = listbox.margin_bottom = 6;
        listbox.get_style_context ().add_class ("pane");
        //listbox.get_style_context ().add_class ("welcome");
        listbox.activate_on_single_click = true;
        listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        listbox.hexpand = true;
        
        listbox.add (inbox_row);
        listbox.add (today_row);
        listbox.add (upcoming_row);

        var listbox_scrolled = new Gtk.ScrolledWindow (null, null);
        listbox_scrolled.width_request = 246;
        listbox_scrolled.expand = true;
        listbox_scrolled.add (listbox);

        var new_project = new Widgets.NewProject ();

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.expand = true;
        main_box.get_style_context ().add_class ("pane");
        main_box.pack_start (profile_box, false, false, 0);
        //main_box.pack_start (search_entry_grid, false, false, 0);
        main_box.pack_start (listbox_scrolled, true, true, 0);
        //main_box.pack_start (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), false, false, 0);     
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
        add_all_projects ();

        listbox.row_selected.connect ((row) => {
            if (row != null) {
                if (row.get_index () == 0 || row.get_index () == 1 || row.get_index () == 2) {
                    var action = (ActionRow) row;

                    activated ("action", row.get_index ());

                    action.icon.get_style_context ().add_class ("active");
                    action.secondary_label.get_style_context ().add_class ("text_color");

                    Timeout.add (700, () => {
                        action.icon.get_style_context ().remove_class ("active");
                        return false;
                    });
                }
            }
        });

        add_eventbox.event.connect ((event) => {
            if (event.type == Gdk.EventType.BUTTON_PRESS) {
                new_project.reveal = true;
            }

            return false;
        });

        add_eventbox.enter_notify_event.connect ((event) => {
            add_image.get_style_context ().add_class ("active");
            add_label.get_style_context ().add_class ("active");
            
            window.cursor = HAND_cursor;
            return true;
        });

        add_eventbox.leave_notify_event.connect ((event) => {
            if (event.detail == Gdk.NotifyType.INFERIOR) {
                return false;
            }

            window.cursor = ARROW_cursor;
            add_image.get_style_context ().remove_class ("active");
            add_label.get_style_context ().remove_class ("active");

            return true;
        });

        Application.database.project_added.connect ((project) => {
            var row = new Widgets.ProjectRow (project);
            listbox.add (row);
            listbox.show_all ();
        });

        new_project.reveal_activated.connect ((val) => {
            add_revealer.reveal_child = !val;
        });
    } 

    public void add_all_projects () {
        var all = new Gee.ArrayList<Objects.Project?> ();
        all = Application.database.get_all_projects ();
            
        foreach (Objects.Project project in all) {
            if (project.inbox_project == 0) {
                var row = new Widgets.ProjectRow (project);
                listbox.add (row);
            }
            
        }

        listbox.show_all ();
    }
}