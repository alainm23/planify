/*
* Copyright © 2019 Alain M. (https://github.com/alainm23/planner)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
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
* Authored by: Alain M. <alain23@protonmail.com>
*/

public class Widgets.Popovers.WhenPopover : Gtk.Popover {
    private Gtk.Stack main_stack;

    public Gtk.Button remove_button;
    public Gtk.Switch reminder_switch;
    public Widgets.TimePicker reminder_timepicker;
    public signal void on_selected_date (GLib.DateTime duedate, bool has_reminder, GLib.DateTime reminder_datetime);
    public signal void on_selected_remove ();

    private int item_selected = 0;
    private DateTime selected_date;
    public WhenPopover (Gtk.Widget relative) {
        Object (
            relative_to: relative,
            modal: true,
            position: Gtk.PositionType.RIGHT
        );
    }

    construct {
        var mode_button = new Granite.Widgets.ModeButton ();
        mode_button.hexpand = true;
        mode_button.margin = 6;
        mode_button.valign = Gtk.Align.CENTER;

        mode_button.append_icon ("office-calendar-symbolic", Gtk.IconSize.MENU);
        mode_button.append_icon ("notification-symbolic", Gtk.IconSize.MENU);

        mode_button.selected = 0;

        main_stack = new Gtk.Stack ();
        main_stack.expand = true;
        main_stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;

        main_stack.add_named (get_when_widget (), "when");
        main_stack.add_named (get_reminder_widget (), "reminder");

        remove_button = new Gtk.Button.with_label (_("Clear"));
        remove_button.margin = 6;
        remove_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);

        var main_grid = new Gtk.Grid ();
        main_grid.expand = true;
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.width_request = 250;

        main_grid.add (mode_button);
        main_grid.add (main_stack);
        main_grid.add (remove_button);

        add (main_grid);

        mode_button.mode_changed.connect ((widget) => {
            if (mode_button.selected == 0) {
                main_stack.visible_child_name = "when";
            } else {
                main_stack.visible_child_name = "reminder";
            }
        });

