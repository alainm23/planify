public class Widgets.FilterPaneRow : Gtk.ListBoxRow {
    public FilterType filter_type { get; construct; }

    public string title;
    public string icon_name;

    private Widgets.DynamicIcon title_image;
    private Gtk.Label title_label;
    private Gtk.Label count_label;

    public FilterPaneRow (FilterType filter_type) {
        Object (
            filter_type: filter_type
        );
    }
    
    construct {
        get_style_context ().add_class ("selectable-item");

        title_image = new Widgets.DynamicIcon ();
        title_image.size = 19;

        title_label = new Gtk.Label (null) {

        };

        count_label = new Gtk.Label ("3") {
            hexpand = true,
            halign = Gtk.Align.END,
            margin_end = 3
        };
        count_label.get_style_context ().add_class ("dim-label");
        count_label.get_style_context ().add_class ("small-label");

        var main_grid = new Gtk.Grid () {
            column_spacing = 6,
            margin = 3
        };
        main_grid.add (title_image);
        main_grid.add (title_label);
        main_grid.add (count_label);

        add (main_grid);

        build_filter_data ();
    }

    private void build_filter_data () {
        if (filter_type == FilterType.TODAY) {
            title_label.label = _("Today");
            title_image.icon_name = "planner-clock";
        } else if (filter_type == FilterType.INBOX) {
            title_label.label = _("Inbox");
            title_image.icon_name = "planner-inbox";
        } else if (filter_type == FilterType.UPCOMING) {
            title_label.label = _("Upcoming");
            title_image.icon_name = "planner-calendar";
        } else if (filter_type == FilterType.TRASH) {
            title_label.label = _("Trash");
            title_image.icon_name = "planner-trash";
        } else if (filter_type == FilterType.QUICK_SEARCH) {
            title_label.label = _("Search");
            title_image.icon_name = "planner-search";
        }
    }
}