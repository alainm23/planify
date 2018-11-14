public class MainWindow : Gtk.Window {
    public weak Planner app { get; construct; }
    public Widgets.HeaderBar headerbar;
    public Views.Main main_view;
    public Unity.LauncherEntry launcher;

    public MainWindow (Planner application) {
        Object (
            application: application,
            app: application,
            icon_name: "com.github.artegeek.planner",
            title: _("Planner"),
            height_request: 700,
            width_request: 1024
        );
    }

    construct {
        headerbar = new Widgets.HeaderBar (this);
        set_titlebar (headerbar);

        main_view = new Views.Main ();

        add (main_view);

        launcher = Unity.LauncherEntry.get_for_desktop_file (GLib.Application.get_default ().application_id + ".desktop");
        check_badge_count ();

        destroy.connect (() => {
            Planner.settings.set_int ("project-sidebar-width", main_view.position);
        });

        delete_event.connect (() => {
            return hide_on_delete ();
        });

        Planner.settings.changed.connect (key => {
            if (key == "badge-count") {
                check_badge_count ();
            }
        });

        Planner.database.add_task_signal.connect (() => {
            check_badge_count ();
        });

        Planner.database.update_task_signal.connect (() => {
            check_badge_count ();
        });
    }

    private void check_badge_count () {
        var badge_count = Planner.settings.get_enum ("badge-count");

        if (badge_count == 0) {
            launcher.count = 0;
            launcher.count_visible = false;
        } else if (badge_count == 1) {
            launcher.count = Planner.database.get_inbox_number ();
            launcher.count_visible = true;
        } else if (badge_count == 2) {
            launcher.count = Planner.database.get_today_number ();
            launcher.count_visible = true;
        } else if (badge_count == 3) {
            launcher.count = Planner.database.get_inbox_number () + Planner.database.get_today_number ();
            launcher.count_visible = true;
        } else {
            
        }
    }

    public override bool configure_event (Gdk.EventConfigure event) {
        Gtk.Allocation rect;
        get_allocation (out rect);
        Planner.settings.set_value ("window-size",  new int[] { rect.height, rect.width });

        int root_x, root_y;
        get_position (out root_x, out root_y);
        Planner.settings.set_value ("window-position",  new int[] { root_x, root_y });

        return base.configure_event (event);
    }
}
