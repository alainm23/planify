public class Views.Scheduled.Scheduled : Gtk.Grid {
    public Gee.HashMap <string, Layouts.ItemRow> items;

    private Gtk.ListBox listbox;
    private Gtk.ScrolledWindow scrolled_window;

    construct {
        items = new Gee.HashMap <string, Layouts.ItemRow> ();

        var headerbar = new Widgets.FilterHeader (Objects.Scheduled.get_default ());
        headerbar.visible_add_button = false;

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
            maximum_size = 720,
            margin_start = 12,
            margin_end = 12
        };

        content_clamp.child = content;

        scrolled_window = new Gtk.ScrolledWindow () {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            hexpand = true,
            vexpand = true
        };

        scrolled_window.child = content_clamp;

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            hexpand = true,
            vexpand = true
        };

        content_box.append (headerbar);
        content_box.append (scrolled_window);

        attach (content_box, 0, 0);
        add_days ();

        headerbar.prepare_new_item.connect (() => {
            prepare_new_item ();
        });
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

    public void prepare_new_item (string content = "") {
        Timeout.add (225, () => {
            scrolled_window.vadjustment.value = 0;
            return GLib.Source.REMOVE;
        });

        // var row = listbox.get_row_at_index (0);
    }
}