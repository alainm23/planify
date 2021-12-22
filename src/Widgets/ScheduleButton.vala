public class Widgets.ScheduleButton : Gtk.Button {
    public Objects.Item item { get; construct; }

    private Gtk.Label due_label;
    private Widgets.DynamicIcon due_image;

    public signal void date_changed (GLib.DateTime? date);
    public signal void dialog_open (bool value);

    public ScheduleButton (Objects.Item item) {
        Object (
            item: item,
            can_focus: false
        );
    }

    construct {
        get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        due_image = new Widgets.DynamicIcon ();
        due_image.update_icon_name ("planner-calendar");
        due_image.size = 19;        

        due_label = new Gtk.Label (_("Schedule")) {
            xalign = 0
        };

        var whenbutton_grid = new Gtk.Grid () {
            column_spacing = 3
        };
        whenbutton_grid.add (due_image);
        whenbutton_grid.add (due_label);

        add (whenbutton_grid);

        clicked.connect (() => {
            var menu = new Dialogs.DateTimePicker.DateTimePicker (item);
            dialog_open (true);
            menu.popup ();

            menu.date_changed.connect ((date) => {
                date_changed (date);
            });

            menu.destroy.connect (() => {
                dialog_open (false);
            });
        });
    }

    public void update_request () {
        due_label.get_style_context ().remove_class ("overdue-label");
        due_label.label = _("Schedule");
        due_image.update_icon_name ("planner-calendar");

        if (item.has_due) {
            due_label.label = Util.get_default ().get_relative_date_from_date (item.due.datetime);
            if (Util.get_default ().is_overdue (item.due.datetime)) {
                due_label.get_style_context ().add_class ("overdue-label");
            }

            if (Util.get_default ().is_today (item.due.datetime)) {
                due_image.update_icon_name ("planner-today");
            } else {
                due_image.update_icon_name ("planner-scheduled");
            }
        }
    }
}