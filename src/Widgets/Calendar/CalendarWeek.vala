public class Widgets.Calendar.CalendarWeek : Gtk.Grid {
    public CalendarWeek () {
        column_homogeneous = true;

        var label_monday = new Gtk.Label (_("M"));
        label_monday.get_style_context ().add_class ("h4");

        var label_tuesday = new Gtk.Label (_("T"));
        label_tuesday.get_style_context ().add_class ("h4");

        var label_wednesday = new Gtk.Label (_("W"));
        label_wednesday.get_style_context ().add_class ("h4");

        var label_thursday = new Gtk.Label (_("T"));
        label_thursday.get_style_context ().add_class ("h4");

        var label_friday = new Gtk.Label (_("F"));
        label_friday.get_style_context ().add_class ("h4");

        var label_saturday = new Gtk.Label (_("S"));
        label_saturday.get_style_context ().add_class ("h4");

        var label_sunday = new Gtk.Label (_("S"));
        label_sunday.get_style_context ().add_class ("h4");

        add (label_monday);
        add (label_tuesday);
        add (label_wednesday);
        add (label_thursday);
        add (label_friday);
        add (label_saturday);
        add (label_sunday);
    }
}
