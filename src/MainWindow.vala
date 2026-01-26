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

public class MainWindow : Adw.ApplicationWindow {
    public weak Planify app { get; construct; }

    private Layouts.Sidebar sidebar;
    private Adw.ViewStack views_stack;
    private Adw.OverlaySplitView overlay_split_view;
    private Gtk.MenuButton settings_button;
    private Layouts.ItemSidebarView item_sidebar_view;
    private Gtk.Button fake_button;
    private Widgets.ContextMenu.MenuItem archive_item;
    private Widgets.ContextMenu.MenuSeparator archive_separator;
    private Adw.ToastOverlay toast_overlay;
    private Adw.ViewStack view_stack;
    private Gtk.Widget error_db_page;
    private string previous_inbox_project_id = "";

    public Services.ActionManager action_manager;

    private const int64 VIEW_TIMEOUT = 300000000;
    private Gee.ArrayList<ViewCacheItem> view_cache = new Gee.ArrayList<ViewCacheItem> ();

    public MainWindow (Planify application) {
        Object (
            application: application,
            app: application,
            icon_name: Build.APPLICATION_ID,
            title: "Planify",
            width_request: 360,
            height_request: 294
        );
    }

    ~MainWindow () {
        debug ("Destroying - MainWindow\n");
    }

    static construct {
        weak Gtk.IconTheme default_theme = Gtk.IconTheme.get_for_display (Gdk.Display.get_default ());
        default_theme.add_resource_path ("/io/github/alainm23/planify/");
    }

