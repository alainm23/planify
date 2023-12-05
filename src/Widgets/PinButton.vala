public class Widgets.PinButton : Gtk.Button {
    public Objects.Item item { get; construct; }
    private Widgets.DynamicIcon pinned_image;

    public signal void changed ();

    public PinButton (Objects.Item item) {
        Object (
            item: item,
            can_focus: false,
            valign: Gtk.Align.CENTER,
            halign: Gtk.Align.CENTER,
            tooltip_text: _("Pinned")
        );
    }

    construct {
        add_css_class (Granite.STYLE_CLASS_FLAT);
                
        pinned_image = new Widgets.DynamicIcon ();
        pinned_image.size = 16;

        var projectbutton_grid = new Gtk.Grid () {
            column_spacing = 6,
            valign = Gtk.Align.CENTER
        };
        projectbutton_grid.attach (pinned_image, 0, 0);

        child = projectbutton_grid;

        update_request ();

        var gesture = new Gtk.GestureClick ();
        gesture.set_button (1);
        add_controller (gesture);

        gesture.pressed.connect ((n_press, x, y) => {
            gesture.set_state (Gtk.EventSequenceState.CLAIMED);
            changed ();
        });
    }

    public void update_request () {
        pinned_image.update_icon_name (item.pinned_icon);
    }
}