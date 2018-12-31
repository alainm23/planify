public class MainWindow : Gtk.Window {
    public weak Application app { get; construct; }
    public Widgets.HeaderBar headerbar;
    public Views.Main main_view;
    public Unity.LauncherEntry launcher;
    public Widgets.QuickFind quick_find;
    public Widgets.CalendarEvents events_widget;

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
        get_style_context ().add_class ("rounded");

        headerbar = new Widgets.HeaderBar (this);
        set_titlebar (headerbar);

        main_view = new Views.Main (this);
        quick_find = new Widgets.QuickFind ();

        events_widget = new Widgets.CalendarEvents ();
        events_widget.halign = Gtk.Align.END;

        var overlay = new Gtk.Overlay ();
        overlay.add_overlay (quick_find);
        overlay.add_overlay (events_widget);
        overlay.add (main_view);

        var eventbox = new Gtk.EventBox ();
        eventbox.add (overlay);

        add (eventbox);

        launcher = Unity.LauncherEntry.get_for_desktop_file (GLib.Application.get_default ().application_id + ".desktop");
        check_badge_count ();

        delete_event.connect (() => {
            Application.settings.set_int ("project-sidebar-width", main_view.position);

            if (Application.settings.get_boolean ("run-background")) {
                return hide_on_delete ();
            } else {
                return false;
            }
        });


        eventbox.event.connect ((event) => {
            if (event.type == Gdk.EventType.DOUBLE_BUTTON_PRESS) {
                events_widget.reveal_child = false;
                quick_find.reveal_child = false;
            }

            return false;
        });

        Application.settings.changed.connect (key => {
            if (key == "badge-count") {
                check_badge_count ();
            }
        });

        Application.database.update_indicators.connect (() => {
            check_badge_count ();
        });


        Application.signals.on_signal_show_events.connect (() => {
            if (events_widget.reveal_child == false) {
                events_widget.reveal_child = true;
            } else {
                events_widget.reveal_child = false;
            }
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
