public class MainWindow : Gtk.Window {
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

        var quick_search_entry = new Gtk.SearchEntry ();
        quick_search_entry.margin = 6;
        quick_search_entry.width_request = 300;
        quick_search_entry.placeholder_text = _("Quick search");

        var quick_search_popover = new Widgets.Popovers.QuickSearchPopover (quick_search_entry);

        quick_search_entry.changed.connect (() => {
            if (quick_search_entry.text != "") {
                quick_search_popover.show_all ();
            } else {
                quick_search_popover.popdown ();
            }
        });
        
        var quick_search_grid = new Gtk.Grid ();
        quick_search_grid.margin_top = 100;
        quick_search_grid.get_style_context ().add_class ("card");
        quick_search_grid.get_style_context ().add_class ("planner-card-radius");
        quick_search_grid.valign = Gtk.Align.START;
        quick_search_grid.halign = Gtk.Align.CENTER;
        quick_search_grid.add (quick_search_entry);

        var overlay = new Gtk.Overlay ();
        overlay.add_overlay (quick_search_grid);
        overlay.add (main_view);

        add (overlay);

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
