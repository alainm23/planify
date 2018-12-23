public class Widgets.Calendar.Calendar : Gtk.Box {
    private Widgets.Calendar.CalendarHeader calendar_header;
    private Widgets.Calendar.CalendarWeek calendar_week;
    private Widgets.Calendar.CalendarView calendar_view;

    private bool sensitive_past_days;
    static bool has_scrolled = false;

    private int month_nav;
    private int year_nav;
    private int day_nav;

    private GLib.DateTime current_date;

    private GLib.DateTime _date;

    public GLib.DateTime date {
        get {
            _date = new DateTime.local (year_nav, month_nav, day_nav, 0, 0, 0);
            return _date;
        }
    }

    public signal void selection_changed (GLib.DateTime date);
    public signal void selection_double_changed (GLib.DateTime date);
    public Calendar (bool _sensitive_past_days = false) {
        sensitive_past_days = _sensitive_past_days;
        orientation = Gtk.Orientation.VERTICAL;
        margin = 6;

        current_date = new GLib.DateTime.now_local ();

        calendar_header = new Widgets.Calendar.CalendarHeader ();
        calendar_week = new Widgets.Calendar.CalendarWeek ();
        calendar_view = new Widgets.Calendar.CalendarView ();

        pack_start (calendar_header);
        pack_start (calendar_week);
        pack_start (calendar_view);

        today ();

        calendar_header.left_clicked.connect (() => {
            previous_month ();
        });

        calendar_header.center_clicked.connect (() => {
            today ();
        });

        calendar_header.right_clicked.connect (() => {
            next_month ();
        });

        calendar_view.day_selected.connect ((day) => {
            day_nav = day;

            var date = new DateTime.local (year_nav, month_nav, day_nav, 0, 0, 0);

            selection_changed (date);
        });

        calendar_view.day_double_selected.connect ((day) => {
            day_nav = day;

            var date = new DateTime.local (year_nav, month_nav, day_nav, 0, 0, 0);

            selection_double_changed (date);
        });

        events |= Gdk.EventMask.SCROLL_MASK;
        events |= Gdk.EventMask.SMOOTH_SCROLL_MASK;
    }

    public void next_month () {
        month_nav = month_nav + 1;

        if (month_nav > 12) {
            year_nav = year_nav + 1;
            month_nav = 1;
        }

        var date = new GLib.DateTime.local (year_nav, month_nav, 1, 0, 0, 0);

        var firts_week = new DateTime.local (date.get_year (), date.get_month (), 1, 0, 0, 0);
        int start_day = firts_week.get_day_of_week () - 1;

        int max_days = Application.utils.get_days_of_month (date.get_month ());

        calendar_view.fill_grid_days (start_day,
                                      max_days,
                                      date.get_day_of_month (),
                                      Application.utils.is_current_month (date),
                                      false,
                                      date);

        calendar_header.date = date;
    }

    public void previous_month () {
        month_nav = month_nav - 1;

        if (month_nav < 1) {
            year_nav = year_nav - 1;
            month_nav = 12;
        }

        var date = new GLib.DateTime.local (year_nav, month_nav, 1, 0, 0, 0);

        var firts_week = new DateTime.local (date.get_year (), date.get_month (), 1, 0, 0, 0);
        int start_day = firts_week.get_day_of_week () - 1;

        int max_days = Application.utils.get_days_of_month (date.get_month ());

        calendar_view.fill_grid_days (start_day,
                                      max_days,
                                      date.get_day_of_month (),
                                      Application.utils.is_current_month (date),
                                      sensitive_past_days,
                                      date);

        calendar_header.date = date;
    }

    public override bool scroll_event (Gdk.EventScroll event) {
        double delta_x;
        double delta_y;
        event.get_scroll_deltas (out delta_x, out delta_y);

        double choice = delta_x;

        if (((int)delta_x).abs () < ((int)delta_y).abs ()) {
            choice = delta_y;
        }

        /* It's mouse scroll ! */
        if (choice == 1 || choice == -1) {
            //DateTime.Widgets.CalendarModel.get_default ().change_month ((int)choice);

            return true;
        }

        if (has_scrolled == true) {
            return true;
        }

        if (choice > 0.3) {
            next_month ();

            return true;
        }

        if (choice < -0.3) {
            previous_month ();

            return true;
        }

        return false;
    }

    private void today () {
        int year = current_date.get_year ();
        int month = current_date.get_month ();
        int day = current_date.get_day_of_month ();

        month_nav = month;
        year_nav = year;
        day_nav = day;

        var firts_week = new DateTime.local (year, month, 1, 0, 0, 0);
        int start_day = firts_week.get_day_of_week () - 1;

        int max_days = Application.utils.get_days_of_month (current_date.get_month ());
        calendar_view.fill_grid_days (start_day, max_days, day, true, sensitive_past_days, current_date);
        calendar_header.date = current_date;

        selection_changed (new GLib.DateTime.now_local ());
    }
}
