/*
 * Copyright © 2025 Alain M. (https://github.com/alainm23/planify)
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
    public bool is_creating { get; construct; }

    private Layouts.HeaderItem reminders_view;
    private Widgets.Calendar.Calendar calendar;
    private Widgets.DateTimePicker.TimePicker time_picker;
    private Adw.NavigationView navigation_view;
    private Widgets.LoadingButton submit_button;

    private Gee.HashMap<string, Widgets.ReminderPicker.ReminderRow> reminders_map = new Gee.HashMap<string, Widgets.ReminderPicker.ReminderRow> ();
    private Gee.HashMap<string, Adw.NavigationPage> pages_map = new Gee.HashMap<string, Adw.NavigationPage> ();
    private Gee.HashMap<ulong, weak GLib.Object> signal_map = new Gee.HashMap<ulong, weak GLib.Object> ();

    public signal void reminder_added (Objects.Reminder reminder);
    public signal void reminder_deleted (Objects.Reminder reminder);

    public bool suggestions_view {
        set {
            if (value) {
                navigation_view.push (build_page ("suggestions"));
            } else {
                navigation_view.push (build_page ("main"));
            }
        }
    }

    public bool has_reminders {
        get {
            return reminders_map.size > 0;
        }
    }

    public ReminderPicker (bool is_creating = false) {
        Object (
            has_arrow: false,
            is_creating: is_creating,
            position: Gtk.PositionType.BOTTOM,
            width_request: 275
        );
    }

    ~ReminderPicker () {
        print ("Destroying - Widgets.ReminderPicker.ReminderPicker\n");
    }

    construct {
        calendar = new Widgets.Calendar.Calendar () {
            vexpand = true,
            hexpand = true
        };


        time_picker = new Widgets.DateTimePicker.TimePicker () {
            hexpand = true,
            halign = Gtk.Align.END
        };

        navigation_view = new Adw.NavigationView ();
        navigation_view.add (build_page ("main"));

        child = navigation_view;

        signal_map[closed.connect (() => {
            navigation_view.pop ();
            submit_button.is_loading = false;
        })] = this;
    }

    private Adw.NavigationPage build_page (string page) {
        if (pages_map.has_key (page)) {
            return pages_map[page];
        }

        if (page == "main") {
            pages_map[page] = build_main_page ();
        } else if (page == "picker") {
            pages_map[page] = build_picker_page ();
        } else if (page == "suggestions") {
            pages_map[page] = build_suggestions_page ();
        }


        return pages_map[page];
    }

    private Adw.NavigationPage build_main_page () {
        reminders_view = new Layouts.HeaderItem (_("Reminders"));
        reminders_view.reveal_child = true;
        reminders_view.placeholder_message = _("Your list of reminders will show up here. Add one by clicking the '+' button.");

        var add_button = new Gtk.Button.from_icon_name ("plus-large-symbolic") {
            valign = Gtk.Align.CENTER,
            css_classes = { "flat", "header-item-button" }
        };

        reminders_view.add_widget_end (add_button);

        var scrolled_window = new Gtk.ScrolledWindow () {
            hexpand = true,
            vexpand = true,
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            vscrollbar_policy = Gtk.PolicyType.NEVER,
            child = reminders_view
        };

        signal_map[add_button.clicked.connect (() => {
            calendar.date = new GLib.DateTime.now_local ();

            time_picker.has_time = true;
            time_picker.no_time_visible = false;
            time_picker.time = new GLib.DateTime.now_local ().add_hours (1);

            navigation_view.push (build_page ("picker"));
        })] = add_button;

        return new Adw.NavigationPage (scrolled_window, "listbox");
    }

    private Adw.NavigationPage build_picker_page () {
        var time_icon = new Gtk.Image.from_icon_name ("clock-symbolic");

        var time_label = new Gtk.Label (_("Time")) {
            css_classes = { "font-weight-500" }
        };

        var time_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            hexpand = true,
            margin_top = 6,
            margin_start = 12
        };

        time_box.append (time_icon);
        time_box.append (time_label);
        time_box.append (time_picker);

        submit_button = new Widgets.LoadingButton (LoadingButtonType.LABEL, _("Add Reminder")) {
            margin_top = 12,
            margin_start = 3,
            margin_end = 3,
            margin_bottom = 6,
            css_classes = { "suggested-action" }
        };

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.append (calendar);
        main_box.append (new Gtk.Separator (Gtk.Orientation.VERTICAL) {
            margin_start = 9,
            margin_end = 6,
            margin_top = 6,
            margin_bottom = 6
        });
        main_box.append (time_box);
        main_box.append (submit_button);

        var toolbar_view = new Adw.ToolbarView () {
            content = main_box
        };

        toolbar_view.add_top_bar (new Adw.HeaderBar () {
            show_title = false,
            show_end_title_buttons = false,
        });

        signal_map[submit_button.clicked.connect (insert_reminder)] = submit_button;
        signal_map[time_picker.activated.connect (insert_reminder)] = time_picker;

        return new Adw.NavigationPage (toolbar_view, "picker");
    }

    private Adw.NavigationPage build_suggestions_page () {
        var 5_m_item = new Widgets.ContextMenu.MenuItem (_("In 5 minutes"), "delay-symbolic");
        var 15_m_item = new Widgets.ContextMenu.MenuItem (_("In 15 minutes"), "delay-symbolic");
        var 30_m_item = new Widgets.ContextMenu.MenuItem (_("In 30 minutes"), "delay-symbolic");
        var 1_h_item = new Widgets.ContextMenu.MenuItem (_("In 1 hour"), "delay-symbolic");
        var 3_h_item = new Widgets.ContextMenu.MenuItem (_("In 3 hours"), "delay-symbolic");
        var 6_h_item = new Widgets.ContextMenu.MenuItem (_("In 6 hours"), "delay-symbolic");

        var menu_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        menu_box.margin_top = menu_box.margin_bottom = 3;
        menu_box.append (5_m_item);
        menu_box.append (15_m_item);
        menu_box.append (30_m_item);
        menu_box.append (1_h_item);
        menu_box.append (3_h_item);
        menu_box.append (6_h_item);

        signal_map[5_m_item.clicked.connect (() => {
            var datetime = new GLib.DateTime.now_local ().add_minutes (5);
            _insert_reminder (datetime, datetime, true);
        })] = 5_m_item;

        signal_map[15_m_item.clicked.connect (() => {
            var datetime = new GLib.DateTime.now_local ().add_minutes (15);
            _insert_reminder (datetime, datetime, true);
        })] = 15_m_item;

        signal_map[30_m_item.clicked.connect (() => {
            var datetime = new GLib.DateTime.now_local ().add_minutes (30);
            _insert_reminder (datetime, datetime, true);
        })] = 30_m_item;

        signal_map[1_h_item.clicked.connect (() => {
            var datetime = new GLib.DateTime.now_local ().add_hours (1);
            _insert_reminder (datetime, datetime, true);
        })] = 1_h_item;

        signal_map[3_h_item.clicked.connect (() => {
            var datetime = new GLib.DateTime.now_local ().add_hours (3);
            _insert_reminder (datetime, datetime, true);
        })] = 3_h_item;

        signal_map[6_h_item.clicked.connect (() => {
            var datetime = new GLib.DateTime.now_local ().add_hours (6);
            _insert_reminder (datetime, datetime, true);
        })] = 6_h_item;

        return new Adw.NavigationPage (menu_box, "suggestions");
    }

    private void insert_reminder () {
        if (calendar.date == null || time_picker.time == null) {
            return;
        }

        _insert_reminder (calendar.date, time_picker.time);
    }

    private void _insert_reminder (GLib.DateTime date, GLib.DateTime time, bool is_suggestion = false) {
        var reminder = new Objects.Reminder ();
        reminder.due.date = Utils.Datetime.get_todoist_datetime_format (
            Utils.Datetime.get_datetime_no_seconds (date, time)
        );

        reminder_added (reminder);

        if (is_suggestion) {
            popdown ();
            return;
        }

        navigation_view.pop ();
        submit_button.is_loading = false;
    }

    public void set_reminders (Gee.ArrayList<Objects.Reminder> reminders) {
        clear ();

        foreach (Objects.Reminder reminder in reminders) {
            add_reminder (reminder);
        }
    }

    public void clear () {
        reminders_view.clear ();
        reminders_map.clear ();
    }

    public void add_reminder (Objects.Reminder reminder) {
        if (!reminders_map.has_key (reminder.id)) {
            reminders_map[reminder.id] = new Widgets.ReminderPicker.ReminderRow (reminder);

            signal_map[reminders_map[reminder.id].deleted.connect (() => {
                if (!is_creating) {
                    reminder.delete ();
                } else {
                    delete_reminder (reminder);
                }

                reminder_deleted (reminder);
            })] = reminders_map[reminder.id];

            reminders_view.add_child (reminders_map[reminder.id]);
        }
    }

    public void delete_reminder (Objects.Reminder reminder) {
        if (reminders_map.has_key (reminder.id)) {
            reminders_map[reminder.id].hide_destroy ();
            reminders_map.unset (reminder.id);
        }
    }

    public Gee.ArrayList<Objects.Reminder> reminders () {
        Gee.ArrayList<Objects.Reminder> return_value = new Gee.ArrayList<Objects.Reminder> ();

        foreach (Widgets.ReminderPicker.ReminderRow row in reminders_map.values) {
            return_value.add (row.reminder);
        }

        return return_value;
    }

    public void clean_up () {
        foreach (var entry in signal_map.entries) {
            entry.value.disconnect (entry.key);
        }

        signal_map.clear ();

        if (calendar != null) {
            calendar.clean_up ();
        }

        if (time_picker != null) {
            time_picker.clean_up ();
        }

        foreach (Gtk.ListBoxRow row in reminders_view.get_children ()) {
            (row as Widgets.ReminderPicker.ReminderRow).clean_up ();
        }
    }
}
