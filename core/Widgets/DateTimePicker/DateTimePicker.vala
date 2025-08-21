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

public class Widgets.DateTimePicker.DateTimePicker : Gtk.Popover {
    // Constants
    private const int WIDGET_WIDTH = 275;
    private const string[] QUICK_DATE_PAGES = { "main", "calendar", "repeat", "repeat-config" };

    // Navigation
    private Adw.NavigationView navigation_view;
    private Gee.HashMap<string, Adw.NavigationPage> pages_map;

    // Main page widgets
    private DateQuickItems quick_items;
    private Widgets.DateTimePicker.TimePicker time_picker;
    private Widgets.Calendar.Calendar calendar_view;
    private Widgets.ContextMenu.MenuItem repeat_item;
    private Gtk.Revealer action_revealer;

    // State
    private Objects.DueDate _duedate;

    // Properties
    public Objects.DueDate duedate {
        get {
            _duedate = get_current_duedate ();
            return _duedate;
        }

        set {
            set_current_duedate (value);
        }
    }

    public bool visible_no_date {
        set {
            action_revealer.reveal_child = value;
        }
    }

    // Signals
    public signal void duedate_changed ();

    public DateTimePicker () {
        Object (
            has_arrow: false,
            position: Gtk.PositionType.RIGHT,
            width_request: WIDGET_WIDTH
        );
    }

    construct {
        pages_map = new Gee.HashMap<string, Adw.NavigationPage> ();
        quick_items = new DateQuickItems ();

        setup_navigation ();
        connect_signals ();
    }

    private void setup_navigation () {
        navigation_view = new Adw.NavigationView ();
        navigation_view.add (get_or_create_page ("main"));
        child = navigation_view;

        closed.connect (() => {
            navigation_view.pop_to_page (get_or_create_page ("main"));
        });
    }

    private void connect_signals () {
        quick_items.date_selected.connect (on_quick_date_selected);
        quick_items.calendar_requested.connect (() => {
            navigation_view.push (get_or_create_page ("calendar"));
        });
        quick_items.repeat_requested.connect (() => {
            navigation_view.push (get_or_create_page ("repeat"));
        });
    }

    private Adw.NavigationPage get_or_create_page (string page_id) {
        if (!pages_map.has_key (page_id)) {
            pages_map[page_id] = create_page (page_id);
        }
        return pages_map[page_id];
    }

    private Adw.NavigationPage create_page (string page_id) {
        switch (page_id) {
            case "main":
                return build_main_page ();
            case "calendar":
                return build_calendar_page ();
            case "repeat":
                return build_repeat_page ();
            case "repeat-config":
                return new Widgets.DateTimePicker.RepeatConfig ();
            default:
                assert_not_reached ();
        }
    }

    private Adw.NavigationPage build_main_page () {
        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

        // Quick date items
        content_box.append (quick_items);

        // Separator
        content_box.append (new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
            margin_top = 6
        });

        // Repeat item
        repeat_item = create_repeat_item ();
        content_box.append (repeat_item);

