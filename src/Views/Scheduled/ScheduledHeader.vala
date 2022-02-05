public class Views.Scheduled.ScheduledHeader : Gtk.EventBox {
    public GLib.DateTime date { get; construct; }

    public signal void date_selected (GLib.DateTime date);
    private Gee.HashMap<uint, Views.Scheduled.ScheduledDay> days_map;

    public ScheduledHeader (GLib.DateTime date) {
        Object (
            date: date,
            expand: true
        );
    }

    construct {
        days_map = new Gee.HashMap<uint, Views.Scheduled.ScheduledDay> ();

        int day_of_week = date.get_day_of_week ();
        date = date.add_days (-day_of_week + 1);

        Planner.database.item_added.connect (add_component_dots);
        Planner.database.item_deleted.connect (remove_component_dots);
        Planner.database.item_updated.connect (add_component_dots);
        
        var main_grid = new Gtk.Grid () {
            column_homogeneous = true,
            column_spacing = 6,
            expand = true
        };

        add (main_grid);

        for (int i = 0; i < 7; i++) {
            Views.Scheduled.ScheduledDay scheduled_day = new Views.Scheduled.ScheduledDay (date);
            scheduled_day.clicked.connect (() => {
                date_selected (scheduled_day.date);
            });

            days_map [day_hash (date)] = scheduled_day;
            main_grid.add (scheduled_day);
            main_grid.show_all ();

            foreach (Objects.Item item in Planner.database.get_items_by_date (date, false)) {
                add_component_dots (item);
            }

            date = date.add_days (1);
        }

        show_all ();
    }

    private uint day_hash (GLib.DateTime date) {
        return date.get_year () * 10000 + date.get_month () * 100 + date.get_day_of_month ();
    }

    private void add_component_dots (Objects.Item item) {
        if (item.has_due && days_map.has_key (day_hash (item.due.datetime))) {
            if (!days_map[day_hash (item.due.datetime)].has_component (item.id_string)) {
                days_map[day_hash (item.due.datetime)].add_component_dot (item);
            }
        }
    }

    private void remove_component_dots (Objects.Item item) {
        if (item.has_due && days_map.has_key (day_hash (item.due.datetime))) {
            days_map[day_hash (item.due.datetime)].remove_component_dot (item.id_string);
        }
    }
}
