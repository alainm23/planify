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
    public bool is_board { get; construct; }
    public string label { get; construct; }

    private Gtk.Label due_label;
    
    private Gtk.Box schedule_box;
    private Gtk.Image due_image;
    private Widgets.DateTimePicker.DateTimePicker datetime_picker;
    private Gtk.Revealer clear_revealer;

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

    public bool visible_clear_button {
        set {
            clear_revealer.visible = value;
        }
    }

    public signal void date_changed (GLib.DateTime? date);

    public ScheduleButton (string label = _("Schedule")) {
        Object (
            is_board: false,
            valign: Gtk.Align.CENTER,
            tooltip_text: label,
            label: label
        );
    }

    public ScheduleButton.for_board (string label = _("Schedule")) {
        Object (
            is_board: true,
            tooltip_text: label,
            label: label
        );
    }

    construct {
        if (is_board) {
            build_card_ui ();
        } else {
            build_ui ();
        }
    }

    private void build_ui () {
        datetime_picker = new Widgets.DateTimePicker.DateTimePicker ();

        due_image = new Gtk.Image ();
        due_image.icon_name = "month-symbolic";

        due_label = new Gtk.Label (label) {
            xalign = 0,
            use_markup = true,
            ellipsize = Pango.EllipsizeMode.END
        };

        schedule_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3);
        schedule_box.append (due_image);
        schedule_box.append (due_label);

        var button = new Gtk.MenuButton () {
            child = schedule_box,
            popover = datetime_picker,
            css_classes = { "flat" }
        };

        var clear_button = new Gtk.Button.from_icon_name ("window-close") {
            css_classes = { "flat" }
        };

        clear_revealer = new Gtk.Revealer () {
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

    private void build_card_ui () {
        due_image = new Gtk.Image.from_icon_name ("month-symbolic");

        var title_label = new Gtk.Label (label) {
            halign = START,
            css_classes = { "title-4", "caption" }
        };

        due_label = new Gtk.Label (_("Set a Due Date")) {
            xalign = 0,
            use_markup = true,
            halign = START,
            ellipsize = Pango.EllipsizeMode.END,
            css_classes = { "caption" }
        };

        var card_grid = new Gtk.Grid () {
            column_spacing = 12,
            margin_start = 12,
            margin_end = 6,
            margin_top = 6,
            margin_bottom = 6,
            vexpand = true,
            hexpand = true
        };
        card_grid.attach (due_image, 0, 0, 1, 2);
        card_grid.attach (title_label, 1, 0, 1, 1);
        card_grid.attach (due_label, 1, 1, 1, 1);

        datetime_picker = new Widgets.DateTimePicker.DateTimePicker () {
            position = Gtk.PositionType.BOTTOM,
            has_arrow = true
        };
        datetime_picker.set_parent (card_grid);

        css_classes = { "card", "activatable" };
        attach (card_grid, 0, 0);
        hexpand = true;
        vexpand = true;

        var click_gesture = new Gtk.GestureClick ();
        card_grid.add_controller (click_gesture);
        click_gesture.pressed.connect ((n_press, x, y) => {
            datetime_picker.show ();
        });

        datetime_picker.date_changed.connect (() => {
            datetime = datetime_picker.datetime;
            date_changed (datetime);
        });
    }

    public void update_from_item (Objects.Item item) {
        if (is_board) {
            due_label.label = _("Set a Due Date");
            tooltip_text = label;
            due_image.icon_name = "month-symbolic";
        } else {
            due_label.label = label;
            tooltip_text = label;
            due_image.icon_name = "month-symbolic";
        }

        if (!item.has_due) {
            return;
        }

        due_label.label = Utils.Datetime.get_relative_date_from_date (item.due.datetime);
        due_label.tooltip_text = due_label.label;
    
        datetime = new GLib.DateTime.local (
            item.due.datetime.get_year (),
            item.due.datetime.get_month (),
            item.due.datetime.get_day_of_month (),
            item.due.datetime.get_hour (),
            item.due.datetime.get_minute (),
            item.due.datetime.get_second ()
        );
        
        if (Utils.Datetime.is_today (item.due.datetime)) {
            due_image.icon_name = "star-outline-thick-symbolic";
        } else if (Utils.Datetime.is_tomorrow (item.due.datetime)) {
            due_image.icon_name = "today-calendar-symbolic";
        } else if (Utils.Datetime.is_overdue (item.due.datetime)) {
            due_image.icon_name = "month-symbolic";
        } else {
            due_image.icon_name = "month-symbolic";
        }

        if (item.due.is_recurring) {
            var end_label = "";
            if (item.due.end_type == RecurrencyEndType.ON_DATE) {
                var date_label = Utils.Datetime.get_default_date_format_from_date (
                    Utils.Datetime.get_date_only (
                        Utils.Datetime.get_date_from_string (item.due.recurrency_end)
                    )
                );
                end_label = _("until") + " " + date_label;
            } else if (item.due.end_type == RecurrencyEndType.AFTER) {
                int count = item.due.recurrency_count;
                end_label = _("for") + " " + "%d %s".printf (count, count > 1 ? _("times") : _("time"));
            }

            due_image.icon_name = "playlist-repeat-symbolic";
            
            string repeat_text = Utils.Datetime.get_recurrency_weeks (
                item.due.recurrency_type,
                item.due.recurrency_interval,
                item.due.recurrency_weeks,
                end_label
            ).down ();

            due_label.label += ", <small>%s</small>".printf (repeat_text);
            due_label.tooltip_text = repeat_text;
        }
    }

    public void reset () {
        due_label.label = label;
        tooltip_text = label;
        due_image.icon_name = "month-symbolic";
        datetime = null;
        datetime_picker.reset ();
    }
}