    construct {
        if (Build.PROFILE == "development") {
            add_css_class ("devel");
        }

        action_manager = new Services.ActionManager (app, this);

        var settings_popover = build_menu_app ();

        fake_button = new Gtk.Button () {
            visible = false
        };

        settings_button = new Gtk.MenuButton () {
            css_classes = { "flat" },
            popover = settings_popover,
            tooltip_text = _("Main Menu"),
            icon_name = "open-menu-symbolic"
        };

        var search_button = new Gtk.Button.from_icon_name ("edit-find-symbolic") {
            tooltip_markup = Util.get_default ().markup_accel_tooltip (_("Open Quick Find"), "Ctrl+F"),
            css_classes = { "flat" }
        };

        var title_label = new Gtk.Label ("Planify");
        title_label.add_css_class ("title");

        var sidebar_header = new Adw.HeaderBar () {
            title_widget = title_label,
            hexpand = true
        };

        sidebar_header.add_css_class ("flat");
        sidebar_header.pack_start (search_button);
        sidebar_header.pack_end (settings_button);
        sidebar_header.pack_end (fake_button);

        sidebar = new Layouts.Sidebar ();

        var sidebar_view = new Adw.ToolbarView ();
        sidebar_view.add_top_bar (sidebar_header);
        sidebar_view.content = sidebar;

        views_stack = new Adw.ViewStack () {
            hexpand = true,
            vexpand = true,
            vhomogeneous = false,
            hhomogeneous = false
        };

        item_sidebar_view = new Layouts.ItemSidebarView ();
        if (Services.Settings.get_default ().settings.get_boolean ("always-show-details-sidebar")) {
            item_sidebar_view.add_css_class ("sidebar");
        }

        var views_split_view = new Adw.OverlaySplitView () {
            sidebar_position = Gtk.PackType.END,
            collapsed = !Services.Settings.get_default ().settings.get_boolean ("always-show-details-sidebar"),
            max_sidebar_width = 360,
            min_sidebar_width = 360,
            content = views_stack,
            sidebar = item_sidebar_view,
            show_sidebar = false
        };

        toast_overlay = new Adw.ToastOverlay () {
            child = views_split_view
        };

        overlay_split_view = new Adw.OverlaySplitView () {
            content = toast_overlay,
            sidebar = sidebar_view
        };

        var breakpoint = new Adw.Breakpoint (Adw.BreakpointCondition.parse ("max-width: 675sp"));
        breakpoint.add_setter (overlay_split_view, "collapsed", true);
        add_breakpoint (breakpoint);

        error_db_page = build_error_db_page ();

        view_stack = new Adw.ViewStack () {
            hhomogeneous = false,
            vhomogeneous = false
        };
        view_stack.add (overlay_split_view);
        view_stack.add (error_db_page);

        content = view_stack;

        Services.Settings.get_default ().settings.bind ("pane-position", overlay_split_view, "min_sidebar_width", GLib.SettingsBindFlags.DEFAULT);
        Services.Settings.get_default ().settings.bind ("slim-mode", overlay_split_view, "show_sidebar", GLib.SettingsBindFlags.DEFAULT);
        Services.Settings.get_default ().settings.bind ("mobile-mode", overlay_split_view, "collapsed", GLib.SettingsBindFlags.DEFAULT);

        Timeout.add (250, () => {
            init_backend ();
            overlay_split_view.show_sidebar = true;
            fake_button.grab_focus ();
            return GLib.Source.REMOVE;
        });

        Services.Database.get_default ().opened.connect (() => {
            if (!Services.Database.get_default ().verify_integrity ()) {
                view_stack.visible_child = error_db_page;
                return;
            }

            view_stack.visible_child = overlay_split_view;

            if (Services.Store.instance ().is_sources_empty ()) {
                Util.get_default ().create_local_source ();
            }

            if (Services.Store.instance ().is_database_empty ()) {
                Util.get_default ().create_inbox_project ();
                Util.get_default ().create_tutorial_project ();
                Util.get_default ().create_default_labels ();
            }

            sidebar.init ();

            Services.Notification.get_default ();
            Services.TimeMonitor.get_default ().init_timeout ();

            go_homepage ();

            Services.Store.instance ().project_deleted.connect (valid_view_removed);
            Services.Store.instance ().project_archived.connect (valid_view_removed);

            check_archived ();

            Services.DBusServer.get_default ().item_added.connect ((id) => {
                Objects.Item item = Services.Database.get_default ().get_item_by_id (id);
                Gee.ArrayList<Objects.Reminder> reminders = Services.Database.get_default ().get_reminders_by_item_id (id);

                Services.Store.instance ().add_item (item);
                foreach (Objects.Reminder reminder in reminders) {
                    item.add_reminder_events (reminder);
                }
            });

            var did_startup_sync = false; // Remove hack when upstream issue is resolved

            Timeout.add (Constants.STARTUP_SYNC_TIMEOUT, () => {
                debug ("Starting startup sync\n");
                foreach (Objects.Source source in Services.Store.instance ().sources) {
                    source.run_server ();
                }
                did_startup_sync = true;

                return GLib.Source.REMOVE;
            });

            // TODO: network_changed is sometimes called very rapidly, so we should debounce it ...
            var network_monitor = GLib.NetworkMonitor.get_default ();
            network_monitor.network_changed.connect (() => {
                if (did_startup_sync == false) {
                    debug ("Ignoring early network change due to bug 1690\n");
                    return;
                }
                debug ("Network has changed, starting sync\n");
                foreach (Objects.Source source in Services.Store.instance ().sources) {
                    source.run_server ();
                }
            });
            
#if WITH_EVOLUTION
            Services.Store.instance ().setup_calendar_events ();
#endif
        });

        var color_scheme_settings = ColorSchemeSettings.Settings.get_default ();
        color_scheme_settings.notify["prefers-color-scheme"].connect (() => {
            if (Services.Settings.get_default ().settings.get_boolean ("system-appearance")) {
                Services.Settings.get_default ().settings.set_boolean (
                    "dark-mode",
                    color_scheme_settings.prefers_color_scheme == ColorSchemeSettings.Settings.ColorScheme.DARK
                );
                Util.get_default ().update_theme ();
            }
        });

        Services.Settings.get_default ().settings.changed["system-appearance"].connect (() => {
            Services.Settings.get_default ().settings.set_boolean (
                "dark-mode",
                color_scheme_settings.prefers_color_scheme == ColorSchemeSettings.Settings.ColorScheme.DARK
            );
            Util.get_default ().update_theme ();
        });

        Services.Settings.get_default ().settings.changed["appearance"].connect (Util.get_default ().update_theme);
        Services.Settings.get_default ().settings.changed["dark-mode"].connect (Util.get_default ().update_theme);

        #if WITH_LIBPORTAL
        Services.Settings.get_default ().settings.changed["run-on-startup"].connect (() => {
            bool active = Services.Settings.get_default ().settings.get_boolean ("run-on-startup");

            if (active) {
                Planify.instance.ask_for_background.begin (Xdp.BackgroundFlags.AUTOSTART, (obj, res) => {
                    Planify.instance.ask_for_background.end (res);
                });
            } else {
                Planify.instance.ask_for_background.begin (Xdp.BackgroundFlags.NONE, (obj, res) => {
                    Planify.instance.ask_for_background.end (res);
                });
            }
        });
        #endif

        Services.Settings.get_default ().settings.changed["mobile-mode"].connect (() => {
            Services.EventBus.get_default ().mobile_mode = Services.Settings.get_default ().settings.get_boolean ("mobile-mode");
        });

        Services.Settings.get_default ().settings.changed["font-scale"].connect (Util.get_default ().update_font_scale);

        Services.EventBus.get_default ().pane_selected.connect ((pane_type, id) => {  
            if (Services.EventBus.get_default ().multi_select_enabled) {
                clear_multi_select ();
            }

            if (pane_type == PaneType.PROJECT) {
                var project = Services.Store.instance ().get_project (id);
                if (project != null) {
                    add_project_view (project);
                } else {
                    add_inbox_view ();
                }
            } else if (pane_type == PaneType.FILTER) {
                if (id == Objects.Filters.Inbox.get_default ().view_id) {
                   add_inbox_view ();
                } else if (id == Objects.Filters.Today.get_default ().view_id) {
                    add_today_view ();
                } else if (id == Objects.Filters.Scheduled.get_default ().view_id) {
                    add_scheduled_view ();
                } else if (id == Objects.Filters.Pinboard.get_default ().view_id) {
                    add_filter_view (Objects.Filters.Pinboard.get_default ());
                } else if (id == Objects.Filters.Labels.get_default ().view_id) {
                    add_labels_view ();
                } else if (id.has_prefix ("priority")) {
                    add_priority_view (id);
                } else if (id == Objects.Filters.Completed.get_default ().view_id) {
                    add_filter_view (Objects.Filters.Completed.get_default ());
                } else if (id == Objects.Filters.Tomorrow.get_default ().view_id) {
                    add_filter_view (Objects.Filters.Tomorrow.get_default ());
                } else if (id == Objects.Filters.Anytime.get_default ().view_id) {
                    add_filter_view (Objects.Filters.Anytime.get_default ());
                } else if (id == Objects.Filters.Repeating.get_default ().view_id) {
                    add_filter_view (Objects.Filters.Repeating.get_default ());
                } else if (id == Objects.Filters.Unlabeled.get_default ().view_id) {
                    add_filter_view (Objects.Filters.Unlabeled.get_default ());
                } else if (id == Objects.Filters.AllItems.get_default ().view_id) {
                    add_filter_view (Objects.Filters.AllItems.get_default ());
                }
            } else if (pane_type == PaneType.LABEL) {
                add_label_view (id);
            } else {
                add_inbox_view ();
            }

            if (overlay_split_view.collapsed) {
                overlay_split_view.show_sidebar = false;
            }

            Services.EventBus.get_default ().item_edit_active = false;
            Services.EventBus.get_default ().dim_content (false, "");
        });

        Services.EventBus.get_default ().send_toast.connect ((toast) => {
            toast_overlay.add_toast (toast);
        });

        Services.EventBus.get_default ().send_error_toast.connect (send_toast_error);

        Services.EventBus.get_default ().send_task_completed_toast.connect (show_task_completed_toast);

        search_button.clicked.connect (() => {
            (new Dialogs.QuickFind.QuickFind ()).present (Planify._instance.main_window);
        });

        Services.EventBus.get_default ().open_item.connect ((item) => {
            if (Services.Settings.get_default ().settings.get_boolean ("always-show-details-sidebar")) {
                views_split_view.show_sidebar = true;
                item_sidebar_view.present_item (item);
            } else {
                if (views_split_view.show_sidebar) {
                    views_split_view.show_sidebar = false;
                    Timeout.add (275, () => {
                        views_split_view.show_sidebar = true;
                        item_sidebar_view.present_item (item);
                        return GLib.Source.REMOVE;
                    });
                } else {
                    views_split_view.show_sidebar = true;
                    item_sidebar_view.present_item (item);
                }
            }
        });

        Services.EventBus.get_default ().close_item.connect (() => {
            views_split_view.show_sidebar = false;
        });

        views_split_view.notify["show-sidebar"].connect (() => {
            if (!views_split_view.show_sidebar) {
                item_sidebar_view.clean_up ();
                fake_button.grab_focus ();
            }
        });

        Services.Store.instance ().project_archived.connect (check_archived);
        Services.Store.instance ().project_unarchived.connect (check_archived);

        Services.Settings.get_default ().settings.changed["always-show-details-sidebar"].connect (() => {
            if (Services.Settings.get_default ().settings.get_boolean ("always-show-details-sidebar")) {
                views_split_view.collapsed = false;
                item_sidebar_view.add_css_class ("sidebar");
            } else {
                views_split_view.collapsed = true;
                item_sidebar_view.add_css_class ("sidebar");
            }
        });

        Services.EventBus.get_default ().theme_changed.connect (() => {
            Appearance appearance_mode = Appearance.get_default ();
            remove_css_class ("theme-dark");
            remove_css_class ("theme-dark-blue");

            if (appearance_mode == Appearance.DARK) {
                add_css_class ("theme-dark");
            } else if (appearance_mode == Appearance.DARK_BLUE) {
                add_css_class ("theme-dark-blue");
            }
        });

        // Cleanup every 2 minutes
        Timeout.add_seconds (120, () => {
            cleanup_unused_views ();
            return Source.CONTINUE;
        });

        var key_controller = new Gtk.EventControllerKey ();
        ((Gtk.Widget) this).add_controller (key_controller);
        key_controller.key_pressed.connect ((keyval, keycode, state) => {
            if (keyval == Gdk.Key.Escape) {
                Services.EventBus.get_default ().escape_pressed ();
                
                if (Services.EventBus.get_default ().item_edit_active) {
                    Services.EventBus.get_default ().item_edit_active = false;
                    Services.EventBus.get_default ().dim_content (false, "");
                    return true;
                }
                
                if (Services.EventBus.get_default ().multi_select_enabled) {
                    clear_multi_select ();
                    return true;
                }
                
                if (views_split_view.show_sidebar) {
                    views_split_view.show_sidebar = false;
                    return true;
                }
            }
            
            return false;
        });

        var window_gesture = new Gtk.GestureClick ();
        view_stack.add_controller (window_gesture);
        window_gesture.pressed.connect ((n_press, x, y) => {
            if (Services.EventBus.get_default ().item_edit_active) {
                var target = view_stack.pick (x, y, Gtk.PickFlags.DEFAULT);
                
                bool clicked_on_editing_task = false;
                var widget = target;
                while (widget != null) {
                    if (widget.has_css_class ("task-editing")) {
                        clicked_on_editing_task = true;
                        break;
                    }
                    widget = widget.get_parent ();
                }
                
                if (!clicked_on_editing_task) {
                    Services.EventBus.get_default ().item_edit_active = false;
                    Services.EventBus.get_default ().dim_content (false, "");
                }
            }
        });

        Services.Settings.get_default ().settings.changed["local-inbox-project-id"].connect (() => {
            handle_inbox_project_change ();
        });
    }

