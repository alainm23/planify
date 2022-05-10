/*
* Copyright © 2019 Alain M. (https://github.com/alainm23/planner)
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

public class Dialogs.Settings.Settings : Hdy.Window {
    public string view { get; construct; }

    private Gtk.Stack main_stack;
    private Gee.HashMap <string, Gtk.Widget> views;
    private BackendType backend_type;

    public Settings (string view = "settings") {
        Object (
            view: view,
            deletable: true,
            resizable: true,
            window_position: Gtk.WindowPosition.CENTER_ON_PARENT,
            modal: true,
            width_request: 400,
            height_request: 500
        );
    }

    construct {
        backend_type = (BackendType) Planner.settings.get_enum ("backend-type");

        unowned Gtk.StyleContext main_context = get_style_context ();
        main_context.add_class ("picker");
        transient_for = Planner.instance.main_window;

        views = new Gee.HashMap <string, Gtk.Widget> ();

        main_stack = new Gtk.Stack () {
            expand = true,
            transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT
        };

        var stack_scrolled = new Gtk.ScrolledWindow (null, null) {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            vscrollbar_policy = Gtk.PolicyType.NEVER,
            expand = true
        };
        stack_scrolled.add (main_stack);
        
        add (stack_scrolled);

        Timeout.add (main_stack.transition_duration, () => {
            go_setting_view (view);
            return GLib.Source.REMOVE;
        });

        focus_out_event.connect (() => {
            // hide_destroy ();
            return false;
        });

        key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                hide_destroy ();
            }

            return false;
        });
    }

    private Gtk.Widget get_settings_view () {
        var settings_header = new Dialogs.Settings.SettingsHeader (_("Settings"), false);

        var sync_content = new Dialogs.Settings.SettingsContent (_("Synchronization"));

        if (backend_type == BackendType.TODOIST) {
            var todoist_item = new Dialogs.Settings.SettingsItem (
                "planner-cloud",
                _("Todoist"),
                Planner.settings.get_string ("todoist-user-email")
            );
    
            sync_content.add_child (todoist_item);

            todoist_item.activated.connect (() => {
                go_setting_view ("todoist");
            });
        } else if (backend_type == BackendType.CALDAV) {
            var caldav_item = new Dialogs.Settings.SettingsItem (
                "planner-cloud",
                _("CalDAV"),
                _("Sync your CalDAV account.")
            );
    
            sync_content.add_child (caldav_item);

            caldav_item.activated.connect (() => {
                go_setting_view ("caldav");
            });
        }

        var general_content = new Dialogs.Settings.SettingsContent (_("General"));

        var general_item = new Dialogs.Settings.SettingsItem (
            "planner-general",
            _("General settings"),
            _("Customize to your liking.")
        );

        var homepage_item = new Dialogs.Settings.SettingsItem (
            "planner-home",
            _("Home Page"),
            Util.get_default ().get_filter ().get_name ()
        );

        var appearance_item = new Dialogs.Settings.SettingsItem (
            "planner-appearance",
            _("Appearance"),
            Util.get_default ().get_theme_name ()
        );

        var badge_count_item = new Dialogs.Settings.SettingsItem (
            "planner-notification",
            _("Notification settings"),
            _("Manage your notification settings")
        );

        var keyboard_shortcuts_item = new Dialogs.Settings.SettingsItem (
            "planner-keyboard",
            _("Keyboard shortcuts"),
            _("Be more productive")
        );

        var calendar_events_item = new Dialogs.Settings.SettingsItem (
            "planner-calendar-events",
            _("Calendar events"),
            _("View your upcoming events")
        );

        general_content.add_child (general_item);
        general_content.add_child (homepage_item);
        general_content.add_child (appearance_item);
        general_content.add_child (badge_count_item);
        general_content.add_child (calendar_events_item);
        general_content.add_child (keyboard_shortcuts_item);

        var contact_content = new Dialogs.Settings.SettingsContent (_("Contact us"));

        var mail_item = new Dialogs.Settings.SettingsItem (
            "planner-mail",
            _("Contact us"),
            _("Request a feature or ask us a question")
        );

        var twitter_item = new Dialogs.Settings.SettingsItem (
            "planner-annotation-dots",
            _("Twitter"),
            _("Follow us on")
        );

        var support_item = new Dialogs.Settings.SettingsItem (
            "planner-heart",
            _("Support & Credits"),
            _("Support us")
        );

        contact_content.add_child (mail_item);
        contact_content.add_child (twitter_item);
        contact_content.add_child (support_item);

        var privacy_content = new Dialogs.Settings.SettingsContent (_("Privacy"));

        var privacy_item = new Dialogs.Settings.SettingsItem (
            "planner-shield-tick",
            _("Privacy policies"),
            _("We have nothing on you")
        );

        var import_item = new Dialogs.Settings.SettingsItem (
            "planner-upload",
            _("Import from Planner 2.0"),
            _("Import your tasks from Planner 2")
        );

        var delete_data_item = new Dialogs.Settings.SettingsItem (
            "planner-trash",
            _("Delete all my app data"),
            _("Start over again")
        );

        privacy_content.add_child (privacy_item);

        if (backend_type == BackendType.LOCAL) {
            privacy_content.add_child (import_item);
        }
        
        privacy_content.add_child (delete_data_item);

        var content_grid = new Gtk.Grid () {
            expand = true,
            orientation = Gtk.Orientation.VERTICAL
        };

        if (backend_type == BackendType.TODOIST || backend_type == BackendType.CALDAV) {
            content_grid.add (sync_content);
        }
        
        content_grid.add (general_content);
        content_grid.add (contact_content);
        content_grid.add (privacy_content);

        var scrolled = new Gtk.ScrolledWindow (null, null) {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            expand = true
        };
        scrolled.add (content_grid);

        var main_grid = new Gtk.Grid () {
            expand = true,
            orientation = Gtk.Orientation.VERTICAL
        };

        main_grid.add (settings_header);
        main_grid.add (scrolled);

        settings_header.done_activated.connect (() => {
            hide_destroy ();
        });

        appearance_item.activated.connect (() => {
            go_setting_view ("appearance");
        });

        badge_count_item.activated.connect (() => {
            go_setting_view ("notification");
        });

        homepage_item.activated.connect (() => {
            go_setting_view ("home-page");
        });

        calendar_events_item.activated.connect (() => {
            go_setting_view ("calendar-events");
        });

        general_item.activated.connect (() => {
            go_setting_view ("general-settings");
        });

        keyboard_shortcuts_item.activated.connect (() => {
            hide_destroy ();
            var dialog = new Dialogs.Shortcuts.Shortcuts ();
            dialog.show_all ();
        });

        delete_data_item.activated.connect (() => {
            hide_destroy ();
            Util.get_default ().delete_app_data ();
        });

        mail_item.activated.connect (() => {
            try {
                AppInfo.launch_default_for_uri ("https://github.com/alainm23/planner/issues", null);
            } catch (Error e) {
                warning ("%s\n", e.message);
            }
        });

        twitter_item.activated.connect (() => {
            try {
                AppInfo.launch_default_for_uri ("https://twitter.com/planner_todo", null);
            } catch (Error e) {
                warning ("%s\n", e.message);
            }
        });

        support_item.activated.connect (() => {
            try {
                AppInfo.launch_default_for_uri ("https://useplanner.com/support/", null);
            } catch (Error e) {
                warning ("%s\n", e.message);
            }
        });

        privacy_item.activated.connect (() => {
            try {
                AppInfo.launch_default_for_uri ("https://useplanner.com/privacy-policy/", null);
            } catch (Error e) {
                warning ("%s\n", e.message);
            }
        });

        import_item.activated.connect (() => {
            Services.MigrateV2.get_default ().import_backup ();
        });

        Planner.settings.changed.connect ((key) => {
            if (key == "appearance") {
                appearance_item.description = Util.get_default ().get_theme_name ();
            } else if (key == "homepage-item") {
                homepage_item.description  = Util.get_default ().get_filter ().get_name ();
            }
        });

        main_grid.show_all ();
        return main_grid;
    }

    private Gtk.Widget get_appearance_view () {
        var settings_header = new Dialogs.Settings.SettingsHeader (_("Appearance"));

        var system_content = new Dialogs.Settings.SettingsContent (null);
        
        var system_switch = new Dialogs.Settings.SettingsSwitch (_("Use system settings"));
        system_switch.active = Planner.settings.get_boolean ("system-appearance");

        system_content.add_child (system_switch);

        // Dark Mode

        var dark_mode_content = new Dialogs.Settings.SettingsContent (null);
        
        var dark_mode_switch = new Dialogs.Settings.SettingsSwitch (_("Dark mode"));
        dark_mode_switch.active = Planner.settings.get_boolean ("dark-mode");

        dark_mode_content.add_child (dark_mode_switch);

        var dark_mode_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            reveal_child = !Planner.settings.get_boolean ("system-appearance")
        };

        dark_mode_revealer.add (dark_mode_content);

        var appearance_content = new Dialogs.Settings.SettingsContent (null);

        var light_item = new Gtk.RadioButton.with_label (null, _("Light")) {
            hexpand = true,
            margin_top = 3,
            margin_start = 3
        };

        var dark_item = new Gtk.RadioButton.with_label_from_widget (light_item, _("Dark")) {
            hexpand = true,
            margin_top = 3,
            margin_left = 3
        };

        var dark_blue_item = new Gtk.RadioButton.with_label_from_widget (light_item, _("Dark Blue")) {
            hexpand = true,
            margin_start = 3,
            margin_bottom = 3
        };

        appearance_content.add_child (dark_item);
        appearance_content.add_child (dark_blue_item);

        bool dark_mode = Planner.settings.get_boolean ("dark-mode");
        if (Planner.settings.get_boolean ("system-appearance")) {
            dark_mode = Granite.Settings.get_default ().prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
        }

        var appearance_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            reveal_child = dark_mode
        };

        appearance_revealer.add (appearance_content);

        var main_grid = new Gtk.Grid () {
            expand = true,
            orientation = Gtk.Orientation.VERTICAL,
            valign = Gtk.Align.START
        };
        
        main_grid.add (settings_header);
        main_grid.add (system_content);
        // main_grid.add (system_description);
        main_grid.add (dark_mode_revealer);
        main_grid.add (appearance_revealer);

        int appearance = Planner.settings.get_enum ("appearance");
        if (appearance == 0) {
            light_item.active = true;
        } else if (appearance == 1) {
            dark_item.active = true;
        } else if (appearance == 2) {
            dark_blue_item.active = true;
        }

        settings_header.done_activated.connect (() => {
            hide_destroy ();
        });

        settings_header.back_activated.connect (() => {
            go_setting_view ("settings");
        });

        dark_item.toggled.connect (() => {
            Planner.settings.set_enum ("appearance", 1);
        });

        dark_blue_item.toggled.connect (() => {
            Planner.settings.set_enum ("appearance", 2);
        });

        dark_mode_switch.activated.connect ((active) => {
            Planner.settings.set_boolean ("dark-mode", active);
        });

        system_switch.activated.connect ((active) => {
            Planner.settings.set_boolean ("system-appearance", active);
        });

        Planner.settings.changed.connect ((key) => {
            if (key == "system-appearance") {
                system_switch.active = Planner.settings.get_boolean ("system-appearance");
                dark_mode_revealer.reveal_child = !Planner.settings.get_boolean ("system-appearance");

                dark_mode = Planner.settings.get_boolean ("dark-mode");
                if (Planner.settings.get_boolean ("system-appearance")) {
                    dark_mode = Granite.Settings.get_default ().prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
                }
                appearance_revealer.reveal_child = dark_mode;
            } else if (key == "appearance") {
                
            } else if (key == "dark-mode") {
                dark_mode_switch.active = Planner.settings.get_boolean ("dark-mode");
                
                dark_mode = Planner.settings.get_boolean ("dark-mode");
                if (Planner.settings.get_boolean ("system-appearance")) {
                    dark_mode = Granite.Settings.get_default ().prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
                }
                appearance_revealer.reveal_child = dark_mode;
            }
        });

        main_grid.show_all ();
        return main_grid;
    }

    private Gtk.Widget get_badge_view () {
        var settings_header = new Dialogs.Settings.SettingsHeader (_("Notification settings"));

        var content = new Dialogs.Settings.SettingsContent (_("Badge Count"));

        var none_item = new Gtk.RadioButton.with_label (null, _("None")) {
            hexpand = true,
            margin_top = 3,
            margin_start = 3
        };
        var inbox_item = new Gtk.RadioButton.with_label_from_widget (none_item, _("Inbox")) {
            hexpand = true,
            margin_left = 3
        };
        
        var today_item = new Gtk.RadioButton.with_label_from_widget (none_item, _("Today")) {
            hexpand = true,
            margin_start = 3
        };

        var today_inbox_item = new Gtk.RadioButton.with_label_from_widget (none_item, _("Today + Inbox")) {
            hexpand = true,
            margin_start = 3,
            margin_bottom = 3
        };

        content.add_child (none_item);
        content.add_child (inbox_item);
        content.add_child (today_item);
        content.add_child (today_inbox_item);

        var main_grid = new Gtk.Grid () {
            expand = true,
            orientation = Gtk.Orientation.VERTICAL,
            valign = Gtk.Align.START
        };
        
        main_grid.add (settings_header);
        main_grid.add (content);

        int badge = Planner.settings.get_enum ("badge-count");
        if (badge == 0) {
            none_item.active = true;
        } else if (badge == 1) {
            inbox_item.active = true;
        } else if (badge == 2) {
            today_item.active = true;
        } else if (badge == 3) {
            today_inbox_item.active = true;
        }

        settings_header.done_activated.connect (() => {
            hide_destroy ();
        });

        settings_header.back_activated.connect (() => {
            go_setting_view ("settings");
        });

        none_item.toggled.connect (() => {
            Planner.settings.set_enum ("badge-count", 0);
        });

        inbox_item.toggled.connect (() => {
            Planner.settings.set_enum ("badge-count", 1);
        });

        today_item.toggled.connect (() => {
            Planner.settings.set_enum ("badge-count", 2);
        });

        today_inbox_item.toggled.connect (() => {
            Planner.settings.set_enum ("badge-count", 3);
        });

        main_grid.show_all ();
        return main_grid;
    }

    private Gtk.Widget get_home_page_view () {
        var settings_header = new Dialogs.Settings.SettingsHeader (_("Home Page"));

        var filters_content = new Dialogs.Settings.SettingsContent (_("Filters"));
        var projects_content = new Dialogs.Settings.SettingsContent (_("Projects"));

        var inbox_item = new Gtk.RadioButton.with_label (null, _("Inbox")) {
            hexpand = true,
            margin_top = 3,
            margin_start = 3
        };
        var today_item = new Gtk.RadioButton.with_label_from_widget (inbox_item, _("Today")) {
            hexpand = true,
            margin_left = 3
        };
        
        var scheduled_item = new Gtk.RadioButton.with_label_from_widget (inbox_item, _("Scheduled")) {
            hexpand = true,
            margin_start = 3
        };

        var pinboard_item = new Gtk.RadioButton.with_label_from_widget (inbox_item, _("Pinboard")) {
            hexpand = true,
            margin_start = 3,
            margin_bottom = 3
        };

        if (!Planner.settings.get_boolean ("homepage-project")) {
            int type = Planner.settings.get_enum ("homepage-item");
            if (type == 0) {
                inbox_item.active = true;
            } else if (type == 1) {
                today_item.active = true;
            } else if (type == 2) {
                scheduled_item.active = true;
            } else {
                pinboard_item.active = true;
            }
        }

        filters_content.add_child (inbox_item);
        filters_content.add_child (today_item);
        filters_content.add_child (scheduled_item);
        filters_content.add_child (pinboard_item);

        int index = 0;
        foreach (Objects.Project project in Planner.database.projects) {
            if (!project.inbox_project) {
                var project_item = new Gtk.RadioButton.with_label_from_widget (inbox_item, project.name) {
                    hexpand = true,
                    margin_start = 3
                };

                if (index <= 0) {
                    project_item.margin_top = 3;
                }

                projects_content.add_child (project_item);

                project_item.toggled.connect (() => {
                    Planner.settings.set_boolean ("homepage-project", true);
                    Planner.settings.set_int64 ("homepage-project-id", project.id);
                });

                if (Planner.settings.get_boolean ("homepage-project")) {
                    if (Planner.settings.get_int64 ("homepage-project-id") == project.id) {
                        project_item.active = true;
                    }
                }

                index++;
            }
        }

        var content_grid = new Gtk.Grid () {
            expand = true,
            orientation = Gtk.Orientation.VERTICAL,
            valign = Gtk.Align.START
        };

        var scrolled = new Gtk.ScrolledWindow (null, null) {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            expand = true
        };
        scrolled.add (content_grid);

        content_grid.add (filters_content);

        BackendType backend_type = (BackendType) Planner.settings.get_enum ("backend-type");
        if (backend_type == BackendType.LOCAL || backend_type == BackendType.TODOIST) {
            content_grid.add (projects_content);
        }

        var main_grid = new Gtk.Grid () {
            expand = true,
            orientation = Gtk.Orientation.VERTICAL
        };

        main_grid.add (settings_header);
        main_grid.add (scrolled);

        settings_header.done_activated.connect (() => {
            hide_destroy ();
        });

        settings_header.back_activated.connect (() => {
            go_setting_view ("settings");
        });

        inbox_item.toggled.connect (() => {
            Planner.settings.set_boolean ("homepage-project", false);
            Planner.settings.set_enum ("homepage-item", 0);
        });

        today_item.toggled.connect (() => {
            Planner.settings.set_boolean ("homepage-project", false);
            Planner.settings.set_enum ("homepage-item", 1);
        });

        scheduled_item.toggled.connect (() => {
            Planner.settings.set_boolean ("homepage-project", false);
            Planner.settings.set_enum ("homepage-item", 2);
        });

        pinboard_item.toggled.connect (() => {
            Planner.settings.set_boolean ("homepage-project", false);
            Planner.settings.set_enum ("homepage-item", 3);
        });

        main_grid.show_all ();
        return main_grid;
    }
 
    private void go_setting_view (string view) {
        if (!views.has_key (view)) {
            views[view] = get_setting_view (view);
            main_stack.add_named (views[view], view);
        }

        main_stack.set_visible_child_name (view);
    }

    private Gtk.Widget get_todoist_view () {
        var settings_header = new Dialogs.Settings.SettingsHeader (_("Todoist"));

        var todoist_avatar = new Hdy.Avatar (64, Planner.settings.get_string ("todoist-user-name"), true) {
            margin = 3
        };

        var file = File.new_for_path (Util.get_default ().get_todoist_avatar_path ());
        if (file.query_exists ()) {
            todoist_avatar.set_loadable_icon (new FileIcon (file));    
        }

        var todoist_user = new Gtk.Label (Planner.settings.get_string ("todoist-user-name")) {
            margin_top = 6
        };

        var todoist_email = new Gtk.Label (Planner.settings.get_string ("todoist-user-email"));
        todoist_email.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        var content = new Dialogs.Settings.SettingsContent (null) {
            margin_top = 12,
            margin_bottom = 6
        };

        var system_switch = new Dialogs.Settings.SettingsSwitch (_("Sync Server"));
        system_switch.active = Planner.settings.get_boolean ("todoist-sync-server");

        content.add_child (system_switch);

        var sync_server_description = new Gtk.Label (
            _("Activate this setting so that Planner automatically synchronizes with your Todoist account every 15 minutes.") // vala-lint=line-length
        );
        sync_server_description.halign = Gtk.Align.START;
        sync_server_description.wrap = true;
        sync_server_description.margin_start = 16;
        sync_server_description.margin_end = 16;
        sync_server_description.xalign = (float) 0.0;
        sync_server_description.wrap_mode = Pango.WrapMode.CHAR;
        sync_server_description.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
        sync_server_description.get_style_context ().add_class (Granite.STYLE_CLASS_SMALL_LABEL);

        var main_grid = new Gtk.Grid () {
            expand = true,
            orientation = Gtk.Orientation.VERTICAL,
            valign = Gtk.Align.START
        };
        
        main_grid.add (settings_header);
        main_grid.add (todoist_avatar);
        main_grid.add (todoist_user);
        main_grid.add (todoist_email);
        main_grid.add (content);
        main_grid.add (sync_server_description);

        settings_header.done_activated.connect (() => {
            hide_destroy ();
        });

        settings_header.back_activated.connect (() => {
            go_setting_view ("settings");
        });

        system_switch.activated.connect ((active) => {
            Planner.settings.set_boolean ("todoist-sync-server", active);
        });

        main_grid.show_all ();
        return main_grid;
    }

    private Gtk.Widget get_calendar_events_view () {
        var settings_header = new Dialogs.Settings.SettingsHeader (_("Calendar Events"));

        var enabled_content = new Dialogs.Settings.SettingsContent (null);

        var enabled_switch = new Dialogs.Settings.SettingsSwitch (_("Use system settings"));
        enabled_switch.active = Planner.settings.get_boolean ("calendar-enabled");

        enabled_content.add_child (enabled_switch);

        var contents_map = new Gee.HashMap <string, Dialogs.Settings.SettingsContent> ();
        var sources_map = new Gee.HashMap <string, Widgets.CalendarSourceRow> ();

        var main_grid = new Gtk.Grid () {
            expand = true,
            orientation = Gtk.Orientation.VERTICAL,
            valign = Gtk.Align.START
        };
        
        var sources_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL
        };

        var sources_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.CROSSFADE,
            reveal_child = Planner.settings.get_boolean ("calendar-enabled")
        };

        sources_revealer.add (sources_grid);

        main_grid.add (settings_header);
        main_grid.add (enabled_content);
        main_grid.add (sources_revealer);

        var scrolled = new Gtk.ScrolledWindow (null, null) {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            expand = true
        };
        scrolled.add (main_grid);

        foreach (E.Source source in Services.CalendarEvents.get_default ().get_all_sources ()) {
            var location = CalendarEventsUtil.get_source_location (source);

            var source_row = new Widgets.CalendarSourceRow (source);
            sources_map[source.dup_uid ()] = source_row;
            source_row.visible_changed.connect (() => {
                string[] sources_disabled = {};

                foreach (Widgets.CalendarSourceRow item in sources_map.values) {
                    if (item.source_enabled == false) {
                        sources_disabled += item.source.dup_uid ();
                    }
                }

                Planner.settings.set_strv ("calendar-sources-disabled", sources_disabled);
            });

            if (contents_map.has_key (location)) {
                contents_map[location].add_child (sources_map[source.dup_uid ()]);
            } else {
                var c = new Dialogs.Settings.SettingsContent (location);
                c.add_class ("listbox-separator-3");
                c.add_class ("p-6");

                contents_map[location] = c;

                sources_grid.add (contents_map[location]);
                contents_map[location].add_child (sources_map[source.dup_uid ()]);
            }
        }

        settings_header.done_activated.connect (() => {
            hide_destroy ();
        });

        settings_header.back_activated.connect (() => {
            go_setting_view ("settings");
        });

        enabled_switch.activated.connect ((active) => {
            Planner.settings.set_boolean ("calendar-enabled", active);
        });

        Planner.settings.bind ("calendar-enabled", sources_revealer, "reveal_child", GLib.SettingsBindFlags.DEFAULT);

        scrolled.show_all ();
        return scrolled;
    }

    private Gtk.Widget get_caldav_view () {
        var settings_header = new Dialogs.Settings.SettingsHeader (_("CalDAV"));
        var settings_caldav = new Dialogs.Settings.SettingsCalDAV ();

        var main_grid = new Gtk.Grid () {
            expand = true,
            orientation = Gtk.Orientation.VERTICAL,
            valign = Gtk.Align.START
        };
        
        main_grid.add (settings_header);
        main_grid.add (settings_caldav);

        var scrolled = new Gtk.ScrolledWindow (null, null) {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            expand = true
        };
        scrolled.add (main_grid);

        settings_header.done_activated.connect (() => {
            hide_destroy ();
        });

        settings_header.back_activated.connect (() => {
            if (settings_caldav.visible_child_name == "login") {
                settings_caldav.visible_child_name = "sources";
            } else if (settings_caldav.visible_child_name == "sources") {
                go_setting_view ("settings");
            }
        });

        scrolled.show_all ();
        return scrolled;
    }

    private Gtk.Widget get_general_settings () {
        var settings_header = new Dialogs.Settings.SettingsHeader (_("General Settings"));

        var sort_projects_content = new Dialogs.Settings.SettingsContent (_("Sort projects"));

        Gee.ArrayList<string> sort_list = new Gee.ArrayList<string> ();
        sort_list.add (_("Alphabetically"));
        sort_list.add (_("Custom sort order"));

        Gee.ArrayList<string> order_list = new Gee.ArrayList<string> ();
        order_list.add (_("Ascending"));
        order_list.add (_("Descending"));

        var sort_projects = new Dialogs.Settings.SettingsSelect (_("Sort by"), sort_list);
        sort_projects.selected_index = Planner.settings.get_enum ("projects-sort-by");

        var ordered_projects = new Dialogs.Settings.SettingsSelect (_("Ordered"), order_list);
        ordered_projects.selected_index = Planner.settings.get_enum ("projects-ordered");

        sort_projects_content.add_child (sort_projects);
        sort_projects_content.add_child (ordered_projects);

        var de_content = new Dialogs.Settings.SettingsContent (_("DE Integration"));

        var run_background_switch = new Dialogs.Settings.SettingsSwitch (_("Run in background"));
        run_background_switch.active = Planner.settings.get_boolean ("run-in-background");
        
        de_content.add_child (run_background_switch);

        var date_time_content = new Dialogs.Settings.SettingsContent (_("Date & Time"));

        Gee.ArrayList<string> clock_list = new Gee.ArrayList<string> ();
        clock_list.add (_("24h"));
        clock_list.add (_("12h"));

        var clock_format = new Dialogs.Settings.SettingsSelect (_("Clock Format"), clock_list);
        clock_format.selected_index = Planner.settings.get_enum ("clock-format");

        Gee.ArrayList<string> week_list = new Gee.ArrayList<string> ();
        week_list.add (_("Sunday"));
        week_list.add (_("Monday"));

        var start_week = new Dialogs.Settings.SettingsSelect (_("Start of the week"), week_list);
        start_week.selected_index = Planner.settings.get_enum ("start-week");

        date_time_content.add_child (clock_format);
        date_time_content.add_child (start_week);

        var task_content = new Dialogs.Settings.SettingsContent (_("Task settings"));

        Gee.ArrayList<string> ct_list = new Gee.ArrayList<string> ();
        ct_list.add (_("Instantly"));
        ct_list.add (_("Wait 2500 milliseconds"));

        var complete_tasks = new Dialogs.Settings.SettingsSelect (_("Complete task"), ct_list);
        complete_tasks.selected_index = Planner.settings.get_enum ("complete-task");
        
        Gee.ArrayList<string> priorities_list = new Gee.ArrayList<string> ();
        priorities_list.add (_("Priority 1"));
        priorities_list.add (_("Priority 2"));
        priorities_list.add (_("Priority 3"));
        priorities_list.add (_("None"));

        var default_priority = new Dialogs.Settings.SettingsSelect (_("Default priority"), priorities_list);
        default_priority.selected_index = Planner.settings.get_enum ("default-priority");

        var description_switch = new Dialogs.Settings.SettingsSwitch (_("Description preview"));
        description_switch.active = Planner.settings.get_boolean ("description-preview");

        var underline_completed_switch = new Dialogs.Settings.SettingsSwitch (_("Underline completed tasks"));
        underline_completed_switch.active = Planner.settings.get_boolean ("underline-completed-tasks");

        task_content.add_child (complete_tasks);
        task_content.add_child (default_priority);
        task_content.add_child (description_switch);
        task_content.add_child (underline_completed_switch);
        
        var content_grid = new Gtk.Grid () {
            expand = true,
            orientation = Gtk.Orientation.VERTICAL,
            valign = Gtk.Align.START
        };

        var scrolled = new Gtk.ScrolledWindow (null, null) {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            expand = true
        };
        scrolled.add (content_grid);

        content_grid.add (sort_projects_content);
        content_grid.add (de_content);
        content_grid.add (date_time_content);
        content_grid.add (task_content);

        var main_grid = new Gtk.Grid () {
            expand = true,
            orientation = Gtk.Orientation.VERTICAL
        };

        main_grid.add (settings_header);
        main_grid.add (scrolled);

        settings_header.done_activated.connect (() => {
            hide_destroy ();
        });

        settings_header.back_activated.connect (() => {
            go_setting_view ("settings");
        });

        sort_projects.activated.connect ((active) => {
            Planner.settings.set_enum ("projects-sort-by", active);
        });

        complete_tasks.activated.connect ((active) => {
            Planner.settings.set_enum ("complete-task", active);
        });

        ordered_projects.activated.connect ((active) => {
            Planner.settings.set_enum ("projects-ordered", active);
        });

        run_background_switch.activated.connect ((active) => {
            Planner.settings.set_boolean ("run-in-background", active);
        });

        clock_format.activated.connect ((active) => {
            Planner.settings.set_enum ("clock-format", active);
        });
        
        start_week.activated.connect ((active) => {
            Planner.settings.set_enum ("start-week", active);
        });

        default_priority.activated.connect ((active) => {
            Planner.settings.set_enum ("default-priority", active);
        });

        description_switch.activated.connect ((active) => {
            Planner.settings.set_boolean ("description-preview", active);
        });

        underline_completed_switch.activated.connect ((active) => {
            Planner.settings.set_boolean ("underline-completed-tasks", active);
        });

        Planner.settings.changed.connect ((key) => {
            if (key == "projects-sort-by") {
                sort_projects.selected_index = Planner.settings.get_enum ("projects-sort-by");
            } else if (key == "projects-ordered") {
                ordered_projects.selected_index = Planner.settings.get_enum ("projects-ordered");
            } else if (key == "run-in-background") {
                run_background_switch.active = Planner.settings.get_boolean ("run-in-background");
            } else if (key == "clock-format") {
                clock_format.selected_index = Planner.settings.get_enum ("clock-format");
            } else if (key == "start-week") {
                start_week.selected_index = Planner.settings.get_enum ("start-week");
            } else if (key == "complete-task") {
                complete_tasks.selected_index = Planner.settings.get_enum ("complete-task");
            } else if (key == "default-priority") {
                default_priority.selected_index = Planner.settings.get_enum ("default-priority");
            } else if (key == "description-preview") {
                description_switch.active = Planner.settings.get_boolean ("description-preview");
            } else if (key == "underline-completed-tasks") {
                underline_completed_switch.active = Planner.settings.get_boolean ("underline-completed-tasks");
            }
        });
        
        main_grid.show_all ();
        return main_grid;
    }
    
    private Gtk.Widget? get_setting_view (string view) {
        Gtk.Widget? returned = null;

        switch (view) {
            case "settings":
                returned = get_settings_view ();
                break;
            
            case "home-page":
                returned = get_home_page_view ();
                break;
            
            case "appearance":
                returned = get_appearance_view ();
                break;
            
            case "notification":
                returned = get_badge_view ();
                break;
            
            case "todoist":
                returned = get_todoist_view ();
                break;
            
            case "calendar-events":
                returned = get_calendar_events_view ();
                break;
            
            case "caldav":
                returned = get_caldav_view ();
                break;
            
            case "general-settings":
                returned = get_general_settings ();
                break;
        }

        return returned;
    }

    public void hide_destroy () {
        hide ();

        Timeout.add (500, () => {
            destroy ();
            return GLib.Source.REMOVE;
        });
    }
}
