/*
 * Copyright © 2025 Alain M. (https://github.com/alainm23/planify)
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

public class Dialogs.Preferences.PreferencesWindow : Adw.PreferencesDialog {
    public PreferencesWindow () {
        Object (
            content_width: 450,
            content_height: 600
        );
    }

    ~PreferencesWindow () {
        print ("Destroying Dialogs.Preferences.PreferencesWindow\n");
    }

    construct {
        add (get_preferences_home ());
        Services.EventBus.get_default ().disconnect_typing_accel ();

        var destroy_controller = new Gtk.EventControllerKey ();
        add_controller ((Gtk.ShortcutController) destroy_controller);
        destroy_controller.key_released.connect ((keyval, keycode, state) => {
            if (keyval == 65307) {
                close ();
            }
        });

        destroy.connect (() => {
            Services.EventBus.get_default ().connect_typing_accel ();
        });
    }

    private Adw.PreferencesPage get_preferences_home () {
        var page = new Adw.PreferencesPage ();
        page.title = _("Preferences");
        page.name = "preferences";
        page.icon_name = "applications-system-symbolic";

        var banner_title = new Gtk.Label (_("Support Planify")) {
            halign = START,
            css_classes = { "font-bold", "banner-text" }
        };

        var banner_description =
            new Gtk.Label (_(
                               "Planify is being developed with love and passion for open source. However, if you like Planify and want to support its development, please consider supporting us.")) {
            halign = START,
            xalign = 0,
            yalign = 0,
            wrap = true,
            css_classes = { "caption", "banner-text" }
        };

        var banner_button = new Gtk.Button.with_label (_("Supporting Us")) {
            halign = START,
            margin_top = 6,
            css_classes = { "banner-text" }
        };

        var close_button = new Gtk.Button.from_icon_name ("window-close-symbolic") {
            css_classes = { "border-radius-50", "banner-text" },
            valign = START,
            halign = END
        };

        var banner_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
            valign = START,
            halign = START
        };

        banner_box.append (banner_title);
        banner_box.append (banner_description);
        banner_box.append (banner_button);

        var banner_overlay = new Gtk.Overlay () {
            css_classes = { "banner", "card" },
        };
        banner_overlay.child = banner_box;
        banner_overlay.add_overlay (close_button);

        var banner_group = new Adw.PreferencesGroup ();
        banner_group.add (banner_overlay);

        Services.Settings.get_default ().settings.bind ("show-support-banner", banner_group, "visible",
                                                        GLib.SettingsBindFlags.DEFAULT);

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

        var discord_row = new Adw.ActionRow ();
        discord_row.activatable = true;
        discord_row.add_prefix (generate_icon ("navigate-symbolic"));
        discord_row.add_suffix (generate_icon ("go-next-symbolic"));
        discord_row.title = _("Discord");
        discord_row.subtitle = _("Discuss and share your feedback");

        discord_row.activated.connect (() => {
            try {
                AppInfo.launch_default_for_uri (Constants.DISCORD_URL, null);
            } catch (Error e) {
                warning ("%s\n", e.message);
            }
        });

        var mastodon_row = new Adw.ActionRow ();
        mastodon_row.activatable = true;
        mastodon_row.add_prefix (generate_icon ("external-link-symbolic"));
        mastodon_row.add_suffix (generate_icon ("go-next-symbolic"));
        mastodon_row.title = _("Mastodon");
        mastodon_row.subtitle = _("Share some love");

        mastodon_row.activated.connect (() => {
            try {
                AppInfo.launch_default_for_uri (Constants.MASTODON_URL, null);
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
        reach_us_group.add (mastodon_row);
        reach_us_group.add (tweet_us_row);
        reach_us_group.add (discord_row);
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
        sort_order_projects_row.sensitive = Services.Settings.get_default ().settings.get_enum ("projects-sort-by") ==
                                            1;

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

        // de_group.add (run_background_row);

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
            sort_order_projects_row.sensitive =
                Services.Settings.get_default ().settings.get_enum ("projects-sort-by") == 1;
        });

        sort_order_projects_row.notify["selected"].connect (() => {
            Services.Settings.get_default ().settings.set_enum ("projects-ordered",
                                                                (int) sort_order_projects_row.selected);
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
        underline_completed_row.title = _("Cross Out Completed Tasks");
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
        show_completed_subtasks.subtitle = _("Keep all completed subtasks visible without collapsing them");
        Services.Settings.get_default ().settings.bind ("always-show-completed-subtasks", show_completed_subtasks,
                                                        "active", GLib.SettingsBindFlags.DEFAULT);

        group.add (show_completed_subtasks);

        var task_complete_tone = new Adw.SwitchRow ();
        task_complete_tone.title = _("Task Complete Tone");
        task_complete_tone.subtitle = _("Play a sound when tasks are completed");
        Services.Settings.get_default ().settings.bind ("task-complete-tone", task_complete_tone, "active",
                                                        GLib.SettingsBindFlags.DEFAULT);

        group.add (task_complete_tone);

        var open_task_sidebar = new Adw.SwitchRow ();
        open_task_sidebar.title = _("Open Tasks in Sidebar View");
        open_task_sidebar.subtitle = _("Always display task details in the sidebar instead of expanding in list view.");
        Services.Settings.get_default ().settings.bind ("open-task-sidebar", open_task_sidebar, "active",
                                                        GLib.SettingsBindFlags.DEFAULT);

        group.add (open_task_sidebar);

        var attention_at_one = new Adw.SwitchRow ();
        attention_at_one.title = _("Single Task Focus Mode");
        attention_at_one.subtitle = _("Allow only one task to be expanded at a time in list view");
        Services.Settings.get_default ().settings.bind ("attention-at-one", attention_at_one, "active",
                                                        GLib.SettingsBindFlags.DEFAULT);
        Services.Settings.get_default ().settings.bind ("open-task-sidebar", attention_at_one, "sensitive",
                                                        GLib.SettingsBindFlags.INVERT_BOOLEAN);

        group.add (attention_at_one);

        var markdown_item = new Adw.SwitchRow ();
        markdown_item.title = _("Enable Markdown Formatting");
        markdown_item.subtitle = _("Toggle Markdown support for tasks on or off");
        Services.Settings.get_default ().settings.bind ("enable-markdown-formatting", markdown_item, "active",
                                                        GLib.SettingsBindFlags.DEFAULT);

        group.add (markdown_item);

        var always_show_sidebar_item = new Adw.SwitchRow ();
        always_show_sidebar_item.title = _("Always Show Details Sidebar");
        always_show_sidebar_item.subtitle = _("Keep the details sidebar always visible for faster task navigation, without repeatedly opening and closing it");
        Services.Settings.get_default ().settings.bind ("always-show-details-sidebar", always_show_sidebar_item,
                                                        "active", GLib.SettingsBindFlags.DEFAULT);

        group.add (always_show_sidebar_item);

        var reminders_group = new Adw.PreferencesGroup () {
            title = _("Reminders")
        };

        var automatic_reminders = new Adw.SwitchRow ();
        automatic_reminders.title = _("Enabled");
        Services.Settings.get_default ().settings.bind ("automatic-reminders-enabled", automatic_reminders, "active",
                                                        GLib.SettingsBindFlags.DEFAULT);

        var reminders_model = new Gtk.StringList (null);
        reminders_model.append (_("At due time"));
        reminders_model.append (_("10 minutes before"));
        reminders_model.append (_("30 minutes before"));
        reminders_model.append (_("45 minutes before"));
        reminders_model.append (_("1 hour before"));
        reminders_model.append (_("2 hours before"));
        reminders_model.append (_("3 hours before"));

        var reminders_comborow = new Adw.ComboRow ();
        reminders_comborow.title = _("Automatic reminders");
        reminders_comborow.subtitle =
            _("When enabled, a reminder before the task’s due time will be added by default.");
        reminders_comborow.model = reminders_model;
        reminders_comborow.selected = Services.Settings.get_default ().settings.get_enum ("automatic-reminders");
        Services.Settings.get_default ().settings.bind ("automatic-reminders-enabled", reminders_comborow, "sensitive",
                                                        GLib.SettingsBindFlags.DEFAULT);

        reminders_group.add (automatic_reminders);
        reminders_group.add (reminders_comborow);

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12);
        content_box.append (group);
        content_box.append (reminders_group);

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
            Services.Settings.get_default ().settings.set_enum ("default-priority",
                                                                (int) default_priority_row.selected);
        });

        tasks_position_row.notify["selected"].connect (() => {
            Services.Settings.get_default ().settings.set_enum ("new-tasks-position",
                                                                (int) tasks_position_row.selected);
        });

        underline_completed_switch.notify["active"].connect (() => {
            Services.Settings.get_default ().settings.set_boolean ("underline-completed-tasks",
                                                                   underline_completed_switch.active);
        });

        reminders_comborow.notify["selected"].connect (() => {
            Services.Settings.get_default ().settings.set_enum ("automatic-reminders",
                                                                (int) reminders_comborow.selected);
        });

        settings_header.back_activated.connect (() => {
            pop_subpage ();
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
        var page = new Dialogs.Preferences.Pages.Appearance ();

        page.pop_subpage.connect (() => {
            pop_subpage ();
        });

        return new Adw.NavigationPage (page, "appearance");
    }

    private Adw.NavigationPage get_accounts_page () {
        var accounts_page = new Dialogs.Preferences.Pages.Accounts ();

        accounts_page.push_subpage.connect ((page) => {
            push_subpage (page);
        });

        accounts_page.pop_subpage.connect (() => {
            pop_subpage ();
        });

        accounts_page.add_toast.connect ((toast) => {
            add_toast (toast);
        });

        return new Adw.NavigationPage (accounts_page, "account");
    }

    private Adw.NavigationPage get_quick_add_page () {
        var settings_header = new Dialogs.Preferences.SettingsHeader (_("Quick Add"));

        string quick_add_command =
            "flatpak run --command=io.github.alainm23.planify.quick-add %s".printf (Build.APPLICATION_ID);
        if (GLib.Environment.get_variable ("SNAP") != null) {
            quick_add_command = "planify.quick-add";
        }

        var description_label = new Gtk.Label (
            _(
                "Use Quick Add to create to-dos from anywhere on your desktop with just a few keystrokes. You don’t even have to leave the app you’re currently in.")
            // vala-lint=line-length
                                ) {
            justify = Gtk.Justification.FILL,
            use_markup = true,
            wrap = true,
            xalign = 0,
            margin_end = 6,
            margin_start = 6
        };

        var description2_label = new Gtk.Label (
            _("Head to System Settings → Keyboard → Shortcuts → Custom, then add a new shortcut with the following:")             // vala-lint=line-length
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
        command_entry.add_css_class ("caption");
        command_entry.add_css_class ("monospace");
        command_entry.add_css_class ("property");

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
            Services.Settings.get_default ().settings.set_boolean ("quick-add-save-last-project",
                                                                   save_last_switch.active);
        });

        return page;
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

        content_box.append (new Gtk.Label (_(
                                               "We collect absolutely nothing and all your data is stored in a database on your computer.")) {
            wrap = true,
            xalign = 0
        });

        content_box.append (new Gtk.Label (_(
                                               "If you choose to integrate Todoist, which is optional and not selected by default, your data will be stored on their private servers, we only display your configured tasks and manage them for you.")) {
            wrap = true,
            xalign = 0
        });

        content_box.append (new Gtk.Label (_("Do you have any questions?")) {
            css_classes = { "font-bold" },
            halign = START
        });

        content_box.append (new Gtk.Label (_(
                                               "If you have any questions about your data or any other issue, please contact us. We will be happy to answer you.")) {
            wrap = true,
            xalign = 0
        });

        var contact_us_button = new Gtk.Button.with_label (_("Contact Us")) {
            vexpand = true,
            margin_bottom = 24,
            valign = END,
            css_classes = { "suggested-action" }
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

        content_box.append (new Gtk.Label (_(
                                               "Our mission is to provide the best open source task management application for users all over the world. Your donations support this work. Want to donate today?")) {
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
        label_widget.add_css_class ("caption");

        var revealer = new Gtk.Revealer () {
            child = label_widget,
            transition_type = CROSSFADE
        };

        append (revealer);

        bind_property ("reveal-child", revealer, "reveal-child", BIDIRECTIONAL | SYNC_CREATE);

        bind_property ("label", label_widget, "label");
    }
}
