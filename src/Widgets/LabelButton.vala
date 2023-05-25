public class Widgets.LabelButton : Gtk.Grid {
    public Objects.Item item { get; construct; }

    private Gtk.MenuButton button; 
    
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
        labels_picker = new Widgets.LabelPicker.LabelPicker ();

        var tag_image = new Widgets.DynamicIcon ();
        tag_image.size = 19;
        tag_image.update_icon_name ("planner-tag");

        button = new Gtk.MenuButton () {
            child = tag_image,
            popover = labels_picker
        };

        button.add_css_class (Granite.STYLE_CLASS_FLAT);

        attach (button, 0, 0);

        labels_picker.show.connect (() => {
            labels_picker.item = item;
        });

        labels_picker.closed.connect (() => {
            labels_changed (labels_picker.labels_map);
        });
    }
}