        // Separator
        content_box.append (new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
            margin_bottom = 6
        });

        // Time picker
        var time_box = create_time_section ();
        content_box.append (time_box);

        // Action buttons
        action_revealer = create_action_section ();
        content_box.append (action_revealer);

        var toolbar_view = new Adw.ToolbarView () {
            content = content_box
        };

        return new Adw.NavigationPage (toolbar_view, _("Menu"));
    }

    private Adw.NavigationPage build_calendar_page () {
        calendar_view = new Widgets.Calendar.Calendar ();

        calendar_view.day_selected.connect (() => {
            set_date (calendar_view.date, false, true);
            visible_no_date = true;
            update_ui_state ();
            navigation_view.pop ();
        });

        return new Adw.NavigationPage (
            build_toolbar_page (calendar_view),
            _("Calendar")
        );
    }

    private Adw.NavigationPage build_repeat_page () {
        var menu_box = new RecurrencyMenu ();

        menu_box.recurrency_selected.connect ((recurrency_config) => {
            set_recurrency (recurrency_config);
            navigation_view.pop ();
        });

        menu_box.custom_requested.connect (() => {
            var repeat_config = (Widgets.DateTimePicker.RepeatConfig) get_or_create_page ("repeat-config");
            navigation_view.push (repeat_config);

            if (duedate != null) {
                repeat_config.duedate = duedate;
            }

            repeat_config.duedate_change.connect ((custom_duedate) => {
                set_recurrency (custom_duedate);
                navigation_view.pop_to_page (get_or_create_page ("main"));
            });
        });

        return new Adw.NavigationPage (
            build_toolbar_page (menu_box),
            _("Repeat")
        );
    }

    private Widgets.ContextMenu.MenuItem create_repeat_item () {
        var item = new Widgets.ContextMenu.MenuItem (_("Repeat"), "playlist-repeat-symbolic") {
            margin_top = 6,
            margin_bottom = 6,
            arrow = true,
            autohide_popover = false
        };

        item.clicked.connect (() => {
            navigation_view.push (get_or_create_page ("repeat"));
        });

        return item;
    }

    private Gtk.Box create_time_section () {
        var time_icon = new Gtk.Image.from_icon_name ("clock-symbolic");
        var time_label = new Gtk.Label (_("Time")) {
            css_classes = { "font-weight-500" }
        };

        time_picker = new Widgets.DateTimePicker.TimePicker () {
            hexpand = true,
            halign = Gtk.Align.END
        };

        var time_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            hexpand = true,
            margin_top = 6,
            margin_start = 12
        };

        time_box.append (time_icon);
        time_box.append (time_label);
        time_box.append (time_picker);

        // Connect time picker signals
        time_picker.time_changed.connect (() => {
            duedate.datetime = Utils.Datetime.get_date_only (duedate.datetime);
        });

        time_picker.time_added.connect (() => {
            visible_no_date = true;
            if (duedate.datetime == null) {
                duedate.datetime = time_picker.time;
                update_ui_state ();
            }
        });

        return time_box;
    }

    private Gtk.Revealer create_action_section () {
        var submit_button = new Widgets.LoadingButton.with_label (_("Done")) {
            css_classes = { "suggested-action" }
        };

        var clear_button = new Widgets.LoadingButton.with_label (_("Clear")) {
            css_classes = { "destructive-action" }
        };

        var action_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            margin_top = 12,
            homogeneous = true
        };

        action_box.append (clear_button);
        action_box.append (submit_button);

        var revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            child = action_box
        };

        // Connect button signals
        submit_button.clicked.connect (() => {
            duedate_changed ();
            popdown ();
        });

        clear_button.clicked.connect (() => {
            clear_date_and_recurrency ();
        });

        return revealer;
    }

    private Adw.ToolbarView build_toolbar_page (Gtk.Widget widget) {
        var toolbar_view = new Adw.ToolbarView () {
            content = widget
        };

        toolbar_view.add_top_bar (new Adw.HeaderBar () {
            show_title = false,
            show_end_title_buttons = false,
        });

        return toolbar_view;
    }

    private void on_quick_date_selected (DateTime date) {
        set_date (date);
    }

    private void clear_date_and_recurrency () {
        time_picker.has_time = false;
        duedate.datetime = null;
        duedate.is_recurring = false;
        duedate.recurrency_type = RecurrencyType.NONE;
        duedate.recurrency_interval = 0;

        popdown ();
        duedate_changed ();
        update_ui_state ();
    }

    private Objects.DueDate get_current_duedate () {
        if (_duedate == null) {
            _duedate = new Objects.DueDate ();
        }

        if (time_picker ? .has_time == true) {
            _duedate.datetime = (_duedate.datetime == null)
                ? time_picker.time
                : DateTimeHelper.combine_date_and_time (_duedate.datetime, time_picker.time);
        } else if (_duedate != null) {
            _duedate.datetime = Utils.Datetime.get_date_only (_duedate.datetime);
        }

        return _duedate;
    }

    private void set_current_duedate (Objects.DueDate value) {
        _duedate = value;

        if (_duedate ? .datetime != null && calendar_view != null) {
            calendar_view.date = _duedate.datetime;
        }

        update_ui_state ();

        if (Utils.Datetime.has_time (_duedate ? .datetime) && time_picker != null) {
            time_picker.time = _duedate.datetime;
            time_picker.has_time = true;
        }
    }

    private void set_date (DateTime date, bool hide_popover = true, bool no_signal = false) {
        duedate = new Objects.DueDate ();
        duedate.datetime = Utils.Datetime.get_date_only (date);

        if (hide_popover) {
            popdown ();
        }

        if (!no_signal) {
            duedate_changed ();
        }
    }

    public void set_recurrency (Objects.DueDate recurrency_config) {
        if (duedate == null) {
            duedate = new Objects.DueDate ();
        }

        var today = Utils.Datetime.get_today_format_date ();

        // Apply recurrency-specific date logic
        RecurrencyHelper.apply_recurrency_date (duedate, recurrency_config, today);

        // Copy recurrency properties
        RecurrencyHelper.copy_properties (duedate, recurrency_config);

        visible_no_date = true;
        update_ui_state ();
    }

    private void update_ui_state () {
        if (quick_items != null) {
            quick_items.update_selection (duedate);
        }

        if (repeat_item != null) {
            update_repeat_item_display ();
        }
    }

    private void update_repeat_item_display () {
        repeat_item.secondary_text = duedate ? .is_recurring == true
            ? Utils.Datetime.get_recurrency_weeks (duedate.recurrency_type,
                                                   duedate.recurrency_interval,
                                                   duedate.recurrency_weeks).down ()
            : "";
    }

    public void reset () {
        time_picker ?.reset ();

        visible_no_date = false;
        calendar_view ?.reset ();

        quick_items ?.reset ();

        update_ui_state ();
    }
}

