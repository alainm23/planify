public class MainWindow : Adw.ApplicationWindow {
    public weak Planner app { get; construct; }

    private Layouts.Sidebar sidebar;
    private Gtk.Stack views_stack;
    private Adw.Flap flap_view;
    private Widgets.ProjectViewHeaderBar project_view_headerbar;
    private Widgets.LabelsHeader labels_header;
    private Gtk.Button settings_button;

    public Services.ActionManager action_manager;
    
    public MainWindow (Planner application) {
        Object (
            application: application,
            app: application,
            icon_name: "com.github.alainm23.planner",
            title: _("Planner")
        );
    }

    static construct {
        weak Gtk.IconTheme default_theme = Gtk.IconTheme.get_for_display (Gdk.Display.get_default ());
        default_theme.add_resource_path ("/com/github/alainm23/planner");
    }

    construct {
        action_manager = new Services.ActionManager (app, this);

        var sidebar_header = new Adw.HeaderBar () {
            title_widget = new Gtk.Label (null),
            hexpand = true,
            decoration_layout = ":"
        };
        
        sidebar_header.add_css_class ("flat");

        var settings_image = new Widgets.DynamicIcon ();
        settings_image.size = 21;
        settings_image.update_icon_name ("planner-settings-sliders");

        settings_button = new Gtk.Button ();
        settings_button.add_css_class (Granite.STYLE_CLASS_FLAT);
        settings_button.child = settings_image;

        var sync_button = new Widgets.SyncButton ();

        var sidebar_buttons = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        sidebar_buttons.append (sync_button);
        sidebar_buttons.append (settings_button);

        sidebar_header.pack_end (sidebar_buttons);

        sidebar = new Layouts.Sidebar ();

        var sidebar_separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);

        var sidebar_content = new Gtk.Grid() {
            orientation = Gtk.Orientation.VERTICAL,
            vexpand = true,
            hexpand = false
        };

        sidebar_content.attach(sidebar_header, 0, 0);
        sidebar_content.attach(sidebar_separator, 0, 1);
        sidebar_content.attach(sidebar, 0, 2);

        var sidebar_image = new Widgets.DynamicIcon ();
        sidebar_image.size = 19;
        sidebar_image.update_icon_name ("sidebar-left");
        
        var sidebar_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER
        };

        sidebar_button.add_css_class (Granite.STYLE_CLASS_FLAT);
        sidebar_button.child = sidebar_image;

        project_view_headerbar = new Widgets.ProjectViewHeaderBar ();

        var search_image = new Widgets.DynamicIcon ();
        search_image.size = 19;
        search_image.update_icon_name ("planner-search");
        
        var search_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER
        };

        search_button.add_css_class (Granite.STYLE_CLASS_FLAT);
        search_button.child = search_image;

        labels_header = new Widgets.LabelsHeader ();

        var multiselect_toolbar = new Widgets.MultiSelectToolbar ();

        var views_header = new Adw.HeaderBar () {
            title_widget = new Gtk.Label (null),
            hexpand = true
        };

        views_header.pack_start (sidebar_button);
        views_header.pack_start (project_view_headerbar);
        views_header.title_widget = multiselect_toolbar;
        views_header.pack_end (search_button);
        views_header.pack_end (labels_header);
        views_header.add_css_class ("flat");

        Planner.event_bus.show_multi_select.connect ((active) => {
            sidebar_button.visible = !active;
            project_view_headerbar.visible = !active;
            search_button.visible = !active;
            labels_header.visible = !active;
        });

        views_stack = new Gtk.Stack () {
            hexpand = true,
            vexpand = true,
            transition_type = Gtk.StackTransitionType.SLIDE_RIGHT
        };

        var views_separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);

        var views_content = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL
        };

        views_content.attach (views_header, 0, 0);
        views_content.attach (views_separator, 0, 1);
        views_content.attach (views_stack, 0, 2);

        var toast_overlay = new Adw.ToastOverlay ();
        toast_overlay.child = views_content;

        flap_view = new Adw.Flap () {
            locked = false,
            fold_policy = Adw.FlapFoldPolicy.AUTO,
            transition_type = Adw.FlapTransitionType.OVER
        };
        flap_view.content = toast_overlay;
        flap_view.separator = new Gtk.Separator (Gtk.Orientation.VERTICAL);
        flap_view.flap = sidebar_content;

        set_content (flap_view);

        Planner.settings.bind ("pane-position", sidebar_content, "width_request", GLib.SettingsBindFlags.DEFAULT);
        Planner.settings.bind ("slim-mode", flap_view, "reveal_flap", GLib.SettingsBindFlags.DEFAULT);

        Timeout.add (250, () => {
            init_backend ();
            flap_view.reveal_flap = true;
            return GLib.Source.REMOVE;
        });

        var granite_settings = Granite.Settings.get_default ();
        granite_settings.notify["prefers-color-scheme"].connect (() => {
            if (Planner.settings.get_boolean ("system-appearance")) {
                Planner.settings.set_boolean (
                    "dark-mode",
                    granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK
                );
                Util.get_default ().update_theme ();
            }
        });

        Planner.settings.changed.connect ((key) => {
            if (key == "system-appearance") {
                Planner.settings.set_boolean (
                    "dark-mode",
                    granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK
                );
                Util.get_default ().update_theme ();
            } else if (key == "appearance" || key == "dark-mode") {
                Util.get_default ().update_theme ();
            } else if (key == "badge-count") {
                //  Timeout.add (main_stack.transition_duration, () => {
                //      Services.Badge.get_default ().update_badge ();
                //      return GLib.Source.REMOVE;
                //  });
            }
        });

        Planner.event_bus.pane_selected.connect ((pane_type, id) => {
            if (pane_type == PaneType.PROJECT) {
                add_project_view (Services.Database.get_default ().get_project (int64.parse (id)));
            } else if (pane_type == PaneType.FILTER) {
                if (id == FilterType.INBOX.to_string ()) {
                    add_inbox_view ();
                } else if (id == FilterType.TODAY.to_string ()) {
                    add_today_view ();
                } else if (id == FilterType.SCHEDULED.to_string ()) {
                    // add_scheduled_view ();
                } else if (id == FilterType.PINBOARD.to_string ()) {
                    add_pinboard_view ();
                }
            } else if (pane_type == PaneType.LABEL) {
                add_label_view (id);
            }

            if (flap_view.folded) {
                show_hide_sidebar ();
            }
        });

        sidebar_button.clicked.connect (() => {
            show_hide_sidebar ();
        });

        search_button.clicked.connect (() => {
            var dialog = new Dialogs.QuickFind.QuickFind ();
            dialog.show ();
        });

        settings_button.clicked.connect (open_menu_app);

        Planner.event_bus.send_notification.connect ((toast) => {
            toast_overlay.add_toast (toast);
        });
    }
    
    public void show_hide_sidebar () {
        flap_view.reveal_flap = !flap_view.reveal_flap;
    }

    private void init_backend () {
        Services.Database.get_default ().init_database ();

        if (Services.Database.get_default ().is_database_empty ()) {
            create_inbox_project ();
        }

        sidebar.init();
        labels_header.init ();

        Services.Notification.get_default ();
        Services.TimeMonitor.get_default ();
    
        go_homepage ();

        Services.Database.get_default ().project_deleted.connect (valid_view_removed);

        Services.Todoist.get_default ().first_sync_finished.connect ((inbox_project_id) => {
            var dialog = new Adw.MessageDialog ((Gtk.Window) Planner.instance.main_window, 
            _("Tasks synced successfully"), _("Do you want to use Todoist as your default task storage?"));

            dialog.body_use_markup = true;
            dialog.add_response ("cancel", _("Cancel"));
            dialog.add_response ("ok", _("Ok"));
            dialog.set_response_appearance ("ok", Adw.ResponseAppearance.SUGGESTED);
            dialog.show ();

            dialog.response.connect ((response) => {
                change_todoist_default (response == "ok", inbox_project_id);
            });
        });

        if (!Services.Todoist.get_default ().invalid_token ()) {
            Timeout.add (Constants.TODOIST_SYNC_TIMEOUT, () => {
                Services.Todoist.get_default ().run_server ();
                return GLib.Source.REMOVE;
            });
        }
    }

    private void create_inbox_project () {
        Objects.Project inbox_project = new Objects.Project ();
        inbox_project.id = Util.get_default ().generate_id ();
        inbox_project.backend_type = BackendType.LOCAL;
        inbox_project.name = _("Inbox");
        inbox_project.inbox_project = true;
        inbox_project.color = "blue";
        
        if (Services.Database.get_default ().insert_project (inbox_project)) {
            Planner.settings.set_int64 ("inbox-project-id", inbox_project.id);
        }
    }

    public Views.Project add_project_view (Objects.Project project) {
        Views.Project? project_view;
        project_view = (Views.Project) views_stack.get_child_by_name (project.view_id);
        if (project_view == null) {
            project_view = new Views.Project (project);
            views_stack.add_named (project_view, project.view_id);
        }

        project_view_headerbar.view = project;
        views_stack.set_visible_child_name (project.view_id);
        return project_view;
    }
    

    private void add_inbox_view () {
        add_project_view (
            Services.Database.get_default ().get_project (Planner.settings.get_int64 ("inbox-project-id"))
        );
    }

    public void add_today_view () {
        Views.Today? today_view;
        today_view = (Views.Today) views_stack.get_child_by_name ("today-view");
        if (today_view == null) {
            today_view = new Views.Today ();
            views_stack.add_named (today_view, "today-view");
        }

        project_view_headerbar.view = Objects.Today.get_default ();
        views_stack.set_visible_child_name ("today-view");
    }

    public void add_pinboard_view () {
        Views.Pinboard? pinboard_view;
        pinboard_view = (Views.Pinboard) views_stack.get_child_by_name ("pinboard-view");
        if (pinboard_view == null) {
            pinboard_view = new Views.Pinboard ();
            views_stack.add_named (pinboard_view, "pinboard-view");
        }

        project_view_headerbar.view = Objects.Pinboard.get_default ();
        views_stack.set_visible_child_name ("pinboard-view");
    }

    private void add_label_view (string id) {
        Views.Label? label_view;
        label_view = (Views.Label) views_stack.get_child_by_name ("label-view");
        if (label_view == null) {
            label_view = new Views.Label ();
            views_stack.add_named (label_view, "label-view");
        }

        project_view_headerbar.view = Services.Database.get_default ().get_label (int64.parse (id));
        label_view.label = Services.Database.get_default ().get_label (int64.parse (id));
        views_stack.set_visible_child_name ("label-view");
    }

    public void go_homepage () {
        Planner.event_bus.pane_selected (
            PaneType.FILTER,
            Util.get_default ().get_filter ().to_string ()
        );
    }

    public void valid_view_removed (Objects.Project project) {
        Views.Project? project_view;
        project_view = (Views.Project) views_stack.get_child_by_name (project.view_id);
        if (project_view != null) {
            views_stack.remove (project_view);
            go_homepage ();
        }
    }

    public void add_task_action (string content = "") {
        if (views_stack.visible_child_name.has_prefix ("project")) {
            Views.Project? project_view = (Views.Project) views_stack.visible_child;
            if (project_view != null) {
                project_view.prepare_new_item (content);
            }
        } else if (views_stack.visible_child_name.has_prefix ("today-view")) {
            //  Views.Today? today_view = (Views.Today) views_stack.visible_child;
            //  if (today_view != null) {
            //      today_view.prepare_new_item (content);
            //  }
        } else if (views_stack.visible_child_name.has_prefix ("scheduled-view")) {
            //  Views.Scheduled.Scheduled? scheduled_view = (Views.Scheduled.Scheduled) views_stack.visible_child;
            //  if (scheduled_view != null) {
            //      scheduled_view.prepare_new_item (content);
            //  }
        } else if (views_stack.visible_child_name.has_prefix ("pinboard-view")) {
            //  Views.Pinboard? pinboard_view = (Views.Pinboard) views_stack.visible_child;
            //  if (pinboard_view != null) {
            //      pinboard_view.prepare_new_item (content);
            //  }
        } else if (views_stack.visible_child_name.has_prefix ("tasklist")) {
            //  Views.Tasklist? tasklist_view = (Views.Tasklist) views_stack.visible_child;
            //  if (tasklist_view != null) {
            //      tasklist_view.prepare_new_item (content);
            //  }
        }
    }

    public void new_section_action () {
        if (!views_stack.visible_child_name.has_prefix ("project")) {
            return;
        }

        Views.Project? project_view = (Views.Project) views_stack.visible_child;
        if (project_view != null) {
            Objects.Section new_section = project_view.project.prepare_new_section ();

            if (project_view.project.backend_type == BackendType.TODOIST) {
                Services.Todoist.get_default ().add.begin (new_section, (obj, res) => {
                    new_section.id = Services.Todoist.get_default ().add.end (res);
                    project_view.project.add_section_if_not_exists (new_section);
                });
            } else {
                new_section.id = Util.get_default ().generate_id ();
                project_view.project.add_section_if_not_exists (new_section);
            }
        }
    }

    private void change_todoist_default (bool use_todoist, int64 inbox_project_id) {
        if (use_todoist) {
            var old_inbox_project = Services.Database.get_default ().get_project (Planner.settings.get_int64 ("inbox-project-id"));
            old_inbox_project.inbox_project = false;
            old_inbox_project.update ();

            var new_inbox_project = Services.Database.get_default ().get_project (inbox_project_id);
            new_inbox_project.inbox_project = true;
            old_inbox_project.update ();

            Planner.settings.set_int64 ("inbox-project-id", inbox_project_id);
            Planner.event_bus.inbox_project_changed ();

            if (views_stack.visible_child_name == old_inbox_project.view_id) {
                add_project_view (new_inbox_project);
            }
        } else {
            var inbox_project = Services.Database.get_default ().get_project (inbox_project_id);
            inbox_project.inbox_project = false;
            inbox_project.update ();
            Planner.event_bus.inbox_project_changed ();
        }
    }

    private Gtk.Popover menu_app = null;
    private void open_menu_app () {
        if (menu_app != null) {
            menu_app.popup ();
            return;
        }

        var preferences_item = new Widgets.ContextMenu.MenuItem (_("Preferences"));
        var keyboard_shortcuts_item = new Widgets.ContextMenu.MenuItem (_("Keyboard shortcuts"));
        var about_item = new Widgets.ContextMenu.MenuItem (_("About Planner"));

        var menu_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        menu_box.margin_top = menu_box.margin_bottom = 3;
        menu_box.append (preferences_item);
        menu_box.append (new Dialogs.ContextMenu.MenuSeparator ());
        menu_box.append (keyboard_shortcuts_item);
        menu_box.append (about_item);

        menu_app = new Gtk.Popover () {
            has_arrow = true,
            child = menu_box,
            position = Gtk.PositionType.BOTTOM
        };

        menu_app.set_parent (settings_button);
        menu_app.popup();

        preferences_item.clicked.connect (() => {
            menu_app.popdown ();

            var dialog = new Dialogs.Preferences.PreferencesWindow ();
            dialog.show ();
        });
    }
}