    public void show_hide_sidebar () {
        overlay_split_view.show_sidebar = !overlay_split_view.show_sidebar;
    }

    private void clear_multi_select () {
        Services.EventBus.get_default ().multi_select_enabled = false;
        Services.EventBus.get_default ().show_multi_select (false);
        Services.EventBus.get_default ().unselect_all ();
    }

    private void init_backend () {
        Services.Database.get_default ().init_database ();
    }

    private void check_archived () {
        archive_item.visible = Services.Store.instance ().get_all_projects_archived ().size > 0;
        archive_separator.visible = Services.Store.instance ().get_all_projects_archived ().size > 0;
    }

    private void add_inbox_view () {
        var inbox_project = Services.Store.instance ().get_project (Services.Settings.get_default ().settings.get_string ("local-inbox-project-id"));
        
        if (inbox_project != null) {
            add_project_view (inbox_project);
            previous_inbox_project_id = inbox_project.id;
        }
    }

    private void handle_inbox_project_change () {
        if (previous_inbox_project_id == "") {
            return;
        }

        var old_project = Services.Store.instance ().get_project (previous_inbox_project_id);
        if (old_project == null) {
            return;
        }

        string old_view_id = old_project.view_id;
        string current_visible = views_stack.visible_child_name;

        if (current_visible == old_view_id) {
            var old_view = views_stack.get_child_by_name (old_view_id);
            if (old_view != null) {
                foreach (var item in view_cache) {
                    if (item.view_id == old_view_id) {
                        view_cache.remove (item);
                        break;
                    }
                }

                cleanup_view (old_view);
                views_stack.remove (old_view);
            }
            
            add_inbox_view ();
        }
    }

