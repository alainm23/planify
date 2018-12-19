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
        label.halign = Gtk.Align.CENTER;
        label.valign = Gtk.Align.CENTER;

        var image = new Gtk.Image ();
        image.gicon = new ThemedIcon ("mail-unread-symbolic");
        image.pixel_size = 8;

        var main_grid = new Gtk.Grid ();
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.margin = 3;
        main_grid.add (label);
        //main_grid.add (image);

        add (main_grid);

        event.connect ((event) => {
            if (event.type == Gdk.EventType.BUTTON_PRESS) {
                day_selected (int.parse (label.label));
                get_style_context ().add_class ("planner-calendar-selected");
            }

            return false;
        });
    }
}
