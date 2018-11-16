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
        //get_style_context ().add_class ("view");

        title = _("Preferences");
        set_size_request (600, 400);
        resizable = false;
        //use_header_bar = 1;
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
        headerbar.get_style_context ().add_class ("planner-preferences-headerbar");

        main_stack = new Gtk.Stack ();
        main_stack.expand = true;
        main_stack.margin = 12;
        main_stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
        main_stack.add_named (get_general_widget (), "general");
        main_stack.visible_child_name = "general";

        var content_grid = new Gtk.Grid ();
        //content_grid.attach (mode_button, 0, 0, 1, 1);
        content_grid.attach (main_stack, 0, 1, 1, 1);

        ((Gtk.Container) get_content_area ()).add (content_grid);

        var close_button = new SettingsButton (_("Close"));

        close_button.clicked.connect (() => {
			destroy ();
		});

        add_action_widget (close_button, 0);
    }

    private Gtk.Widget get_general_widget () {
        int pixel_size = 24;

        var badge_count_icon = new Gtk.Image ();
        badge_count_icon.gicon = new ThemedIcon ("preferences-system-notifications");
        badge_count_icon.pixel_size = pixel_size;

        var badge_count_label = new Gtk.Label (_("Badge Count"));
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
        badge_count_box.tooltip_text = _("Choose which items should be counted for \n the badge on the application icon.");
        badge_count_box.pack_start (badge_count_icon, false, false, 0);
        badge_count_box.pack_start (badge_count_label, false, false, 6);
        badge_count_box.pack_end (badge_count_combobox, false, false, 0);

        var start_page_icon = new Gtk.Image ();
        start_page_icon.gicon = new ThemedIcon ("go-home");
        start_page_icon.pixel_size = pixel_size;

        var start_page_label = new Gtk.Label (_("Start Page"));
        start_page_label.get_style_context ().add_class ("h3");

        var start_page_combobox = new Gtk.ComboBoxText ();
        start_page_combobox.width_request = 120;
		start_page_combobox.append_text (_("Inbox"));
		start_page_combobox.append_text (_("Today"));
        start_page_combobox.append_text (_("Tomorrow"));
		start_page_combobox.active = Planner.settings.get_enum ("start-page");

        var start_page_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        start_page_box.hexpand = true;
        start_page_box.tooltip_text = _("Choose that page should be first initial \n when Planner is open.");
        start_page_box.pack_start (start_page_icon, false, false, 0);
        start_page_box.pack_start (start_page_label, false, false, 6);
        start_page_box.pack_end (start_page_combobox, false, false, 0);

        var button_press_icon = new Gtk.Image ();
        button_press_icon.gicon = new ThemedIcon ("input-mouse");
        button_press_icon.pixel_size = pixel_size;

        var button_press_label = new Gtk.Label (_("Button Press"));
        button_press_label.get_style_context ().add_class ("h3");

        var button_press_combobox = new Gtk.ComboBoxText ();
        button_press_combobox.width_request = 120;
		button_press_combobox.append_text (_("None"));
        button_press_combobox.append_text (_("Double Button Press"));
		button_press_combobox.append_text (_("Triple Button Press"));

		button_press_combobox.active = Planner.settings.get_enum ("button-press");

        var button_press_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        button_press_box.hexpand = true;
        button_press_box.tooltip_text = _("You can click on any part of the interface \n to close all open tasks.");
        button_press_box.pack_start (button_press_icon, false, false, 0);
        button_press_box.pack_start (button_press_label, false, false, 6);
        button_press_box.pack_end (button_press_combobox, false, false, 0);

        var main_grid = new Gtk.Grid ();
        main_grid.row_spacing = 12;
        main_grid.orientation = Gtk.Orientation.VERTICAL;

        main_grid.add (badge_count_box);
        main_grid.add (start_page_box);
        main_grid.add (button_press_box);

        // Events
        badge_count_combobox.changed.connect (() => {
            Planner.settings.set_enum ("badge-count", badge_count_combobox.active);
        });

        start_page_combobox.changed.connect(() => {
            Planner.settings.set_enum ("start-page", start_page_combobox.active);
        });

        button_press_combobox.changed.connect(() => {
            Planner.settings.set_enum ("button-press", button_press_combobox.active);
        });

        return main_grid;
    }

    private class SettingsButton : Gtk.Button {
		public SettingsButton (string text) {
			label = text;
			valign = Gtk.Align.END;
			get_style_context ().add_class ("suggested-action");
		}
	}
}
