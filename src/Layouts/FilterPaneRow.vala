

public class Layouts.FilterPaneRow : Gtk.FlowBoxChild {
    public FilterType filter_type { get; construct; }

    public string title;
    public string icon_name;

    private Widgets.DynamicIcon title_image;
    private Gtk.Label title_label;
    private Gtk.Label count_label;

    public FilterPaneRow (FilterType filter_type) {
        Object (
            filter_type: filter_type,
            can_focus: false
        );
    }

    construct {
        add_css_class ("card");
        add_css_class ("filter-pane-row-%s".printf (filter_type.to_string ()));

        title_image = new Widgets.DynamicIcon () {
            hexpand = true,
            halign = Gtk.Align.END
        };
        title_image.size = 19;

        title_label = new Gtk.Label (null) {
            hexpand = true,
            halign = Gtk.Align.START,
            margin_start = 3
        };

        title_label.add_css_class ("font-bold");

        count_label = new Gtk.Label ("2") {
            hexpand = true,
            halign = Gtk.Align.START,
            margin_start = 3
        };

        count_label.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);
        count_label.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);

        var main_grid = new Gtk.Grid () {
            column_spacing = 6,
            margin_start = 3,
            margin_end = 3,
            margin_top = 3,
            margin_bottom = 3
        };
        main_grid.attach (title_label, 0, 0, 1, 1);
        main_grid.attach (title_image, 1, 0, 1, 1);
        main_grid.attach (count_label, 0, 1, 2, 2);

        child = main_grid;

        build_filter_data ();
    }

    private void build_filter_data () {
        if (filter_type == FilterType.TODAY) {
            title_label.label = _("Today");
            title_image.update_icon_name ("planner-today");
        } else if (filter_type == FilterType.INBOX) {
            title_label.label = _("Inbox");
            title_image.update_icon_name ("planner-inbox");
        } else if (filter_type == FilterType.SCHEDULED) {
            title_label.label = _("Scheduled");
            title_image.update_icon_name ("planner-scheduled");
        } else if (filter_type == FilterType.PINBOARD) {
            title_label.label = _("Pinboard");
            title_image.update_icon_name ("planner-pin-tack");
        }
    }
}