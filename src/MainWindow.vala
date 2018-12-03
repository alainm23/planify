public class MainWindow : Gtk.ApplicationWindow {
    public weak Application app { get; construct; }
    public Widgets.HeaderBar headerbar;
    public Views.Main main_view;
    public Unity.LauncherEntry launcher;

    public MainWindow (Application application) {
        Object (
            application: application,
            app: application,
            icon_name: "com.github.alainm23.planner",
            title: _("Planner"),
            height_request: 700,
            width_request: 1024
        );
    }

    construct {
        headerbar = new Widgets.HeaderBar (this);
        set_titlebar (headerbar);

        main_view = new Views.Main (this);
        add (main_view);

        launcher = Unity.LauncherEntry.get_for_desktop_file (GLib.Application.get_default ().application_id + ".desktop");
        check_badge_count ();

        destroy.connect (() => {
            Application.settings.set_int ("project-sidebar-width", main_view.position);
        });

        delete_event.connect (() => {
            return hide_on_delete ();
        });

        Application.settings.changed.connect (key => {
            if (key == "badge-count") {
                check_badge_count ();
            }
        });

        Application.database.update_indicators.connect (() => {
            check_badge_count ();
        });

        Application.database.update_indicators ();
    }

    private void check_badge_count () {
        var badge_count = Application.settings.get_enum ("badge-count");

        if (badge_count == 0) {
            launcher.count = 0;
            launcher.count_visible = false;
        } else if (badge_count == 1) {
            launcher.count = Application.database.get_inbox_number ();
            launcher.count_visible = launcher.count > 0;
        } else if (badge_count == 2) {
            launcher.count = Application.database.get_today_number ();
            launcher.count_visible = launcher.count > 0;
        } else if (badge_count == 3) {
            launcher.count = Application.database.get_inbox_number () + Application.database.get_today_number ();
            launcher.count_visible = launcher.count > 0;
        } else {

        }
    }

    public override bool configure_event (Gdk.EventConfigure event) {
        Gtk.Allocation rect;
        get_allocation (out rect);
        Application.settings.set_value ("window-size",  new int[] { rect.height, rect.width });

        int root_x, root_y;
        get_position (out root_x, out root_y);
        Application.settings.set_value ("window-position",  new int[] { root_x, root_y });

        return base.configure_event (event);
    }
}