private class DateQuickItems : Gtk.Box {
    private Widgets.ContextMenu.MenuItem today_item;
    private Widgets.ContextMenu.MenuItem tomorrow_item;
    private Widgets.ContextMenu.MenuItem next_week_item;
    private Widgets.ContextMenu.MenuItem date_item;

    public signal void date_selected (DateTime date);
    public signal void calendar_requested ();
    public signal void repeat_requested ();

    public DateQuickItems () {
        Object (
            orientation : Gtk.Orientation.VERTICAL,
            spacing : 0
        );
    }

    construct {
        create_items ();
        connect_signals ();
    }

    private void create_items () {
        today_item = new Widgets.ContextMenu.MenuItem (_("Today"), "star-outline-thick-symbolic");
        tomorrow_item = new Widgets.ContextMenu.MenuItem (_("Tomorrow"), "today-calendar-symbolic");
        next_week_item = new Widgets.ContextMenu.MenuItem (_("Next week"), "work-week-symbolic");
        date_item = new Widgets.ContextMenu.MenuItem (_("Choose a date"), "month-symbolic") {
            arrow = true,
            autohide_popover = false
        };

        append (today_item);
        append (tomorrow_item);
        append (next_week_item);
        append (date_item);
    }

    private void connect_signals () {
        today_item.activate_item.connect (() => {
            date_selected (new DateTime.now_local ());
        });

        tomorrow_item.activate_item.connect (() => {
            date_selected (new DateTime.now_local ().add_days (1));
        });

        next_week_item.activate_item.connect (() => {
            date_selected (new DateTime.now_local ().add_days (7));
        });

        date_item.clicked.connect (() => {
            calendar_requested ();
        });
    }

    public void update_selection (Objects.DueDate ? duedate) {
        reset_selection ();

        if (duedate ? .datetime == null) {
            return;
        }

        if (Utils.Datetime.is_today (duedate.datetime)) {
            today_item.selected = true;
        } else if (Utils.Datetime.is_tomorrow (duedate.datetime)) {
            tomorrow_item.selected = true;
        } else if (Utils.Datetime.is_next_week (duedate.datetime)) {
            next_week_item.selected = true;
        } else {
            date_item.secondary_text = Utils.Datetime.get_relative_date_from_date (
                Utils.Datetime.get_date_only (duedate.datetime)
            );
        }
    }

    public void reset () {
        reset_selection ();
    }

    private void reset_selection () {
        today_item.selected = false;
        tomorrow_item.selected = false;
        next_week_item.selected = false;
        date_item.selected = false;
        date_item.secondary_text = "";
    }
}

private class RecurrencyMenu : Gtk.Box {
    public signal void recurrency_selected (Objects.DueDate recurrency_config);
    public signal void custom_requested ();

    public RecurrencyMenu () {
        Object (orientation : Gtk.Orientation.VERTICAL, spacing : 0);
        setup_menu_items ();
    }

    private void setup_menu_items () {
        margin_top = margin_bottom = 3;

        var daily_item = create_menu_item (_("Daily"), RecurrencyType.EVERY_DAY);
        var weekdays_item = create_weekdays_item ();
        var weekends_item = create_weekends_item ();
        var weekly_item = create_menu_item (_("Weekly"), RecurrencyType.EVERY_WEEK);
        var monthly_item = create_menu_item (_("Monthly"), RecurrencyType.EVERY_MONTH);
        var yearly_item = create_menu_item (_("Yearly"), RecurrencyType.EVERY_YEAR);
        var none_item = create_none_item ();
        var custom_item = create_custom_item ();

        append (daily_item);
        append (weekdays_item);
        append (weekends_item);
        append (weekly_item);
        append (monthly_item);
        append (yearly_item);
        append (new Widgets.ContextMenu.MenuSeparator ());
        append (none_item);
        append (custom_item);
    }

