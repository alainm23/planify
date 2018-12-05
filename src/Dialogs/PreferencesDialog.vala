public class Dialogs.PreferencesDialog : Gtk.Dialog {
    public weak Gtk.Window window { get; construct; }
    private Gtk.Stack main_stack;

    private Gtk.Label start_page_preview_label;
    private Gtk.Label badge_count_preview_label;
    private Gtk.Label quick_save_preview_label;

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
        set_size_request (640, 500);

        var mode_button = new Granite.Widgets.ModeButton ();
        mode_button.hexpand = true;
        mode_button.halign = Gtk.Align.CENTER;

        mode_button.append_text (_("General"));
        mode_button.append_text (_("Theme"));
        mode_button.selected = 0;

        main_stack = new Gtk.Stack ();
        main_stack.expand = true;
        main_stack.margin = 12;
        main_stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;

        main_stack.add_named (get_general_widget (), "general");
        main_stack.add_named (get_badge_count_widget (), "badge_count");
        main_stack.add_named (get_start_page_widget (), "start_page");
        main_stack.add_named (get_quick_save_widget (), "quick_save");

        main_stack.visible_child_name = "general";

        var content_grid = new Gtk.Grid ();
        content_grid.orientation = Gtk.Orientation.VERTICAL;
        content_grid.add (mode_button);
        content_grid.add (main_stack);

        ((Gtk.Container) get_content_area ()).add (content_grid);

        var close_button = new SettingsButton (_("Close"));
        close_button.margin_bottom = 6;
        close_button.margin_end = 6;

        close_button.clicked.connect (() => {
			destroy ();
		});

        add_action_widget (close_button, 0);
    }

    private Gtk.Widget get_badge_count_widget () {
        var back_button = new Gtk.Button.with_label (Application.utils.BACK_STRING);
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
        badge_count_label.selectable = true;
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
        start_page_label.selectable = true;
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
        quick_save_label.selectable = true;
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
        quick_save_box.hexpand = true;
        quick_save_box.pack_start (quick_save_icon, false, false, 0);
        quick_save_box.pack_start (quick_save_label, false, false, 6);
        quick_save_box.pack_end (quick_save_preview_label, false, false, 0);

        var quick_save_eventbox = new Gtk.EventBox ();
        quick_save_eventbox.add (quick_save_box);

        // Run Background
        var run_background_icon = new Gtk.Image ();
        run_background_icon.gicon = new ThemedIcon ("system-shutdown");
        run_background_icon.pixel_size = pixel_size;

        var run_background_label = new Gtk.Label (_("Run in background"));
        run_background_label.get_style_context ().add_class ("h3");

        var run_background_switch = new Gtk.Switch ();
        run_background_switch.valign = Gtk.Align.CENTER;
        run_background_switch.get_style_context ().add_class ("active-switch");
        run_background_switch.active = Application.settings.get_boolean ("run-background");

        var run_background_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        run_background_box.margin = 6;
        run_background_box.hexpand = true;
        run_background_box.tooltip_text = _("Let Planner run in background and send notifications.");
        run_background_box.pack_start (run_background_icon, false, false, 0);
        run_background_box.pack_start (run_background_label, false, false, 6);
        run_background_box.pack_end (run_background_switch, false, false, 0);

        var tutorial_project_icon = new Gtk.Image ();
        tutorial_project_icon.gicon = new ThemedIcon ("help-about");
        tutorial_project_icon.pixel_size = pixel_size;

        var tutorial_project_label = new Gtk.Label (_("Create Tutorial Project"));
        tutorial_project_label.get_style_context ().add_class ("h3");

        var tutorial_project_button = new Gtk.Button.with_label (_("Create"));
        tutorial_project_button.get_style_context ().add_class ("no-padding");

        var tutorial_project_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        tutorial_project_box.margin = 6;
        tutorial_project_box.hexpand = true;
        tutorial_project_box.tooltip_text = _("Learn the app step by step with a \n short tutorial project.");
        tutorial_project_box.pack_start (tutorial_project_icon, false, false, 0);
        tutorial_project_box.pack_start (tutorial_project_label, false, false, 6);
        tutorial_project_box.pack_end (tutorial_project_button, false, false, 0);

        var help_label = new Granite.HeaderLabel (_("Help"));
        help_label.margin_start = 6;

        var main_grid = new Gtk.Grid ();
        main_grid.orientation = Gtk.Orientation.VERTICAL;

        main_grid.add (badge_count_eventbox);
        main_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        main_grid.add (start_page_eventbox);
        main_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        main_grid.add (quick_save_eventbox);
        main_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        main_grid.add (run_background_box);
        main_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        main_grid.add (tutorial_project_box);

        var main_frame = new Gtk.Frame (null);
        main_frame.valign = Gtk.Align.START;
        main_frame.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        main_frame.add (main_grid);

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

        tutorial_project_button.clicked.connect (() => {
            destroy ();

            Application.notification.send_local_notification (
                _("Tutorial Project Created"),
                _("A tutorial project has been created."),
                "help-about",
                4,
                false
            );
        });

        run_background_switch.notify["active"].connect (() => {
            if (run_background_switch.active) {
                Application.settings.set_boolean ("run-background", true);
            } else {
                Application.settings.set_boolean ("run-background", false);
            }
        });

        return main_frame;
    }

    private class SettingsButton : Gtk.Button {
		public SettingsButton (string text) {
			label = text;
			valign = Gtk.Align.END;
			get_style_context ().add_class ("suggested-action");
		}
	}
}
