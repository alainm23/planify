public class Widgets.EventRow : Gtk.ListBoxRow {
    public GLib.DateTime date { get; construct; }
    public unowned ICal.Component component { get; construct; }
    public unowned E.SourceCalendar cal { get; construct; }
    public E.Source source { get; set; }

    public GLib.DateTime start_time { get; private set; }
    public GLib.DateTime? end_time { get; private set; }
    public bool is_allday { get; private set; default = false; }

    private Gtk.Revealer  main_revealer;

    private Gtk.Grid color_grid;
    private Gtk.Label time_label;

    public EventRow (GLib.DateTime date, ICal.Component component, E.Source source) {
        Object (
            date: date,
            component: component,
            cal: (E.SourceCalendar?) source.get_extension (E.SOURCE_EXTENSION_CALENDAR)
        );
    }

    construct {
        get_style_context ().add_class ("item-row");
        start_time = Util.ical_to_date_time (component.get_dtstart ());
        end_time = Util.ical_to_date_time (component.get_dtend ());

        if (end_time != null && Util.is_the_all_day (start_time, end_time)) {
            is_allday = true;
        }

        color_grid = new Gtk.Grid ();
        color_grid.width_request = 3;
        color_grid.height_request = 29;
        color_grid.valign = Gtk.Align.CENTER;
        color_grid.get_style_context ().add_class ("event-%s".printf (component.get_uid ()));

        if (is_allday) {
            color_grid.height_request = 19;
        }

        time_label = new Gtk.Label (null);
        time_label.use_markup = true;
        time_label.xalign = 0;
        time_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        var name_label = new Gtk.Label (component.get_summary ());
        name_label.hexpand = true;
        name_label.ellipsize = Pango.EllipsizeMode.END;
        name_label.lines = 3;
        name_label.wrap = true;
        name_label.wrap_mode = Pango.WrapMode.WORD_CHAR;
        name_label.xalign = 0;

        var grid = new Gtk.Grid ();
        grid.column_spacing = 6;
        grid.margin_start = 43;
        grid.margin_top = 3;
        grid.margin_bottom = 3;
        grid.attach (color_grid, 0, 0, 1, 2);
        grid.attach (name_label, 1, 0, 1, 1);
        if (!is_allday) {
            grid.attach (time_label, 1, 1, 1, 1);
        }

        main_revealer = new Gtk.Revealer ();
        main_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        main_revealer.add (grid);
        main_revealer.reveal_child = false;

        add (main_revealer);

        set_color ();
        cal.notify["color"].connect (set_color);
        
        update_timelabel ();
        check_visible ();

        Application.settings.changed.connect ((key) => {
            if (key == "calendar-sources-disabled") {
                check_visible ();
            }
        });
    }

    private void check_visible () {
        bool _visible = true;

        foreach (var uid in Application.settings.get_strv ("calendar-sources-disabled")) {
            if (cal.get_source ().uid == uid) {
                _visible = false;
            }
        }

        main_revealer.reveal_child = _visible;
    }
    
    private void update_timelabel () {
        var time_format = Granite.DateTime.get_default_time_format (true, false);
        time_label.label = "<small>%s – %s</small>".printf (start_time.format (time_format), end_time.format (time_format));
    }
    
    private void set_color () {
        var color = cal.dup_color ();

        string COLOR_CSS = """
            .event-%s {
                background-color: %s;
                border-radius: 4px; 
            }
        """;

        var provider = new Gtk.CssProvider ();

        try {
            var colored_css = COLOR_CSS.printf (
                component.get_uid (),
                color
            );
            
            provider.load_from_data (colored_css, colored_css.length);

            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (GLib.Error e) {
            return;
        }
    }
}