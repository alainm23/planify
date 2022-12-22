public class MainWindow : Adw.ApplicationWindow {
    public weak Planner app { get; construct; }

    private Layouts.Sidebar sidebar;
    private Gtk.Stack views_stack;
    private Adw.Flap flap_view;
    private Widgets.ProjectViewHeaderBar project_view_headerbar;
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
        
        var views_header = new Adw.HeaderBar () {
            title_widget = new Gtk.Label (null),
            hexpand = true
        };

        // views_header.title_widget = view_headerbar;
        views_header.pack_start (sidebar_button);
        views_header.pack_start (project_view_headerbar);
        views_header.pack_end (search_button);

        views_header.add_css_class ("flat");

        views_stack = new Gtk.Stack () {
            hexpand = true,
            vexpand = true,
            transition_type = Gtk.StackTransitionType.SLIDE_RIGHT
        };

        var views_separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);

        var views_content = new Gtk.Grid() {
            orientation = Gtk.Orientation.VERTICAL
        };

        views_content.attach(views_header, 0, 0);
        views_content.attach(views_separator, 0, 1);
        views_content.attach(views_stack, 0, 2);

        flap_view = new Adw.Flap () {
            locked = false,
            fold_policy = Adw.FlapFoldPolicy.AUTO,
            transition_type = Adw.FlapTransitionType.OVER
        };
        flap_view.content = views_content;
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

        //  var granite_settings = Granite.Settings.get_default ();
        //  granite_settings.notify["prefers-color-scheme"].connect (() => {
        //      if (Planner.settings.get_boolean ("system-appearance")) {
        //          Planner.settings.set_boolean (
        //              "dark-mode",
        //              granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK
        //          );
        //          Util.get_default ().update_theme ();
        //      }
        //  });

        Planner.settings.changed.connect ((key) => {
            //  if (key == "system-appearance") {
            //      Planner.settings.set_boolean (
            //          "dark-mode",
            //          Util.get_default ().is_dark_theme ()
            //      );
                
            //      Util.get_default ().update_theme ();
            //  } else if (key == "appearance" || key == "dark-mode") {
            //      Util.get_default ().update_theme ();
            //  }

            if (key == "appearance" || key == "dark-mode") {
                Util.get_default ().update_theme ();
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
    }
    
    public void show_hide_sidebar () {
        flap_view.reveal_flap = !flap_view.reveal_flap;
    }

    private void init_backend () {
        Services.Database.get_default().init_database ();
        sidebar.init();

        if (!Services.Todoist.get_default ().invalid_token ()) {
            Timeout.add (Constants.TODOIST_SYNC_TIMEOUT, () => {
                Services.Todoist.get_default ().run_server ();
                return GLib.Source.REMOVE;
            });
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

    private Gtk.Popover menu_app = null;
    private void open_menu_app () {
        if (menu_app != null) {
            menu_app.popup ();
            return;
        }

        var preferences_item = new Gtk.Button.with_label (_("Preferences"));
        preferences_item.add_css_class (Granite.STYLE_CLASS_FLAT);

        var keyboard_shortcuts_item = new Gtk.Button.with_label (_("Keyboard shortcuts"));
        keyboard_shortcuts_item.add_css_class (Granite.STYLE_CLASS_FLAT);

        var about_item = new Gtk.Button.with_label (_("About Planner"));
        about_item.add_css_class (Granite.STYLE_CLASS_FLAT);

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
    }
}