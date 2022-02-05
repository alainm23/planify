public class Widgets.LabelButton : Gtk.Button {
    public Objects.Item item { get; construct; }

    public signal void labels_changed (Gee.HashMap <string, Objects.Label> labels);
    public signal void dialog_open (bool value);

    public LabelButton (Objects.Item item) {
        Object (
            item: item,
            can_focus: false,
            valign: Gtk.Align.CENTER,
            halign: Gtk.Align.CENTER
        );
    }

    construct {
        get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var tag_image = new Widgets.DynamicIcon ();
        tag_image.size = 19;
        tag_image.update_icon_name ("planner-tag");

        var button_grid = new Gtk.Grid () {
            column_spacing = 6,
            valign = Gtk.Align.CENTER
        };
        button_grid.add (tag_image);

        add (button_grid);

        clicked.connect (() => {
            var dialog = new Dialogs.LabelPicker.LabelPicker (item);
            
            dialog.labels_changed.connect ((labels) => {
                labels_changed (labels);
            });

            dialog_open (true);
            dialog.popup ();

            dialog.destroy.connect (() => {
                dialog_open (false);
            });
        });
    }
}