public class Widgets.Calendar.Calendar : Gtk.Box {
    private Widgets.Calendar.CalendarHeader calendar_header;
    private Widgets.Calendar.CalendarWeek calendar_week;
    private Widgets.Calendar.CalendarView calendar_view;

    private int year;
    private int month;
    private int day;

    private int month_nav;
    private int year_nav;

    private GLib.DateTime current_date;

    public Calendar () {
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
            month_nav = month_nav - 1;

            if (month_nav < 1) {
                year_nav = year_nav - 1;
                month_nav = 12;
            }

            var date = new GLib.DateTime.local (year_nav, month_nav, 1, 0, 0, 0);

            var firts_week = new DateTime.local (date.get_year (), date.get_month (), day, 0, 0, 0);
            int start_day = firts_week.get_day_of_week () - 1;

            int max_days = Application.utils.get_days_of_month (date.get_month ());

            calendar_view.fill_grid_days (start_day,
                                          max_days,
                                          date.get_day_of_month (),
                                          Application.utils.is_current_month (date));

            calendar_header.date = date;
        });

        calendar_header.center_clicked.connect (() => {
            today ();
        });

        calendar_header.right_clicked.connect (() => {
            month_nav = month_nav + 1;

            if (month_nav > 12) {
                year_nav = year_nav + 1;
                month_nav = 1;
            }

            var date = new GLib.DateTime.local (year_nav, month_nav, day, 0, 0, 0);

            var firts_week = new DateTime.local (date.get_year (), date.get_month (), 1, 0, 0, 0);
            int start_day = firts_week.get_day_of_week () - 1;

            int max_days = Application.utils.get_days_of_month (date.get_month ());

            calendar_view.fill_grid_days (start_day,
                                          max_days,
                                          date.get_day_of_month (),
                                          Application.utils.is_current_month (date));

            calendar_header.date = date;
        });
    }

    private void today () {
        year = current_date.get_year ();
        month = current_date.get_month ();
        day = current_date.get_day_of_month ();

        month_nav = month;
        year_nav = year;

        var firts_week = new DateTime.local (year, month, day, 0, 0, 0);
        int start_day = firts_week.get_day_of_week () - 1;

        int max_days = Application.utils.get_days_of_month (current_date.get_month ());
        calendar_view.fill_grid_days (start_day, max_days, day, true);
        calendar_header.date = current_date;
    }
}
