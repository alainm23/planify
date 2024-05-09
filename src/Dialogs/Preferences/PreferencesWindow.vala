/*
* Copyright © 2023 Alain M. (https://github.com/alainm23/planify)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Alain M. <alainmh23@gmail.com>
*/

public class Dialogs.Preferences.PreferencesWindow : Adw.PreferencesWindow {
	public PreferencesWindow () {
		Object (
			transient_for: (Gtk.Window) Planify.instance.main_window,
			deletable: true,
			destroy_with_parent: true,
			modal: true,
			default_width: 450,
			height_request: 500
		);
	}

	construct {
		add (get_preferences_home ());
	}

	private Adw.PreferencesPage get_preferences_home () {
		var page = new Adw.PreferencesPage ();
		page.title = _("Preferences");
		page.name = "preferences";
		page.icon_name = "applications-system-symbolic";

		var banner_image = new Adw.Bin () {
			css_classes = { "banner", "card" },
			height_request = 140
		};

		var banner_title = new Gtk.Label (_("Support Planify")) {
			halign = START,
			css_classes = { "font-bold", "banner-text" }
		};

		var banner_description = new Gtk.Label (_("Planify is being developed with love and passion for open source. However, if you like Planify and want to support its development, please consider supporting us.")) {
			halign = START,
			xalign = 0,
			yalign = 0,
			wrap = true,
			css_classes = { "small-label", "banner-text" }
		};

		var banner_button = new Gtk.Button.with_label (_("Supporting Us")) {
			halign = START,
			margin_top = 6,
			css_classes = { "banner-text" }
		};

		var close_button = new Gtk.Button.from_icon_name ("window-close-symbolic") {
			css_classes = { "border-radius-50", "banner-text" },
			margin_top = 6,
			margin_end = 6,
			valign = START,
			halign = END
		};

		var banner_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
			valign = START,
			halign = START,
			margin_top = 12,
			margin_start = 12,
			margin_end = 12,
			margin_bottom = 12
		};

		banner_box.append (banner_title);
		banner_box.append (banner_description);
		banner_box.append (banner_button);
		
		var banner_overlay = new Gtk.Overlay ();
		banner_overlay.child = banner_image;
		banner_overlay.add_overlay (banner_box);
		banner_overlay.add_overlay (close_button);

		var banner_group = new Adw.PreferencesGroup ();
		banner_group.add (banner_overlay);

		Services.Settings.get_default ().settings.bind ("show-support-banner", banner_group, "visible", GLib.SettingsBindFlags.DEFAULT);

		banner_button.clicked.connect (() => {
			push_subpage (get_support_page ());
		});

		close_button.clicked.connect (() => {
			Services.Settings.get_default ().settings.set_boolean ("show-support-banner", false);
		});

		page.add (banner_group);

		// Accounts
		var accounts_row = new Adw.ActionRow ();
		accounts_row.activatable = true;
		accounts_row.add_prefix (generate_icon ("cloud-outline-thick-symbolic"));
		accounts_row.add_suffix (generate_icon ("go-next-symbolic"));
		accounts_row.title = _("Integrations");
		accounts_row.subtitle = _("Sync your favorite to-do providers");

		accounts_row.activated.connect (() => {
			push_subpage (get_accounts_page ());
		});

		var accounts_group = new Adw.PreferencesGroup ();
		accounts_group.add (accounts_row);

		page.add (accounts_group);

		// Personalization
		var general_row = new Adw.ActionRow ();
		general_row.activatable = true;
		general_row.add_prefix (generate_icon ("settings-symbolic"));
		general_row.add_suffix (generate_icon ("go-next-symbolic"));
		general_row.title = _("General");
		general_row.subtitle = _("Customize to your liking");

		general_row.activated.connect (() => {
			push_subpage (get_general_page ());
		});

		var task_setting_row = new Adw.ActionRow ();
		task_setting_row.activatable = true;
		task_setting_row.add_prefix (generate_icon ("check-round-outline-symbolic"));
		task_setting_row.add_suffix (generate_icon ("go-next-symbolic"));
		task_setting_row.title = _("Task Setting");

		task_setting_row.activated.connect (() => {
			push_subpage (get_task_setting_page ());
		});

		var sidebar_row = new Adw.ActionRow ();
		sidebar_row.activatable = true;
		sidebar_row.add_prefix (generate_icon ("dock-left-symbolic"));
		sidebar_row.add_suffix (generate_icon ("go-next-symbolic"));
		sidebar_row.title = _("Sidebar");
		sidebar_row.subtitle = _("Customize your sidebar");

		sidebar_row.activated.connect (() => {
			push_subpage (get_sidebar_page ());
		});

		var appearance_row = new Adw.ActionRow ();
		appearance_row.activatable = true;
		appearance_row.add_prefix (generate_icon ("color-symbolic"));
		appearance_row.add_suffix (generate_icon ("go-next-symbolic"));
		appearance_row.title = _("Appearance");
		appearance_row.subtitle = Util.get_default ().get_theme_name ();

		appearance_row.activated.connect (() => {
			push_subpage (get_appearance_page ());
		});

		var quick_add_row = new Adw.ActionRow ();
		quick_add_row.activatable = true;
		quick_add_row.add_prefix (generate_icon ("tab-new-symbolic"));
		quick_add_row.add_suffix (generate_icon ("go-next-symbolic"));
		quick_add_row.title = _("Quick Add");
		quick_add_row.subtitle = _("Adding to-do's from anywhere");

		quick_add_row.activated.connect (() => {
			push_subpage (get_quick_add_page ());
		});

		var backups_row = new Adw.ActionRow ();
		backups_row.activatable = true;
		backups_row.add_prefix (generate_icon ("arrow3-down-symbolic"));
		backups_row.add_suffix (generate_icon ("go-next-symbolic"));
		backups_row.title = _("Backups");
		backups_row.subtitle = _("Backup or migrate from Planner.");

		var tutorial_row = new Adw.ActionRow ();
		tutorial_row.activatable = true;
		tutorial_row.add_prefix (generate_icon ("rescue-symbolic"));
		tutorial_row.add_suffix (generate_icon ("go-next-symbolic"));
		tutorial_row.title = _("Create Tutorial Project");
		tutorial_row.subtitle = _("Learn the app step by step with a short tutorial project");

		var personalization_group = new Adw.PreferencesGroup ();
		personalization_group.add (general_row);
		personalization_group.add (task_setting_row);
		personalization_group.add (sidebar_row);
		personalization_group.add (appearance_row);
		personalization_group.add (quick_add_row);
		personalization_group.add (backups_row);
		personalization_group.add (tutorial_row);

		page.add (personalization_group);

		// Reach Us Group

		var reach_us_group = new Adw.PreferencesGroup ();
		reach_us_group.title = _("Reach Us");

		var contact_us_row = new Adw.ActionRow ();
		contact_us_row.activatable = true;
		contact_us_row.add_prefix (generate_icon ("mail-symbolic"));
		contact_us_row.add_suffix (generate_icon ("go-next-symbolic"));
		contact_us_row.title = _("Contact Us");
		contact_us_row.subtitle = _("Request a feature or ask us anything");

		contact_us_row.activated.connect (() => {
			string uri = "mailto:%s".printf (Constants.CONTACT_US);

            try {
                AppInfo.launch_default_for_uri (uri, null);
            } catch (Error e) {
                warning ("%s\n", e.message);
            }
        });

		var tweet_us_row = new Adw.ActionRow ();
		tweet_us_row.activatable = true;
		tweet_us_row.add_prefix (generate_icon ("chat-bubble-text-symbolic"));
		tweet_us_row.add_suffix (generate_icon ("go-next-symbolic"));
		tweet_us_row.title = _("Tweet Us");
		tweet_us_row.subtitle = _("Share some love");

