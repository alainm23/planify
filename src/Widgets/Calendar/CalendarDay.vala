public class Widgets.Calendar.CalendarDay : Gtk.EventBox {
    public int day {
        set {
            label.label = value.to_string ();
        }
        get {
            return int.parse (label.label);
        }
    }

    private Gtk.Label label;
    public signal void day_selected (int day);
    public CalendarDay () {

    }

    construct {
        label = new Gtk.Label (null);
        label.height_request = 24;
        label.width_request = 24;
        label.margin = 3;
        label.halign = Gtk.Align.CENTER;
        label.valign = Gtk.Align.CENTER;

        var main_grid = new Gtk.Grid ();
        main_grid.add (label);

        add (main_grid);

        event.connect ((event) => {
            if (event.type == Gdk.EventType.BUTTON_PRESS) {
                day_selected (int.parse (label.label));
                get_style_context ().add_class ("planner-calendar-today");
            }

            return false;
        });
    }
}
