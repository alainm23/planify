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

public class Widgets.ReminderPicker.ReminderPicker : Gtk.Popover {  
    public Objects.Item item { get; construct; }

    private Gtk.ListBox listbox;
    private Widgets.Calendar.Calendar calendar;
    private Widgets.DateTimePicker.TimePicker time_picker;
    private Gtk.Stack main_stack;
    private Widgets.LoadingButton submit_button;

    private Gee.HashMap<string, Dialogs.ReminderPicker.ReminderRow> reminders_map;

    public ReminderPicker (Objects.Item item) {
        Object (
            item: item,
            has_arrow: false,
            position: Gtk.PositionType.TOP
        );
    }

    construct {
        reminders_map = new Gee.HashMap<string, Dialogs.ReminderPicker.ReminderRow> ();

        var name_label = new Gtk.Label (_("Reminders")) {
            halign = Gtk.Align.START
        };

        name_label.add_css_class (Granite.STYLE_CLASS_H4_LABEL);
        name_label.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);

        var add_image = new Widgets.DynamicIcon () {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER,
        };
        add_image.size = 16;
        add_image.update_icon_name ("plus");

        var add_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.END,
            hexpand = true
        };

        add_button.child = add_image;

        add_button.add_css_class (Granite.STYLE_CLASS_FLAT);
        add_button.add_css_class ("p3");

        var header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            hexpand = true,
            margin_start = 6
        };

        header_box.append (name_label);
        header_box.append (add_button);

        listbox = new Gtk.ListBox () {
            hexpand = true
        };

        listbox.set_placeholder (get_placeholder ());
        listbox.add_css_class ("listbox-separator-3");
        listbox.add_css_class ("listbox-background");

        var listbox_scrolled = new Gtk.ScrolledWindow () {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            hexpand = true,
            vexpand = true,
            height_request = 200
        };

        listbox_scrolled.child = listbox;

        var add_reminder_button = new Gtk.Button.with_label (_("Add reminder"));
        add_reminder_button.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        content_box.append (header_box);
        content_box.append (listbox_scrolled);

        main_stack = new Gtk.Stack ();
        main_stack.vexpand = true;
        main_stack.hexpand = true;
        main_stack.vhomogeneous = false;
        main_stack.hhomogeneous = false;
        main_stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;

        main_stack.add_named (content_box, "listbox");
        main_stack.add_named (get_picker (), "picker");

        var content_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            hexpand = true,
            width_request = 200
        };

        content_grid.attach (main_stack, 0, 0);

        child = content_grid;
        add_reminders ();

        item.reminder_added.connect (add_reminder);

        Services.Database.get_default ().reminder_deleted.connect ((reminder) => {
            if (reminders_map.has_key (reminder.id_string)) {
                reminders_map[reminder.id_string].hide_destroy ();
                reminders_map.unset (reminder.id_string);
            }
        });

        add_button.clicked.connect (() => {
            time_picker.has_time = true;
            time_picker.no_time_visible = false;
            time_picker.time = new GLib.DateTime.now_local ().add_hours (1);
            main_stack.visible_child_name = "picker";
        });

        closed.connect (() => {
            main_stack.visible_child_name = "listbox";
            submit_button.is_loading = false;
        });
    }

    private void add_reminders () {
        foreach (Objects.Reminder reminder in item.reminders) {
            add_reminder (reminder);
        }
    }

    private void add_reminder (Objects.Reminder reminder) {
        if (!reminders_map.has_key (reminder.id_string)) {
            reminders_map [reminder.id_string] = new Dialogs.ReminderPicker.ReminderRow (reminder);
            listbox.append (reminders_map[reminder.id_string]);
        }
    }

    private void insert_reminder () {
        var reminder = new Objects.Reminder ();
        reminder.due.date = Util.get_default ().get_todoist_datetime_format (get_datetime_picker ());
        reminder.item_id = item.id;

        if (item.project.backend_type == BackendType.TODOIST) {
            submit_button.is_loading = true;
            Services.Todoist.get_default ().add.begin (reminder, (obj, res) => {
                TodoistResponse response = Services.Todoist.get_default ().add.end (res);
                if (response.status) {
                    reminder.id = response.data;
                } else {
                    reminder.id = Util.get_default ().generate_id ();
                }

                item.add_reminder_if_not_exists (reminder);
                main_stack.visible_child_name = "listbox";
                submit_button.is_loading = false;
            });
        } else {
            reminder.id = Util.get_default ().generate_id ();
            item.add_reminder_if_not_exists (reminder);

            main_stack.visible_child_name = "listbox";
            submit_button.is_loading = false;
        }
    }

    private GLib.DateTime get_datetime_picker () {
        return new DateTime.local (
            calendar.date.get_year (),
            calendar.date.get_month (),
            calendar.date.get_day_of_month (),
            time_picker.time.get_hour (),
            time_picker.time.get_minute (),
            0
        );
    }

    private Gtk.Widget get_picker () {
        calendar = new Widgets.Calendar.Calendar (true) {
            vexpand = true,
            hexpand = true
        };

        var calendar_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL
        };

        calendar_grid.attach (calendar, 0, 0);

        var time_label = new Gtk.Label (_("Time"));

        time_label.add_css_class ("font-bold");

        time_picker = new Widgets.DateTimePicker.TimePicker () {
            hexpand = true,
            halign = Gtk.Align.END
        };

        var time_picker_grid = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            margin_top = 12,
            margin_start = 18
        };
        time_picker_grid.append (time_label);
        time_picker_grid.append (time_picker);

        submit_button = new Widgets.LoadingButton (LoadingButtonType.LABEL, _("Add reminder")) {
            margin_top = 12,
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 6
        };
        submit_button.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);
        submit_button.add_css_class ("no-padding");
        submit_button.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);

        var main_grid = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_grid.append (calendar_grid);
        main_grid.append (time_picker_grid);
        main_grid.append (submit_button);

        submit_button.clicked.connect (insert_reminder);

        return main_grid;
    }

    private Gtk.Widget get_placeholder () {
        var message_label = new Gtk.Label (_("Your list of reminders will show up here. Add one by clicking the button.")) {
            wrap = true,
            justify = Gtk.Justification.CENTER
        };
        
        message_label.add_css_class ("dim-label");
        message_label.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);

        var grid = new Gtk.Grid () {
            margin_top = 6,
            margin_bottom = 6,
            margin_start = 6,
            margin_end = 6,
            valign = Gtk.Align.CENTER
        };

        grid.attach (message_label, 0, 0);

        return grid;
    }
}