		tweet_us_row.activated.connect (() => {
            try {
                AppInfo.launch_default_for_uri (Constants.TWITTER_URL, null);
            } catch (Error e) {
                warning ("%s\n", e.message);
            }
        });

		var telegram_row = new Adw.ActionRow ();
		telegram_row.activatable = true;
		telegram_row.add_prefix (generate_icon ("navigate-symbolic"));
		telegram_row.add_suffix (generate_icon ("go-next-symbolic"));
		telegram_row.title = _("Telegram");
		telegram_row.subtitle = _("Discuss and share your feedback");

		telegram_row.activated.connect (() => {
            try {
                AppInfo.launch_default_for_uri (Constants.TELEGRAM_GROUP, null);
            } catch (Error e) {
                warning ("%s\n", e.message);
            }
        });

		var matrix_row = new Adw.ActionRow ();
		matrix_row.activatable = true;
		matrix_row.add_prefix (generate_icon ("chat-bubble-text-symbolic"));
		matrix_row.add_suffix (generate_icon ("go-next-symbolic"));
		matrix_row.title = _("Matrix Room");
		matrix_row.subtitle = _("Discuss and share your feedback");

		matrix_row.activated.connect (() => {
            try {
                AppInfo.launch_default_for_uri (Constants.MATRIX_URL, null);
            } catch (Error e) {
                warning ("%s\n", e.message);
            }
        });

		var supporting_us_row = new Adw.ActionRow ();
		supporting_us_row.activatable = true;
		supporting_us_row.add_prefix (generate_icon ("heart-outline-thick-symbolic"));
		supporting_us_row.add_suffix (generate_icon ("go-next-symbolic"));
		supporting_us_row.title = _("Support Planify");
		supporting_us_row.subtitle = _("Want to buy me a drink?");

		supporting_us_row.activated.connect (() => {
			push_subpage (get_support_page ());
        });

		reach_us_group.add (contact_us_row);
		reach_us_group.add (matrix_row);
		reach_us_group.add (telegram_row);
		reach_us_group.add (supporting_us_row);
		
		page.add (reach_us_group);

		var privacy_group = new Adw.PreferencesGroup ();
		privacy_group.title = _("Privacy");

		var privacy_policy_row = new Adw.ActionRow ();
		privacy_policy_row.activatable = true;
		privacy_policy_row.add_prefix (generate_icon ("shield-safe-symbolic"));
		privacy_policy_row.add_suffix (generate_icon ("go-next-symbolic"));
		privacy_policy_row.title = _("Privacy Policy");
		privacy_policy_row.subtitle = _("We have nothing on you");
		
		var delete_row = new Adw.ActionRow ();
		delete_row.activatable = true;
		delete_row.add_prefix (generate_icon ("user-trash-symbolic"));
		delete_row.add_suffix (generate_icon ("go-next-symbolic"));
		delete_row.title = _("Delete App Data");

		privacy_group.add (privacy_policy_row);
		privacy_group.add (delete_row);

		page.add (privacy_group);

		tutorial_row.activated.connect (() => {
			Util.get_default ().create_tutorial_project ();
			add_toast (Util.get_default ().create_toast (_("A tutorial project has been created")));
		});

		backups_row.activated.connect (() => {
			push_subpage (get_backups_page ());
		});

		privacy_policy_row.activated.connect (() => {
			push_subpage (get_privacy_policy_page ());
		});

		delete_row.activated.connect (() => {
			Util.get_default ().clear_database (_("Delete All Data?"),
			                                    _("Deletes all your lists, tasks, and reminders irreversibly"),
											Planify.instance.main_window);
		});

