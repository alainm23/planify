public class Widgets.ItemSummary : Gtk.Revealer {
    public Objects.Item item { get; construct; }

    private Gtk.Label calendar_label;
    private Gtk.Revealer calendar_revealer;
    private Gtk.Revealer summary_revealer;

    private Gtk.Label description_label;
    private Gtk.Revealer description_label_revealer;

    public ItemSummary (Objects.Item item) {
        Object (
            item: item
        );
    }

    construct {
        calendar_label = new Gtk.Label (null);
        calendar_label.get_style_context ().add_class ("small-label");

        var calendar_grid = new Gtk.Grid () {
            column_spacing = 3
        };
        calendar_grid.add (calendar_label);

        calendar_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT
        };
        calendar_revealer.add (calendar_grid);

        description_label = new Gtk.Label (null) {
            xalign = 0,
            lines = 1,
            ellipsize = Pango.EllipsizeMode.END
        };
        description_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
        description_label.get_style_context ().add_class ("small-label");

        description_label_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            reveal_child = false
        };
        description_label_revealer.add (description_label);
        
        var summary_grid = new Gtk.Grid ();
        summary_grid.add (calendar_revealer);

        unowned Gtk.StyleContext summary_grid_context = summary_grid.get_style_context ();
        summary_grid_context.add_class ("dim-label");

        summary_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };
        summary_revealer.add (summary_grid);

        var main_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL
        };
        main_grid.add (description_label_revealer);
        main_grid.add (summary_revealer);

        add (main_grid);

        update_request ();
    }

    public void update_request () {
        calendar_label.get_style_context ().remove_class ("overdue-label");

        if (item.has_due) {
            calendar_label.label = Util.get_default ().get_relative_date_from_date (item.due.datetime);
            calendar_revealer.reveal_child = true;

            if (Util.get_default ().is_overdue (item.due.datetime)) {
                calendar_label.get_style_context ().add_class ("overdue-label");
            }
        } else {
            calendar_label.label = "";
            calendar_revealer.reveal_child = false;
        }

        description_label.label = Util.get_default ().line_break_to_space (item.description);
        description_label_revealer.reveal_child = description_label.label.length > 0;

        check_revealer ();
    }

    public void check_revealer () {
        summary_revealer.reveal_child = calendar_revealer.reveal_child;
        reveal_child = summary_revealer.reveal_child || description_label_revealer.reveal_child;
    }
}