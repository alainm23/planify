/*
* Copyright (c) 2017 Daniel Foré (http://danielfore.com)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
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
*/

public class MainWindow : Hdy.Window {
    public weak Planner app { get; construct; }

    private Layouts.Sidebar sidebar;
    private Gtk.Stack main_stack;
    private Gtk.Stack views_stack;
    private Layouts.ViewHeader views_header;

    public Services.ActionManager action_manager;

    private uint configure_id = 0;
    public MainWindow (Planner application) {
        Object (
            application: application,
            app: application,
            icon_name: "com.github.alainm23.planner",
            title: _("Planner")
        );
    }

    static construct {
        Hdy.init ();

        weak Gtk.IconTheme default_theme = Gtk.IconTheme.get_default ();
        default_theme.add_resource_path ("/com/github/alainm23/planner");
    }
    
    construct {
        action_manager = new Services.ActionManager (app, this);

        var sidebar_header = new Hdy.HeaderBar () {
            has_subtitle = false,
            show_close_button = true,
            hexpand = true,
            spacing = 0
        };
        unowned Gtk.StyleContext sidebar_header_context = sidebar_header.get_style_context ();
        sidebar_header_context.add_class (Gtk.STYLE_CLASS_FLAT);

        var settings_image = new Widgets.DynamicIcon ();
        settings_image.size = 19;
        settings_image.update_icon_name ("planner-settings");

        var settings_button = new Gtk.Button () {
            can_focus = false
        };

        settings_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        settings_button.add (settings_image);

        var sync_button = new Widgets.SyncButton ();

        sidebar_header.pack_end (settings_button);
        sidebar_header.pack_end (sync_button);

        views_header = new Layouts.ViewHeader () {
            has_subtitle = false,
            show_close_button = true,
            hexpand = true,
            margin_start = 3,
            margin_end = 3
        };

        unowned Gtk.StyleContext views_header_context = views_header.get_style_context ();
        views_header_context.add_class (Gtk.STYLE_CLASS_FLAT);

        var header_group = new Hdy.HeaderGroup ();
        header_group.add_header_bar (sidebar_header);
        header_group.add_header_bar (views_header);

        sidebar = new Layouts.Sidebar ();

        var sidebar_content = new Gtk.Grid () {
            vexpand = true,
            hexpand = false
        };
        sidebar_content.attach (sidebar_header, 0, 0);
        sidebar_content.attach (sidebar, 0, 1);

        unowned Gtk.StyleContext sidebar_content_context = sidebar_content.get_style_context ();
        sidebar_content_context.add_class ("planner-sidebar");

        views_stack = new Gtk.Stack () {
            expand = true,
            transition_type = Gtk.StackTransitionType.SLIDE_RIGHT
        };

        var main_grid = new Gtk.Grid ();
        main_grid.attach (views_header, 0, 0);
        main_grid.attach (views_stack, 0, 1);

        unowned Gtk.StyleContext main_grid_context = main_grid.get_style_context ();
        main_grid_context.add_class ("main-view");

        var flap_view = new Hdy.Flap () {
            locked = true,
            fold_policy = Hdy.FlapFoldPolicy.NEVER
        };
        flap_view.content = main_grid;
        flap_view.separator = new Gtk.Separator (Gtk.Orientation.VERTICAL);
        flap_view.flap = sidebar_content;

        var welcome_view = new Views.Welcome ();

        main_stack = new Gtk.Stack ();
        main_stack.expand = true;
        main_stack.transition_type = Gtk.StackTransitionType.CROSSFADE;

        main_stack.add_named (welcome_view, "welcome-view");
        main_stack.add_named (flap_view, "main-view");

        add (main_stack);

        Planner.settings.bind ("pane-position", sidebar_content, "width_request", GLib.SettingsBindFlags.DEFAULT);
        Planner.settings.bind ("slim-mode", flap_view, "reveal_flap", GLib.SettingsBindFlags.DEFAULT);

        welcome_view.activated.connect ((index) => {
            if (Planner.settings.set_enum ("backend-type", index + 1)) {
                init_backend ();
            }
        });

        Timeout.add (main_stack.transition_duration, () => {
            init_backend ();
            return GLib.Source.REMOVE;
        });

        delete_event.connect (() => {
            if (Planner.settings.get_boolean ("run-in-background")) {
                return hide_on_delete ();
            }

            return false;
        });
        
        Planner.event_bus.pane_selected.connect ((pane_type, id) => {
            if (pane_type == PaneType.PROJECT) {
                add_project_view (Planner.database.get_project (int64.parse (id)));
            } else if (pane_type == PaneType.FILTER) {
                if (id == FilterType.INBOX.to_string ()) {
                    add_inbox_view ();
                } else if (id == FilterType.TODAY.to_string ()) {
                    add_today_view ();
                } else if (id == FilterType.SCHEDULED.to_string ()) {
                    add_scheduled_view ();
                } else if (id == FilterType.PINBOARD.to_string ()) {
                    add_pinboard_view ();
                }
            } else if (pane_type == PaneType.LABEL) {
                add_label_view (id);
            } else if (pane_type == PaneType.TASKLIST) {
                add_tasklist_view (sidebar.get_source (id));
            }
        });

        Planner.settings.changed.connect ((key) => {
            if (key == "appearance") {
                Util.get_default ().update_theme ();
            } else if (key == "badge-count") {
                Timeout.add (main_stack.transition_duration, () => {
                    Services.Badge.get_default ().update_badge ();
                    return GLib.Source.REMOVE;
                });
            }
        });

        settings_button.clicked.connect (() => {
            var dialog = new Dialogs.Settings.Settings ();
            dialog.show_all ();
        });
    }

