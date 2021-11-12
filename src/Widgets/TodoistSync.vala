public class Widgets.TodoistSync : Gtk.EventBox {
    private Gtk.Revealer main_revealer;
    private Widgets.DynamicIcon sync_icon;
    private Hdy.Avatar avatar;

    public bool reveal_child {
        set {
            main_revealer.reveal_child = value;
        }
    }

    construct {
        var available_icon = new Gtk.Image () {
            gicon = new ThemedIcon ("user-available"),
            pixel_size = 13,
            halign = Gtk.Align.END,
            valign = Gtk.Align.END
        };

        avatar = new Hdy.Avatar (24, Planner.settings.get_string ("todoist-user-name"), true) {
            margin = 3
        };

        var todoist_overlay = new Gtk.Overlay () {
        };
        todoist_overlay.add_overlay (available_icon);
        todoist_overlay.add (avatar);

        var username_label = new Gtk.Label (Planner.settings.get_string ("todoist-user-name")) {
        };
                
        sync_icon = new Widgets.DynamicIcon ();
        sync_icon.size = 16;
        sync_icon.icon_name = "planner-refresh";

        var sync_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            can_focus = false,
            margin_end = 6
            // tooltip_text = add_tooltip
        };

        sync_button.add (sync_icon);

        unowned Gtk.StyleContext sync_button_context = sync_button.get_style_context ();
        sync_button_context.add_class (Gtk.STYLE_CLASS_FLAT);
        sync_button_context.add_class ("no-padding");

        var todoist_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            hexpand = true
        };

        todoist_box.pack_start (todoist_overlay, false, false, 0);
        todoist_box.pack_start (username_label, false, false, 3);
        todoist_box.pack_end (sync_button, false, true, 0);

        var main_grid = new Gtk.Grid () {
            margin = 9,
            margin_top = 0
        };

        unowned Gtk.StyleContext main_grid_context = main_grid.get_style_context ();
        main_grid_context.add_class ("pane-listbox");
        main_grid_context.add_class ("todoist-sync-button");

        main_grid.add (todoist_box);

        main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            reveal_child = false
        };
        main_revealer.add (main_grid);

        add (main_revealer);

        update ();

        Planner.settings.bind ("todoist-user-email", username_label, "label", GLib.SettingsBindFlags.DEFAULT);
        Planner.settings.bind ("todoist-account", main_revealer, "reveal_child", GLib.SettingsBindFlags.DEFAULT);

        sync_button.clicked.connect (() => {
            Services.Todoist.get_default ().sync_async ();
        });

        Planner.event_bus.avatar_downloaded.connect (() => {
           update ();
        });
    }

    public void sync_started () {
        unowned Gtk.StyleContext sync_icon_context = sync_icon.get_style_context ();
        sync_icon_context.add_class ("is_loading");
    }
    
    public void sync_finished () {
        unowned Gtk.StyleContext sync_icon_context = sync_icon.get_style_context ();
        sync_icon_context.remove_class ("is_loading");
    }

    private void update () {
        avatar.set_loadable_icon (
            new FileIcon (File.new_for_path (Util.get_default ().get_todoist_avatar_path ()))
        );
        avatar.text = Planner.settings.get_string ("todoist-user-name");
    }
}
