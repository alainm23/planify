public class PlannerQuickAdd : Gtk.Application {
    public const string SHORTCUT = "<Alt>a";
    public const string ID = "planner-quick-add";

    private const string CSS = """
        entry {
            caret-color: #3689e6;
        }
        
        textview {
            caret-color: #3689e6;
        }

        .titlebar {
            padding: 0px;
            background-color: @base_color;
        }

        .checklist-button check {
            border-radius: 4px;
        }

        .content-entry {
            color: @text_color;
            font-weight: 600;
            border-width: 0px 0px 0px 0px;
            background-color: @base_color;
        }
        
        .content-entry:focus {
            border-color: transparent;
            box-shadow: none;
        }

        .label {
            font-size: 14px;
        }
    """;

    public static Database database;
    public static GLib.Settings settings;

    public PlannerQuickAdd () {
        Object (
            application_id: ID,
            flags: ApplicationFlags.FLAGS_NONE
        );

        settings = new Settings ("com.github.alainm23.planner");
        database = new Database ();
    }

    protected override void activate () {
        unowned List<Gtk.Window> windows = get_windows ();
        if (windows.length () > 0 && !windows.data.visible) {
            windows.data.destroy ();
            return;
        }
        
        var main_window = new MainWindow (this);
        main_window.show_all ();

        var quit_action = new SimpleAction ("quit", null);

        add_action (quit_action);
        set_accels_for_action ("app.quit", {"Escape"});

        quit_action.activate.connect (() => {
            if (main_window != null) {
                main_window.hide ();

                Timeout.add (500, () => {
                    main_window.destroy ();
                    return false;
                });
            }
        });

        // CSS provider
        var provider = new Gtk.CssProvider ();
        provider.load_from_data (CSS, CSS.length);
        Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        
        // Default Icon Theme
        weak Gtk.IconTheme default_theme = Gtk.IconTheme.get_default ();
        default_theme.add_resource_path ("/com/github/alainm23/planner");
        
        // Set shortcut
        CustomShortcutSettings.init ();
        bool has_shortcut = false;
        foreach (var shortcut in CustomShortcutSettings.list_custom_shortcuts ()) {
            if (shortcut.command == ID) {
                // CustomShortcutSettings.edit_shortcut (shortcut.relocatable_schema, SHORTCUT);
                has_shortcut = true;
                return;
            }
        }
        if (!has_shortcut) {
            var shortcut = CustomShortcutSettings.create_shortcut ();
            if (shortcut != null) {
                CustomShortcutSettings.edit_shortcut (shortcut, SHORTCUT);
                CustomShortcutSettings.edit_command (shortcut, ID);
            }
        }
    }
}

public static int main (string[] args) {
    var application = new PlannerQuickAdd ();
    return application.run (args);
}