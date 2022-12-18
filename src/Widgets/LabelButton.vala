public class Widgets.LabelButton : Gtk.Button {
    public Objects.Item item { get; construct; }

    private Widgets.LabelPicker.LabelPicker labels_picker = null;
    public signal void labels_changed (Gee.HashMap <string, Objects.Label> labels);

    public LabelButton (Objects.Item item) {
        Object (
            item: item,
            valign: Gtk.Align.CENTER,
            halign: Gtk.Align.CENTER,
            tooltip_text: _("Add label(s)")
        );
    }

    construct {
        add_css_class (Granite.STYLE_CLASS_FLAT);
        add_css_class ("p3");

        var tag_image = new Widgets.DynamicIcon ();
        tag_image.size = 19;
        tag_image.update_icon_name ("planner-tag");

        var button_grid = new Gtk.Grid () {
            column_spacing = 6,
            valign = Gtk.Align.CENTER
        };
        button_grid.attach (tag_image, 0, 0);

        child = button_grid;

        var gesture = new Gtk.GestureClick ();
        gesture.set_button (1);
        add_controller (gesture);

        gesture.pressed.connect ((n_press, x, y) => {
            gesture.set_state (Gtk.EventSequenceState.CLAIMED);

            if (labels_picker == null) {
                labels_picker = new Widgets.LabelPicker.LabelPicker ();

                labels_picker.closed.connect (() => {
                    labels_changed (labels_picker.labels_map);
                });
            }

            labels_picker.item = item;
            labels_picker.set_parent (this);
            labels_picker.popup ();
        });
    }
}