    public Views.Project add_project_view (Objects.Project project) {
        Views.Project ? project_view = (Views.Project) views_stack.get_child_by_name (project.view_id);
        if (project_view == null) {
            project_view = new Views.Project (project);
            views_stack.add_named (project_view, project.view_id);
            add_view_to_cache (project.view_id, project_view);
        } else {
            update_view_access (project.view_id);
        }

        views_stack.set_visible_child_name (project.view_id);
        return project_view;
    }

    public void add_today_view () {
        Views.Today ? today_view = (Views.Today) views_stack.get_child_by_name ("today-view");
        if (today_view == null) {
            today_view = new Views.Today ();
            views_stack.add_named (today_view, "today-view");
            add_view_to_cache ("today-view", today_view);
        } else {
            update_view_access ("today-view");
        }

        views_stack.set_visible_child_name ("today-view");
    }

    public void add_scheduled_view () {
        Views.Scheduled.Scheduled ? scheduled_view = (Views.Scheduled.Scheduled) views_stack.get_child_by_name ("scheduled-view");
        if (scheduled_view == null) {
            scheduled_view = new Views.Scheduled.Scheduled ();
            views_stack.add_named (scheduled_view, "scheduled-view");
            add_view_to_cache ("scheduled-view", scheduled_view);
        } else {
            update_view_access ("scheduled-view");
        }

        views_stack.set_visible_child_name ("scheduled-view");
    }

