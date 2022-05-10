/*
* Copyright © 2019 Alain M. (https://github.com/alainm23/planner)
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

public class Dialogs.ReminderPicker.ReminderPicker : Hdy.Window {
    public Objects.Item item { get; construct; }
    
    private Widgets.LoadingButton done_button;
    private Gtk.ListBox listbox;
    private Gtk.Button cancel_button;
    private Widgets.Calendar.Calendar calendar;
    private Dialogs.DateTimePicker.TimePicker time_picker;
    private Gtk.Revealer cancel_revealer;
    private Gtk.Stack main_stack;

    private Gee.HashMap<string, Dialogs.ReminderPicker.ReminderRow> reminders_map;

    public ReminderPicker (Objects.Item item) {
        Object (
            item: item,
            transient_for: (Gtk.Window) Planner.instance.main_window.get_toplevel (),
            destroy_with_parent: true,
            resizable: false
        );
    }

    construct {
        reminders_map = new Gee.HashMap<string, Dialogs.ReminderPicker.ReminderRow> ();

        var headerbar = new Hdy.HeaderBar () {
            has_subtitle = false,
            show_close_button = false,
            hexpand = true
        };
        headerbar.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        headerbar.get_style_context ().add_class ("default-decoration");

        done_button = new Widgets.LoadingButton (LoadingButtonType.LABEL, _("Done")) {
            halign = Gtk.Align.CENTER,
            valign = Gtk.Align.CENTER,
            can_focus = false
        };
        done_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        done_button.get_style_context ().add_class ("primary-color");
        done_button.get_style_context ().add_class (Granite.STYLE_CLASS_SMALL_LABEL);

        cancel_button = new Gtk.Button.with_label (_("Cancel")) {
            halign = Gtk.Align.CENTER,
            valign = Gtk.Align.CENTER,
            can_focus = false
        };
        cancel_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        cancel_button.get_style_context ().add_class (Granite.STYLE_CLASS_SMALL_LABEL);

        cancel_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.CROSSFADE,
            reveal_child = false
        };
        cancel_revealer.add (cancel_button);

        var title_label = new Gtk.Label (_("Reminders"));
        title_label.get_style_context ().add_class ("h4");

        var header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            hexpand = true,
            margin_start = 3,
            margin_end = 3
        };
        header_box.pack_start (cancel_revealer, false, false, 0);
        header_box.set_center_widget (title_label);
        header_box.pack_end (done_button, false, false, 0);

        headerbar.set_custom_title (header_box);

        var reminder_new = new Dialogs.ReminderPicker.ReminderRow.new ();
        
        listbox = new Gtk.ListBox () {
            hexpand = true
        };

        listbox.add (reminder_new);

        var listbox_scrolled = new Gtk.ScrolledWindow (null, null) {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            vscrollbar_policy = Gtk.PolicyType.NEVER,
            expand = true
        };
        listbox_scrolled.add (listbox);

        unowned Gtk.StyleContext listbox_context = listbox.get_style_context ();
        listbox_context.add_class ("picker-background");
        listbox_context.add_class ("listbox-separator-3");

        var listbox_grid = new Gtk.Grid ();
        listbox_grid.add (listbox_scrolled);

        unowned Gtk.StyleContext listbox_grid_context = listbox_grid.get_style_context ();
        listbox_grid_context.add_class ("picker-content");

        main_stack = new Gtk.Stack ();
        main_stack.expand = true;
        main_stack.homogeneous = false;
        main_stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;

        main_stack.add_named (listbox_grid, "listbox");
        main_stack.add_named (get_picker (), "picker");

        var content_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            hexpand = true,
            margin = 9,
            margin_top = 0,
            margin_bottom = 12
        };

        content_grid.add (main_stack);

        var main_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            width_request = 225
        };
        main_grid.add (headerbar);
        main_grid.add (content_grid);

        unowned Gtk.StyleContext main_grid_context = main_grid.get_style_context ();
        main_grid_context.add_class ("picker");

        add (main_grid);
        add_reminders ();

        focus_out_event.connect (() => {
            hide_destroy ();
            return false;
        });

        key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                hide_destroy ();
            }

            return false;
        });

        cancel_button.clicked.connect (() => {
            if (main_stack.visible_child_name == "picker") {
                main_stack.visible_child_name = "listbox";
                cancel_revealer.reveal_child = false;
            } else {
                hide_destroy ();
            }
        });

        reminder_new.activated.connect (() => {
            cancel_revealer.reveal_child = true;

            time_picker.has_time = true;
            time_picker.no_time_visible = false;
            time_picker.time = new GLib.DateTime.now_local ().add_hours (1);
            main_stack.visible_child_name = "picker";
        });

        done_button.clicked.connect (() => {
            if (main_stack.visible_child_name == "picker") {
                insert_reminder ();
            } else {
                hide_destroy ();
            }
        });

        item.reminder_added.connect (add_reminder);

        Planner.database.reminder_deleted.connect ((reminder) => {
            if (reminders_map.has_key (reminder.id_string)) {
                reminders_map[reminder.id_string].hide_destroy ();
                reminders_map.unset (reminder.id_string);
            }
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
            listbox.insert (reminders_map[reminder.id_string], 0);
            listbox.show_all ();
        }
    }

    private void insert_reminder () {
        var reminder = new Objects.Reminder ();
        reminder.due.date = Util.get_default ().get_todoist_datetime_format (get_datetime_picker ());
        reminder.item_id = item.id;

        if (item.project.todoist) {
            done_button.is_loading = true;
            Planner.todoist.add.begin (reminder, (obj, res) => {
                int64? id = Planner.todoist.add.end (res);
                if (id != null) {
                    reminder.id = id;
                } else {
                    reminder.id = Util.get_default ().generate_id ();
                }

                item.add_reminder_if_not_exists (reminder);

                main_stack.visible_child_name = "listbox";
                cancel_revealer.reveal_child = false;

                done_button.is_loading = false;
            });
        } else {
            reminder.id = Util.get_default ().generate_id ();
            Planner.database.insert_reminder (reminder);

            main_stack.visible_child_name = "listbox";
            cancel_revealer.reveal_child = false;
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
            expand = true
        };

        var calendar_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL
        };

        calendar_grid.add (calendar);

        unowned Gtk.StyleContext calendar_grid_context = calendar_grid.get_style_context ();
        calendar_grid_context.add_class ("picker-content");

        var time_icon = new Widgets.DynamicIcon () {
            margin_start = 3
        };
        time_icon.size = 19;
        time_icon.update_icon_name ("planner-clock");

        var time_label = new Gtk.Label (_("Time")) {
            margin_start = 6
        };
        time_label.get_style_context ().add_class ("font-weight-500");

        time_picker = new Dialogs.DateTimePicker.TimePicker ();

        var time_picker_grid = new Gtk.Grid ();
        time_picker_grid.add (time_label);
        time_picker_grid.add (time_picker);

        unowned Gtk.StyleContext time_picker_grid_context = time_picker_grid.get_style_context ();
        time_picker_grid_context.add_class ("picker-content");

        var main_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            row_spacing = 9
        };

        main_grid.add (calendar_grid);
        main_grid.add (time_picker_grid);

        return main_grid;
    }

    private void hide_destroy () {
        hide ();

        Timeout.add (500, () => {
            destroy ();
            return GLib.Source.REMOVE;
        });
    }

    public void popup () {
        move (Planner.event_bus.x_root, Planner.event_bus.y_root);
        show_all ();
    }
}