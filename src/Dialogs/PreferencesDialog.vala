public class Dialogs.PreferencesDialog : Gtk.Dialog {
    public weak MainWindow parent_window { private get; construct; }
    private Gtk.Stack main_stack;

    public signal void on_close ();
    public PreferencesDialog (MainWindow parent) {
        Object (
            parent_window: parent
        );
	}

    construct {
        get_style_context ().add_class ("view");

        title = _("Preferences");
        set_size_request (600, 400);
        resizable = false;
        deletable = true;
        use_header_bar = 1;
        destroy_with_parent = true;
        window_position = Gtk.WindowPosition.CENTER_ON_PARENT;
        transient_for = parent_window;

        var mode_button = new Granite.Widgets.ModeButton ();
        mode_button.hexpand = true;
        mode_button.halign = Gtk.Align.CENTER;

        mode_button.append_text ("General");
        mode_button.append_text ("Cloud");
        mode_button.append_text ("Calendar");

        Gtk.HeaderBar headerbar = get_header_bar () as Gtk.HeaderBar;
        //headerbar.custom_title = mode_button;
        //headerbar.spacing = 0;
        headerbar.get_style_context ().add_class ("planner-preferences-headerbar");

        main_stack = new Gtk.Stack ();
        main_stack.expand = true;
        main_stack.margin = 24;
        main_stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
        main_stack.add_named (get_general_widget (), "general");
        main_stack.visible_child_name = "general";

        var close_button = new Gtk.Button.with_label (_("Close"));
        close_button.clicked.connect (() => {
            on_close ();
            this.destroy ();
        });

        var button_box = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
        button_box.margin_right = 10;
        button_box.set_layout (Gtk.ButtonBoxStyle.END);
        button_box.pack_end (close_button);

        var content_grid = new Gtk.Grid ();
        //content_grid.attach (mode_button, 0, 0, 1, 1);
        content_grid.attach (main_stack, 0, 1, 1, 1);

        ((Gtk.Container) get_content_area ()).add (content_grid);
    }

    private Gtk.Widget get_general_widget () {
        var badge_count_icon = new Gtk.Image ();
        badge_count_icon.gicon = new ThemedIcon ("preferences-system-notifications");
        badge_count_icon.pixel_size = 16;

        var badge_count_label = new Gtk.Label (_("Badge Count"));
        badge_count_label.tooltip_text = _("Choose which items should be counted for \n the badge on the application icon.");
        badge_count_label.get_style_context ().add_class ("h3");

        var badge_count_combobox = new Gtk.ComboBoxText ();
        badge_count_combobox.width_request = 120;
		badge_count_combobox.append_text (_("None"));
        badge_count_combobox.append_text (_("Inbox"));
		badge_count_combobox.append_text (_("Today"));
		badge_count_combobox.append_text (_("Today + Inbox"));
        badge_count_combobox.append_text (_("Notifications"));

		badge_count_combobox.active = Planner.settings.get_enum ("badge-count");

        var badge_count_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        badge_count_box.hexpand = true;
        badge_count_box.pack_start (badge_count_icon, false, false, 0);
        badge_count_box.pack_start (badge_count_label, false, false, 6);
        badge_count_box.pack_end (badge_count_combobox, false, false, 0);

        var start_page_icon = new Gtk.Image ();
        start_page_icon.gicon = new ThemedIcon ("go-home");
        start_page_icon.pixel_size = 16;

        var start_page_label = new Gtk.Label (_("Start Page"));
        start_page_label.tooltip_text = _("Choose which items should be counted for \n the badge on the application icon.");
        start_page_label.get_style_context ().add_class ("h3");

        var start_page_combobox = new Gtk.ComboBoxText ();
        start_page_combobox.width_request = 120;
		start_page_combobox.append_text (_("Inbox"));
		start_page_combobox.append_text (_("Today"));
        start_page_combobox.append_text (_("Tomorrow"));
		start_page_combobox.active = 1;

        var start_page_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        start_page_box.hexpand = true;
        start_page_box.pack_start (start_page_icon, false, false, 0);
        start_page_box.pack_start (start_page_label, false, false, 6);
        start_page_box.pack_end (start_page_combobox, false, false, 0);

        var main_grid = new Gtk.Grid ();
        main_grid.row_spacing = 6;
        main_grid.orientation = Gtk.Orientation.VERTICAL;

        main_grid.add (badge_count_box);
        main_grid.add (start_page_box);

        // Events

        badge_count_combobox.changed.connect (() => {
            Planner.settings.set_enum ("badge-count", badge_count_combobox.active);
        });

        return main_grid;
    }
}
