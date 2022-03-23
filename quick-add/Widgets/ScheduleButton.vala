public class Widgets.ScheduleButton : Gtk.Button {
    public Objects.Item item { get; construct; }

    private Gtk.Label due_label;
    private Gtk.Grid schedule_grid;
    private Widgets.DynamicIcon due_image;

    public signal void date_changed (GLib.DateTime? date);
    public signal void dialog_open (bool value);

    public ScheduleButton (Objects.Item item) {
        Object (
            item: item,
            can_focus: false,
            valign: Gtk.Align.CENTER,
            halign: Gtk.Align.CENTER
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

        schedule_grid = new Gtk.Grid () {
            column_spacing = 3
        };
        schedule_grid.add (due_image);
        schedule_grid.add (due_label);

        add (schedule_grid);

        clicked.connect (() => {
            //  var datetime_picker = new Dialogs.DateTimePicker.DateTimePicker ();

            //  dialog_open (true);
            //  datetime_picker.popup ();

            //  if (item.has_due) {
            //      datetime_picker.datetime = item.due.datetime;
            //  }
            
            //  datetime_picker.date_changed.connect (() => {
            //      date_changed (datetime_picker.datetime);
            //  });

            //  datetime_picker.destroy.connect (() => {
            //      dialog_open (false);
            //  });
        });
    }

    public void update_request () {
        schedule_grid.get_style_context ().remove_class ("today-label");
        schedule_grid.get_style_context ().remove_class ("overdue-label");
        due_label.label = _("Schedule");
        due_image.update_icon_name ("planner-calendar");

        if (item.has_due) {
            due_label.label = QuickAddUtil.get_relative_date_from_date (item.due.datetime);

            if (QuickAddUtil.is_today (item.due.datetime)) {
                due_image.update_icon_name ("planner-today");
                schedule_grid.get_style_context ().add_class ("today-label");
            } else if (QuickAddUtil.is_overdue (item.due.datetime)) {
                schedule_grid.get_style_context ().add_class ("overdue-label");
            } else {
                due_image.update_icon_name ("planner-scheduled");
            }
        }
    }
}
