public class Widgets.Pane : Gtk.EventBox {
    private Widgets.ActionRow inbox_row;
    private Widgets.ActionRow today_row;
    private Widgets.ActionRow upcoming_row;

    private Gtk.ListBox action_listbox;
    private Gtk.ListBox project_listbox;
    private Gtk.ListBox label_listbox;

    public signal void activated (string type, int? id);

    public bool sensitive_ui {
        set {
            
        }
    }
    public Pane () {
        
    }

    construct {
        get_style_context ().add_class ("welcome");

        inbox_row = new Widgets.ActionRow (_("Inbox"), "mail-mailbox-symbolic", "inbox", _("Create new task"));
        inbox_row.secondary_text = "3";

        today_row = new Widgets.ActionRow (_("Today"), "user-bookmarks-symbolic", "today", _("Create new task"));
        today_row.secondary_text = "8";
        
        upcoming_row = new Widgets.ActionRow (_("Upcoming"), "x-office-calendar-symbolic", "upcoming", _("Create new task"));
        upcoming_row.secondary_text = "10";

        // Menu
        var username = GLib.Environment.get_user_name ();
        var iconfile = @"/var/lib/AccountsService/icons/$username";

        var user_avatar = new Granite.Widgets.Avatar.from_file (iconfile, 16);
        user_avatar.margin_start = 2;

        var username_label = new Gtk.Label ("%s".printf (GLib.Environment.get_real_name ()));
        username_label.halign = Gtk.Align.CENTER;
        username_label.valign = Gtk.Align.CENTER;
        username_label.margin_bottom = 1;
        username_label.use_markup = true;

        // Search Button
        var search_button = new Gtk.Button.from_icon_name ("system-search-symbolic", Gtk.IconSize.MENU);
        search_button.can_focus = false;
        //search_button.tooltip_text = _("See calendar of events");
        search_button.valign = Gtk.Align.CENTER;
        search_button.halign = Gtk.Align.CENTER;
        search_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        search_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        // Search Button
        var settings_button = new Gtk.Button.from_icon_name ("preferences-system-symbolic", Gtk.IconSize.MENU);
        settings_button.can_focus = false;
        //settings_button.tooltip_text = _("See calendar of events");
        settings_button.valign = Gtk.Align.CENTER;
        settings_button.halign = Gtk.Align.CENTER;
        settings_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        settings_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        var profile_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3);
        profile_box.get_style_context ().add_class ("pane");
        profile_box.pack_start (user_avatar, false, false, 0);
        profile_box.pack_start (username_label, false, false, 0);
        profile_box.pack_end (settings_button, false, false, 0);
        profile_box.pack_end (search_button, false, false, 0);

        // Search Entry
        var search_entry = new Gtk.SearchEntry ();
        search_entry.margin = 6;
        search_entry.valign = Gtk.Align.CENTER;
        search_entry.hexpand = true;
        search_entry.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
        search_entry.placeholder_text = _("Quick find");

        var search_entry_grid = new Gtk.Grid ();
        search_entry_grid.orientation = Gtk.Orientation.VERTICAL;
        search_entry_grid.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        search_entry_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        search_entry_grid.add (search_entry);
        search_entry_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));

        var show_project_image = new Gtk.Image.from_icon_name ("pan-end-symbolic", Gtk.IconSize.MENU);
        show_project_image.get_style_context ().add_class ("show-button");
        show_project_image.get_style_context ().add_class ("closed");

        var show_project_label = new Gtk.Label ("<b>%s</b>".printf (_("Projects")));
        show_project_label.use_markup = true;
    
        var show_project_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        show_project_box.margin_start = 6;
        show_project_box.pack_start (show_project_image, false, false, 0);
        show_project_box.pack_start (show_project_label, false, false, 0);

        var show_project_eventbox = new Gtk.EventBox ();
        show_project_eventbox.add (show_project_box);

        var add_projects_button = new Gtk.Button.from_icon_name ("list-add-symbolic", Gtk.IconSize.MENU);
        add_projects_button.can_focus = false;
        add_projects_button.tooltip_text = _("Add new project");
        add_projects_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var show_projects_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        show_projects_box.hexpand = true;
        //show_projects_box.get_style_context ().add_class ("view");
        show_projects_box.pack_start (show_project_eventbox, true, true, 0);
        show_projects_box.pack_end (add_projects_button, false, false, 0);

        /*
            Labels
        */

        var show_label_image = new Gtk.Image.from_icon_name ("pan-end-symbolic", Gtk.IconSize.MENU);
        show_label_image.get_style_context ().add_class ("show-button");
        show_label_image.get_style_context ().add_class ("closed");

        var show_label_label = new Gtk.Label ("<b>%s</b>".printf (_("Labels")));
        show_label_label.use_markup = true;
    
        var show_label_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        show_label_box.margin_start = 6;
        show_label_box.pack_start (show_label_image, false, false, 0);
        show_label_box.pack_start (show_label_label, false, false, 0);

        var show_label_eventbox = new Gtk.EventBox ();
        show_label_eventbox.add (show_label_box);

        var add_label_button = new Gtk.Button.from_icon_name ("list-add-symbolic", Gtk.IconSize.MENU);
        add_label_button.can_focus = false;
        add_label_button.tooltip_text = _("Add new project");
        add_label_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var label_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        label_box.hexpand = true;
        //label_box.get_style_context ().add_class ("view");
        label_box.pack_start (show_label_eventbox, true, true, 0);
        label_box.pack_end (add_label_button, false, false, 0);

        action_listbox = new Gtk.ListBox  ();
        action_listbox.margin_top = 6;
        action_listbox.margin_bottom = 6;
        action_listbox.get_style_context ().add_class ("pane");
        action_listbox.activate_on_single_click = true;
        action_listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        action_listbox.hexpand = true;
        
        action_listbox.add (inbox_row);
        action_listbox.add (today_row);
        action_listbox.add (upcoming_row);

        project_listbox = new Gtk.ListBox  ();
        project_listbox.get_style_context ().add_class ("pane");
        project_listbox.activate_on_single_click = true;
        project_listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        project_listbox.hexpand = true;

        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        //separator.margin_start = 9;
        //separator.margin_end = 9;

        var separator_2 = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator_2.margin_start = 9;
        separator_2.margin_end = 9;

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.expand = true;
        main_box.get_style_context ().add_class ("pane");
        main_box.pack_start (profile_box, false, false, 0);
        //main_box.pack_start (separator_2, false, false, 0);
        //main_box.pack_start (search_entry_grid, false, false, 0);
        main_box.pack_start (action_listbox, false, false, 0);
        //main_box.pack_start (separator, false, false, 0);
        //main_box.pack_start (show_projects_box, false, false, 0);
        //main_box.pack_start (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), false, false, 0);
        //main_box.pack_start (project_listbox, false, false, 0);

        //main_box.pack_start (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), false, false, 0);
        //main_box.pack_start (label_box, false, false, 0);
        //main_box.pack_start (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), false, false, 0);

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.expand = true;
        scrolled.add (main_box);

        add (scrolled);

        action_listbox.row_selected.connect ((row) => {
            var action = (ActionRow) row;

            activated ("action", row.get_index ());

            action.icon.get_style_context ().add_class ("active");
            action.secondary_label.get_style_context ().add_class ("text_color");

            Timeout.add (700, () => {
                action.icon.get_style_context ().remove_class ("active");
                return false;
            });
        });
    } 
}