    public void add_task_action (string content = "") {
        if (views_stack.visible_child_name.has_prefix ("project")) {
            Views.Project? project_view = (Views.Project) views_stack.visible_child;
            if (project_view != null) {
                project_view.prepare_new_item (content);
            }
        } else if (views_stack.visible_child_name.has_prefix ("today-view")) {
            Views.Today? today_view = (Views.Today) views_stack.visible_child;
            if (today_view != null) {
                today_view.prepare_new_item (content);
            }
        } else if (views_stack.visible_child_name.has_prefix ("scheduled-view")) {
            Views.Scheduled.Scheduled? scheduled_view = (Views.Scheduled.Scheduled) views_stack.visible_child;
            if (scheduled_view != null) {
                scheduled_view.prepare_new_item (content);
            }
        } else if (views_stack.visible_child_name.has_prefix ("pinboard-view")) {
            Views.Pinboard? pinboard_view = (Views.Pinboard) views_stack.visible_child;
            if (pinboard_view != null) {
                pinboard_view.prepare_new_item (content);
            }
        }
    }

    public void new_section_action () {
        if (!views_stack.visible_child_name.has_prefix ("project")) {
            return;
        }

        Views.Project? project_view = (Views.Project) views_stack.visible_child;
        if (project_view != null) {
            Objects.Section new_section = project_view.project.prepare_new_section ();

            if (project_view.project.todoist) {
                Planner.todoist.add.begin (new_section, (obj, res) => {
                    new_section.id = Planner.todoist.add.end (res);
                    project_view.project.add_section_if_not_exists (new_section);
                });
            } else {
                new_section.id = Util.get_default ().generate_id ();
                project_view.project.add_section_if_not_exists (new_section);
            }
        }
    }

    public void add_today_view () {
        Views.Today? today_view;
        today_view = (Views.Today) views_stack.get_child_by_name ("today-view");
        if (today_view == null) {
            today_view = new Views.Today ();
            views_stack.add_named (today_view, "today-view");
        }

        views_stack.set_visible_child_name ("today-view");
    }

    public void add_scheduled_view () {
        Views.Scheduled.Scheduled? scheduled_view;
        scheduled_view = (Views.Scheduled.Scheduled) views_stack.get_child_by_name ("scheduled-view");
        if (scheduled_view == null) {
            scheduled_view = new Views.Scheduled.Scheduled ();
            views_stack.add_named (scheduled_view, "scheduled-view");
        }

        views_stack.set_visible_child_name ("scheduled-view");
    }

    public void add_pinboard_view () {
        Views.Pinboard? pinboard_view;
        pinboard_view = (Views.Pinboard) views_stack.get_child_by_name ("pinboard-view");
        if (pinboard_view == null) {
            pinboard_view = new Views.Pinboard ();
            views_stack.add_named (pinboard_view, "pinboard-view");
        }

        views_stack.set_visible_child_name ("pinboard-view");
    }

    private void add_label_view (string id) {
        Views.Label? label_view;
        label_view = (Views.Label) views_stack.get_child_by_name ("label-view");
        if (label_view == null) {
            label_view = new Views.Label ();
            views_stack.add_named (label_view, "label-view");
        }

        label_view.label = Planner.database.get_label (int64.parse (id));
        views_stack.set_visible_child_name ("label-view");
    }
    
    private void add_inbox_view () {
        BackendType backend_type = (BackendType) Planner.settings.get_enum ("backend-type");

        if (backend_type == BackendType.LOCAL || backend_type == BackendType.TODOIST) {
            add_project_view (Planner.database.get_project (Planner.settings.get_int64 ("inbox-project-id")));
        } else if (backend_type == BackendType.CALDAV) {
            try {
                var registry = Services.CalDAV.get_default ().get_registry_sync ();
                add_tasklist_view (registry.default_task_list);
            } catch (Error e) {
                warning (e.message);
            }
        }
    }

    public Views.Project add_project_view (Objects.Project project) {
        Views.Project? project_view;
        project_view = (Views.Project) views_stack.get_child_by_name (project.view_id);
        if (project_view == null) {
            project_view = new Views.Project (project);
            views_stack.add_named (project_view, project.view_id);
        }

        views_header.project = project;
        views_stack.set_visible_child_name (project.view_id);
        return project_view;
    }

