public class Widgets.TodoistSync : Gtk.EventBox {
    private Gtk.Revealer main_revealer;
    public bool reveal_child {
        set {
            main_revealer.reveal_child = value;
        }
    }

    construct {
        var available_icon = new Gtk.Image () {
            gicon = new ThemedIcon ("user-available"),
            pixel_size = 16,
            halign = Gtk.Align.END,
            valign = Gtk.Align.END
        };

        var todoist_icon = new Gtk.Image () {
            gicon = new ThemedIcon ("planner-todoist"),
            pixel_size = 24,
            margin_bottom = 3,
            margin_right = 3
        };

        var todoist_overlay = new Gtk.Overlay ();
        todoist_overlay.add_overlay (available_icon);
        todoist_overlay.add (todoist_icon);

        var username_label = new Gtk.Label (Planner.settings.get_string ("todoist-user-email"));
        
        var sync_icon = new Widgets.DynamicIcon ();
        sync_icon.size = 16;
        sync_icon.icon_name = "planner-refresh";
        // sync_image.get_style_context ().add_class ("sync-image-rotate");

        var sync_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            hexpand = true,
            halign = Gtk.Align.END,
            can_focus = false
            // tooltip_text = add_tooltip
        };

        sync_button.add (sync_icon);

        unowned Gtk.StyleContext sync_button_context = sync_button.get_style_context ();
        sync_button_context.add_class (Gtk.STYLE_CLASS_FLAT);
        sync_button_context.add_class ("no-padding");

        var main_grid = new Gtk.Grid () {
            column_spacing = 6,
            margin = 9,
            margin_top = 0
        };

        unowned Gtk.StyleContext main_grid_context = main_grid.get_style_context ();
        main_grid_context.add_class ("pane-listbox");
        main_grid_context.add_class ("todoist-sync-button");

        main_grid.add (todoist_overlay);
        main_grid.add (username_label);
        main_grid.add (sync_button);

        main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            reveal_child = false
        };
        main_revealer.add (main_grid);

        add (main_revealer);

        Planner.settings.bind ("todoist-user-email", username_label, "label", GLib.SettingsBindFlags.DEFAULT);
        Planner.settings.bind ("todoist-account", main_revealer, "reveal_child", GLib.SettingsBindFlags.DEFAULT);

        sync_button.clicked.connect (() => {
            Services.Todoist.get_default ().sync_async ();
        });
    }
}