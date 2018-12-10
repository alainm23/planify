public class Dialogs.PreferencesDialog : Gtk.Dialog {
    public weak Gtk.Window window { get; construct; }
    private Gtk.Stack main_stack;

    private Gtk.Label start_page_preview_label;
    private Gtk.Label badge_count_preview_label;
    private Gtk.Label quick_save_preview_label;
    private Gtk.Label weather_preview_label;
    private Gtk.Label calendar_preview_label;

    public signal void on_close ();
    public PreferencesDialog (Gtk.Window parent) {
        Object (
            window: parent,
            transient_for: parent,
            deletable: false,
            resizable: false,
            destroy_with_parent: true,
            window_position: Gtk.WindowPosition.CENTER_ON_PARENT
        );
	}

    construct {
        title = _("Preferences");
        set_size_request (640, 494);

        var mode_button = new Granite.Widgets.ModeButton ();
        mode_button.hexpand = true;
        mode_button.halign = Gtk.Align.CENTER;

        mode_button.append_text (_("General"));
        mode_button.append_text (_("Help"));
        mode_button.selected = 0;

        main_stack = new Gtk.Stack ();
        main_stack.expand = true;
        main_stack.margin = 12;
        main_stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;

        main_stack.add_named (get_general_widget (), "general");
        main_stack.add_named (get_help_widget (), "help");
        main_stack.add_named (get_badge_count_widget (), "badge_count");
        main_stack.add_named (get_start_page_widget (), "start_page");
        main_stack.add_named (get_quick_save_widget (), "quick_save");
        main_stack.add_named (get_weather_widget (), "weather");

        main_stack.visible_child_name = "general";

        var content_grid = new Gtk.Grid ();
        content_grid.orientation = Gtk.Orientation.VERTICAL;
        content_grid.add (mode_button);
        content_grid.add (main_stack);

        ((Gtk.Container) get_content_area ()).add (content_grid);

        var close_button = new Gtk.Button.with_label (_("Close"));
        close_button.valign = Gtk.Align.END;
        close_button.get_style_context ().add_class ("suggested-action");
        close_button.margin_bottom = 6;
        close_button.margin_end = 6;

        close_button.clicked.connect (() => {
			destroy ();
		});

        mode_button.mode_changed.connect ((widget) => {
            if (mode_button.selected == 0) {
                main_stack.visible_child_name = "general";
            } else {
                main_stack.visible_child_name = "help";
            }
        });

        add_action_widget (close_button, 0);
    }

    private Gtk.Widget get_badge_count_widget () {
        var back_button = new Gtk.Button.with_label (Application.utils.BACK_STRING);
        back_button.can_focus = false;
        back_button.valign = Gtk.Align.CENTER;
        back_button.get_style_context ().add_class (Granite.STYLE_CLASS_BACK_BUTTON);

        var title_label = new Gtk.Label ("<b>%s</b>".printf (Application.utils.BADGE_COUNT_STRING));
        title_label.use_markup = true;

        var top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        top_box.margin = 6;
        top_box.hexpand = true;
        top_box.pack_start (back_button, false, false, 0);
        top_box.set_center_widget (title_label);

        var badge_count_icon = new Gtk.Image ();
        badge_count_icon.gicon = new ThemedIcon ("preferences-system-notifications");
        badge_count_icon.pixel_size = 32;

        var badge_count_label = new Gtk.Label (_("Choose which items should be counted for the badge on the application icon."));
        badge_count_label.get_style_context ().add_class ("h3");
        badge_count_label.max_width_chars = 41;
        badge_count_label.wrap = true;

        var description_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        description_box.margin = 10;
        description_box.hexpand = true;
        description_box.pack_start (badge_count_icon, false, false, 0);
        description_box.pack_start (badge_count_label, false, false, 0);

        var none_radio = new Gtk.RadioButton.with_label_from_widget (null, Application.utils.NONE_STRING);
        none_radio.get_style_context ().add_class ("h3");
        none_radio.margin_start = 12;
        none_radio.margin_top = 6;

        var inbox_radio = new Gtk.RadioButton.with_label_from_widget (none_radio, Application.utils.INBOX_STRING);
        inbox_radio.get_style_context ().add_class ("h3");
        inbox_radio.margin_start = 12;
        inbox_radio.margin_top = 3;

        var today_radio = new Gtk.RadioButton.with_label_from_widget (none_radio, Application.utils.TODAY_STRING);
        today_radio.get_style_context ().add_class ("h3");
        today_radio.margin_start = 12;
        today_radio.margin_top = 3;

        var today_string_radio = new Gtk.RadioButton.with_label_from_widget (none_radio, "%s + %s".printf (Application.utils.TODAY_STRING, Application.utils.INBOX_STRING));
        today_string_radio.get_style_context ().add_class ("h3");
        today_string_radio.margin_start = 12;
        today_string_radio.margin_top = 3;

        var notification_radio = new Gtk.RadioButton.with_label_from_widget (none_radio, Application.utils.NOTIFICATIONS_STRING);
        notification_radio.get_style_context ().add_class ("h3");
        notification_radio.margin_start = 12;
        notification_radio.margin_top = 3;
        notification_radio.margin_bottom = 6;

        int index = Application.settings.get_enum ("start-page");

        if (index == 0) {
            none_radio.active = true;
        } else if (index == 1) {
            inbox_radio.active = true;
        } else if (index == 2) {
            today_radio.active = true;
        } else if (index == 3) {
            today_string_radio.active = true;
        } else if (index == 4) {
            notification_radio.active = true;
        }

        var main_grid = new Gtk.Grid ();
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.add (top_box);
        main_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        main_grid.add (description_box);
        main_grid.add (none_radio);
        main_grid.add (inbox_radio);
        main_grid.add (today_radio);
        main_grid.add (today_string_radio);
        main_grid.add (notification_radio);

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.add (main_grid);

        var main_frame = new Gtk.Frame (null);
        main_frame.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        main_frame.add (scrolled);

        back_button.clicked.connect (() => {
            check_badge_count_preview ();
            main_stack.visible_child_name = "general";
        });

        none_radio.toggled.connect (() => {
            Application.settings.set_enum ("badge-count", 0);
        });

        inbox_radio.toggled.connect (() => {
            Application.settings.set_enum ("badge-count", 1);
        });

        today_radio.toggled.connect (() => {
            Application.settings.set_enum ("badge-count", 2);
        });

        today_string_radio.toggled.connect (() => {
            Application.settings.set_enum ("badge-count", 3);
        });

        notification_radio.toggled.connect (() => {
            Application.settings.set_enum ("badge-count", 4);
        });

        return main_frame;
    }

    private Gtk.Widget get_start_page_widget () {
        var back_button = new Gtk.Button.with_label (Application.utils.BACK_STRING);
        back_button.can_focus = false;
        back_button.valign = Gtk.Align.CENTER;
        back_button.get_style_context ().add_class (Granite.STYLE_CLASS_BACK_BUTTON);

        var title_label = new Gtk.Label ("<b>%s</b>".printf (Application.utils.START_PAGE_STRING));
        title_label.use_markup = true;

        var top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        top_box.margin = 6;
        top_box.hexpand = true;
        top_box.pack_start (back_button, false, false, 0);
        top_box.set_center_widget (title_label);

        var start_page_icon = new Gtk.Image ();
        start_page_icon.gicon = new ThemedIcon ("go-home");
        start_page_icon.pixel_size = 32;

        var start_page_label = new Gtk.Label (_("Choose that page should be first initial when Planner is open."));
        start_page_label.get_style_context ().add_class ("h3");
        start_page_label.max_width_chars = 41;
        start_page_label.wrap = true;

        var description_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        description_box.margin = 10;
        description_box.hexpand = true;
        description_box.pack_start (start_page_icon, false, false, 0);
        description_box.pack_start (start_page_label, false, false, 6);

        var inbox_radio = new Gtk.RadioButton.with_label_from_widget (null, Application.utils.INBOX_STRING);
        inbox_radio.get_style_context ().add_class ("h3");
        inbox_radio.margin_start = 12;
        inbox_radio.margin_top = 6;

        var today_radio = new Gtk.RadioButton.with_label_from_widget (inbox_radio, Application.utils.TODAY_STRING);
        today_radio.get_style_context ().add_class ("h3");
        today_radio.margin_start = 12;
        today_radio.margin_top = 3;

        var upcoming_radio = new Gtk.RadioButton.with_label_from_widget (inbox_radio, Application.utils.UPCOMING_STRING);
        upcoming_radio.get_style_context ().add_class ("h3");
        upcoming_radio.margin_start = 12;
        upcoming_radio.margin_top = 3;
        upcoming_radio.margin_bottom = 6;

        int index = Application.settings.get_enum ("start-page");

        if (index == 0) {
            inbox_radio.active = true;
        } else if (index == 1) {
            today_radio.active = true;
        } else if (index == 2) {
            upcoming_radio.active = true;
        }

        var main_grid = new Gtk.Grid ();
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.add (top_box);
        main_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        main_grid.add (description_box);
        main_grid.add (inbox_radio);
        main_grid.add (today_radio);
        main_grid.add (upcoming_radio);

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.add (main_grid);

        var main_frame = new Gtk.Frame (null);
        main_frame.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        main_frame.add (scrolled);

        back_button.clicked.connect (() => {
            check_start_page_preview ();
            main_stack.visible_child_name = "general";
        });

        inbox_radio.toggled.connect (() => {
            Application.settings.set_enum ("start-page", 0);
        });

        today_radio.toggled.connect (() => {
            Application.settings.set_enum ("start-page", 1);
        });

        upcoming_radio.toggled.connect (() => {
            Application.settings.set_enum ("start-page", 2);
        });

        return main_frame;
    }

    private Gtk.Widget get_quick_save_widget () {
        var back_button = new Gtk.Button.with_label (Application.utils.BACK_STRING);
        back_button.can_focus = false;
        back_button.valign = Gtk.Align.CENTER;
        back_button.get_style_context ().add_class (Granite.STYLE_CLASS_BACK_BUTTON);

        var title_label = new Gtk.Label ("<b>%s</b>".printf (Application.utils.QUICK_SAVE_STRING));
        title_label.use_markup = true;

        var top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        top_box.margin = 6;
        top_box.hexpand = true;
        top_box.pack_start (back_button, false, false, 0);
        top_box.set_center_widget (title_label);

        var quick_save_icon = new Gtk.Image ();
        quick_save_icon.gicon = new ThemedIcon ("input-mouse");
        quick_save_icon.pixel_size = 32;

        var quick_save_label = new Gtk.Label (_("Choose how many clicks to close and save all open tasks."));
        quick_save_label.get_style_context ().add_class ("h3");
        quick_save_label.max_width_chars = 41;
        quick_save_label.wrap = true;

        var description_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        description_box.margin = 10;
        description_box.hexpand = true;
        description_box.pack_start (quick_save_icon, false, false, 0);
        description_box.pack_start (quick_save_label, false, false, 6);

        var none_radio = new Gtk.RadioButton.with_label_from_widget (null, Application.utils.NONE_STRING);
        none_radio.get_style_context ().add_class ("h3");
        none_radio.margin_start = 12;
        none_radio.margin_top = 6;

        var double_radio = new Gtk.RadioButton.with_label_from_widget (none_radio, Application.utils.DOUBLE_STRING);
        double_radio.get_style_context ().add_class ("h3");
        double_radio.margin_start = 12;
        double_radio.margin_top = 3;

        var triple_radio = new Gtk.RadioButton.with_label_from_widget (none_radio, Application.utils.TRIPLE_STRING);
        triple_radio.get_style_context ().add_class ("h3");
        triple_radio.margin_start = 12;
        triple_radio.margin_top = 3;
        triple_radio.margin_bottom = 6;

        int index = Application.settings.get_enum ("quick-save");

        if (index == 0) {
            none_radio.active = true;
        } else if (index == 1) {
            double_radio.active = true;
        } else if (index == 2) {
            triple_radio.active = true;
        }

        var main_grid = new Gtk.Grid ();
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.add (top_box);
        main_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        main_grid.add (description_box);
        main_grid.add (none_radio);
        main_grid.add (double_radio);
        main_grid.add (triple_radio);

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.add (main_grid);

        var main_frame = new Gtk.Frame (null);
        main_frame.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        main_frame.add (scrolled);

        back_button.clicked.connect (() => {
            check_quick_save_preview ();
            main_stack.visible_child_name = "general";
        });

        none_radio.toggled.connect (() => {
            Application.settings.set_enum ("quick-save", 0);
        });

        double_radio.toggled.connect (() => {
            Application.settings.set_enum ("quick-save", 1);
        });

        triple_radio.toggled.connect (() => {
            Application.settings.set_enum ("quick-save", 2);
        });

        return main_frame;
    }

    private Gtk.Widget get_weather_widget () {
        var back_button = new Gtk.Button.with_label (Application.utils.BACK_STRING);
        back_button.can_focus = false;
        back_button.valign = Gtk.Align.CENTER;
        back_button.get_style_context ().add_class (Granite.STYLE_CLASS_BACK_BUTTON);

        var title_label = new Gtk.Label ("<b>%s</b>".printf (Application.utils.WEATHER_STRING));
        title_label.use_markup = true;

        var top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        top_box.margin = 6;
        top_box.hexpand = true;
        top_box.pack_start (back_button, false, false, 0);
        top_box.set_center_widget (title_label);

        var weather_icon = new Gtk.Image ();
        weather_icon.gicon = new ThemedIcon ("applications-internet");
        weather_icon.pixel_size = 32;

        var weather_label = new Gtk.Label (_("Get the weather forecast in a simple and beautiful widget."));
        weather_label.get_style_context ().add_class ("h3");
        weather_label.max_width_chars = 41;
        weather_label.wrap = true;

        var description_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        description_box.margin = 10;
        description_box.hexpand = true;
        description_box.pack_start (weather_icon, false, false, 0);
        description_box.pack_start (weather_label, false, false, 6);

        var temperature_label = new Granite.HeaderLabel (_("Temperature"));
        temperature_label.margin_start = 12;

        var temperature_modebutton = new Granite.Widgets.ModeButton ();
        temperature_modebutton.margin_start = 12;
        temperature_modebutton.valign = Gtk.Align.CENTER;
        temperature_modebutton.halign = Gtk.Align.START;
        temperature_modebutton.append_text (_("°F"));
        temperature_modebutton.append_text (_("°C"));
        temperature_modebutton.selected = Application.settings.get_enum ("weather-unit-format");

        var location_label = new Granite.HeaderLabel (_("Location"));
        location_label.margin_start = 12;

        var manual_location_entry = new Gtk.Entry ();
        manual_location_entry.placeholder_text = "Seattle, US";
        manual_location_entry.text = Application.settings.get_string ("location-manual-value");

        var location_help_button = new Gtk.Button.from_icon_name ("help-contents-symbolic", Gtk.IconSize.MENU);
        location_help_button.can_focus = false;

        var manual_location_grid = new Gtk.Grid ();
        manual_location_grid.get_style_context ().add_class (Gtk.STYLE_CLASS_LINKED);
        manual_location_grid.add (manual_location_entry);
        manual_location_grid.add (location_help_button);

        var automatic_label = new Gtk.Label (_("Automatic:"));

        var automatic_switch = new Gtk.Switch ();
        automatic_switch.tooltip_text = _("Automatic Location");
        automatic_switch.active = Application.settings.get_boolean ("location-automatic");

        var location_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        location_box.margin_start = 12;
        location_box.margin_end = 12;
        location_box.pack_start (manual_location_grid, false, false, 0);
        location_box.pack_start (automatic_label, false, false, 6);
        location_box.pack_start (automatic_switch, false, false, 0);

        var main_grid = new Gtk.Grid ();
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.add (top_box);
        main_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        main_grid.add (description_box);
        main_grid.add (temperature_label);
        main_grid.add (temperature_modebutton);
        main_grid.add (location_label);
        main_grid.add (location_box);

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.add (main_grid);

        var main_frame = new Gtk.Frame (null);
        main_frame.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        main_frame.add (scrolled);

        back_button.clicked.connect (() => {
            check_weather_preview ();
            main_stack.visible_child_name = "general";
        });

        manual_location_entry.activate.connect (() =>{
            Application.settings.set_string ("location-manual-value", manual_location_entry.text);
            Application.notification.on_signal_location_manual ();
        });

        manual_location_entry.focus_out_event.connect (() => {
            Application.settings.set_string ("location-manual-value", manual_location_entry.text);
            Application.notification.on_signal_location_manual ();
            return false;
        });

        automatic_switch.notify["active"].connect (() => {
			if (automatic_switch.active) {
                Application.settings.set_boolean ("location-automatic", true);
                manual_location_entry.sensitive = false;

                Application.notification.on_signal_weather_update ();
			} else {
                Application.settings.set_boolean ("location-automatic", false);
			    manual_location_entry.sensitive = true;

                Application.notification.on_signal_location_manual ();
			}
		});

        location_help_button.clicked.connect (() => {
            try {
                Gtk.show_uri (null, "https://openweathermap.org/find?q=", 0);
            } catch (Error e) {
                stderr.printf ("Failed to open uri.\n");
            }
        });

        temperature_modebutton.mode_changed.connect (() => {
            Application.settings.set_enum ("weather-unit-format", temperature_modebutton.selected);
            Application.notification.on_signal_weather_update ();
        });

        return main_frame;
    }

    private void check_start_page_preview () {
        int index = Application.settings.get_enum ("start-page");

        if (index == 0) {
            start_page_preview_label.label = Application.utils.INBOX_STRING;
        } else if (index == 1) {
            start_page_preview_label.label = Application.utils.TODAY_STRING;
        } else if (index == 2) {
            start_page_preview_label.label = Application.utils.UPCOMING_STRING;
        }
    }

    private void check_badge_count_preview () {
        int index = Application.settings.get_enum ("badge-count");

        if (index == 0) {
            badge_count_preview_label.label = Application.utils.NONE_STRING;
        } else if (index == 1) {
            badge_count_preview_label.label = Application.utils.INBOX_STRING;
        } else if (index == 2) {
            badge_count_preview_label.label = Application.utils.TODAY_STRING;
        } else if (index == 3) {
            badge_count_preview_label.label = "%s + %s".printf (Application.utils.TODAY_STRING, Application.utils.INBOX_STRING);
        } else if (index == 4) {
            badge_count_preview_label.label = Application.utils.NOTIFICATIONS_STRING;
        }
    }

    private void check_quick_save_preview () {
        int index = Application.settings.get_enum ("quick-save");

        if (index == 0) {
            quick_save_preview_label.label = Application.utils.NONE_STRING;
        } else if (index == 1) {
            quick_save_preview_label.label = Application.utils.DOUBLE_STRING;
        } else if (index == 2) {
            quick_save_preview_label.label = Application.utils.TRIPLE_STRING;
        }
    }

    private void check_weather_preview () {
        string location = "";
        string unit = "";

        if (Application.settings.get_boolean ("location-automatic")) {
            location = _("Automatic Location");
        } else {
            location = Application.settings.get_string ("location-manual-value");
        }

        if (Application.settings.get_enum ("weather-unit-format") == 0) {
            unit = "°F";
        } else {
            unit = "°C";
        }

        weather_preview_label.label = "%s / %s".printf (location, unit);
    }

    private Gtk.Widget get_help_widget () {
        int pixel_size = 24;

        var tutorial_project_icon = new Gtk.Image ();
        tutorial_project_icon.gicon = new ThemedIcon ("help-about");
        tutorial_project_icon.pixel_size = pixel_size;

        var tutorial_project_label = new Gtk.Label (_("Create Tutorial Project"));
        tutorial_project_label.get_style_context ().add_class ("h3");

        var tutorial_project_button = new Gtk.Button.with_label (_("Create"));
        tutorial_project_button.margin_end = 6;
        tutorial_project_button.can_focus = false;
        //tutorial_project_button.get_style_context ().add_class ("flat");
        tutorial_project_button.get_style_context ().add_class ("no-padding");

        var loading_spinner = new Gtk.Spinner ();
        loading_spinner.active = true;
        loading_spinner.visible = false;
        loading_spinner.no_show_all = true;

        var tutorial_project_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        tutorial_project_box.margin = 6;
        tutorial_project_box.hexpand = true;
        tutorial_project_box.tooltip_text = _("Learn the app step by step with a \n short tutorial project.");
        tutorial_project_box.pack_start (tutorial_project_icon, false, false, 0);
        tutorial_project_box.pack_start (tutorial_project_label, false, false, 6);
        tutorial_project_box.pack_end (tutorial_project_button, false, false, 0);
        tutorial_project_box.pack_end (loading_spinner, false, false, 0);

        var bug_icon = new Gtk.Image ();
        bug_icon.gicon = new ThemedIcon ("bug");
        bug_icon.pixel_size = pixel_size;

        var bug_label = new Gtk.Label (_("Report a issue"));
        bug_label.get_style_context ().add_class ("h3");

        var bug_button = new Gtk.LinkButton.with_label ("https://github.com/alainm23/planner/issues", _("Go Github"));
        bug_button.can_focus = false;
        bug_button.get_style_context ().add_class ("no-padding");
        bug_button.get_style_context ().remove_class ("flat");
        bug_button.get_style_context ().remove_class ("link");

        var bug_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        bug_box.margin = 6;
        bug_box.hexpand = true;
        bug_box.pack_start (bug_icon, false, false, 0);
        bug_box.pack_start (bug_label, false, false, 6);
        bug_box.pack_end (bug_button, false, false, 6);

        var main_grid = new Gtk.Grid ();
        main_grid.orientation = Gtk.Orientation.VERTICAL;

        main_grid.add (tutorial_project_box);
        main_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        main_grid.add (bug_box);
        main_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));

        var main_frame = new Gtk.Frame (null);
        main_frame.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        main_frame.add (main_grid);

        tutorial_project_button.clicked.connect (() => {
            tutorial_project_button.visible = false;
            loading_spinner.visible = true;
            loading_spinner.no_show_all = false;

            Application.utils.create_tutorial_project ();

            Application.notification.send_local_notification (
                _("Tutorial Project Created"),
                _("A tutorial project has been created."),
                "help-about",
                4,
                false
            );

            destroy ();
        });

        return main_frame;
    }

    private Gtk.Widget get_general_widget () {
        int pixel_size = 24;

        // Badge Count
        var badge_count_icon = new Gtk.Image ();
        badge_count_icon.gicon = new ThemedIcon ("preferences-system-notifications");
        badge_count_icon.pixel_size = pixel_size;

        var badge_count_label = new Gtk.Label (Application.utils.BADGE_COUNT_STRING);
        badge_count_label.get_style_context ().add_class ("h3");

        badge_count_preview_label = new Gtk.Label (null);
        check_badge_count_preview ();

        var badge_count_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        badge_count_box.margin = 6;
        badge_count_box.margin_end = 12;
        badge_count_box.hexpand = true;
        badge_count_box.pack_start (badge_count_icon, false, false, 0);
        badge_count_box.pack_start (badge_count_label, false, false, 6);
        badge_count_box.pack_end (badge_count_preview_label, false, false, 0);

        var badge_count_eventbox = new Gtk.EventBox ();
        badge_count_eventbox.add (badge_count_box);

        // Start Page
        var start_page_icon = new Gtk.Image ();
        start_page_icon.gicon = new ThemedIcon ("go-home");
        start_page_icon.pixel_size = pixel_size;

        var start_page_label = new Gtk.Label (Application.utils.START_PAGE_STRING);
        start_page_label.get_style_context ().add_class ("h3");

        start_page_preview_label = new Gtk.Label (null);
        check_start_page_preview ();

        var start_page_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        start_page_box.margin = 6;
        start_page_box.margin_end = 12;
        start_page_box.hexpand = true;
        start_page_box.pack_start (start_page_icon, false, false, 0);
        start_page_box.pack_start (start_page_label, false, false, 6);
        start_page_box.pack_end (start_page_preview_label, false, false, 0);

        var start_page_eventbox = new Gtk.EventBox ();
        start_page_eventbox.add (start_page_box);

        // Quick save
        var quick_save_icon = new Gtk.Image ();
        quick_save_icon.gicon = new ThemedIcon ("input-mouse");
        quick_save_icon.pixel_size = pixel_size;

        var quick_save_label = new Gtk.Label (Application.utils.QUICK_SAVE_STRING);
        quick_save_label.get_style_context ().add_class ("h3");

        quick_save_preview_label = new Gtk.Label (null);
        check_quick_save_preview ();

        var quick_save_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        quick_save_box.margin = 6;
        quick_save_box.margin_end = 12;
        quick_save_box.hexpand = true;
        quick_save_box.pack_start (quick_save_icon, false, false, 0);
        quick_save_box.pack_start (quick_save_label, false, false, 6);
        quick_save_box.pack_end (quick_save_preview_label, false, false, 0);

        var quick_save_eventbox = new Gtk.EventBox ();
        quick_save_eventbox.add (quick_save_box);

        // Weather
        var weather_icon = new Gtk.Image ();
        weather_icon.gicon = new ThemedIcon ("applications-internet");
        weather_icon.pixel_size = pixel_size;

        var weather_label = new Gtk.Label (Application.utils.WEATHER_STRING);
        weather_label.get_style_context ().add_class ("h3");

        weather_preview_label = new Gtk.Label (null);
        check_weather_preview ();

        var weather_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        weather_box.margin = 6;
        weather_box.margin_end = 12;
        weather_box.hexpand = true;
        weather_box.pack_start (weather_icon, false, false, 0);
        weather_box.pack_start (weather_label, false, false, 6);
        weather_box.pack_end (weather_preview_label, false, false, 0);

        var weather_eventbox = new Gtk.EventBox ();
        weather_eventbox.add (weather_box);

        // Calendar
        var calendar_icon = new Gtk.Image ();
        calendar_icon.gicon = new ThemedIcon ("office-calendar");
        calendar_icon.pixel_size = pixel_size;

        var calendar_label = new Gtk.Label (Application.utils.CALENDAR_STRING);
        calendar_label.get_style_context ().add_class ("h3");

        calendar_preview_label = new Gtk.Label (null);

        var calendar_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        calendar_box.margin = 6;
        calendar_box.margin_end = 12;
        calendar_box.hexpand = true;
        calendar_box.pack_start (calendar_icon, false, false, 0);
        calendar_box.pack_start (calendar_label, false, false, 6);
        calendar_box.pack_end (calendar_preview_label, false, false, 0);

        var calendar_eventbox = new Gtk.EventBox ();
        calendar_eventbox.add (calendar_box);

        // Run Background
        var run_background_icon = new Gtk.Image ();
        run_background_icon.gicon = new ThemedIcon ("preferences-system");
        run_background_icon.pixel_size = pixel_size;

        var run_background_label = new Gtk.Label (_("Run in background"));
        run_background_label.get_style_context ().add_class ("h3");

        var run_background_switch = new Gtk.Switch ();
        run_background_switch.valign = Gtk.Align.CENTER;
        run_background_switch.get_style_context ().add_class ("active-switch");
        run_background_switch.active = Application.settings.get_boolean ("run-background");

        var run_background_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        run_background_box.margin = 6;
        run_background_box.margin_end = 12;
        run_background_box.hexpand = true;
        run_background_box.tooltip_text = _("Let Planner run in background and send notifications.");
        run_background_box.pack_start (run_background_icon, false, false, 0);
        run_background_box.pack_start (run_background_label, false, false, 6);
        run_background_box.pack_end (run_background_switch, false, false, 0);

        var run_background_eventbox = new Gtk.EventBox ();
        run_background_eventbox.add (run_background_box);

        // Launch at login
        var launch_icon = new Gtk.Image ();
        launch_icon.gicon = new ThemedIcon ("system-shutdown");
        launch_icon.pixel_size = pixel_size;

        var launch_icon_label = new Gtk.Label (_("Launch at Login"));
        launch_icon_label.get_style_context ().add_class ("h3");

        var launch_switch = new Gtk.Switch ();
        launch_switch.valign = Gtk.Align.CENTER;
        launch_switch.get_style_context ().add_class ("active-switch");
        launch_switch.active = Application.settings.get_boolean ("launch-login");

        var launch_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        launch_box.margin = 6;
        launch_box.margin_end = 12;
        launch_box.hexpand = true;
        launch_box.pack_start (launch_icon, false, false, 0);
        launch_box.pack_start (launch_icon_label, false, false, 6);
        launch_box.pack_end (launch_switch, false, false, 0);

        var launch_eventbox = new Gtk.EventBox ();
        launch_eventbox.add (launch_box);

        var main_grid = new Gtk.Grid ();
        main_grid.orientation = Gtk.Orientation.VERTICAL;

        main_grid.add (badge_count_eventbox);
        main_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        main_grid.add (start_page_eventbox);
        main_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        main_grid.add (quick_save_eventbox);
        main_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        main_grid.add (weather_eventbox);
        main_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        main_grid.add (calendar_eventbox);
        main_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        main_grid.add (run_background_eventbox);
        main_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        main_grid.add (launch_eventbox);
        main_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.add (main_grid);

        var main_frame = new Gtk.Frame (null);
        //main_frame.valign = Gtk.Align.START;
        main_frame.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        main_frame.add (scrolled);

        // Events
        badge_count_eventbox.event.connect ((event) => {
            if (event.type == Gdk.EventType.BUTTON_PRESS) {
                main_stack.visible_child_name = "badge_count";
            }

            return false;
        });

        start_page_eventbox.event.connect ((event) => {
            if (event.type == Gdk.EventType.BUTTON_PRESS) {
                main_stack.visible_child_name = "start_page";
            }

            return false;
        });

        quick_save_eventbox.event.connect ((event) => {
            if (event.type == Gdk.EventType.BUTTON_PRESS) {
                main_stack.visible_child_name = "quick_save";
            }

            return false;
        });

        weather_eventbox.event.connect ((event) => {
            if (event.type == Gdk.EventType.BUTTON_PRESS) {
                main_stack.visible_child_name = "weather";
            }

            return false;
        });

        run_background_eventbox.event.connect ((event) => {
            if (event.type == Gdk.EventType.BUTTON_PRESS) {
                if (run_background_switch.active) {
                    run_background_switch.active = false;
                } else {
                    run_background_switch.active = true;
                }
            }

            return false;
        });

        launch_eventbox.event.connect ((event) => {
            if (event.type == Gdk.EventType.BUTTON_PRESS) {
                if (launch_switch.active) {
                    launch_switch.active = false;
                } else {
                    launch_switch.active = true;
                }
            }

            return false;
        });

        run_background_switch.notify["active"].connect (() => {
            if (run_background_switch.active) {
                Application.settings.set_boolean ("run-background", true);
            } else {
                Application.settings.set_boolean ("run-background", false);
            }
        });

        launch_switch.notify["active"].connect (() => {
            if (launch_switch.active) {
                set_autostart (true);
                Application.settings.set_boolean ("launch-login", true);
            } else {
                set_autostart (false);
                Application.settings.set_boolean ("launch-login", false);
            }
        });

        return main_frame;
    }

    private void set_autostart (bool active) {
        var desktop_file_name = "com.github.alainm23.planner.desktop";
        var desktop_file_path = new DesktopAppInfo (desktop_file_name).filename;
        var desktop_file = File.new_for_path (desktop_file_path);
        var dest_path = Path.build_path (Path.DIR_SEPARATOR_S,
                                         Environment.get_user_config_dir (),
                                         "autostart",
                                         desktop_file_name);
        var dest_file = File.new_for_path (dest_path);
        try {
            desktop_file.copy (dest_file, FileCopyFlags.OVERWRITE);
        } catch (Error e) {
            warning ("Error making copy of desktop file for autostart: %s", e.message);
        }

        var keyfile = new KeyFile ();
        try {
            keyfile.load_from_file (dest_path, KeyFileFlags.NONE);
            keyfile.set_boolean ("Desktop Entry", "X-GNOME-Autostart-enabled", active);
            keyfile.save_to_file (dest_path);
        } catch (Error e) {
            warning ("Error enabling autostart: %s", e.message);
        }
    }
}
