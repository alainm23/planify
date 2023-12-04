public class Widgets.SyncButton : Gtk.Grid {
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
        sync_icon.size = 16;
        sync_icon.update_icon_name ("planner-refresh");

        var sync_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            can_focus = false
        };

        sync_button.child = sync_icon;
        sync_button.add_css_class (Granite.STYLE_CLASS_FLAT);

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
        
        main_revealer.child = stack;

        attach (main_revealer, 0, 0);

        Timeout.add (main_revealer.transition_duration, () => {
            main_revealer.reveal_child = Services.Todoist.get_default ().is_logged_in ();
            network_available ();
            init_signals ();
            return GLib.Source.REMOVE;
        });

        sync_button.clicked.connect (() => {
            Services.Todoist.get_default ().sync_async ();
        });

        var network_monitor = GLib.NetworkMonitor.get_default ();
        network_monitor.network_changed.connect (() => {
            network_available ();
        });
    }

    private void network_available () {
        if (GLib.NetworkMonitor.get_default ().network_available) {
            stack.visible_child_name = "sync";
            // tooltip_markup = Granite.markup_accel_tooltip ({"<Ctrl>S"}, _("Sync"));
        } else {
            stack.visible_child_name = "error";
            tooltip_markup = "<b>%s</b>\n%s".printf (_("Offline mode is on"), _("Looks like you'are not connected to the\ninternet. Changes you make in offline\nmode will be synced when you reconnect")); // vala-lint=line-length
        }
    }

    private void init_signals () {
        Services.Todoist.get_default ().sync_started.connect (sync_started);
        Services.Todoist.get_default ().sync_finished.connect (sync_finished);
    }

    public void sync_started () {
        sync_icon.add_css_class ("is_loading");
    }
    
    public void sync_finished () {
        sync_icon.remove_css_class ("is_loading");
    }
}