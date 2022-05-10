public class Widgets.ScheduleButton : Gtk.Button {
    public Objects.Item item { get; set; }
    public ECal.Component task { get; construct set; }

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
            halign: Gtk.Align.CENTER,
            tooltip_text: _("Schedule")
        );
    }

    public ScheduleButton.for_component (ECal.Component task) {
        Object (
            task: task,
            can_focus: false,
            valign: Gtk.Align.CENTER,
            halign: Gtk.Align.CENTER,
            tooltip_text: _("Schedule")
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
            var datetime_picker = new Dialogs.DateTimePicker.DateTimePicker ();

            dialog_open (true);
            datetime_picker.popup ();
            
            if (item != null && item.has_due) {
                datetime_picker.datetime = item.due.datetime;
            }

            if (task != null && !task.get_icalcomponent ().get_due ().is_null_time ()) {
                datetime_picker.datetime = CalDAVUtil.ical_to_date_time_local (
                    task.get_icalcomponent ().get_due ()
                );
            }
            
            datetime_picker.date_changed.connect (() => {
                date_changed (datetime_picker.datetime);
            });

            datetime_picker.destroy.connect (() => {
                dialog_open (false);
            });
        });
    }

    public void update_request (Objects.Item? item = null, ECal.Component? task = null) {
        schedule_grid.get_style_context ().remove_class ("today-label");
        schedule_grid.get_style_context ().remove_class ("overdue-label");
        due_label.label = _("Schedule");
        due_image.update_icon_name ("planner-calendar");

        if (item != null && item.has_due) {
            due_label.label = Util.get_default ().get_relative_date_from_date (item.due.datetime);

            if (Util.get_default ().is_today (item.due.datetime)) {
                due_image.update_icon_name ("planner-today");
                schedule_grid.get_style_context ().add_class ("today-label");
            } else if (Util.get_default ().is_overdue (item.due.datetime)) {
                schedule_grid.get_style_context ().add_class ("overdue-label");
            } else {
                due_image.update_icon_name ("planner-scheduled");
            }
        }

        if (task != null && !task.get_icalcomponent ().get_due ().is_null_time ()) {
            GLib.DateTime datetime = CalDAVUtil.ical_to_date_time_local (
                task.get_icalcomponent ().get_due ()
            );

            due_label.label = Util.get_default ().get_relative_date_from_date (datetime);

            if (Util.get_default ().is_today (datetime)) {
                due_image.update_icon_name ("planner-today");
                schedule_grid.get_style_context ().add_class ("today-label");
            } else if (Util.get_default ().is_overdue (datetime)) {
                schedule_grid.get_style_context ().add_class ("overdue-label");
            } else {
                due_image.update_icon_name ("planner-scheduled");
            }
        }
    }
}