    public void add_tasklist_view (E.Source source) {
        Views.Tasklist? tasklist_view;
        tasklist_view = (Views.Tasklist) views_stack.get_child_by_name ("tasklist-%s".printf (source.uid));
        if (tasklist_view == null) {
            tasklist_view = new Views.Tasklist (source);
            views_stack.add_named (tasklist_view, "tasklist-%s".printf (source.uid));
        }

        views_stack.set_visible_child_name ("tasklist-%s".printf (source.uid));
    }

    public void valid_view_removed (Objects.Project project) {
        Views.Project? project_view;
        project_view = (Views.Project) views_stack.get_child_by_name (project.view_id);
        if (project_view != null) {
            project_view.destroy ();
            go_homepage ();
        }
    }

    public void valid_tasklist_removed (E.Source source) {
        Views.Tasklist? tasklist_view;
        tasklist_view = (Views.Tasklist) views_stack.get_child_by_name ("tasklist-%s".printf (source.uid));
        if (tasklist_view != null) {
            tasklist_view.destroy ();
            add_inbox_view ();
        }
    }

    private void init_backend () {
        BackendType backend_type = (BackendType) Planner.settings.get_enum ("backend-type");
        if (backend_type == BackendType.LOCAL) {
            Planner.database = Services.Database.get_default ();
            Planner.database.init_database ();

            main_stack.visible_child_name = "main-view";

            if (Planner.database.is_database_empty ()) {
                create_inbox_project ();
            }

            init_local_todoist_backend (backend_type);
        } else if (backend_type == BackendType.TODOIST) {
            Planner.database = Services.Database.get_default ();
            Planner.database.init_database ();

            Planner.todoist = Services.Todoist.get_default ();
            Planner.todoist.init ();

            Planner.todoist.oauth_closed.connect ((welcome) => {
                if (welcome) {
                    Planner.settings.set_enum ("backend-type", 0);
                    Planner.todoist.log_out ();
                    main_stack.visible_child_name = "welcome-view";
                }
            });

            Planner.todoist.first_sync_finished.connect (() => {
                init_local_todoist_backend (backend_type);

                Timeout.add (Constants.TODOIST_SYNC_TIMEOUT, () => {
                    Services.Todoist.get_default ().run_server ();
                    return GLib.Source.REMOVE;
                });
            });

            main_stack.visible_child_name = "main-view";

            if (!Planner.todoist.invalid_token () && !Planner.database.is_database_empty ()) {
                init_local_todoist_backend (backend_type);

                Timeout.add (Constants.TODOIST_SYNC_TIMEOUT, () => {
                    Services.Todoist.get_default ().run_server ();
                    return GLib.Source.REMOVE;
                });
            }
        } else if (backend_type == BackendType.CALDAV) {
            Services.CalDAV.get_default ().start.begin ();

            main_stack.visible_child_name = "main-view";
            sidebar.init (backend_type);

            sidebar.caldav_finished.connect (go_homepage);
            sidebar.valid_tasklist_removed.connect (valid_tasklist_removed);
        } else {
            main_stack.visible_child_name = "welcome-view";
        }
    }

    public void init_local_todoist_backend (BackendType backend_type) {
        sidebar.init (backend_type);
        
        Services.Badge.get_default ();
        Services.Notification.get_default ();
        Services.CalendarEvents.get_default ();

        go_homepage ();

        Planner.database.project_deleted.connect (valid_view_removed);
    }
    
    public void go_homepage () {
        if (Planner.settings.get_boolean ("homepage-project")) {
            int64 project_id = Planner.settings.get_int64 ("homepage-project-id");
            if (Planner.database.get_project (project_id) != null) {
                Planner.event_bus.pane_selected (PaneType.PROJECT, project_id.to_string ());
            } else {
                Planner.event_bus.pane_selected (PaneType.FILTER, FilterType.INBOX.to_string ());
            }
        } else {
            Planner.event_bus.pane_selected (
                PaneType.FILTER,
                Util.get_default ().get_filter ().to_string ()
            );
        }
    }

    private void create_inbox_project () {
        Objects.Project inbox_project = new Objects.Project ();
        inbox_project.id = Util.get_default ().generate_id ();
        inbox_project.name = _("Inbox");
        inbox_project.inbox_project = true;
        inbox_project.color = "blue";
        
        if (Planner.database.insert_project (inbox_project)) {
            Planner.settings.set_int64 ("inbox-project-id", inbox_project.id);
        }
    }

    public override bool configure_event (Gdk.EventConfigure event) {
        if (configure_id != 0) {
            GLib.Source.remove (configure_id);
        }

        configure_id = Timeout.add (100, () => {
            configure_id = 0;
            
            Gdk.Rectangle rect;
            get_allocation (out rect);
            Planner.settings.set ("window-size", "(ii)", rect.width, rect.height);

            int root_x, root_y;
            get_position (out root_x, out root_y);
            Planner.settings.set ("window-position", "(ii)", root_x, root_y);

            return GLib.Source.REMOVE;
        });

        return base.configure_event (event);
    }
}
