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
    public Gee.HashMap<ulong, weak GLib.Object> signal_map = new Gee.HashMap<ulong, weak GLib.Object> ();
    private Gee.HashMap<string, Dialogs.Preferences.Pages.BasePage> page_map = new Gee.HashMap<string, Dialogs.Preferences.Pages.BasePage> ();
    private Adw.PreferencesGroup banner_group;
    private Gtk.ShortcutController shortcut_controller;

    public PreferencesWindow () {
        Object (
            content_width: 450,
            content_height: 600
        );
    }

    ~PreferencesWindow () {
        print ("Destroying - Dialogs.Preferences.PreferencesWindow\n");
    }

    construct {
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

        banner_group = new Adw.PreferencesGroup ();
        banner_group.add (banner_overlay);

        Services.Settings.get_default ().settings.bind ("show-support-banner", banner_group, "visible",
                                                        GLib.SettingsBindFlags.DEFAULT);

        signal_map[banner_button.clicked.connect (() => {
            push_subpage (build_page ("support"));
        })] = banner_button;

        signal_map[close_button.clicked.connect (() => {
            Services.Settings.get_default ().settings.set_boolean ("show-support-banner", false);
        })] = close_button;

        page.add (banner_group);

        // Accounts
        var accounts_row = new Adw.ActionRow ();
        accounts_row.activatable = true;
        accounts_row.add_prefix (generate_icon ("cloud-outline-thick-symbolic"));
        accounts_row.add_suffix (generate_icon ("go-next-symbolic"));
        accounts_row.title = _("Integrations");
        accounts_row.subtitle = _("Sync your favorite to-do providers");

        signal_map[accounts_row.activated.connect (() => {
            push_subpage (get_accounts_page ());
        })] = accounts_row;

        var accounts_group = new Adw.PreferencesGroup ();
        accounts_group.add (accounts_row);

        page.add (accounts_group);

        // Personalization
        var home_page_row = new Adw.ActionRow () {
            activatable = true,
            title = _("Home View"),
            subtitle = _("Set the view shown at first launch")
        };
        home_page_row.add_prefix (generate_icon ("go-home-symbolic"));
        home_page_row.add_suffix (generate_icon ("go-next-symbolic"));
        
        signal_map[home_page_row.activated.connect (() => {
            push_subpage (build_page ("home-view"));
        })] = home_page_row;

        var general_row = new Adw.ActionRow ();
        general_row.activatable = true;
        general_row.add_prefix (generate_icon ("settings-symbolic"));
        general_row.add_suffix (generate_icon ("go-next-symbolic"));
        general_row.title = _("General");
        general_row.subtitle = _("Customize to your liking");

        signal_map[general_row.activated.connect (() => {
            push_subpage (build_page ("general-page"));
        })] = general_row;

        var task_setting_row = new Adw.ActionRow ();
        task_setting_row.activatable = true;
        task_setting_row.add_prefix (generate_icon ("check-round-outline-symbolic"));
        task_setting_row.add_suffix (generate_icon ("go-next-symbolic"));
        task_setting_row.title = _("Task Setting");

        signal_map[task_setting_row.activated.connect (() => {
            push_subpage (build_page ("task-setting"));
        })] = task_setting_row;

        var sidebar_row = new Adw.ActionRow ();
        sidebar_row.activatable = true;
        sidebar_row.add_prefix (generate_icon ("dock-left-symbolic"));
        sidebar_row.add_suffix (generate_icon ("go-next-symbolic"));
        sidebar_row.title = _("Sidebar");
        sidebar_row.subtitle = _("Customize your sidebar");

        signal_map[sidebar_row.activated.connect (() => {
            push_subpage (build_page ("sidebar-page"));
        })] = sidebar_row;

        var appearance_row = new Adw.ActionRow ();
        appearance_row.activatable = true;
        appearance_row.add_prefix (generate_icon ("color-symbolic"));
        appearance_row.add_suffix (generate_icon ("go-next-symbolic"));
        appearance_row.title = _("Appearance");
        appearance_row.subtitle = Util.get_default ().get_theme_name ();

        signal_map[appearance_row.activated.connect (() => {
            push_subpage (build_page ("appearance"));
        })] = appearance_row;

        var quick_add_row = new Adw.ActionRow ();
        quick_add_row.activatable = true;
        quick_add_row.add_prefix (generate_icon ("tab-new-symbolic"));
        quick_add_row.add_suffix (generate_icon ("go-next-symbolic"));
        quick_add_row.title = _("Quick Add");
        quick_add_row.subtitle = _("Adding to-do's from anywhere");

        signal_map[quick_add_row.activated.connect (() => {
            push_subpage (build_page ("quick-add"));
        })] = quick_add_row;

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
        personalization_group.add (home_page_row);
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

        signal_map[contact_us_row.activated.connect (() => {
            string uri = "mailto:%s".printf (Constants.CONTACT_US);

            try {
                AppInfo.launch_default_for_uri (uri, null);
            } catch (Error e) {
                warning ("%s\n", e.message);
            }
        })] = contact_us_row;

        var tweet_us_row = new Adw.ActionRow ();
        tweet_us_row.activatable = true;
        tweet_us_row.add_prefix (generate_icon ("chat-bubble-text-symbolic"));
        tweet_us_row.add_suffix (generate_icon ("go-next-symbolic"));
        tweet_us_row.title = _("Tweet Us");
        tweet_us_row.subtitle = _("Share some love");

        signal_map[tweet_us_row.activated.connect (() => {
            try {
                AppInfo.launch_default_for_uri (Constants.TWITTER_URL, null);
            } catch (Error e) {
                warning ("%s\n", e.message);
            }
        })] = tweet_us_row;

        var discord_row = new Adw.ActionRow ();
        discord_row.activatable = true;
        discord_row.add_prefix (generate_icon ("navigate-symbolic"));
        discord_row.add_suffix (generate_icon ("go-next-symbolic"));
        discord_row.title = _("Discord");
        discord_row.subtitle = _("Discuss and share your feedback");

        signal_map[discord_row.activated.connect (() => {
            try {
                AppInfo.launch_default_for_uri (Constants.DISCORD_URL, null);
            } catch (Error e) {
                warning ("%s\n", e.message);
            }
        })] = discord_row;

        var mastodon_row = new Adw.ActionRow ();
        mastodon_row.activatable = true;
        mastodon_row.add_prefix (generate_icon ("external-link-symbolic"));
        mastodon_row.add_suffix (generate_icon ("go-next-symbolic"));
        mastodon_row.title = _("Mastodon");
        mastodon_row.subtitle = _("Share some love");

        signal_map[mastodon_row.activated.connect (() => {
            try {
                AppInfo.launch_default_for_uri (Constants.MASTODON_URL, null);
            } catch (Error e) {
                warning ("%s\n", e.message);
            }
        })] = mastodon_row;

        var supporting_us_row = new Adw.ActionRow ();
        supporting_us_row.activatable = true;
        supporting_us_row.add_prefix (generate_icon ("heart-outline-thick-symbolic"));
        supporting_us_row.add_suffix (generate_icon ("go-next-symbolic"));
        supporting_us_row.title = _("Support Planify");
        supporting_us_row.subtitle = _("Want to buy me a drink?");

        signal_map[supporting_us_row.activated.connect (() => {
            push_subpage (build_page ("support"));
        })] = supporting_us_row;

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

        signal_map[tutorial_row.activated.connect (() => {
            Util.get_default ().create_tutorial_project ();
            add_toast (Util.get_default ().create_toast (_("A tutorial project has been created")));
        })] = tutorial_row;

        signal_map[backups_row.activated.connect (() => {
            push_subpage (build_page ("backups-page"));
        })] = backups_row;

        signal_map[privacy_policy_row.activated.connect (() => {
            push_subpage (get_privacy_policy_page ());
        })] = privacy_policy_row;

        signal_map[delete_row.activated.connect (() => {
            Util.get_default ().clear_database (_("Delete All Data?"),
                                                _("Deletes all your lists, tasks, and reminders irreversibly"),
                                                Planify.instance.main_window);
        })] = delete_row;

        add (page);
        Services.EventBus.get_default ().disconnect_typing_accel ();

        shortcut_controller = new Gtk.ShortcutController ();
        var shortcut = new Gtk.Shortcut (new Gtk.KeyvalTrigger (Gdk.Key.Escape, 0), new Gtk.CallbackAction ((widget, args) => {
            close ();
            return true;
        }));
        shortcut_controller.add_shortcut (shortcut);
        add_controller (shortcut_controller);

        closed.connect (() => {
            clean_up ();
            Services.EventBus.get_default ().connect_typing_accel ();
        });
    }

    private Adw.NavigationPage get_accounts_page () {
        var accounts_page = new Dialogs.Preferences.Pages.Accounts ();

        signal_map[accounts_page.push_subpage.connect ((page) => {
            push_subpage (page);
        })] = accounts_page;

        signal_map[accounts_page.pop_subpage.connect (() => {
            pop_subpage ();
        })] = accounts_page;

        signal_map[accounts_page.add_toast.connect ((toast) => {
            add_toast (toast);
        })] = accounts_page;

        return new Adw.NavigationPage (accounts_page, "account");
    }

    private Adw.NavigationPage get_privacy_policy_page () {
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
        toolbar_view.add_top_bar (new Adw.HeaderBar ());
        toolbar_view.content = scrolled_window;

        var page = new Adw.NavigationPage (toolbar_view, "oauth-todoist") {
            title = _("Privacy Policy")
        };
        
        signal_map[contact_us_button.clicked.connect (() => {
            string uri = "mailto:%s".printf (Constants.CONTACT_US);

            try {
                AppInfo.launch_default_for_uri (uri, null);
            } catch (Error e) {
                warning ("%s\n", e.message);
            }
        })] = contact_us_button;

        return page;
    }

    private Gtk.Widget generate_icon (string icon_name, int size = 16) {
        return new Gtk.Image.from_icon_name (icon_name) {
                   pixel_size = size
        };
    }

    private Adw.NavigationPage build_page (string page) {
        if (page_map.has_key (page)) {
            return page_map[page];
        }

        switch (page) {
            case "home-view":
                page_map[page] = new Dialogs.Preferences.Pages.HomeView (this);
                break;
            case "appearance":
                page_map[page] = new Dialogs.Preferences.Pages.Appearance (this);
                break;
            case "backups-page":
                page_map[page] = new Dialogs.Preferences.Pages.Backup (this);
                break;
            case "sidebar-page":
                page_map[page] = new Dialogs.Preferences.Pages.Sidebar (this);
                break;
            case "general-page":
                page_map[page] = new Dialogs.Preferences.Pages.General (this);
                break;
            case "task-setting":
                page_map[page] = new Dialogs.Preferences.Pages.TaskSetting (this);
                break;
            case "quick-add":
                page_map[page] = new Dialogs.Preferences.Pages.QuickAdd (this);
                break;
            case "support":
                page_map[page] = new Dialogs.Preferences.Pages.Support (this);
                break;
            default:
                warning ("The page %s does not exist\n", page);
                return null;
        }

        return page_map[page];
    }

    public void clean_up () {
        foreach (var entry in signal_map.entries) {
            entry.value.disconnect (entry.key);
        }

        signal_map.clear ();

        if (shortcut_controller != null) {
            remove_controller (shortcut_controller);
            shortcut_controller = null;
        }

        foreach (Dialogs.Preferences.Pages.BasePage page in page_map.values) {
            page.clean_up ();
        }

        page_map.clear ();
    }
}