    public void add_labels_view () {
        Views.Labels ? labels_view = (Views.Labels) views_stack.get_child_by_name ("labels-view");
        if (labels_view == null) {
            labels_view = new Views.Labels ();
            views_stack.add_named (labels_view, "labels-view");
            add_view_to_cache ("labels-view", labels_view);
        } else {
            update_view_access ("labels-view");
        }

        views_stack.set_visible_child_name ("labels-view");
    }

    private void add_label_view (string id) {
        Views.Label ? label_view = (Views.Label) views_stack.get_child_by_name ("label-view");
        if (label_view == null) {
            label_view = new Views.Label ();
            views_stack.add_named (label_view, "label-view");
            add_view_to_cache ("label-view", label_view);
        } else {
            update_view_access ("label-view");
        }

        label_view.label = Services.Store.instance ().get_label (id);
        views_stack.set_visible_child_name ("label-view");
    }

    public void add_priority_view (string view_id) {
        Views.Filter ? filter_view = (Views.Filter) views_stack.get_child_by_name (view_id);
        if (filter_view == null) {
            filter_view = new Views.Filter (Objects.Filters.Priority.get_default (int.parse (view_id.split ("-")[1])));
            views_stack.add_named (filter_view, view_id);
            add_view_to_cache (view_id, filter_view);
        } else {
            update_view_access (view_id);
        }

        views_stack.set_visible_child_name (view_id);
    }

