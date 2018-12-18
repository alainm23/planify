public class Widgets.Calendar.CalendarView : Gtk.Box {
    private Gee.ArrayList <Gtk.Label> labels;
    private Gtk.Grid days_grid;

    public CalendarView () {
        orientation = Gtk.Orientation.VERTICAL;

        labels = new Gee.ArrayList<Gtk.Label> ();
        int max_labels = 42;

        days_grid = new Gtk.Grid ();
        days_grid.column_homogeneous = true;
        days_grid.row_homogeneous = false;

        var col = 0;
        var row = 0;

        for (int i = 0; i < max_labels; i++) {
            var label_day = new Gtk.Label (null);
            label_day.height_request = 24;
            label_day.width_request = 24;
            label_day.margin = 6;
            label_day.halign = Gtk.Align.CENTER;
            label_day.valign = Gtk.Align.CENTER;

            days_grid.attach (label_day, col, row, 1, 1);
            col = col + 1;

            if (col != 0 && col % 7 == 0) {
                row = row + 1;
                col = 0;
            }

            label_day.no_show_all = true;
            labels.add (label_day);
        }

        pack_end (days_grid);
    }

    public void fill_grid_days (int start_day, int max_day, int current_day, bool apply_style) {
        var day_number = 1;

        for (int i = 0; i < 42; i++) {
            var label = labels [i];
            label.visible = true;
            label.get_style_context ().remove_class ("planner-calendar-today");

            if (i < start_day || i >= max_day + start_day) {
                label.visible = false;
            } else {
                if (current_day != -1 && (i+1) == current_day + start_day ) {
                    if (apply_style) {
                        label.get_style_context ().add_class ("planner-calendar-today");
                    }
                }

                label.label = day_number.to_string();
                day_number++;
            }
        }

        days_grid.show_all ();
    }
}
