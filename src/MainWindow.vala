public class MainWindow : Adw.ApplicationWindow {
    public weak Planner app { get; construct; }

    private Layouts.Sidebar sidebar;
    private Gtk.Stack views_stack;

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
        var sidebar_header = new Adw.HeaderBar () {
            title_widget = new Gtk.Label (null),
            hexpand = true,
            decoration_layout = ":"
        };
        
        sidebar_header.add_css_class ("flat");

        var settings_image = new Widgets.DynamicIcon ();
        settings_image.size = 24;
        settings_image.update_icon_name ("planner-settings");

        var settings_button = new Gtk.Button () {
            can_focus = false
        };

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

         var views_header = new Adw.HeaderBar () {
            title_widget = new Gtk.Label (null),
            hexpand = true
        };

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

        var flap_view = new Adw.Flap () {
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
                    // add_today_view ();
                } else if (id == FilterType.SCHEDULED.to_string ()) {
                    // add_scheduled_view ();
                } else if (id == FilterType.PINBOARD.to_string ()) {
                    // add_pinboard_view ();
                }
            } 
        });
    }

    private void init_backend () {
        Services.Database.get_default().init_database ();
        sidebar.init();
    }

    public Views.Project add_project_view (Objects.Project project) {
        Views.Project? project_view;
        project_view = (Views.Project) views_stack.get_child_by_name (project.view_id);
        if (project_view == null) {
            project_view = new Views.Project (project);
            views_stack.add_named (project_view, project.view_id);
        }

        // views_header.view = project;
        views_stack.set_visible_child_name (project.view_id);
        return project_view;
    }
    

    private void add_inbox_view () {
        add_project_view (
            Services.Database.get_default ().get_project (Planner.settings.get_int64 ("inbox-project-id"))
        );
    }
}