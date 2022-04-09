public class Widgets.SyncButton : Gtk.EventBox {
    private Gtk.Revealer main_revealer;
    private Widgets.DynamicIcon sync_icon;
    private Gtk.Stack stack;

    public bool reveal_child {
        set {
            main_revealer.reveal_child = value;
        }
    }

    construct {
        sync_icon = new Widgets.DynamicIcon ();
        sync_icon.size = 19;
        sync_icon.update_icon_name ("planner-refresh");

        var sync_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            can_focus = false
        };

        sync_button.add (sync_icon);

        unowned Gtk.StyleContext sync_button_context = sync_button.get_style_context ();
        sync_button_context.add_class (Gtk.STYLE_CLASS_FLAT);

        var error_image = new Gtk.Image () {
            gicon = new ThemedIcon ("dialog-warning-symbolic"),
            pixel_size = 13
        };

        stack = new Gtk.Stack () {
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };

        stack.add_named (sync_button, "sync");
        stack.add_named (error_image, "error");

        main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT
        };
        
        main_revealer.add (stack);

        add (main_revealer);

        Timeout.add (main_revealer.transition_duration, () => {
            main_revealer.reveal_child = reveal_child = (BackendType) Planner.settings.get_enum ("backend-type") == BackendType.TODOIST;
            network_available ();
            init_signals ();
            return GLib.Source.REMOVE;
        });

        sync_button.clicked.connect (() => {
            Services.Todoist.get_default ().sync_async ();
        });

        Planner.settings.changed.connect ((key) => {
            if (key == "backend-type") {
                main_revealer.reveal_child = (BackendType) Planner.settings.get_enum ("backend-type") == BackendType.TODOIST;
                init_signals ();
            }
        });

        var network_monitor = GLib.NetworkMonitor.get_default ();
        network_monitor.network_changed.connect (() => {
            network_available ();
        });
    }

    private void network_available () {
        if (GLib.NetworkMonitor.get_default ().network_available) {
            stack.visible_child_name = "sync";
            tooltip_markup = Granite.markup_accel_tooltip ({"<Ctrl>S"}, _("Sync"));
        } else {
            stack.visible_child_name = "error";
            tooltip_markup = "<b>%s</b>\n%s".printf (_("Offline mode is on"), _("Looks like you'are not connected to the\ninternet. Changes you make in offline\nmode will be synced when you reconnect")); // vala-lint=line-length
        }
    }

    private void init_signals () {
        if ((BackendType) Planner.settings.get_enum ("backend-type") == BackendType.TODOIST) {
            Services.Todoist.get_default ().sync_started.connect (sync_started);
            Services.Todoist.get_default ().sync_finished.connect (sync_finished);
        }
    }

    public void sync_started () {
        unowned Gtk.StyleContext sync_icon_context = sync_icon.get_style_context ();
        sync_icon_context.add_class ("is_loading");
    }
    
    public void sync_finished () {
        unowned Gtk.StyleContext sync_icon_context = sync_icon.get_style_context ();
        sync_icon_context.remove_class ("is_loading");
    }
}