    private void add_filter_view (Objects.BaseObject base_object) {
        Views.Filter ? filter_view = (Views.Filter) views_stack.get_child_by_name (base_object.view_id);
        if (filter_view == null) {
            filter_view = new Views.Filter (base_object);
            views_stack.add_named (filter_view, base_object.view_id);
            add_view_to_cache (base_object.view_id, filter_view);
        } else {
            update_view_access (base_object.view_id);
        }

        views_stack.set_visible_child_name (base_object.view_id);
    }

    public void go_homepage () {
        string home_page_id = Services.Settings.get_default ().get_string ("home-view");

        if (home_page_id.has_prefix ("project-")) {
            var project_id = home_page_id.substring (8);
            if (project_id != null && project_id.length > 0) {
                Services.EventBus.get_default ().pane_selected (PaneType.PROJECT, project_id);
            }
        } else {
            Services.EventBus.get_default ().pane_selected (PaneType.FILTER, home_page_id);
        }
    }

    public void view_item (string id) {
        var item = Services.Database.get_default ().get_item_by_id (id);
        Services.EventBus.get_default ().pane_selected (PaneType.PROJECT, item.project_id);
    }

    public void valid_view_removed (Objects.Project project) {
        Views.Project ? project_view = (Views.Project) views_stack.get_child_by_name (project.view_id);
        if (project_view != null) {
            foreach (var item in view_cache) {
                if (item.view_id == project.view_id) {
                    view_cache.remove (item);
                    break;
                }
            }

            if (views_stack.visible_child == project_view) {
                go_homepage ();
                // Use a timeout to ensure the view transition is complete before cleanup
                GLib.Timeout.add (views_stack.transition_duration, () => {
                    project_view.clean_up ();
                    project_view.destroy ();
                    views_stack.remove (project_view);
                    return GLib.Source.REMOVE;
                });
            } else {
                // If not visible, we can clean up immediately
                project_view.clean_up ();
                project_view.destroy ();
                views_stack.remove (project_view);
            }
        }
    }

    public void add_task_action (string content = "") {
        if (views_stack.visible_child_name.has_prefix ("project")) {
            Views.Project ? project_view = (Views.Project) views_stack.visible_child;
            if (project_view != null) {
                project_view.prepare_new_item (content);
            }
        } else if (views_stack.visible_child_name.has_prefix ("today-view")) {
            Views.Today ? today_view = (Views.Today) views_stack.visible_child;
            if (today_view != null) {
                today_view.prepare_new_item (content);
            }
        } else if (views_stack.visible_child_name.has_prefix ("scheduled-view")) {
            Views.Scheduled.Scheduled ? scheduled_view = (Views.Scheduled.Scheduled) views_stack.visible_child;
            if (scheduled_view != null) {
                scheduled_view.prepare_new_item (content);
            }
        } else if (views_stack.visible_child_name.has_prefix ("labels-view")) {
            Views.Labels ? labels_view = (Views.Labels) views_stack.visible_child;
            if (labels_view != null) {
                labels_view.prepare_new_item (content);
            }
        } else if (views_stack.visible_child_name.has_prefix ("label-view")) {
            Views.Label ? label_view = (Views.Label) views_stack.visible_child;
            if (label_view != null) {
                label_view.prepare_new_item (content);
            }
        } else {
            Views.Filter ? filter_view = (Views.Filter) views_stack.visible_child;
            if (filter_view != null) {
                filter_view.prepare_new_item (content);
            } else {
                var dialog = new Dialogs.QuickAdd ();
                dialog.update_content (content);
                dialog.present (Planify._instance.main_window);
            }
        }
    }

