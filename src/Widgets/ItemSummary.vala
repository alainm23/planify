public class Widgets.ItemSummary : Gtk.Revealer {
    public Objects.Item item { get; construct; }

    private Widgets.DynamicIcon calendar_icon;
    private Gtk.Label calendar_label;
    private Gtk.Revealer calendar_revealer;

    private Widgets.DynamicIcon description_image;
    private Gtk.Revealer description_revealer;

    public ItemSummary (Objects.Item item) {
        Object (
            item: item
        );
    }

    construct {
        calendar_icon = new Widgets.DynamicIcon ();
        calendar_icon.size = 12;
        calendar_icon.update_icon_name ("planner-calendar");

        calendar_label = new Gtk.Label (null);
        calendar_label.get_style_context ().add_class ("small-label");

        var calendar_grid = new Gtk.Grid () {
            column_spacing = 3
        };
        calendar_grid.add (calendar_icon);
        calendar_grid.add (calendar_label);

        calendar_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT
        };
        calendar_revealer.add (calendar_grid);

        description_image = new Widgets.DynamicIcon () {
            margin_start = 6
        };
        description_image.size = 12;
        description_image.update_icon_name ("planner-note");

        description_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT
        };
        description_revealer.add (description_image);

        var summary_grid = new Gtk.Grid () {
            margin_top = 3
        };
        summary_grid.add (calendar_revealer);
        summary_grid.add (description_revealer);

        unowned Gtk.StyleContext summary_grid_context = summary_grid.get_style_context ();
        summary_grid_context.add_class ("dim-label");

        add (summary_grid);

        update_request ();
    }

    public void update_request () {
        if (item.has_due) {
            var icon_name = Util.get_default ().get_calendar_icon (item.due.datetime);
            calendar_icon.dark = icon_name == "planner-calendar" ? true : false;
            calendar_icon.update_icon_name (icon_name);
            calendar_label.label = Util.get_default ().get_relative_date_from_date (item.due.datetime);
            calendar_revealer.reveal_child = true;
        } else {
            calendar_label.label = "";
            calendar_revealer.reveal_child = false;
        }

        description_revealer.reveal_child = item.description != "";

        check_revealer ();
    }

    public void check_revealer () {
        reveal_child = calendar_revealer.reveal_child || description_revealer.reveal_child;
    }
}