		return page;
	}

	private Adw.NavigationPage get_general_page () {
		var settings_header = new Dialogs.Preferences.SettingsHeader (_("General"));

		var home_page_model = new Gtk.StringList (null);
		home_page_model.append (_("Inbox"));
		home_page_model.append (_("Today"));
		home_page_model.append (_("Scheduled"));
		home_page_model.append (_("Labels"));
		home_page_model.append (_("Pinboard"));
		
		var home_page_row = new Adw.ComboRow ();
		home_page_row.title = _("Home Page");
		home_page_row.model = home_page_model;
		home_page_row.selected = Services.Settings.get_default ().settings.get_enum ("homepage-item");

		var general_group = new Adw.PreferencesGroup ();
		general_group.title = _("General");
		general_group.add (home_page_row);

		var sort_projects_model = new Gtk.StringList (null);
		sort_projects_model.append (_("Custom Sort Order"));
		sort_projects_model.append (_("Alphabetically"));

		var sort_projects_row = new Adw.ComboRow ();
		sort_projects_row.title = _("Sort by");
		sort_projects_row.model = sort_projects_model;
		sort_projects_row.selected = Services.Settings.get_default ().settings.get_enum ("projects-sort-by");

		var sort_order_projects_model = new Gtk.StringList (null);
		sort_order_projects_model.append (_("Ascending"));
		sort_order_projects_model.append (_("Descending"));

		var sort_order_projects_row = new Adw.ComboRow ();
		sort_order_projects_row.title = _("Ordered");
		sort_order_projects_row.model = sort_order_projects_model;
		sort_order_projects_row.selected = Services.Settings.get_default ().settings.get_enum ("projects-ordered");
		sort_order_projects_row.sensitive = Services.Settings.get_default ().settings.get_enum ("projects-sort-by") == 1;
		
		var sort_setting_group = new Adw.PreferencesGroup ();
		sort_setting_group.title = _("Projects");
		sort_setting_group.add (sort_projects_row);
		sort_setting_group.add (sort_order_projects_row);

		var de_group = new Adw.PreferencesGroup ();
		de_group.title = _("DE Integration");

		var run_background_switch = new Gtk.Switch () {
			valign = Gtk.Align.CENTER,
			active = Services.Settings.get_default ().settings.get_boolean ("run-in-background")
		};

		var run_background_row = new Adw.ActionRow ();
		run_background_row.title = _("Run in Background");
		run_background_row.subtitle = _("Let Planify run in background and send notifications");
		run_background_row.set_activatable_widget (run_background_switch);
		run_background_row.add_suffix (run_background_switch);

		//  de_group.add (run_background_row);

		var run_on_startup_switch = new Gtk.Switch () {
			valign = Gtk.Align.CENTER,
			active = Services.Settings.get_default ().settings.get_boolean ("run-on-startup")
		};

		var run_on_startup_row = new Adw.ActionRow ();
		run_on_startup_row.title = _("Run on Startup");
		run_on_startup_row.subtitle = _("Whether Planify should run on startup");
		run_on_startup_row.set_activatable_widget (run_on_startup_switch);
		run_on_startup_row.add_suffix (run_on_startup_switch);

		de_group.add (run_on_startup_row);

		var calendar_events_switch = new Gtk.Switch () {
			valign = Gtk.Align.CENTER,
			active = Services.Settings.get_default ().settings.get_boolean ("calendar-enabled")
		};

		var calendar_events_row = new Adw.ActionRow ();
		calendar_events_row.title = _("Calendar Events");
		calendar_events_row.set_activatable_widget (calendar_events_switch);
		calendar_events_row.add_suffix (calendar_events_switch);

		de_group.add (calendar_events_row);

		var datetime_group = new Adw.PreferencesGroup ();
		datetime_group.title = _("Date and Time");

		var clock_format_model = new Gtk.StringList (null);
		clock_format_model.append (_("24h"));
		clock_format_model.append (_("12h"));

		var clock_format_row = new Adw.ComboRow ();
		clock_format_row.title = _("Clock Format");
		clock_format_row.model = clock_format_model;
		clock_format_row.selected = Services.Settings.get_default ().settings.get_enum ("clock-format");

		datetime_group.add (clock_format_row);

		var start_week_model = new Gtk.StringList (null);
		start_week_model.append (_("Sunday"));
		start_week_model.append (_("Monday"));
		start_week_model.append (_("Tuesday"));
		start_week_model.append (_("Wednesday"));
		start_week_model.append (_("Thursday"));
		start_week_model.append (_("Friday"));
		start_week_model.append (_("Saturday"));

		var start_week_row = new Adw.ComboRow ();
		start_week_row.title = _("Start of the Week");
		start_week_row.model = start_week_model;
		start_week_row.selected = Services.Settings.get_default ().settings.get_enum ("start-week");

		datetime_group.add (start_week_row);

		var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12);
		content_box.append (general_group);
		content_box.append (sort_setting_group);
		content_box.append (de_group);
		content_box.append (datetime_group);

		var content_clamp = new Adw.Clamp () {
			maximum_size = 600,
			margin_start = 24,
			margin_end = 24,
			margin_bottom = 24
		};

		content_clamp.child = content_box;

		var scrolled_window = new Gtk.ScrolledWindow () {
			hscrollbar_policy = Gtk.PolicyType.NEVER,
			hexpand = true,
			vexpand = true
		};
		scrolled_window.child = content_clamp;

		var toolbar_view = new Adw.ToolbarView ();
		toolbar_view.add_top_bar (settings_header);
		toolbar_view.content = scrolled_window;

		var page = new Adw.NavigationPage (toolbar_view, "general");

		home_page_row.notify["selected"].connect (() => {
			Services.Settings.get_default ().settings.set_enum ("homepage-item", (int) home_page_row.selected);
		});

		sort_projects_row.notify["selected"].connect (() => {
			Services.Settings.get_default ().settings.set_enum ("projects-sort-by", (int) sort_projects_row.selected);
			sort_order_projects_row.sensitive = Services.Settings.get_default ().settings.get_enum ("projects-sort-by") == 1;
		});

		sort_order_projects_row.notify["selected"].connect (() => {
			Services.Settings.get_default ().settings.set_enum ("projects-ordered", (int) sort_order_projects_row.selected);
		});

		run_background_switch.notify["active"].connect (() => {
			Services.Settings.get_default ().settings.set_boolean ("run-in-background", run_background_switch.active);
		});

		run_on_startup_switch.notify["active"].connect (() => {
			Services.Settings.get_default ().settings.set_boolean ("run-on-startup", run_on_startup_switch.active);
		});

		calendar_events_switch.notify["active"].connect (() => {
			Services.Settings.get_default ().settings.set_boolean ("calendar-enabled", calendar_events_switch.active);
		});

		clock_format_row.notify["selected"].connect (() => {
			Services.Settings.get_default ().settings.set_enum ("clock-format", (int) clock_format_row.selected);
		});

		start_week_row.notify["selected"].connect (() => {
			Services.Settings.get_default ().settings.set_enum ("start-week", (int) start_week_row.selected);
		});

		settings_header.back_activated.connect (() => {
			pop_subpage ();
		});

		return page;
	}

	private Adw.NavigationPage get_task_setting_page () {
		var settings_header = new Dialogs.Preferences.SettingsHeader (_("Task Settings"));

		var group = new Adw.PreferencesGroup ();

		var complete_tasks_model = new Gtk.StringList (null);
		complete_tasks_model.append (_("Instantly"));
		complete_tasks_model.append (_("Wait 2500 Milliseconds"));

		var complete_tasks_row = new Adw.ComboRow ();
		complete_tasks_row.title = _("Complete Task");
		complete_tasks_row.subtitle = _("Complete your to-do instantly or wait 2500 milliseconds with the undo option");
		complete_tasks_row.model = complete_tasks_model;
		complete_tasks_row.selected = Services.Settings.get_default ().settings.get_enum ("complete-task");

		group.add (complete_tasks_row);

		var default_priority_model = new Gtk.StringList (null);
		default_priority_model.append (_("Priority 1"));
		default_priority_model.append (_("Priority 2"));
		default_priority_model.append (_("Priority 3"));
		default_priority_model.append (_("None"));

		var default_priority_row = new Adw.ComboRow ();
		default_priority_row.title = _("Default Priority");
		default_priority_row.model = default_priority_model;
		default_priority_row.selected = Services.Settings.get_default ().settings.get_enum ("default-priority");

		group.add (default_priority_row);

		var underline_completed_switch = new Gtk.Switch () {
			valign = Gtk.Align.CENTER,
			active = Services.Settings.get_default ().settings.get_boolean ("underline-completed-tasks")
		};

		var underline_completed_row = new Adw.ActionRow ();
		underline_completed_row.title = _("Underline Completed Tasks");
		underline_completed_row.set_activatable_widget (underline_completed_switch);
		underline_completed_row.add_suffix (underline_completed_switch);

		group.add (underline_completed_row);

		var tasks_position_model = new Gtk.StringList (null);
		tasks_position_model.append (_("Top"));
		tasks_position_model.append (_("Bottom"));

		var tasks_position_row = new Adw.ComboRow ();
		tasks_position_row.title = _("New Task Position");
		tasks_position_row.model = tasks_position_model;
		tasks_position_row.selected = Services.Settings.get_default ().settings.get_enum ("new-tasks-position");

		group.add (tasks_position_row);

		var show_completed_subtasks = new Adw.SwitchRow ();
		show_completed_subtasks.title = _("Always Show Completed Sub-Tasks");
		Services.Settings.get_default ().settings.bind ("always-show-completed-subtasks", show_completed_subtasks, "active", GLib.SettingsBindFlags.DEFAULT);

		group.add (show_completed_subtasks);

		var task_complete_tone = new Adw.SwitchRow ();
		task_complete_tone.title = _("Task Complete Tone");
		task_complete_tone.subtitle = _("Play a sound when tasks are completed");
		Services.Settings.get_default ().settings.bind ("task-complete-tone", task_complete_tone, "active", GLib.SettingsBindFlags.DEFAULT);

		group.add (task_complete_tone);

		var open_task_sidebar = new Adw.SwitchRow ();
		open_task_sidebar.title = _("Open Task In Sidebar View");
		Services.Settings.get_default ().settings.bind ("open-task-sidebar", open_task_sidebar, "active", GLib.SettingsBindFlags.DEFAULT);

		group.add (open_task_sidebar);

		var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12);
		content_box.append (group);

		var content_clamp = new Adw.Clamp () {
			maximum_size = 600,
			margin_start = 24,
			margin_end = 24,
			margin_bottom = 24,
			margin_top = 24
		};

		content_clamp.child = content_box;

		var scrolled_window = new Gtk.ScrolledWindow () {
			hscrollbar_policy = Gtk.PolicyType.NEVER,
			hexpand = true,
			vexpand = true
		};
		scrolled_window.child = content_clamp;

		var toolbar_view = new Adw.ToolbarView ();
		toolbar_view.add_top_bar (settings_header);
		toolbar_view.content = scrolled_window;

		var page = new Adw.NavigationPage (toolbar_view, "general");

		complete_tasks_row.notify["selected"].connect (() => {
			Services.Settings.get_default ().settings.set_enum ("complete-task", (int) complete_tasks_row.selected);
		});

		default_priority_row.notify["selected"].connect (() => {
			Services.Settings.get_default ().settings.set_enum ("default-priority", (int) default_priority_row.selected);
		});

		tasks_position_row.notify["selected"].connect (() => {
			Services.Settings.get_default ().settings.set_enum ("new-tasks-position", (int) tasks_position_row.selected);
		});

		underline_completed_switch.notify["active"].connect (() => {
			Services.Settings.get_default ().settings.set_boolean ("underline-completed-tasks", underline_completed_switch.active);
		});

		return page;
	}

	private Adw.NavigationPage get_sidebar_page () {
		var sidebar_page = new Dialogs.Preferences.Pages.Sidebar ();
		var page = new Adw.NavigationPage (sidebar_page, "sidebar");

		sidebar_page.pop_subpage.connect (() => {
			pop_subpage ();
		});

		return page;
	}

	private Adw.NavigationPage get_appearance_page () {
		var settings_header = new Dialogs.Preferences.SettingsHeader (_("Appearance"));

		var appearance_group = new Adw.PreferencesGroup ();
		appearance_group.title = _("App Theme");

		var system_appearance_switch = new Gtk.Switch () {
			valign = Gtk.Align.CENTER,
			active = Services.Settings.get_default ().settings.get_boolean ("system-appearance")
		};

		var system_appearance_row = new Adw.ActionRow ();
		system_appearance_row.title = _("Use System Settings");
		system_appearance_row.set_activatable_widget (system_appearance_switch);
		system_appearance_row.add_suffix (system_appearance_switch);

		appearance_group.add (system_appearance_row);

		var light_check = new Gtk.CheckButton () {
			halign = Gtk.Align.CENTER,
			focus_on_click = false,
			tooltip_text = _("Light Style"),
			visible = is_light_visible ()
		};
		light_check.add_css_class ("theme-selector");
		light_check.add_css_class ("light");

		var dark_check = new Gtk.CheckButton () {
			halign = Gtk.Align.CENTER,
			focus_on_click = false,
			tooltip_text = _("Dark Style"),
			group = light_check
		};
		dark_check.add_css_class ("theme-selector");
		dark_check.add_css_class ("dark");

		var dark_blue_check = new Gtk.CheckButton () {
			halign = Gtk.Align.CENTER,
			focus_on_click = false,
			tooltip_text = _("Dark Blue Style"),
			group = light_check
		};
		dark_blue_check.add_css_class ("theme-selector");
		dark_blue_check.add_css_class ("dark-blue");

		var dark_modes_group = new Adw.PreferencesGroup () {
			visible = is_dark_modes_visible ()
		};

		var dark_modes_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
			hexpand = true,
			halign = CENTER
		};
		dark_modes_box.append (light_check);
		dark_modes_box.append (dark_check);
		dark_modes_box.append (dark_blue_check);

		var dark_modes_row = new Adw.ActionRow ();
		dark_modes_row.set_child (dark_modes_box);

		dark_modes_group.add (dark_modes_row);

		appearance_group.add (system_appearance_row);

		var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12);
		content_box.append (appearance_group);
		content_box.append (dark_modes_group);

		var content_clamp = new Adw.Clamp () {
			maximum_size = 600,
			margin_start = 24,
			margin_end = 24
		};

		content_clamp.child = content_box;

		var main_content = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
			vexpand = true,
			hexpand = true
		};

		main_content.append (settings_header);
		main_content.append (content_clamp);

		var page = new Adw.NavigationPage (main_content, "appearance");

		int appearance = Services.Settings.get_default ().settings.get_enum ("appearance");
		if (appearance == 0) {
			light_check.active = true;
		} else if (appearance == 1) {
			dark_check.active = true;
		} else if (appearance == 2) {
			dark_blue_check.active = true;
		}

		system_appearance_switch.notify["active"].connect (() => {
			Services.Settings.get_default ().settings.set_boolean ("system-appearance", system_appearance_switch.active);
		});

		light_check.toggled.connect (() => {
			Services.Settings.get_default ().settings.set_boolean ("dark-mode", false);
			Services.Settings.get_default ().settings.set_enum ("appearance", 0);
		});

		dark_check.toggled.connect (() => {
			Services.Settings.get_default ().settings.set_boolean ("dark-mode", true);
			Services.Settings.get_default ().settings.set_enum ("appearance", 1);
		});

		dark_blue_check.toggled.connect (() => {
			Services.Settings.get_default ().settings.set_boolean ("dark-mode", true);
			Services.Settings.get_default ().settings.set_enum ("appearance", 2);
		});

		Services.Settings.get_default ().settings.changed.connect ((key) => {
			if (key == "system-appearance" || key == "dark-mode") {
				system_appearance_switch.active = Services.Settings.get_default ().settings.get_boolean ("system-appearance");
				light_check.visible = is_light_visible ();
				dark_modes_group.visible = is_dark_modes_visible ();
			}
		});

		settings_header.back_activated.connect (() => {
			pop_subpage ();
		});

		return page;
	}

	private Adw.NavigationPage get_accounts_page () {
		var settings_header = new Dialogs.Preferences.SettingsHeader (_("Accounts"));
		
		// Todoist
		var todoist_switch = new Gtk.Switch () {
			valign = Gtk.Align.CENTER,
			active = Services.Todoist.get_default ().is_logged_in ()
		};

		var todoist_setting_button = new Gtk.Button.from_icon_name ("settings-symbolic") {
			margin_end = 6,
			valign = Gtk.Align.CENTER,
			halign = Gtk.Align.CENTER,
			css_classes = { Granite.STYLE_CLASS_FLAT }
		};

		var todoist_setting_revealer = new Gtk.Revealer () {
			transition_type = Gtk.RevealerTransitionType.CROSSFADE,
			reveal_child = Services.Todoist.get_default ().is_logged_in ()
		};

		todoist_setting_revealer.child = todoist_setting_button;

		var todoist_row = new Adw.ActionRow ();
		todoist_row.title = _("Todoist");
		todoist_row.subtitle = _("Synchronize with your Todoist Account");
		todoist_row.add_suffix (todoist_setting_revealer);
		todoist_row.add_suffix (todoist_switch);
        todoist_row.add_prefix (new Gtk.Image.from_icon_name ("todoist") {
			pixel_size = 32
		});

		// CalDAV
		var caldav_switch = new Gtk.Switch () {
			valign = Gtk.Align.CENTER,
			active = Services.CalDAV.Core.get_default ().is_logged_in ()
		};

		var caldav_setting_button = new Gtk.Button.from_icon_name ("settings-symbolic") {
			margin_end = 6,
			valign = Gtk.Align.CENTER,
			halign = Gtk.Align.CENTER,
			css_classes = { "flat" }
		};

		var caldav_setting_revealer = new Gtk.Revealer () {
			transition_type = Gtk.RevealerTransitionType.CROSSFADE,
			reveal_child = Services.CalDAV.Core.get_default ().is_logged_in (),
			child = caldav_setting_button
		};

		var caldav_row = new Adw.ActionRow ();
		caldav_row.title = _("CalDAV");
		caldav_row.subtitle = _("Synchronization based on open Internet standards");
		caldav_row.add_suffix (caldav_setting_revealer);
		caldav_row.add_suffix (caldav_switch);
        caldav_row.add_prefix (new Gtk.Image.from_icon_name ("cloud") {
			pixel_size = 32
		});

		var accounts_group = new Adw.PreferencesGroup ();
		accounts_group.title = _("Accounts");
		accounts_group.add (todoist_row);
		accounts_group.add (caldav_row);

		var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12);
		content_box.append (accounts_group);

		var content_clamp = new Adw.Clamp () {
			maximum_size = 600,
			margin_start = 24,
			margin_end = 24,
			margin_top = 12
		};

		content_clamp.child = content_box;

		var toolbar_view = new Adw.ToolbarView ();
		toolbar_view.add_top_bar (settings_header);
		toolbar_view.content = content_clamp;

		var page = new Adw.NavigationPage (toolbar_view, "account");

		var todoist_switch_gesture = new Gtk.GestureClick ();
		todoist_switch_gesture.set_button (1);
		todoist_switch.add_controller (todoist_switch_gesture);
		todoist_switch_gesture.pressed.connect (() => {
			todoist_switch.active = !todoist_switch.active;

			if (todoist_switch.active) {
				todoist_switch.active = false;
				if (!Services.Todoist.get_default ().is_logged_in ()) {
					push_subpage (get_oauth_todoist_page (todoist_switch));
				}
			} else {
				confirm_log_out (todoist_switch, BackendType.TODOIST);
			}
		});

		var caldav_switch_gesture = new Gtk.GestureClick ();
		caldav_switch_gesture.set_button (1);
		caldav_switch.add_controller (caldav_switch_gesture);
		caldav_switch_gesture.pressed.connect (() => {
			caldav_switch.active = !caldav_switch.active;
			
			if (caldav_switch.active) {
				caldav_switch.active = false;
				push_subpage (get_caldav_setup_page (caldav_switch));
			} else {
				confirm_log_out (caldav_switch, BackendType.CALDAV);
			}
		});

		Services.Todoist.get_default ().first_sync_finished.connect (() => {
			todoist_setting_revealer.reveal_child = Services.Todoist.get_default ().is_logged_in ();
			todoist_switch.active = Services.Todoist.get_default ().is_logged_in ();

			Timeout.add (250, () => {
				destroy ();
				return GLib.Source.REMOVE;
			});
		});

		Services.CalDAV.Core.get_default ().first_sync_finished.connect (() => {
			caldav_setting_revealer.reveal_child = Services.CalDAV.Core.get_default ().is_logged_in ();
			caldav_switch.active = Services.CalDAV.Core.get_default ().is_logged_in ();

			Timeout.add (250, () => {
				destroy ();
				return GLib.Source.REMOVE;
			});
		});

		Services.Todoist.get_default ().log_out.connect (() => {
			todoist_setting_revealer.reveal_child = Services.Todoist.get_default ().is_logged_in ();
			todoist_switch.active = Services.Todoist.get_default ().is_logged_in ();
		});

		Services.CalDAV.Core.get_default ().log_out.connect (() => {
			caldav_setting_revealer.reveal_child = Services.CalDAV.Core.get_default ().is_logged_in ();
			caldav_switch.active = Services.CalDAV.Core.get_default ().is_logged_in ();
		});

		todoist_setting_button.clicked.connect (() => {
			push_subpage (get_todoist_view ());
		});

		caldav_setting_button.clicked.connect (() => {
			push_subpage (get_caldav_view ());
		});

		settings_header.back_activated.connect (() => {
			pop_subpage ();
		});

		return page;
	}

	private Adw.NavigationPage get_todoist_view () {
		var settings_header = new Dialogs.Preferences.SettingsHeader (_("Todoist"));

		var todoist_avatar = new Adw.Avatar (84, Services.Settings.get_default ().settings.get_string ("todoist-user-name"), true);

		var file = File.new_for_path (Util.get_default ().get_avatar_path ("todoist-user"));
		if (file.query_exists ()) {
			var image = new Gtk.Image.from_file (file.get_path ());
			todoist_avatar.custom_image = image.get_paintable ();
		}

		var todoist_user = new Gtk.Label (Services.Settings.get_default ().settings.get_string ("todoist-user-name")) {
			margin_top = 12
		};
		todoist_user.add_css_class ("title-1");

		var todoist_email = new Gtk.Label (Services.Settings.get_default ().settings.get_string ("todoist-user-email"));
		todoist_email.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);

		var user_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
			margin_top = 24
		};
		user_box.append (todoist_avatar);
		user_box.append (todoist_user);
		user_box.append (todoist_email);

		var sync_server_switch = new Gtk.Switch () {
			valign = Gtk.Align.CENTER,
			active = Services.Settings.get_default ().settings.get_boolean ("todoist-sync-server")
		};

		var sync_server_row = new Adw.ActionRow ();
		sync_server_row.title = _("Sync Server");
		sync_server_row.subtitle = _("Activate this setting so that Planify automatically synchronizes with your Todoist account every 15 minutes");
		sync_server_row.set_activatable_widget (sync_server_switch);
		sync_server_row.add_suffix (sync_server_switch);

		var last_sync_date = new GLib.DateTime.from_iso8601 (
			Services.Settings.get_default ().settings.get_string ("todoist-last-sync"), new GLib.TimeZone.local ()
			);

		var last_sync_label = new Gtk.Label (Utils.Datetime.get_relative_date_from_date (
												 last_sync_date
												 ));

		var last_sync_row = new Adw.ActionRow ();
		last_sync_row.activatable = false;
		last_sync_row.title = _("Last Sync");
		last_sync_row.add_suffix (last_sync_label);

		var default_group = new Adw.PreferencesGroup () {
			margin_top = 24
		};

		default_group.add (sync_server_row);
		default_group.add (last_sync_row);

		var content_clamp = new Adw.Clamp () {
			maximum_size = 600,
			margin_start = 24,
			margin_end = 24,
			child = default_group
		};

		var main_content = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
			vexpand = true,
			hexpand = true
		};

		main_content.append (user_box);
		main_content.append (content_clamp);

		var toolbar_view = new Adw.ToolbarView ();
		toolbar_view.add_top_bar (settings_header);
		toolbar_view.content = main_content;

		var page = new Adw.NavigationPage (toolbar_view, "todoist");

		settings_header.back_activated.connect (() => {
			pop_subpage ();
		});

		sync_server_row.notify["active"].connect (() => {
			Services.Settings.get_default ().settings.set_boolean ("todoist-sync-server", sync_server_switch.active);
		});

		return page;
	}

	private Adw.NavigationPage get_caldav_view () {
		var settings_header = new Dialogs.Preferences.SettingsHeader (_("CalDAV"));

		var username_label = new Gtk.Label (Services.Settings.get_default ().settings.get_string ("caldav-user-displayname")) {
			margin_top = 12,
			css_classes = { "title-1" }
		};

		var email_label = new Gtk.Label (Services.Settings.get_default ().settings.get_string ("caldav-user-email")) {
			css_classes = { Granite.STYLE_CLASS_DIM_LABEL }
		};

		var server_url_label = new Gtk.Label (Services.Settings.get_default ().settings.get_string ("caldav-server-url")) {
			css_classes = { Granite.STYLE_CLASS_DIM_LABEL }
		};

		var user_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
			margin_top = 24
		};
		user_box.append (username_label);
		user_box.append (email_label);
		user_box.append (server_url_label);

		var sync_server_switch = new Gtk.Switch () {
			valign = Gtk.Align.CENTER,
			active = Services.Settings.get_default ().settings.get_boolean ("caldav-sync-server")
		};

		var sync_server_row = new Adw.ActionRow ();
		sync_server_row.title = _("Sync Server");
		sync_server_row.subtitle = _("Activate this setting so that Planify automatically synchronizes with your CalDAV account every 15 minutes");
		sync_server_row.set_activatable_widget (sync_server_switch);
		sync_server_row.add_suffix (sync_server_switch);

		var last_sync_date = new GLib.DateTime.from_iso8601 (
			Services.Settings.get_default ().settings.get_string ("caldav-last-sync"), new GLib.TimeZone.local ()
		);

		var last_sync_label = new Gtk.Label (
			Utils.Datetime.get_relative_date_from_date (last_sync_date)
		);

		var last_sync_row = new Adw.ActionRow ();
		last_sync_row.activatable = false;
		last_sync_row.title = _("Last Sync");
		last_sync_row.add_suffix (last_sync_label);

		var default_group = new Adw.PreferencesGroup () {
			margin_top = 24
		};

		default_group.add (sync_server_row);
		default_group.add (last_sync_row);

		var content_clamp = new Adw.Clamp () {
			maximum_size = 600,
			margin_start = 24,
			margin_end = 24,
			child = default_group
		};

		var main_content = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
			vexpand = true,
			hexpand = true
		};

		main_content.append (user_box);
		main_content.append (content_clamp);

		var toolbar_view = new Adw.ToolbarView ();
		toolbar_view.add_top_bar (settings_header);
		toolbar_view.content = main_content;

		var page = new Adw.NavigationPage (toolbar_view, "caldav");

		settings_header.back_activated.connect (() => {
			pop_subpage ();
		});

		sync_server_row.notify["active"].connect (() => {
			Services.Settings.get_default ().settings.set_boolean ("caldav-sync-server", sync_server_switch.active);
		});

		return page;
	}

	private Adw.NavigationPage get_quick_add_page () {
		var settings_header = new Dialogs.Preferences.SettingsHeader (_("Quick Add"));
    
		string quick_add_command = "flatpak run --command=io.github.alainm23.planify.quick-add %s".printf (Build.APPLICATION_ID);
		if (GLib.Environment.get_variable ("SNAP") != null) {
			quick_add_command = "planify.quick-add";
		}
		
		var description_label = new Gtk.Label (
            _("Use Quick Add to create to-dos from anywhere on your desktop with just a few keystrokes. You don’t even have to leave the app you’re currently in.") // vala-lint=line-length
        ) {
			justify = Gtk.Justification.FILL,
			use_markup = true,
			wrap = true,
			xalign = 0,
			margin_end = 6,
			margin_start = 6
		};

		var description2_label = new Gtk.Label (
            _("Head to System Settings → Keyboard → Shortcuts → Custom, then add a new shortcut with the following:") // vala-lint=line-length
        ) {
			justify = Gtk.Justification.FILL,
			use_markup = true,
			wrap = true,
			xalign = 0,
			margin_top = 6,
			margin_end = 6,
			margin_start = 6
		};

		var copy_button = new Gtk.Button.from_icon_name ("edit-copy-symbolic") {
			valign = CENTER
		};
		copy_button.add_css_class ("flat");

		var command_entry = new Adw.ActionRow ();
		command_entry.add_suffix (copy_button);
		command_entry.title = quick_add_command;
		command_entry.add_css_class ("small-label");
		command_entry.add_css_class ("monospace");

		var command_group = new Adw.PreferencesGroup () {
			margin_top = 12
		};
		command_group.add (command_entry);

		var settings_group = new Adw.PreferencesGroup ();
		settings_group.title = _("Settings");

		var save_last_switch = new Gtk.Switch () {
			valign = Gtk.Align.CENTER,
			active = Services.Settings.get_default ().settings.get_boolean ("quick-add-save-last-project")
		};

		var save_last_row = new Adw.ActionRow ();
		save_last_row.title = _("Save Last Selected Project");
		save_last_row.subtitle = _("If unchecked, the default project selected is Inbox");
		save_last_row.set_activatable_widget (save_last_switch);
		save_last_row.add_suffix (save_last_switch);

		settings_group.add (save_last_row);

		var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12) {
			vexpand = true,
			hexpand = true
		};

		content_box.append (description_label);
		content_box.append (description2_label);
		content_box.append (command_group);
		content_box.append (settings_group);

		var content_clamp = new Adw.Clamp () {
			maximum_size = 400,
			margin_start = 24,
			margin_end = 24,
			margin_top = 12
		};

		content_clamp.child = content_box;

		var toolbar_view = new Adw.ToolbarView ();
		toolbar_view.add_top_bar (settings_header);
		toolbar_view.content = content_clamp;

		var page = new Adw.NavigationPage (toolbar_view, "quick-add");

		copy_button.clicked.connect (() => {
			Gdk.Clipboard clipboard = Gdk.Display.get_default ().get_clipboard ();
			clipboard.set_text (quick_add_command);
			add_toast (Util.get_default ().create_toast (_("The command was copied to the clipboard")));
		});

		settings_header.back_activated.connect (() => {
			pop_subpage ();
		});

		save_last_switch.notify["active"].connect (() => {
			Services.Settings.get_default ().settings.set_boolean ("quick-add-save-last-project", save_last_switch.active);
		});

		return page;
	}

	private Adw.NavigationPage get_oauth_todoist_page (Gtk.Switch switch_widget) {
		var settings_header = new Dialogs.Preferences.SettingsHeader (_("Loading…"));

		string oauth_open_url = "https://todoist.com/oauth/authorize?client_id=%s&scope=%s&state=%s";
		string state = Util.get_default ().generate_string ();
		oauth_open_url = oauth_open_url.printf (Constants.TODOIST_CLIENT_ID, Constants.TODOIST_SCOPE, state);

		WebKit.WebView webview = new WebKit.WebView ();
        webview.zoom_level = 0.85;
        webview.vexpand = true;
        webview.hexpand = true;

        WebKit.WebContext.get_default ().set_preferred_languages (GLib.Intl.get_language_names ());
        webview.network_session.set_tls_errors_policy (WebKit.TLSErrorsPolicy.IGNORE);

        webview.load_uri (oauth_open_url);

        var sync_image = new Gtk.Image.from_icon_name ("cloud-outline-thick-symbolic") {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER,
			pixel_size = 128
        };

        // Loading
        var progress_bar = new Gtk.ProgressBar () {
            margin_top = 6
        };

        var sync_label = new Gtk.Label (_("Planify is is syncing your tasks, this may take a few minutes"));
        sync_label.wrap = true;
        sync_label.justify = Gtk.Justification.CENTER;
        sync_label.margin_top = 12;
        sync_label.margin_start = 12;
        sync_label.margin_end = 12;

        var sync_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            margin_top = 24,
            margin_start = 64,
            margin_end = 64
        };
        sync_box.append (sync_image);
        sync_box.append (progress_bar);
        sync_box.append (sync_label);

        var stack = new Gtk.Stack ();
        stack.vexpand = true;
        stack.hexpand = true;
        stack.transition_type = Gtk.StackTransitionType.CROSSFADE;

        stack.add_named (webview, "web_view");
        stack.add_named (sync_box, "spinner-view");

		var scrolled_window = new Gtk.ScrolledWindow () {
            hexpand = true,
            vexpand = true,
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            hscrollbar_policy = Gtk.PolicyType.NEVER,
			child = stack
        };

		var toolbar_view = new Adw.ToolbarView ();
		toolbar_view.add_top_bar (settings_header);
		toolbar_view.content = scrolled_window;

		var page = new Adw.NavigationPage (toolbar_view, "oauth-todoist");

		settings_header.back_activated.connect (() => {
			switch_widget.active = false;
			pop_subpage ();
		});

		webview.load_changed.connect ((load_event) => {
            var redirect_uri = webview.get_uri ();

            if (("https://github.com/alainm23/planner?code=" in redirect_uri) &&
                ("&state=%s".printf (state) in redirect_uri)) {
				settings_header.title = _("Synchronizing..."); // vala-lint=ellipsis
                get_todoist_token.begin (redirect_uri);
            }

            if ("https://github.com/alainm23/planner?error=access_denied" in redirect_uri) {
                debug ("access_denied");
				switch_widget.active = false;
				pop_subpage ();
            }

            if (load_event == WebKit.LoadEvent.FINISHED) {
                settings_header.title = _("Please Enter Your Credentials");
                return;
            }

            if (load_event == WebKit.LoadEvent.STARTED) {
                settings_header.title = _("Loading…");
                return;
            }

            return;
        });

        webview.load_failed.connect ((load_event, failing_uri, _error) => {
            var error = (GLib.Error)_error;
            warning ("Loading uri '%s' failed, error : %s", failing_uri, error.message);

            if (GLib.strcmp (failing_uri, oauth_open_url) == 0) {
                settings_header.title = _("Network Is Not Available");
				
				var toast = new Adw.Toast (_("Network Is Not Available"));
				toast.button_label = _("Ok");
				toast.timeout = 0;

				toast.button_clicked.connect (() => {
					switch_widget.active = false;
					pop_subpage ();
				});

				add_toast (toast);
            }

            return true;
        });

        Services.Todoist.get_default ().first_sync_started.connect (() => {
            stack.visible_child_name = "spinner-view";
        });

        Services.Todoist.get_default ().first_sync_finished.connect (() => {
			pop_subpage ();
        });

        Services.Todoist.get_default ().first_sync_progress.connect ((progress) => {
            progress_bar.fraction = progress;
        });

		return page;
	}

	private Adw.NavigationPage get_caldav_setup_page (Gtk.Switch switch_widget) {
		var settings_header = new Dialogs.Preferences.SettingsHeader (_("CalDAV Setup"));
		
		var server_entry = new Adw.EntryRow ();
        server_entry.title = _("Server URL");

		var username_entry = new Adw.EntryRow ();
        username_entry.title = _("User Name");

		var password_entry = new Adw.PasswordEntryRow ();
        password_entry.title = _("Password");

		var providers_model = new Gtk.StringList (null);
		providers_model.append (_("Nextcloud"));
		//  providers_model.append (_("Radicale"));
		
		var providers_row = new Adw.ComboRow ();
		providers_row.title = _("Provider");
		providers_row.model = providers_model;

		var entries_group = new Adw.PreferencesGroup ();

		entries_group.add (server_entry);
		entries_group.add (username_entry);
		entries_group.add (password_entry);
		entries_group.add (providers_row);
		
		var message_label = new Gtk.Label ("""Server URL examples:
  - https://evi.nl.tab.digital/
  - https://use01.thegood.cloud/""") {
	wrap = true
  };

		var message_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
			margin_top = 12,
			margin_bottom = 12,
			margin_start = 12,
			margin_end = 12,
			css_classes = { "accent" }
		};

		message_box.append (message_label);

		var message_card = new Adw.Bin () {
			css_classes = { "card" },
			child = message_box
		};

		var message_revealer = new Gtk.Revealer () {
			transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
			reveal_child = true,
			child = message_card
		};

		var login_button = new Widgets.LoadingButton.with_label (_("Log In")) {
			margin_top = 12,
			sensitive = false,
			css_classes = { Granite.STYLE_CLASS_SUGGESTED_ACTION }
        };

		var cancel_button = new Gtk.Button.with_label (_("Cancel")) {
			css_classes = { "flat" },
			visible = false
		};

		var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12) {
			vexpand = true,
			hexpand = true
		};

		content_box.append (entries_group);
		content_box.append (message_revealer);
		content_box.append (login_button);
		content_box.append (cancel_button);

		var content_clamp = new Adw.Clamp () {
			maximum_size = 400,
			margin_start = 24,
			margin_end = 24,
			margin_top = 12,
			child = content_box
		};

		var toolbar_view = new Adw.ToolbarView ();
		toolbar_view.add_top_bar (settings_header);
		toolbar_view.content = content_clamp;

		var page = new Adw.NavigationPage (toolbar_view, "oauth-todoist");

		settings_header.back_activated.connect (() => {
			switch_widget.active = false;
			pop_subpage ();
		});

		server_entry.changed.connect (() => {
			if (server_entry.text != null && server_entry.text != "") {
                var is_valid_url = is_valid_url (server_entry.text);
				if (!is_valid_url) {
					server_entry.add_css_class ("error");
				} else {
					server_entry.remove_css_class ("error");
				}
            } else {
                server_entry.remove_css_class ("error");
            }

			if (server_entry.has_css_class ("error") || username_entry.has_css_class ("error") | password_entry.has_css_class ("error")) {
				login_button.sensitive = false;
			} else {
				login_button.sensitive = true;
			}
		});

		username_entry.changed.connect (() => {
			if (username_entry.text != null && username_entry.text != "") {
				username_entry.remove_css_class ("error");
			} else {
				username_entry.add_css_class ("error");
			}

			if (server_entry.has_css_class ("error") || username_entry.has_css_class ("error") | password_entry.has_css_class ("error")) {
				login_button.sensitive = false;
			} else {
				login_button.sensitive = true;
			}
		});

		password_entry.changed.connect (() => {
			if (password_entry.text != null && password_entry.text != "") {
				password_entry.remove_css_class ("error");
			} else {
				password_entry.add_css_class ("error");
			}

			if (server_entry.has_css_class ("error") || username_entry.has_css_class ("error") | password_entry.has_css_class ("error")) {
				login_button.sensitive = false;
			} else {
				login_button.sensitive = true;
			}
		});

		login_button.clicked.connect (() => {
			GLib.Cancellable cancellable = new GLib.Cancellable ();
			login_button.is_loading = true;
			cancel_button.visible = true;

			cancel_button.clicked.connect (() => {
				cancellable.cancel ();
			});

			Services.CalDAV.Core.get_default ().login.begin (server_entry.text, username_entry.text, password_entry.text, cancellable, (obj, res) => {
				HttpResponse response = Services.CalDAV.Core.get_default ().login.end (res);
				if (response.status) {
					Services.CalDAV.Core.get_default ().first_sync.begin ();
				} else {
					login_button.is_loading = false;
					cancel_button.visible = false;
					show_message_error (_("Failed to login"), response.error.strip ());
				}
			});
		});

		Services.CalDAV.Core.get_default ().first_sync_started.connect (() => {
			login_button.is_loading = true;
		});
		
		Services.CalDAV.Core.get_default ().first_sync_finished.connect (() => {
			pop_subpage ();
		});

		return page;
	}

	private bool is_valid_url (string uri) {
        var scheme = Uri.parse_scheme (uri);
        if (scheme == null) {
            return false;
        }

        return scheme.has_prefix ("http");
    }

	private void show_message_error (string title, string error) {
		var dialog = new Adw.MessageDialog (Planify._instance.main_window, title, null);

		var textview = new Gtk.TextView () {
			left_margin = 12,
			top_margin = 12,
			bottom_margin = 12,
			right_margin = 12,
			wrap_mode = Gtk.WrapMode.WORD
		};
		textview.buffer.text = error;
		textview.add_css_class ("monospace");
		textview.add_css_class ("error-message");

		var textview_scrolled_window = new Gtk.ScrolledWindow () {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            hexpand = true,
            vexpand = true,
			child = textview,
			width_request = 500,
			height_request = 430
        };

		var textview_frame = new Gtk.Frame (null) {
			child = textview_scrolled_window
		};

        dialog.add_response ("ok", _("Ok"));
		dialog.extra_child = textview_frame;
        dialog.show ();
	}

	private Adw.NavigationPage get_backups_page () {
		var backup_page = new Dialogs.Preferences.Pages.Backup ();
		var page = new Adw.NavigationPage (backup_page, "backups-page");

		backup_page.pop_subpage.connect (() => {
			pop_subpage ();
		});

		backup_page.popup_toast.connect ((msg) => {
			var toast = new Adw.Toast (msg);
			toast.timeout = 3;
			add_toast (toast);
		});

		return page;
	}

	private Adw.NavigationPage get_privacy_policy_page () {
		var settings_header = new Dialogs.Preferences.SettingsHeader (_("Privacy Policy"));

		var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12) {
			vexpand = true,
			hexpand = true
		};

		content_box.append (new Gtk.Label (_("Personal Data")) {
			css_classes = { "font-bold" },
			halign = START
		});

		content_box.append (new Gtk.Label (_("We collect absolutely nothing and all your data is stored in a database on your computer.")) {
			wrap = true,
			xalign = 0
		});

		content_box.append (new Gtk.Label (_("If you choose to integrate Todoist, which is optional and not selected by default, your data will be stored on their private servers, we only display your configured tasks and manage them for you.")) {
			wrap = true,
			xalign = 0
		});

		content_box.append (new Gtk.Label (_("Do you have any questions?")) {
			css_classes = { "font-bold" },
			halign = START
		});

		content_box.append (new Gtk.Label (_("If you have any questions about your data or any other issue, please contact us. We will be happy to answer you.")) {
			wrap = true,
			xalign = 0
		});

		var contact_us_button = new Gtk.Button.with_label (_("Contact Us")) {
			vexpand = true,
			margin_bottom = 24,
			valign = END,
			css_classes = { Granite.STYLE_CLASS_SUGGESTED_ACTION }
        };

		content_box.append (contact_us_button);

		var content_clamp = new Adw.Clamp () {
			maximum_size = 400,
			margin_start = 24,
			margin_end = 24,
			margin_top = 12
		};

		content_clamp.child = content_box;

		var scrolled_window = new Gtk.ScrolledWindow () {
            hexpand = true,
            vexpand = true,
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            hscrollbar_policy = Gtk.PolicyType.NEVER,
			child = content_clamp
        };

		var toolbar_view = new Adw.ToolbarView ();
		toolbar_view.add_top_bar (settings_header);
		toolbar_view.content = scrolled_window;

		var page = new Adw.NavigationPage (toolbar_view, "oauth-todoist");

		settings_header.back_activated.connect (() => {
			pop_subpage ();
		});

		contact_us_button.clicked.connect (() => {
			string uri = "mailto:%s".printf (Constants.CONTACT_US);

            try {
                AppInfo.launch_default_for_uri (uri, null);
            } catch (Error e) {
                warning ("%s\n", e.message);
            }
		});

		return page;
	}

	private Adw.NavigationPage get_support_page () {
		var settings_header = new Dialogs.Preferences.SettingsHeader (_("Supporting Us"));

		var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12) {
			vexpand = true,
			hexpand = true
		};

		content_box.append (new Gtk.Label (_("Our mission is to provide the best open source task management application for users all over the world. Your donations support this work. Want to donate today?")) {
			wrap = true,
			xalign = 0
		});
		
		var patreon_row = new Adw.ActionRow ();
		patreon_row.activatable = true;
		patreon_row.add_suffix (generate_icon ("go-next-symbolic", 16));
		patreon_row.title = _("Patreon");

		patreon_row.activated.connect (() => {
			try {
                AppInfo.launch_default_for_uri (Constants.PATREON_URL, null);
            } catch (Error e) {
                warning ("%s\n", e.message);
            }
		});

		var paypal_row = new Adw.ActionRow ();
		paypal_row.activatable = true;
		paypal_row.add_suffix (generate_icon ("go-next-symbolic", 16));
		paypal_row.title = _("PayPal");

		paypal_row.activated.connect (() => {
			try {
                AppInfo.launch_default_for_uri (Constants.PAYPAL_ME_URL, null);
            } catch (Error e) {
                warning ("%s\n", e.message);
            }
		});

		var liberapay_row = new Adw.ActionRow ();
		liberapay_row.activatable = true;
		liberapay_row.add_suffix (generate_icon ("go-next-symbolic", 16));
		liberapay_row.title = _("Liberapay");
		
		liberapay_row.activated.connect (() => {
			try {
                AppInfo.launch_default_for_uri (Constants.LIBERAPAY_URL, null);
            } catch (Error e) {
                warning ("%s\n", e.message);
            }
		});

		var kofi_row = new Adw.ActionRow ();
		kofi_row.activatable = true;
		kofi_row.add_suffix (generate_icon ("go-next-symbolic", 16));
		kofi_row.title = _("Ko-fi");

		kofi_row.activated.connect (() => {
			try {
                AppInfo.launch_default_for_uri (Constants.KOFI_URL, null);
            } catch (Error e) {
                warning ("%s\n", e.message);
            }
		});

		var group = new Adw.PreferencesGroup () {
			margin_top = 12
		};
		group.add (patreon_row);
		group.add (paypal_row);
		group.add (liberapay_row);
		group.add (kofi_row);

		content_box.append (group);

		var content_clamp = new Adw.Clamp () {
			maximum_size = 400,
			margin_start = 24,
			margin_end = 24,
			margin_top = 12
		};

		content_clamp.child = content_box;

		var scrolled_window = new Gtk.ScrolledWindow () {
            hexpand = true,
            vexpand = true,
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            hscrollbar_policy = Gtk.PolicyType.NEVER,
			child = content_clamp
        };

		var toolbar_view = new Adw.ToolbarView ();
		toolbar_view.add_top_bar (settings_header);
		toolbar_view.content = scrolled_window;

		var page = new Adw.NavigationPage (toolbar_view, "oauth-todoist");

		settings_header.back_activated.connect (() => {
			pop_subpage ();
		});

		return page;
	}

	private async void get_todoist_token (string redirect_uri) {
        yield Services.Todoist.get_default ().get_todoist_token (redirect_uri);
    }

	public bool is_dark_theme () {
        var dark_mode = Services.Settings.get_default ().settings.get_boolean ("dark-mode");

		if (Services.Settings.get_default ().settings.get_boolean ("system-appearance")) {
			dark_mode = Granite.Settings.get_default ().prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
		}

		return dark_mode;
    }

	public bool is_light_visible () {
		bool system_appearance = Services.Settings.get_default ().settings.get_boolean ("system-appearance");

		if (system_appearance) {
			return !is_dark_theme ();
		}

		return true;
	}

	public bool is_dark_modes_visible () {
		bool system_appearance = Services.Settings.get_default ().settings.get_boolean ("system-appearance");

		if (system_appearance) {
			return is_dark_theme ();
		}

		return true;
	}

	private void confirm_log_out (Gtk.Switch switch_widget, BackendType backend_type) {
		string message = "";

		if (backend_type == BackendType.TODOIST) {
			message = _("Are you sure you want to remove the Todoist sync? This action will delete all your tasks and settings.");
		} else if (backend_type == BackendType.CALDAV) {
			message = _("Are you sure you want to remove the CalDAV sync? This action will delete all your tasks and settings.");
		}

		var dialog = new Adw.MessageDialog ((Gtk.Window) Planify.instance.main_window,
		                                    _("Sign Off"), message);

		dialog.body_use_markup = true;
		dialog.add_response ("cancel", _("Cancel"));
		dialog.add_response ("delete", _("Delete"));
		dialog.set_response_appearance ("delete", Adw.ResponseAppearance.DESTRUCTIVE);
		dialog.show ();

		dialog.response.connect ((response) => {
			if (response == "delete") {
				if (backend_type == BackendType.TODOIST) {
					Services.Todoist.get_default ().remove_items ();
				} else if (backend_type == BackendType.CALDAV) {
					Services.CalDAV.Core.get_default ().remove_items ();
				}
			} else {
				switch_widget.active = true;
			}
		});
	}

	private Gtk.Widget generate_icon (string icon_name, int size = 16) {
		return new Gtk.Image.from_icon_name (icon_name) {
			pixel_size = size
		};
	}
}

private class ValidationMessage : Gtk.Box {
    public Gtk.Label label_widget { get; construct; }
    public string label { get; construct set; }
    public bool reveal_child { get; set; }

    public ValidationMessage (string label) {
        Object (label: label);
    }

    construct {
        label_widget = new Gtk.Label (label) {
            halign = Gtk.Align.END,
            justify = Gtk.Justification.RIGHT,
            max_width_chars = 55,
            wrap = true,
            xalign = 1
        };
        label_widget.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);

        var revealer = new Gtk.Revealer () {
            child = label_widget,
            transition_type = CROSSFADE
        };

        append (revealer);

        bind_property ("reveal-child", revealer, "reveal-child", BIDIRECTIONAL | SYNC_CREATE);

        bind_property ("label", label_widget, "label");
    }
}