    public void new_section_action () {
        if (views_stack.visible_child == null) {
            return;
        }

        if (views_stack.visible_child is Views.Project) {
            Views.Project ? project_view = (Views.Project) views_stack.visible_child;
            if (project_view != null) {
                project_view.prepare_new_section ();
            }
        }
    }

    private Gtk.Popover build_menu_app () {
        var preferences_item = new Widgets.ContextMenu.MenuItem (_("Preferences"));
        preferences_item.secondary_text = "Ctrl+,";

        var keyboard_shortcuts_item = new Widgets.ContextMenu.MenuItem (_("Keyboard Shortcuts"));
        keyboard_shortcuts_item.secondary_text = "F1";

        var about_item = new Widgets.ContextMenu.MenuItem (_("About Planify"));

        archive_item = new Widgets.ContextMenu.MenuItem (_("Archived Projects"));
        archive_separator = new Widgets.ContextMenu.MenuSeparator ();

        var menu_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        menu_box.margin_top = menu_box.margin_bottom = 3;
        menu_box.append (preferences_item);
        menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
        menu_box.append (archive_item);
        menu_box.append (archive_separator);
        menu_box.append (keyboard_shortcuts_item);
        menu_box.append (about_item);

        var popover = new Gtk.Popover () {
            has_arrow = true,
            child = menu_box,
            width_request = 250,
            position = Gtk.PositionType.BOTTOM
        };

        preferences_item.clicked.connect (() => {
            open_preferences_window ();
        });

        about_item.clicked.connect (() => {
            about_dialog ();
        });

        keyboard_shortcuts_item.clicked.connect (() => {
            open_shortcuts_window ();
        });

        archive_item.clicked.connect (() => {
            var dialog = new Dialogs.ManageProjects ();
            dialog.present (Planify._instance.main_window);
        });

        return popover;
    }

    public void open_shortcuts_window () {
        try {
            var shortcuts_builder = new Gtk.Builder ();
            shortcuts_builder.add_from_resource ("/io/github/alainm23/planify/shortcuts.ui");
            
            var shortcuts_dialog = (Adw.ShortcutsDialog) shortcuts_builder.get_object ("shortcuts_dialog");
            shortcuts_dialog.present (this);
        } catch (Error e) {
            warning ("Failed to open shortcuts window: %s\n", e.message);
        }
    }

    public void open_preferences_window () {
        var preferences_dialog = new Dialogs.Preferences.PreferencesWindow ();
        preferences_dialog.present (Planify._instance.main_window);
    }

    public void send_toast_error (int error_code, string error_message) {
        var toast = new Adw.Toast (_("Oops! Something happened"));
        toast.timeout = 3;
        toast.priority = Adw.ToastPriority.HIGH;
        toast.button_label = _("See More");

        toast.button_clicked.connect (() => {
            (new Dialogs.ErrorDialog (error_code, error_message)).present (this);
        });

        toast_overlay.add_toast (toast);
    }

    public void show_task_completed_toast (string project_id) {
        var project = Services.Store.instance ().get_project (project_id);

        if (project == null) {
            return;
        }

        var toast = new Adw.Toast (_("Task completed"));
        toast.button_label = _("View");
        toast.timeout = 3;

        toast.button_clicked.connect (() => {
            project.show_completed = true;
            project.update_local ();
        });

        toast_overlay.add_toast (toast);
    }

