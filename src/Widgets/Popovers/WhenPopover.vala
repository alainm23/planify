public class Widgets.Popovers.WhenPopover : Gtk.Popover {
    public Gtk.Button remove_button;
    public Gtk.Button add_button;
    public Gtk.Switch reminder_switch;
    public signal void on_selected_date (GLib.DateTime duedate, bool has_reminder, GLib.DateTime reminder_datetime);
    public signal void on_selected_remove ();

    private int item_selected = 0;
    public WhenPopover (Gtk.Widget relative) {
        Object (
            relative_to: relative,
            modal: true,
            position: Gtk.PositionType.RIGHT
        );
    }

    construct {
        var title_label = new Gtk.Label ("<small>%s</small>".printf (_("When")));
        title_label.use_markup = true;
        title_label.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);

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
        tomorrow_box.pack_start (new Gtk.Image.from_icon_name ("weather-few-clouds-symbolic", Gtk.IconSize.MENU), false, false, 0);
        tomorrow_box.pack_start (new Gtk.Label (_("Tomorrow")), false, false, 0);
        tomorrow_box.pack_end (tomorrow_radio, false, false, 0);

        var tomorrow_eventbox = new Gtk.EventBox ();
        tomorrow_eventbox.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        tomorrow_eventbox.get_style_context ().add_class ("menuitem");
        tomorrow_eventbox.add (tomorrow_box);

        var calendar = new Gtk.Calendar ();
        calendar.get_style_context ().add_class ("menuitem");
        calendar.get_style_context ().add_class ("calendar-no-selected");
        calendar.expand = true;
        calendar.mark_day (new GLib.DateTime.now_local ().get_day_of_month ());

        var reminder_icon = new Gtk.Image.from_icon_name ("preferences-system-notifications", Gtk.IconSize.MENU);
        var reminder_label = new Gtk.Label ("Reminder");

        reminder_switch = new Gtk.Switch ();
        reminder_switch.get_style_context ().add_class ("active-switch");
        reminder_switch.valign = Gtk.Align.CENTER;

        var reminder_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        reminder_box.get_style_context ().add_class ("menuitem");
        reminder_box.pack_start (reminder_icon, false, false, 0);
        reminder_box.pack_start (reminder_label, false, false, 6);
        reminder_box.pack_end (reminder_switch, false, false, 0);

        var reminder_timepicker = new Granite.Widgets.TimePicker ();
        reminder_timepicker.margin_start = 6;
        reminder_timepicker.margin_end = 6;

        reminder_timepicker.activate.connect (() => {
            if (item_selected == 0) {
                var duedate_now = new GLib.DateTime.now_local ();
                on_selected_date (duedate_now, reminder_switch.active, reminder_timepicker.time);
                popdown ();
            } else if (item_selected == 1) {
                var duedate_tomorrow = new GLib.DateTime.now_local ().add_days (1);
                on_selected_date (duedate_tomorrow, reminder_switch.active, reminder_timepicker.time);
                popdown ();
            } else {
                var duedate = new GLib.DateTime.local (calendar.year, calendar.month + 1, calendar.day, 0, 0, 0);
                on_selected_date (duedate, reminder_switch.active, reminder_timepicker.time);
                popdown ();
            }
        });

        var timepicker_revealer = new Gtk.Revealer ();
        timepicker_revealer.margin_start = 3;
        timepicker_revealer.reveal_child = false;
        timepicker_revealer.add (reminder_timepicker);

        remove_button = new Gtk.Button.with_label (_("Remove"));
        remove_button.no_show_all = true;
        remove_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);

        add_button = new Gtk.Button.with_label (_("Add"));
        add_button.no_show_all = false;
        add_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        var action_grid = new Gtk.Grid ();
        action_grid.column_spacing = 6;
        action_grid.column_homogeneous = true;
        action_grid.margin_start = 9;
        action_grid.margin_end = 7;
        action_grid.margin_top = 12;
        action_grid.margin_bottom = 8;
        action_grid.add (remove_button);
        action_grid.add (add_button);

        var main_grid = new Gtk.Grid ();
        main_grid.expand = true;
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.width_request = 250;

        main_grid.add (title_label);
        main_grid.add (today_eventbox);
        main_grid.add (tomorrow_eventbox);
        main_grid.add (calendar);
        main_grid.add (reminder_box);
        main_grid.add (timepicker_revealer);
        main_grid.add (action_grid);

        add (main_grid);

        reminder_switch.notify["active"].connect(() => {
            if (reminder_switch.active) {
                timepicker_revealer.reveal_child = true;
            } else {
                timepicker_revealer.reveal_child = false;
            }
        });

        today_eventbox.event.connect ((event) => {
            if (event.type == Gdk.EventType.BUTTON_PRESS) {
                today_radio.visible = true;
                today_radio.active = true;
                item_selected = 0;

                tomorrow_radio.visible = false;
                calendar.get_style_context ().remove_class ("calendar-selected");
                calendar.get_style_context ().add_class ("calendar-no-selected");
            } else if (event.type == Gdk.EventType.@2BUTTON_PRESS) {
                var duedate_now = new GLib.DateTime.now_local ();
                on_selected_date (duedate_now, reminder_switch.active, reminder_timepicker.time);
                popdown ();
            }

            return false;
        });

        tomorrow_eventbox.event.connect ((event) => {
            if (event.type == Gdk.EventType.BUTTON_PRESS) {
                tomorrow_radio.visible = true;
                tomorrow_radio.active = true;
                item_selected = 1;

                today_radio.visible = false;
                calendar.get_style_context ().remove_class ("calendar-selected");
                calendar.get_style_context ().add_class ("calendar-no-selected");
            } else if (event.type == Gdk.EventType.@2BUTTON_PRESS) {
                var duedate_tomorrow = new GLib.DateTime.now_local ().add_days (1);
                on_selected_date (duedate_tomorrow, reminder_switch.active, reminder_timepicker.time);
                popdown ();
            }

            return false;
        });

        calendar.day_selected.connect (() => {
            calendar.get_style_context ().remove_class ("calendar-no-selected");
            calendar.get_style_context ().add_class ("calendar-selected");

            today_radio.visible = false;
            tomorrow_radio.visible = false;
            item_selected = 2;
        });

        calendar.day_selected_double_click.connect (() => {
            var duedate_now = new GLib.DateTime.now_local ();
            var duedate = new GLib.DateTime.local (calendar.year, calendar.month + 1, calendar.day, 0, 0, 0);

            if (duedate_now.compare (duedate) >= 1) {
                on_selected_date (duedate_now, reminder_switch.active, reminder_timepicker.time);
            } else {
                on_selected_date (duedate, reminder_switch.active, reminder_timepicker.time);
            }

            popdown ();
        });

        add_button.clicked.connect (() => {
            if (item_selected == 0) {
                var duedate_now = new GLib.DateTime.now_local ();
                on_selected_date (duedate_now, reminder_switch.active, reminder_timepicker.time);
                popdown ();
            } else if (item_selected == 1) {
                var duedate_tomorrow = new GLib.DateTime.now_local ().add_days (1);
                on_selected_date (duedate_tomorrow, reminder_switch.active, reminder_timepicker.time);
                popdown ();
            } else {
                var duedate = new GLib.DateTime.local (calendar.year, calendar.month + 1, calendar.day, 0, 0, 0);
                on_selected_date (duedate, reminder_switch.active, reminder_timepicker.time);
                popdown ();
            }
        });

        remove_button.clicked.connect (() => {
            popdown ();
            remove_button.visible = false;
            on_selected_remove ();
        });

        today_eventbox.enter_notify_event.connect ((event) => {
            today_eventbox.get_style_context ().add_class ("duedate-item");
            return false;
        });

        today_eventbox.leave_notify_event.connect ((event) => {
            if (event.detail == Gdk.NotifyType.INFERIOR) {
                return false;
            }

            today_eventbox.get_style_context ().remove_class ("duedate-item");
            return false;
        });

        tomorrow_eventbox.enter_notify_event.connect ((event) => {
            tomorrow_eventbox.get_style_context ().add_class ("duedate-item");

            return false;
        });

        tomorrow_eventbox.leave_notify_event.connect ((event) => {
            if (event.detail == Gdk.NotifyType.INFERIOR) {
                return false;
            }

            tomorrow_eventbox.get_style_context ().remove_class ("duedate-item");
            return false;
        });
    }
}
