/*
* Copyright © 2023 Alain M. (https://github.com/alainm23/planify)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Alain M. <alainmh23@gmail.com>
*/

public class Widgets.ScheduleButton : Gtk.Grid {
    private Gtk.Label due_label;
    
    private Gtk.Box schedule_box;
    private Widgets.DynamicIcon due_image;
    private Widgets.DateTimePicker.DateTimePicker datetime_picker;

    private GLib.DateTime _datetime;
    public GLib.DateTime datetime {
        get {
            return _datetime;
        }

        set {
            _datetime = value;

            if (_datetime != null) {
                datetime_picker.visible_no_date = true;
                datetime_picker.datetime = _datetime;
            } else {
                datetime_picker.visible_no_date = false;
            }
        }
    }

    public bool visible_no_date {
        set {
            datetime_picker.visible_no_date = value;
        }
    }

    public signal void date_changed (GLib.DateTime? date);

    public ScheduleButton () {
        Object (
            valign: Gtk.Align.CENTER,
            halign: Gtk.Align.CENTER,
            tooltip_text: _("Schedule")
        );
    }

    construct {
        datetime_picker = new Widgets.DateTimePicker.DateTimePicker ();

        due_image = new Widgets.DynamicIcon ();
        due_image.size = 19;
        due_image.update_icon_name ("planner-calendar");

        due_label = new Gtk.Label (_("Schedule")) {
            xalign = 0,
            use_markup = true
        };

        schedule_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3);
        schedule_box.append (due_image);
        schedule_box.append (due_label);

        var button = new Gtk.MenuButton () {
            child = schedule_box,
            popover = datetime_picker,
            css_classes = { "flat" }
        };

        var clear_button = new Gtk.Button () {
            child = new Widgets.DynamicIcon.from_icon_name ("window-close"),
            css_classes = { "flat" }
        };

        var clear_revealer = new Gtk.Revealer () {
			transition_type = Gtk.RevealerTransitionType.CROSSFADE,
			child = clear_button
		};

        attach (button, 0, 0);
        attach (clear_revealer, 1, 0);

        datetime_picker.date_changed.connect (() => {
            datetime = datetime_picker.datetime;
            clear_revealer.reveal_child = false;
            date_changed (datetime);
        });

        var motion_gesture = new Gtk.EventControllerMotion ();
        add_controller (motion_gesture);

        motion_gesture.enter.connect (() => {
            clear_revealer.reveal_child = datetime != null;
        });

        motion_gesture.leave.connect (() => {
            clear_revealer.reveal_child = false;
        });

        clear_button.clicked.connect (() => {
            datetime = null;
            date_changed (datetime);
            clear_revealer.reveal_child = false;
            datetime_picker.reset ();
        });
    }

    public void update_from_item (Objects.Item item) {
        due_label.label = _("Schedule");
        tooltip_text = _("Schedule");
        due_image.update_icon_name ("planner-calendar");
        
        if (item.has_due) {
            due_label.label = Util.get_default ().get_relative_date_from_date (item.due.datetime);

            datetime = new GLib.DateTime.local (
                item.due.datetime.get_year (),
                item.due.datetime.get_month (),
                item.due.datetime.get_day_of_month (),
                item.due.datetime.get_hour (),
                item.due.datetime.get_minute (),
                item.due.datetime.get_second ()
            );
            
            if (Util.get_default ().is_today (item.due.datetime)) {
                due_image.update_icon_name ("planner-today");
            } else if (Util.get_default ().is_overdue (item.due.datetime)) {

            } else {
                due_image.update_icon_name ("planner-scheduled");
            }

            if (item.due.is_recurring) {
                var end_label = "";
                if (item.due.end_type == RecurrencyEndType.ON_DATE) {
                    var date_label = Util.get_default ().get_default_date_format_from_date (
                        Util.get_default ().get_format_date (
                            Utils.Datetime.get_date_from_string (item.due.recurrency_end)
                        )
                    );
                    end_label = _("until") + " " + date_label;
                } else if (item.due.end_type == RecurrencyEndType.AFTER) {
                    int count = item.due.recurrency_count;
                    end_label = _("for") + " " + "%d %s".printf (count, count > 1 ? _("times") : _("time"));
                }

                due_image.update_icon_name ("planner-repeat");
                due_label.label += " <small>%s</small>".printf (
                    Util.get_default ().get_recurrency_weeks (
                        item.due.recurrency_type,
                        item.due.recurrency_interval,
                        item.due.recurrency_weeks,
                        end_label
                    )
                ); 
            }
        }
    }

    public void reset () {
        due_label.label = _("Schedule");
        tooltip_text = _("Schedule");
        due_image.update_icon_name ("planner-calendar");
        datetime = null;
        datetime_picker.reset ();
    }
}