    private void about_dialog () {
        Adw.AboutDialog dialog;

        if (Build.PROFILE == "development") {
            dialog = new Adw.AboutDialog ();
        } else {
            dialog = new Adw.AboutDialog.from_appdata (
                "/io/github/alainm23/planify/" + Build.APPLICATION_ID + ".appdata.xml.in.in", Build.VERSION
            );
        }

        dialog.application_icon = Build.APPLICATION_ID;
        dialog.application_name = "Planify";
        dialog.developer_name = "Alain";
        dialog.designers = { "Alain" };
        dialog.website = "https://github.com/alainm23/planify";
        dialog.developers = { "Alain" };
        dialog.issue_url = "https://github.com/alainm23/planify/issues";

        dialog.present (Planify._instance.main_window);
    }

    private Gtk.Widget build_error_db_page () {
        var headerbar = new Adw.HeaderBar ();

        var status_page = new Adw.StatusPage ();
        status_page.icon_name = "process-error-symbolic";
        status_page.title = _("Database Integrity Check Failed");
        status_page.description = _("We've detected issues with the database structure that may prevent the application from functioning properly. This may be due to missing tables or columns, likely caused by data corruption or an incomplete update.\n\nThe database will now be reset to restore normal functionality, and any existing data will be removed.\n\nAfter the reset, you’ll be able to restore any backup you’ve created previously. Thank you for your patience");

        var reset_button = new Gtk.Button.with_label (_("Reset Database")) {
            halign = CENTER
        };
        reset_button.add_css_class ("destructive-action");
        reset_button.add_css_class ("pill");

        var box = new Gtk.Box (VERTICAL, 12) {
            valign = CENTER,
            margin_bottom = 32
        };
        box.append (status_page);
        box.append (reset_button);

        var toolbar_view = new Adw.ToolbarView () {
            content = box
        };
        toolbar_view.add_top_bar (headerbar);

        reset_button.clicked.connect (() => {
            Services.Database.get_default ().clear_database ();
            Services.Settings.get_default ().reset_settings ();

            Timeout.add (250, () => {
                init_backend ();
                return GLib.Source.REMOVE;
            });
        });

        return toolbar_view;
    }

    private void cleanup_unused_views () {
        var current_time = GLib.get_monotonic_time ();
        var current_view = views_stack.visible_child_name;

        var to_remove = new Gee.ArrayList<ViewCacheItem> ();

        foreach (var item in view_cache) {
            if (item.view_id != current_view &&
                current_time - item.last_access > get_timeout_for_view (item.view_id)) {
                to_remove.add (item);
            }
        }

        foreach (var item in to_remove) {
            cleanup_view (item.view);
            views_stack.remove (item.view);
            view_cache.remove (item);
        }
    }

    private int64 get_timeout_for_view (string view_id) {
        if (view_id.has_prefix ("project-")) {
            return 600000000; // 10 min
        }

        if (view_id == "today-view") {
            return 180000000; // 3 min
        }

        return VIEW_TIMEOUT; // 5 min
    }

    private void cleanup_view (Gtk.Widget view) {
        if (view is Views.Project) {
            ((Views.Project) view).clean_up ();
        } else if (view is Views.Today) {
            ((Views.Today) view).clean_up ();
        } else if (view is Views.Scheduled.Scheduled) {
            ((Views.Scheduled.Scheduled) view).clean_up ();
        } else if (view is Views.Filter) {
            ((Views.Filter) view).clean_up ();
        } else if (view is Views.Label) {
            ((Views.Label) view).clean_up ();
        } else if (view is Views.Labels) {
            ((Views.Labels) view).clean_up ();
        }
    }

    private void update_view_access (string view_id) {
        foreach (var item in view_cache) {
            if (item.view_id == view_id) {
                item.update_access ();
                break;
            }
        }
    }

    private void add_view_to_cache (string view_id, Gtk.Widget view) {
        view_cache.add (new ViewCacheItem (view_id, view));
    }

    private class ViewCacheItem {
        public string view_id;
        public Gtk.Widget view;
        public int64 last_access;

        public ViewCacheItem (string id, Gtk.Widget widget) {
            view_id = id;
            view = widget;
            last_access = GLib.get_monotonic_time ();
        }

        public void update_access () {
            last_access = GLib.get_monotonic_time ();
        }
    }
}
