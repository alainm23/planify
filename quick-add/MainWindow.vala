public class MainWindow : Adw.ApplicationWindow {
    public MainWindow (QuickAdd application) {
        Object (
            application: application,
            icon_name: "io.github.alainm23.planify",
            title: _("Planify - Quick Add"),
            resizable: false,
            width_request: 600,
            halign: Gtk.Align.START
        );
    }

    static construct {
        weak Gtk.IconTheme default_theme = Gtk.IconTheme.get_for_display (Gdk.Display.get_default ());
        default_theme.add_resource_path ("/io/github/alainm23/planify");
    }

    construct {
        Services.Database.get_default ().init_database ();
        
        var quick_add_widget = new Layouts.QuickAdd (true);
        set_content (quick_add_widget);

        quick_add_widget.hide_destroy.connect (hide_destroy);
        quick_add_widget.send_interface_id.connect (send_interface_id);
    }

    private void send_interface_id (string id) {
        try {
            DBusClient.get_default ().interface.add_item (id);
        } catch (Error e) {
            debug (e.message);
        }
    }

    public void hide_destroy () {
        hide ();

        Timeout.add (500, () => {
            destroy ();
            return GLib.Source.REMOVE;
        });
    }
}