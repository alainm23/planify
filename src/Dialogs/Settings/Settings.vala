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
    public Gee.HashMap <string, Gtk.Widget> views;

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
            hide_destroy ();
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

        var todoist_content = new Dialogs.Settings.SettingsContent (_("Synchronization"));
        var todoist_item = new Dialogs.Settings.SettingsItem (
            "planner-cloud",
            _("Todoist"),
            Planner.settings.get_string ("todoist-user-email")
        );

        todoist_content.add_child (todoist_item);

        var general_content = new Dialogs.Settings.SettingsContent (_("General"));

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
            _("Be more productive")
        );

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
            _("Follow us on")
        );

        var import_item = new Dialogs.Settings.SettingsItem (
            "planner-upload",
            _("Import from Planner 2.0"),
            _("Follow us on")
        );

        var delete_data_item = new Dialogs.Settings.SettingsItem (
            "planner-trash",
            _("Delete all my app data"),
            _("Start over again")
        );

        privacy_content.add_child (privacy_item);
        // privacy_content.add_child (import_item);
        privacy_content.add_child (delete_data_item);

        var main_grid = new Gtk.Grid () {
            expand = true,
            orientation = Gtk.Orientation.VERTICAL,
            valign = Gtk.Align.START
        };

        main_grid.add (settings_header);

        if ((BackendType) Planner.settings.get_enum ("backend-type") == BackendType.TODOIST) {
            main_grid.add (todoist_content);
        }
        
        main_grid.add (general_content);
        main_grid.add (contact_content);
        main_grid.add (privacy_content);

        var main_grid_scrolled = new Gtk.ScrolledWindow (null, null) {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            expand = true
        };
        main_grid_scrolled.add (main_grid);

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

        todoist_item.activated.connect (() => {
            go_setting_view ("todoist");
        });

        calendar_events_item.activated.connect (() => {
            go_setting_view ("calendar-events");
        });

        keyboard_shortcuts_item.activated.connect (() => {
            var dialog = new Dialogs.Shortcuts.Shortcuts ();
            dialog.show_all ();
        });

        delete_data_item.activated.connect (() => {
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

        Planner.settings.changed.connect ((key) => {
            if (key == "appearance") {
                appearance_item.description = Util.get_default ().get_theme_name ();
            } else if (key == "homepage-item") {
                homepage_item.description  = Util.get_default ().get_filter ().get_name ();
            }
        });

        main_grid_scrolled.show_all ();
        return main_grid_scrolled;
    }

    private Gtk.Widget get_appearance_view () {
        var settings_header = new Dialogs.Settings.SettingsHeader (_("Appearance"));

        var content = new Dialogs.Settings.SettingsContent (null);

        var light_item = new Gtk.RadioButton.with_label (null, _("Light")) {
            hexpand = true,
            margin_top = 3,
            margin_start = 6
        };
        var dark_item = new Gtk.RadioButton.with_label_from_widget (light_item, _("Dark")) {
            hexpand = true,
            margin_top = 3,
            margin_left = 6
        };
        var dark_blue_item = new Gtk.RadioButton.with_label_from_widget (light_item, _("Dark Blue")) {
            hexpand = true,
            margin_top = 3,
            margin_start = 6,
            margin_bottom = 6
        };

        content.add_child (light_item);
        content.add_child (dark_item);
        content.add_child (dark_blue_item);

        var main_grid = new Gtk.Grid () {
            expand = true,
            orientation = Gtk.Orientation.VERTICAL,
            valign = Gtk.Align.START
        };
        
        main_grid.add (settings_header);
        main_grid.add (content);

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

        light_item.toggled.connect (() => {
            Planner.settings.set_enum ("appearance", 0);
        });

        dark_item.toggled.connect (() => {
            Planner.settings.set_enum ("appearance", 1);
        });

        dark_blue_item.toggled.connect (() => {
            Planner.settings.set_enum ("appearance", 2);
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
            margin_start = 6
        };
        var inbox_item = new Gtk.RadioButton.with_label_from_widget (none_item, _("Inbox")) {
            hexpand = true,
            margin_top = 3,
            margin_left = 6
        };
        
        var today_item = new Gtk.RadioButton.with_label_from_widget (none_item, _("Today")) {
            hexpand = true,
            margin_top = 3,
            margin_start = 6
        };

        var today_inbox_item = new Gtk.RadioButton.with_label_from_widget (none_item, _("Today + Inbox")) {
            hexpand = true,
            margin_top = 3,
            margin_start = 6,
            margin_bottom = 6
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
            margin_start = 6
        };
        var today_item = new Gtk.RadioButton.with_label_from_widget (inbox_item, _("Today")) {
            hexpand = true,
            margin_top = 3,
            margin_left = 6
        };
        
        var scheduled_item = new Gtk.RadioButton.with_label_from_widget (inbox_item, _("Scheduled")) {
            hexpand = true,
            margin_top = 3,
            margin_start = 6
        };

        var pinboard_item = new Gtk.RadioButton.with_label_from_widget (inbox_item, _("Pinboard")) {
            hexpand = true,
            margin_top = 3,
            margin_start = 6,
            margin_bottom = 6
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

        foreach (Objects.Project project in Planner.database.projects) {
            if (!project.inbox_project) {
                var project_item = new Gtk.RadioButton.with_label_from_widget (inbox_item, project.name) {
                    hexpand = true,
                    margin_top = 3,
                    margin_start = 6,
                    margin_bottom = 6
                };

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
            }
        }

        var main_grid = new Gtk.Grid () {
            expand = true,
            orientation = Gtk.Orientation.VERTICAL,
            valign = Gtk.Align.START
        };
        
        main_grid.add (settings_header);
        main_grid.add (filters_content);
        main_grid.add (projects_content);

        var scrolled = new Gtk.ScrolledWindow (null, null) {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            expand = true
        };
        scrolled.add (main_grid);

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

        scrolled.show_all ();
        return scrolled;
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

        var sync_server_label = new Gtk.Label (_("Sync Server"));

        var sync_server_switch = new Gtk.Switch ();
        sync_server_switch.active = Planner.settings.get_boolean ("todoist-sync-server");
        sync_server_switch.get_style_context ().add_class ("active-switch");

        var sync_server_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            hexpand = true,
            margin = 3
        };
        
        sync_server_box.pack_start (sync_server_label, false, true, 0);
        sync_server_box.pack_end (sync_server_switch, false, false, 0);

        content.add_child (sync_server_box);

        var sync_server_description = new Gtk.Label (
            _("Activate this setting so that Planner automatically synchronizes with your Todoist account every 15 minutes.") // vala-lint=line-length
        );
        sync_server_description.halign = Gtk.Align.START;
        sync_server_description.wrap = true;
        sync_server_description.margin_start = 16;
        sync_server_description.margin_end = 16;
        sync_server_description.xalign = (float) 0.0;
        sync_server_description.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

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

        sync_server_switch.notify["active"].connect ((val) => {
            Planner.settings.set_boolean ("todoist-sync-server", sync_server_switch.active);
        });

        main_grid.show_all ();
        return main_grid;
    }

    private Gtk.Widget get_calendar_events_view () {
        var settings_header = new Dialogs.Settings.SettingsHeader (_("Calendar Events"));

        var enabled_content = new Dialogs.Settings.SettingsContent (null);

        var enabled_label = new Gtk.Label (_("Show Calendar Events"));

        var enabled_switch = new Gtk.Switch ();
        enabled_switch.active = Planner.settings.get_boolean ("calendar-enabled");
        enabled_switch.get_style_context ().add_class ("active-switch");

        var enabled_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            hexpand = true,
            margin = 3
        };
        
        enabled_box.pack_start (enabled_label, false, true, 0);
        enabled_box.pack_end (enabled_switch, false, false, 0);

        enabled_content.add_child (enabled_box);

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
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
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

        enabled_switch.notify["active"].connect ((val) => {
            Planner.settings.set_boolean ("calendar-enabled", enabled_switch.active);
        });

        Planner.settings.bind ("calendar-enabled", sources_revealer, "reveal_child", GLib.SettingsBindFlags.DEFAULT);

        scrolled.show_all ();
        return scrolled;
    }

    //  private int sort_function (Gtk.ListBoxRow lbrow, Gtk.ListBoxRow lbbefore) {
    //      if (!(lbrow is Widgets.CalendarSource)) {
    //          return -1;
    //      }
    //      var row = (Widgets.CalendarSource) lbrow;
    //      var before = (Widgets.CalendarSource) lbbefore;
    //      if (row.source.parent == null || before.source.parent == null) {
    //          return -1;
    //      } else if (row.source.parent == before.source.parent) {
    //          return row.source.display_name.collate (before.source.display_name);
    //      } else {
    //          return row.source.parent.collate (before.source.parent);
    //      }
    //  }

    //  private void header_update_func (Gtk.ListBoxRow lbrow, Gtk.ListBoxRow? lbbefore) {
    //      if (!(lbrow is Widgets.CalendarSource)) {
    //          return;
    //      }

    //      var row = (Widgets.CalendarSource) lbrow;
    //      if (lbbefore != null) {
    //          var before = (Widgets.CalendarSource) lbbefore;
    //          if (row.source.parent == before.source.parent) {
    //              row.set_header (null);
    //              return;
    //          }
    //      }

    //      var header_label = new Granite.HeaderLabel (CalendarEventsUtil.get_source_location (row.source)) {
    //          ellipsize = Pango.EllipsizeMode.END
    //      };
    //      header_label.get_style_context ().add_class ("no-padding-left");

    //      row.set_header (header_label);
    //  }


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
