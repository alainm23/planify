public class Views.Scheduled.ScheduledDay : Gtk.EventBox {
    public GLib.DateTime date { get; construct; }

    private Gee.HashMap<string, Gtk.Widget> component_dots;
    private Gtk.Grid dots_grid;
    private Gtk.Button button;

    public signal void clicked ();

    public ScheduledDay (GLib.DateTime date) {
        Object (date: date);
    }

    construct {
        var day_name_label = new Gtk.Label (date.format ("%a")) {
            hexpand = true,
            halign = Gtk.Align.CENTER
        };

        day_name_label.get_style_context ().add_class (Granite.STYLE_CLASS_SMALL_LABEL);

        var day_label = new Gtk.Label (date.get_day_of_month ().to_string ()) {
            hexpand = true,
            halign = Gtk.Align.CENTER
        };

        var today_icon = new Gtk.Image () {
            gicon = new ThemedIcon ("planner-today"),
            pixel_size = 19
        };

        var day_stack = new Gtk.Stack () {
            expand = true,
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };

        day_stack.add_named (day_label, "day");
        day_stack.add_named (today_icon, "icon");

        if (Util.get_default ().is_today (date)) {
            Timeout.add (day_stack.transition_duration, () => {
                day_stack.visible_child_name = "icon";
                return GLib.Source.REMOVE;
            });
        } else if (Util.get_default ().is_overdue (date)) {
            day_name_label.get_style_context ().remove_class (Gtk.STYLE_CLASS_DIM_LABEL);
            day_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
        } else {
            day_name_label.get_style_context ().remove_class (Gtk.STYLE_CLASS_DIM_LABEL);
            day_label.get_style_context ().add_class ("font-bold");
        }

        component_dots = new Gee.HashMap<string, Gtk.Widget> ();

        dots_grid = new Gtk.Grid () {
            halign = Gtk.Align.CENTER,
            margin_top = 3,
            margin_bottom = 3
        };

        var button_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            valign = Gtk.Align.START
        };

        button_grid.add (day_name_label);
        button_grid.add (day_stack);

        button = new Gtk.Button ();
        button.add (button_grid);

        button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        // button.get_style_context ().add_class ("scheduled-day");

        var main_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            valign = Gtk.Align.START
        };

        main_grid.add (button);
        main_grid.add (dots_grid);

        add (main_grid);

        Planner.database.item_updated.connect ((item) => {
            if (has_component (item.id_string) && (!item.has_due || item.checked)) {
                remove_component_dot (item.id_string);
            }

            if (has_component (item.id_string) && item.has_due &&
                day_hash (item.due.datetime) != day_hash (date)) {
                remove_component_dot (item.id_string);
            }
        });

        button.clicked.connect (() => {
            clicked ();
        });
    }

    public void add_component_dot (Objects.Item item) {
        if (component_dots.size >= 3) {
            return;
        }

        var component_uid = item.id_string;
        if (!component_dots.has_key (component_uid)) {
            var event_dot = new Gtk.Image ();
            event_dot.gicon = new ThemedIcon ("pager-checked-symbolic");
            event_dot.pixel_size = 6;

            unowned Gtk.StyleContext style_context = event_dot.get_style_context ();
            style_context.add_class (Granite.STYLE_CLASS_ACCENT);
            Util.get_default ().set_widget_color (Util.get_default ().get_color (item.project.color), event_dot);

            component_dots[component_uid] = event_dot;
            dots_grid.add (event_dot);
            dots_grid.show_all ();
        }
    }

    public void remove_component_dot (string id) {
        var dot = component_dots[id];
        if (dot != null) {
            dot.destroy ();
            component_dots.unset (id);
        }
    }

    public bool has_component (string id) {
        return component_dots.has_key (id);
    }

    private uint day_hash (GLib.DateTime date) {
        return date.get_year () * 10000 + date.get_month () * 100 + date.get_day_of_month ();
    }
}