    private Widgets.ContextMenu.MenuItem create_menu_item (string label, RecurrencyType type) {
        var item = new Widgets.ContextMenu.MenuItem (label) {
            autohide_popover = false
        };

        item.clicked.connect (() => {
            var config = new Objects.DueDate ();
            config.is_recurring = true;
            config.recurrency_type = type;
            config.recurrency_interval = 1;
            recurrency_selected (config);
        });

        return item;
    }

    private Widgets.ContextMenu.MenuItem create_weekdays_item () {
        var item = new Widgets.ContextMenu.MenuItem (_("Weekdays")) {
            autohide_popover = false
        };

        item.clicked.connect (() => {
            var config = new Objects.DueDate ();
            config.is_recurring = true;
            config.recurrency_type = RecurrencyType.EVERY_WEEK;
            config.recurrency_weeks = "1,2,3,4,5";
            config.recurrency_interval = 1;
            recurrency_selected (config);
        });

        return item;
    }

    private Widgets.ContextMenu.MenuItem create_weekends_item () {
        var item = new Widgets.ContextMenu.MenuItem (_("Weekends")) {
            autohide_popover = false
        };

        item.clicked.connect (() => {
            var config = new Objects.DueDate ();
            config.is_recurring = true;
            config.recurrency_type = RecurrencyType.EVERY_WEEK;
            config.recurrency_weeks = "6,7";
            config.recurrency_interval = 1;
            recurrency_selected (config);
        });

        return item;
    }

    private Widgets.ContextMenu.MenuItem create_none_item () {
        var item = new Widgets.ContextMenu.MenuItem (_("None")) {
            autohide_popover = false
        };

        item.clicked.connect (() => {
            var config = new Objects.DueDate ();
            config.is_recurring = false;
            config.recurrency_type = RecurrencyType.NONE;
            config.recurrency_interval = 0;
            recurrency_selected (config);
        });

        return item;
    }

    private Widgets.ContextMenu.MenuItem create_custom_item () {
        var item = new Widgets.ContextMenu.MenuItem (_("Custom")) {
            autohide_popover = false,
            arrow = true
        };

        item.clicked.connect (() => {
            custom_requested ();
        });

        return item;
    }
}

private class DateTimeHelper {
    public static GLib.DateTime combine_date_and_time (GLib.DateTime date, GLib.DateTime time) {
        return new GLib.DateTime.local (
            date.get_year (),
            date.get_month (),
            date.get_day_of_month (),
            time.get_hour (),
            time.get_minute (),
            time.get_second ()
        );
    }
}

private class RecurrencyHelper {
    public static void apply_recurrency_date (Objects.DueDate target, Objects.DueDate source, DateTime today) {
        switch (source.recurrency_type) {
            case RecurrencyType.MINUTELY :
            case RecurrencyType.HOURLY :
                set_date_if_null (target,
                                  Utils.Datetime.get_todoist_datetime_format (new DateTime.now_local ())
                );
                break;

            case RecurrencyType.EVERY_DAY :
            case RecurrencyType.EVERY_MONTH :
            case RecurrencyType.EVERY_YEAR:
                set_date_if_null (target,
                                  Utils.Datetime.get_todoist_datetime_format (today)
                );
                break;

            case RecurrencyType.EVERY_WEEK:
                apply_weekly_recurrency (target, source, today);
                break;

            case RecurrencyType.NONE:
                break;
        }
    }

    private static void set_date_if_null (Objects.DueDate duedate, string datetime) {
        if (duedate.datetime == null) {
            duedate.date = datetime;
        }
    }

    private static void apply_weekly_recurrency (Objects.DueDate target, Objects.DueDate source, DateTime today) {
        if (source.has_weeks) {
            var due_selected = target.datetime ?? today;
            var day_of_week = due_selected.get_day_of_week ();
            var next_day = Utils.Datetime.get_next_day_of_week_from_recurrency_week (
                due_selected, source
            );

            var due_date = (day_of_week == next_day)
                ? due_selected
                : Utils.Datetime.next_recurrency_week (due_selected, source);

            target.date = Utils.Datetime.get_todoist_datetime_format (due_date);
        } else {
            set_date_if_null (target, Utils.Datetime.get_todoist_datetime_format (today));
        }
    }

    public static void copy_properties (Objects.DueDate target, Objects.DueDate source) {
        target.is_recurring = source.is_recurring;
        target.recurrency_type = source.recurrency_type;
        target.recurrency_interval = source.recurrency_interval;
        target.recurrency_weeks = source.recurrency_weeks;
        target.recurrency_count = source.recurrency_count;
        target.recurrency_end = source.recurrency_end;
    }
}