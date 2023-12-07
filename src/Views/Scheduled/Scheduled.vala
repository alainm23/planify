public class Views.Scheduled.Scheduled : Adw.Bin {
    private Gtk.ListBox listbox;
    private Gtk.ScrolledWindow scrolled_window;

    public Gee.HashMap <string, Layouts.ItemRow> items;
    
    construct {
        items = new Gee.HashMap <string, Layouts.ItemRow> ();

        var headerbar = new Layouts.HeaderBar ();
        headerbar.title = _("Scheduled");

        listbox = new Gtk.ListBox () {
            valign = Gtk.Align.START,
            activate_on_single_click = true,
            selection_mode = Gtk.SelectionMode.NONE,
            hexpand = true
        };

        listbox.add_css_class ("listbox-background");

        var listbox_grid = new Gtk.Grid () {
            margin_top = 12
        };
        listbox_grid.attach (listbox, 0, 0);

        var content = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            hexpand = true,
            vexpand = true
        };

        content.append (listbox_grid);

        var content_clamp = new Adw.Clamp () {
            maximum_size = 1024,
            tightening_threshold = 800,
            margin_start = 24,
            margin_end = 24
        };

        content_clamp.child = content;

        scrolled_window = new Gtk.ScrolledWindow () {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            hexpand = true,
            vexpand = true
        };

        scrolled_window.child = content_clamp;

        var toolbar_view = new Adw.ToolbarView ();
		toolbar_view.add_top_bar (headerbar);
		toolbar_view.content = scrolled_window;

        child = toolbar_view;
        add_days ();
    }

    private void add_days () {
        var date = new GLib.DateTime.now_local ();
        var month_days = Util.get_default ().get_days_of_month (date.get_month (), date.get_year ());
        var remaining_days = month_days - date.add_days (7).get_day_of_month ();
        var days_to_iterate = 7;

        if (remaining_days >= 1 && remaining_days <= 3) {
            days_to_iterate += remaining_days;
        }

        for (int i = 0; i < days_to_iterate; i++) {
            date = date.add_days (1);

            var row = new Views.Scheduled.ScheduledDay (date);
            listbox.append (row);
        }

        month_days = Util.get_default ().get_days_of_month (date.get_month (), date.get_year ());
        remaining_days = month_days - date.get_day_of_month ();

        if (remaining_days > 3) {
            var row = new Views.Scheduled.ScheduledRange (date.add_days (1), date.add_days (remaining_days));
            listbox.append (row);
        }

        for (int i = 0; i < 4; i++) {
            date = date.add_months (1);
            var row = new Views.Scheduled.ScheduledMonth (date);
            listbox.append (row);
        }
    }
}
