public class Widgets.PinButton : Gtk.Button {
    public Objects.Item item { get; construct; }
    private Widgets.DynamicIcon pinned_image;

    public signal void changed ();

    public PinButton (Objects.Item item) {
        Object (
            item: item,
            can_focus: false,
            valign: Gtk.Align.CENTER,
            halign: Gtk.Align.CENTER
        );
    }

    construct {
        get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        pinned_image = new Widgets.DynamicIcon ();
        pinned_image.size = 19;

        var projectbutton_grid = new Gtk.Grid () {
            column_spacing = 6,
            valign = Gtk.Align.CENTER
        };
        projectbutton_grid.add (pinned_image);

        add (projectbutton_grid);

        update_request ();

        clicked.connect (() => {
            changed ();
        });
    }

    public void update_request () {
        pinned_image.update_icon_name (item.pinned_icon);
    }
}
