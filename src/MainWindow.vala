public class MainWindow : Gtk.Window {
    public Widgets.HeaderBar headerbar;
    public Views.Main main_view;

    public MainWindow (Gtk.Application application) {
        Object (application: application,
            icon_name: "com.github.artegeek.planner",
            title: _("Planner"),
            height_request: 700,
            width_request: 1024
        );
    }

    construct {
        headerbar = new Widgets.HeaderBar ();
        set_titlebar (headerbar);

        main_view = new Views.Main ();

        add (main_view);

        this.destroy.connect (() => {
            Planner.settings.set_int ("project-sidebar-width", main_view.position);
        });
    }

    public override bool configure_event (Gdk.EventConfigure event) {
        Gtk.Allocation rect;
        get_allocation (out rect);
        Planner.settings.set_int ("window-height", rect.height);
        Planner.settings.set_int ("window-width", rect.width);

        int root_x, root_y;
        get_position (out root_x, out root_y);
        Planner.settings.set_int ("window-x", root_x);
        Planner.settings.set_int ("window-y", root_y);

        return base.configure_event (event);
    }
}