        remove_button.clicked.connect (() => {
            remove_button.visible = false;
            reminder_switch.active = false;

            on_selected_remove ();

            popdown ();
        });
    }

    private Gtk.Widget get_when_widget () {
        var today_radio = new Gtk.RadioButton.with_label_from_widget (null, "");
        today_radio.no_show_all = true;

        var today_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        today_box.margin = 6;
        today_box.pack_start (new Gtk.Image.from_icon_name ("planner-when", Gtk.IconSize.MENU), false, false, 0);
        today_box.pack_start (new Gtk.Label (_("Today")), false, false, 0);
        today_box.pack_end (today_radio, false, false, 0);

        var today_eventbox = new Gtk.EventBox ();
        today_eventbox.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        today_eventbox.get_style_context ().add_class ("menuitem");
        today_eventbox.add (today_box);

        var tomorrow_radio = new Gtk.RadioButton.with_label_from_widget (today_radio, "");
        tomorrow_radio.no_show_all = true;

        var tomorrow_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        tomorrow_box.margin = 6;
        tomorrow_box.pack_start (new Gtk.Image.from_icon_name ("planner-upcoming", Gtk.IconSize.MENU), false, false, 0);
        tomorrow_box.pack_start (new Gtk.Label (_("Tomorrow")), false, false, 0);
        tomorrow_box.pack_end (tomorrow_radio, false, false, 0);

        var tomorrow_eventbox = new Gtk.EventBox ();
        tomorrow_eventbox.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        tomorrow_eventbox.get_style_context ().add_class ("menuitem");
        tomorrow_eventbox.add (tomorrow_box);

        var calendar = new Widgets.Calendar.Calendar (true);
        calendar.hexpand = true;

        var main_grid = new Gtk.Grid ();
        main_grid.expand = true;
        main_grid.orientation = Gtk.Orientation.VERTICAL;

        main_grid.add (today_eventbox);
        main_grid.add (tomorrow_eventbox);
        main_grid.add (calendar);

        today_eventbox.event.connect ((event) => {
            if (event.type == Gdk.EventType.BUTTON_PRESS) {
                today_radio.visible = true;
                today_radio.active = true;
                item_selected = 0;

                tomorrow_radio.visible = false;

                var duedate_now = new GLib.DateTime.now_local ();
                on_selected_date (duedate_now, reminder_switch.active, reminder_timepicker.time);
            }

            return false;
        });

        tomorrow_eventbox.event.connect ((event) => {
            if (event.type == Gdk.EventType.BUTTON_PRESS) {
                tomorrow_radio.visible = true;
                tomorrow_radio.active = true;
                item_selected = 1;

                today_radio.visible = false;

                var duedate_tomorrow = new GLib.DateTime.now_local ().add_days (1);
                on_selected_date (duedate_tomorrow, reminder_switch.active, reminder_timepicker.time);
            }

            return false;
        });

        calendar.selection_changed.connect ((date) => {
            selected_date = date;

            today_radio.visible = false;
            tomorrow_radio.visible = false;
            item_selected = 2;

            on_selected_date (date, reminder_switch.active, reminder_timepicker.time);
        });

        today_eventbox.enter_notify_event.connect ((event) => {
            today_eventbox.get_style_context ().add_class ("when-item");
            return false;
        });

        today_eventbox.leave_notify_event.connect ((event) => {
            if (event.detail == Gdk.NotifyType.INFERIOR) {
                return false;
            }

            today_eventbox.get_style_context ().remove_class ("when-item");
            return false;
        });

        tomorrow_eventbox.enter_notify_event.connect ((event) => {
            tomorrow_eventbox.get_style_context ().add_class ("when-item");

            return false;
        });

        tomorrow_eventbox.leave_notify_event.connect ((event) => {
            if (event.detail == Gdk.NotifyType.INFERIOR) {
                return false;
            }

            tomorrow_eventbox.get_style_context ().remove_class ("when-item");
            return false;
        });

        return main_grid;
    }

    private Gtk.Widget get_reminder_widget () {
        var reminder_icon = new Gtk.Image.from_icon_name ("planner-notification-symbolic", Gtk.IconSize.MENU);
        var reminder_label = new Gtk.Label ("Reminder");

        reminder_switch = new Gtk.Switch ();
        reminder_switch.get_style_context ().add_class ("active-switch");
        reminder_switch.valign = Gtk.Align.CENTER;

        var reminder_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        reminder_box.margin_end = 3;
        reminder_box.get_style_context ().add_class ("menuitem");
        reminder_box.pack_start (reminder_icon, false, false, 0);
        reminder_box.pack_start (reminder_label, false, false, 6);
        reminder_box.pack_end (reminder_switch, false, false, 0);

        reminder_timepicker = new Widgets.TimePicker ();
        reminder_timepicker.margin_start = 6;
        reminder_timepicker.margin_end = 6;

        var timepicker_revealer = new Gtk.Revealer ();
        timepicker_revealer.margin_start = 3;
        timepicker_revealer.reveal_child = false;
        timepicker_revealer.add (reminder_timepicker);

        var main_grid = new Gtk.Grid ();
        main_grid.expand = true;
        main_grid.orientation = Gtk.Orientation.VERTICAL;

        main_grid.add (reminder_box);
        main_grid.add (timepicker_revealer);

        reminder_switch.notify["active"].connect(() => {
            if (reminder_switch.active) {
                timepicker_revealer.reveal_child = true;

                if (item_selected == 0) {
                    var duedate_now = new GLib.DateTime.now_local ();
                    on_selected_date (duedate_now, reminder_switch.active, reminder_timepicker.time);
                } else if (item_selected == 1) {
                    var duedate_tomorrow = new GLib.DateTime.now_local ().add_days (1);
                    on_selected_date (duedate_tomorrow, reminder_switch.active, reminder_timepicker.time);
                } else {
                    if (selected_date == null) {
                        on_selected_date (new GLib.DateTime.now_local (), reminder_switch.active, reminder_timepicker.time);
                    } else {
                        on_selected_date (selected_date, reminder_switch.active, reminder_timepicker.time);
                    }
                }
            } else {
                timepicker_revealer.reveal_child = false;
                on_selected_date (new GLib.DateTime.now_local (), reminder_switch.active, reminder_timepicker.time);
            }
        });

        reminder_switch.notify["active"].connect(() => {
            if (reminder_switch.active) {
                timepicker_revealer.reveal_child = true;

                if (item_selected == 0) {
                    var duedate_now = new GLib.DateTime.now_local ();
                    on_selected_date (duedate_now, reminder_switch.active, reminder_timepicker.time);
                } else if (item_selected == 1) {
                    var duedate_tomorrow = new GLib.DateTime.now_local ().add_days (1);
                    on_selected_date (duedate_tomorrow, reminder_switch.active, reminder_timepicker.time);
                } else {
                    if (selected_date == null) {
                        on_selected_date (new GLib.DateTime.now_local (), reminder_switch.active, reminder_timepicker.time);
                    } else {
                        on_selected_date (selected_date, reminder_switch.active, reminder_timepicker.time);
                    }
                }
            } else {
                timepicker_revealer.reveal_child = false;
                on_selected_date (new GLib.DateTime.now_local (), reminder_switch.active, reminder_timepicker.time);
            }
        });

        reminder_timepicker.time_entry.activate.connect (() => {
            if (item_selected == 0) {
                var duedate_now = new GLib.DateTime.now_local ();
                on_selected_date (duedate_now, reminder_switch.active, reminder_timepicker.time);
            } else if (item_selected == 1) {
                var duedate_tomorrow = new GLib.DateTime.now_local ().add_days (1);
                on_selected_date (duedate_tomorrow, reminder_switch.active, reminder_timepicker.time);
            } else {
                if (selected_date == null) {
                    on_selected_date (new GLib.DateTime.now_local (), reminder_switch.active, reminder_timepicker.time);
                } else {
                    on_selected_date (selected_date, reminder_switch.active, reminder_timepicker.time);
                }
            }

            popdown ();
        });

        reminder_timepicker.time_entry.changed.connect (() => {
            if (item_selected == 0) {
                var duedate_now = new GLib.DateTime.now_local ();
                on_selected_date (duedate_now, reminder_switch.active, reminder_timepicker.time);
            } else if (item_selected == 1) {
                var duedate_tomorrow = new GLib.DateTime.now_local ().add_days (1);
                on_selected_date (duedate_tomorrow, reminder_switch.active, reminder_timepicker.time);
            } else {
                if (selected_date == null) {
                    on_selected_date (new GLib.DateTime.now_local (), reminder_switch.active, reminder_timepicker.time);
                } else {
                    on_selected_date (selected_date, reminder_switch.active, reminder_timepicker.time);
                }
            }
        });

        return main_grid;
    }
}