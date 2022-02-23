public class Widgets.ReminderButton : Gtk.Button {
    public Objects.Item item { get; construct; }

    public signal void dialog_open (bool value);

    public ReminderButton (Objects.Item item) {
        Object (
            item: item,
            can_focus: false,
            valign: Gtk.Align.CENTER,
            halign: Gtk.Align.CENTER
        );
    }

    construct {
        get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var button_image = new Widgets.DynamicIcon ();
        button_image.size = 19;
        button_image.update_icon_name ("planner-bell");

        var button_grid = new Gtk.Grid () {
            column_spacing = 6,
            valign = Gtk.Align.CENTER
        };
        button_grid.add (button_image);

        add (button_grid);

        clicked.connect (() => {
            var dialog = new Dialogs.ReminderPicker.ReminderPicker (item);

            dialog_open (true);
            dialog.popup ();

            dialog.destroy.connect (() => {
                dialog_open (false);
            });
        });
    }
}
