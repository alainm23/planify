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

public class Widgets.ReminderButton : Gtk.ToggleButton {
    public Objects.Item item { get; construct; }

    private Gtk.Popover popover = null;
    private Gtk.Stack stack;
    private Gtk.Label reminder_label;
    private Gtk.Revealer label_revealer;
    private Widgets.Calendar.Calendar calendar;
    private Granite.Widgets.TimePicker time_picker;

    private Objects.Reminder? first_reminder = null;

    public ReminderButton (Objects.Item item) {
        Object (
            item: item
        );
    }

    construct {
        first_reminder = Planner.database.get_first_reminders_by_item (item.id);
        tooltip_text = _("Reminders");

        get_style_context ().add_class ("flat");
        get_style_context ().add_class ("item-action-button");

        var reminder_image = new Gtk.Image ();
        reminder_image.valign = Gtk.Align.CENTER;
        reminder_image.gicon = new ThemedIcon ("alarm-symbolic");
        reminder_image.pixel_size = 16;
        reminder_image.margin_bottom = 1;

        reminder_label = new Gtk.Label (null);
        reminder_label.get_style_context ().add_class ("pane-item");
        reminder_label.margin_bottom = 1;
        reminder_label.use_markup = true;

        label_revealer = new Gtk.Revealer ();
        label_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
        label_revealer.add (reminder_label);

        var main_grid = new Gtk.Grid ();
        main_grid.halign = Gtk.Align.CENTER;
        main_grid.valign = Gtk.Align.CENTER;
        main_grid.add (reminder_image);
        main_grid.add (label_revealer);

        add (main_grid);

        check_reminder_label (first_reminder);

        Planner.utils.clock_format_changed.connect (() => {
            check_reminder_label (first_reminder);
        });

        this.toggled.connect (() => {
            if (this.active) {
                if (popover == null) {
                    create_popover ();
                }

                popover.popup ();
            }
        });

        Planner.database.reminder_deleted.connect ((id) => {
            if (first_reminder != null && first_reminder.id == id) {
                first_reminder = Planner.database.get_first_reminders_by_item (item.id);
                check_reminder_label (first_reminder);
            }
        });
    }

    public void check_reminder_label (Objects.Reminder? first_reminder) {
        if (first_reminder != null) {
            reminder_label.label = "%s %s".printf (
                Planner.utils.get_relative_date_from_string (first_reminder.due_date),
                Planner.utils.get_relative_time_from_string (first_reminder.due_date)
            );
            label_revealer.reveal_child = true;
        } else {
            reminder_label.label = "";
            label_revealer.reveal_child = false;
        }
    }

    private void create_popover () {
        popover = new Gtk.Popover (this);
        popover.position = Gtk.PositionType.BOTTOM;

        stack = new Gtk.Stack ();
        stack.expand = true;
        stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;

        stack.add_named (get_reminders_widget (), "list");
        stack.add_named (get_reminder_new_widget (), "new");

        Timeout.add (125, () => {
            stack.visible_child_name = "list";
            return false;
        });

        var popover_grid = new Gtk.Grid ();
        popover_grid.width_request = 235;
        popover_grid.orientation = Gtk.Orientation.VERTICAL;
        popover_grid.add (stack);
        popover_grid.show_all ();

        popover.add (popover_grid);

        popover.closed.connect (() => {
            this.active = false;
        });
    }

    private Gtk.Widget get_reminders_widget () {
        var listbox = new Gtk.ListBox ();
        listbox.activate_on_single_click = true;
        listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        listbox.expand = true;
        listbox.set_sort_func ((row1, row2) => {
            var r1 = (Widgets.ReminderRow) row1;
            var r2 = (Widgets.ReminderRow) row2;

            return r1.reminder.datetime.compare (r2.reminder.datetime);
        });

        var listbox_scrolled = new Gtk.ScrolledWindow (null, null);
        listbox_scrolled.expand = true;
        listbox_scrolled.add (listbox);

        var add_icon = new Gtk.Image ();
        add_icon.valign = Gtk.Align.CENTER;
        add_icon.gicon = new ThemedIcon ("list-add-symbolic");
        add_icon.pixel_size = 14;

        var add_button = new Gtk.Button ();
        add_button.margin_bottom = 6;
        add_button.image = add_icon;
        add_button.valign = Gtk.Align.CENTER;
        add_button.halign = Gtk.Align.START;
        add_button.always_show_image = true;
        add_button.can_focus = false;
        add_button.label = _("Add reminder");
        add_button.get_style_context ().add_class ("flat");
        add_button.get_style_context ().add_class ("font-bold");

        var grid = new Gtk.Grid ();
        grid.margin_top = 3;
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.add (listbox_scrolled);
        grid.add (add_button);

        add_reminders (listbox);

        add_button.clicked.connect (() => {
            stack.visible_child_name = "new";
        });

        Planner.database.reminder_added.connect ((reminder) => {
            var row = new Widgets.ReminderRow (reminder);
            listbox.add (row);
            listbox.show_all ();

            first_reminder = Planner.database.get_first_reminders_by_item (item.id);
            check_reminder_label (first_reminder);
        });

        return grid;
    }

    private Gtk.Widget get_reminder_new_widget () {
        calendar = new Widgets.Calendar.Calendar ();
        calendar.margin_bottom = 0;
        calendar.margin_top = 0;
        calendar.margin_end = 9;
        calendar.hexpand = true;

        var time_header = new Granite.HeaderLabel (_("Time:"));
        time_header.margin_start = 9;

        time_picker = new Granite.Widgets.TimePicker ();
        time_picker.margin_start = 9;
        time_picker.margin_end = 9;

        var cancel_button = new Gtk.Button.with_label (_("Cancel"));

        var add_button = new Gtk.Button.with_label (_("Add"));
        add_button.sensitive = false;
        add_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        var action_grid = new Gtk.Grid ();
        action_grid.margin = 9;
        action_grid.column_spacing = 9;
        action_grid.column_homogeneous = true;
        action_grid.add (cancel_button);
        action_grid.add (add_button);

        var grid = new Gtk.Grid ();
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.add (calendar);
        grid.add (time_header);
        grid.add (time_picker);
        grid.add (action_grid);
        grid.show_all ();

        cancel_button.clicked.connect (() => {
            stack.visible_child_name = "list";
        });

        calendar.selection_changed.connect ((date) => {
            add_button.sensitive = true;
        });

        time_picker.activate.connect (() => {
            add_reminder ();
        });

        add_button.clicked.connect (() => {
            add_reminder ();
        });

        return grid;
    }

    private void add_reminder () {
        var date = new GLib.DateTime.local (
            calendar.date.get_year (),
            calendar.date.get_month (),
            calendar.date.get_day_of_month (),
            time_picker.time.get_hour (),
            time_picker.time.get_minute (),
            0
        );

        var reminder = new Objects.Reminder ();
        reminder.due_date = date.to_string ();
        reminder.item_id = item.id;

        if (Planner.database.insert_reminder (reminder)) {
            stack.visible_child_name = "list";
        }
    }

    private void add_reminders (Gtk.ListBox listbox) {
        foreach (var item in Planner.database.get_reminders_by_item (item.id)) {
            var row = new Widgets.ReminderRow (item);

            listbox.add (row);
            listbox.show_all ();
        }
    }
}
