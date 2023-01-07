public class Widgets.ScheduleButton : Gtk.Button {
    private Gtk.Label due_label;
    private Gtk.Box schedule_box;
    private Widgets.DynamicIcon due_image;

    private Widgets.DateTimePicker.DateTimePicker datetime_picker = null;
    public GLib.DateTime datetime { get; set; }

    public signal void date_changed (GLib.DateTime? date);

    public ScheduleButton () {
        Object (
            can_focus: false,
            valign: Gtk.Align.CENTER,
            halign: Gtk.Align.CENTER,
            tooltip_text: _("Schedule")
        );
    }

    construct {
        add_css_class (Granite.STYLE_CLASS_FLAT);
        add_css_class ("p3");

        due_image = new Widgets.DynamicIcon ();
        due_image.update_icon_name ("planner-calendar");
        due_image.size = 19;        

        due_label = new Gtk.Label (_("Schedule")) {
            xalign = 0
        };

        schedule_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3);
        schedule_box.append (due_image);
        schedule_box.append (due_label);

        set_child (schedule_box);

        var gesture = new Gtk.GestureClick ();
        gesture.set_button (1);
        add_controller (gesture);

        gesture.pressed.connect ((n_press, x, y) => {
            gesture.set_state (Gtk.EventSequenceState.CLAIMED);
            open_datetime_picker ();
        });
    }

    private void open_datetime_picker () {
        if (datetime_picker == null) {
            datetime_picker = new Widgets.DateTimePicker.DateTimePicker ();
            datetime_picker.set_parent (this);
                    
            datetime_picker.date_changed.connect (() => {
                date_changed (datetime_picker.datetime);
            });
        }

        if (datetime != null) {
            datetime_picker.datetime = datetime;
        }

        datetime_picker.popup ();
    }

    public void update_from_item (Objects.Item item) {
        schedule_box.remove_css_class ("today-label");
        schedule_box.remove_css_class ("overdue-label");
        due_label.label = _("Schedule");
        due_image.update_icon_name ("planner-calendar");
        datetime = null;

        if (item.has_due) {
            datetime = new GLib.DateTime.local (
                item.due.datetime.get_year (),
                item.due.datetime.get_month (),
                item.due.datetime.get_day_of_month (),
                item.due.datetime.get_hour (),
                item.due.datetime.get_minute (),
                item.due.datetime.get_second ()
            );

            due_label.label = Util.get_default ().get_relative_date_from_date (item.due.datetime);

            if (Util.get_default ().is_today (item.due.datetime)) {
                due_image.update_icon_name ("planner-today");
                schedule_box.add_css_class ("today-label");
            } else if (Util.get_default ().is_overdue (item.due.datetime)) {
                schedule_box.add_css_class ("overdue-label");
            } else {
                due_image.update_icon_name ("planner-scheduled");
            }
        }
    }
    //  public void update_request (Objects.Item? item = null, ECal.Component? task = null) {
    //      schedule_grid.get_style_context ().remove_class ("today-label");
    //      schedule_grid.get_style_context ().remove_class ("overdue-label");
    //      due_label.label = _("Schedule");
    //      due_image.update_icon_name ("planner-calendar");

    //      if (item != null && item.has_due) {
    //          due_label.label = Util.get_default ().get_relative_date_from_date (item.due.datetime);

    //          if (Util.get_default ().is_today (item.due.datetime)) {
    //              due_image.update_icon_name ("planner-today");
    //              schedule_grid.get_style_context ().add_class ("today-label");
    //          } else if (Util.get_default ().is_overdue (item.due.datetime)) {
    //              schedule_grid.get_style_context ().add_class ("overdue-label");
    //          } else {
    //              due_image.update_icon_name ("planner-scheduled");
    //          }
    //      }

    //      if (task != null && !task.get_icalcomponent ().get_due ().is_null_time ()) {
    //          GLib.DateTime datetime = CalDAVUtil.ical_to_date_time_local (
    //              task.get_icalcomponent ().get_due ()
    //          );

    //          due_label.label = Util.get_default ().get_relative_date_from_date (datetime);

    //          if (Util.get_default ().is_today (datetime)) {
    //              due_image.update_icon_name ("planner-today");
    //              schedule_grid.get_style_context ().add_class ("today-label");
    //          } else if (Util.get_default ().is_overdue (datetime)) {
    //              schedule_grid.get_style_context ().add_class ("overdue-label");
    //          } else {
    //              due_image.update_icon_name ("planner-scheduled");
    //          }
    //      }
    //  }
}