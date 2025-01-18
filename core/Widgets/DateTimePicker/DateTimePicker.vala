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
    private Adw.NavigationView navigation_view;

    private Widgets.ContextMenu.MenuItem today_item;
    private Widgets.ContextMenu.MenuItem tomorrow_item;
    private Widgets.ContextMenu.MenuItem date_item;
    private Widgets.ContextMenu.MenuItem next_week_item;
    private Widgets.DateTimePicker.TimePicker time_picker;
    private Widgets.Calendar.Calendar calendar_view;
    private Widgets.ContextMenu.MenuItem repeat_item;
    private Gtk.Revealer action_revealer;

    Objects.DueDate _duedate;
    public Objects.DueDate duedate {
        set {
            _duedate = value;
            if (_duedate.datetime != null) {
                calendar_view.date = _duedate.datetime;
            }

            check_items (_duedate);

            if (Utils.Datetime.has_time (_duedate.datetime)) {
                time_picker.time = _duedate.datetime;
                time_picker.has_time = true;
            }
        }
        
        get {
            if (time_picker.has_time) {
                if (_duedate.datetime == null) {
                    _duedate.datetime = time_picker.time;
                } else {
                    _duedate.datetime = add_date_time (_duedate.datetime, time_picker.time);
                }
            } else {
                if (_duedate != null) {
                    _duedate.datetime = Utils.Datetime.get_date_only (_duedate.datetime);
                }
            }

            return _duedate;
        }
    }

    public bool visible_no_date {
        set {
            action_revealer.reveal_child = value;
        }
    }

    public signal void duedate_changed ();

    private Gee.HashMap<string, Adw.NavigationPage> pages_map = new Gee.HashMap<string, Adw.NavigationPage> ();

    public DateTimePicker () {
        Object (
            has_arrow: false,
            position: Gtk.PositionType.RIGHT,
            width_request: 275
        );
    }

    construct {
        navigation_view = new Adw.NavigationView ();
        navigation_view.add (build_page ("main"));

        child = navigation_view;

        closed.connect (() => {
            navigation_view.pop ();
        });
    }

    private Adw.NavigationPage build_page (string page) {
        if (pages_map.has_key (page)) {
            return pages_map[page];
        }

        if (page == "main") {
            pages_map[page] = build_main_page ();
        } else if (page == "calendar") {
            pages_map[page] = build_calendar_page ();
        } else if (page == "repeat") {
            pages_map[page] = build_repeat_page ();
        } else if (page == "repeat-config") {
            pages_map[page] = new Widgets.DateTimePicker.RepeatConfig ();
        }

        return pages_map[page];
    }

    private Adw.NavigationPage build_main_page () {
        today_item = new Widgets.ContextMenu.MenuItem (_("Today"), "star-outline-thick-symbolic");
        tomorrow_item = new Widgets.ContextMenu.MenuItem (_("Tomorrow"), "today-calendar-symbolic");
        next_week_item = new Widgets.ContextMenu.MenuItem (_("Next week"), "work-week-symbolic");
        date_item = new Widgets.ContextMenu.MenuItem (_("Choose a date"), "month-symbolic");
        date_item.arrow = true;
        date_item.autohide_popover = false;

        repeat_item = new Widgets.ContextMenu.MenuItem (_("Repeat"), "playlist-repeat-symbolic") {
            margin_top = 6,
            margin_bottom = 6
        };
		repeat_item.arrow = true;
        repeat_item.autohide_popover = false;

        var time_icon = new Gtk.Image.from_icon_name ("clock-symbolic") {
            css_classes = { "dim-label" }
        };

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

        action_revealer = new Gtk.Revealer () {
			transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
			child = action_box
		};

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);  
        content_box.append (today_item);
        content_box.append (tomorrow_item);
        content_box.append (next_week_item);
        content_box.append (date_item);
        content_box.append (new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
            margin_top = 6
        });
        content_box.append (repeat_item);
        content_box.append (new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
            margin_bottom = 6
        });
        content_box.append (time_box);
        content_box.append (action_revealer);

        var toolbar_view = new Adw.ToolbarView ();
		toolbar_view.content = content_box;

        today_item.activate_item.connect (() => {
            set_date (new DateTime.now_local ());
        });

        tomorrow_item.activate_item.connect (() => {
            set_date (new DateTime.now_local ().add_days (1));
        });

        next_week_item.activate_item.connect (() => {
            set_date (new DateTime.now_local ().add_days (7));
        });

        time_picker.time_changed.connect (() => {
            duedate.datetime = Utils.Datetime.get_date_only (duedate.datetime);
        });

        time_picker.time_added.connect (() => {
            visible_no_date = true;

            if (duedate.datetime == null) {
                duedate.datetime = time_picker.time;
                check_items (duedate);
            }
        });

        submit_button.clicked.connect (() => {
            duedate_changed ();
            popdown ();
        });

        clear_button.clicked.connect (() => {
            time_picker.has_time = false;
            duedate.datetime = null;
            popdown ();
            duedate_changed ();
            check_items (null);
        });

        date_item.clicked.connect (() => {
            navigation_view.push (build_page ("calendar"));
        });

        repeat_item.clicked.connect (() => {
            navigation_view.push (build_page ("repeat"));
        });

        return new Adw.NavigationPage (toolbar_view, _("Menu"));
    }

    private Adw.NavigationPage build_calendar_page () {
        var back_item = new Widgets.ContextMenu.MenuItem (_("Back"), "go-previous-symbolic");
        back_item.autohide_popover = false;

        calendar_view = new Widgets.Calendar.Calendar ();

        var calendar_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            hexpand = true
        };

        calendar_box.append (back_item);
        calendar_box.append (new Widgets.ContextMenu.MenuSeparator ());
        calendar_box.append (calendar_view);

        var toolbar_view = new Adw.ToolbarView ();
		toolbar_view.content = calendar_box;

        back_item.clicked.connect (() => {
            navigation_view.pop ();
        });

        calendar_view.day_selected.connect (() => {
            set_date (calendar_view.date, false, true);
            visible_no_date = true;
            check_items (duedate);

            navigation_view.pop ();
        });
        
        return new Adw.NavigationPage (toolbar_view, _("Calendar"));
    }

    private Adw.NavigationPage build_repeat_page () {
        var back_item = new Widgets.ContextMenu.MenuItem (_("Back"), "go-previous-symbolic");
        back_item.autohide_popover = false;
        
        var none_item = new Widgets.ContextMenu.MenuItem (_("None")) {
            autohide_popover = false
        };
        
		var daily_item = new Widgets.ContextMenu.MenuItem (_("Daily")) {
            autohide_popover = false
        };
		
        var weekly_item = new Widgets.ContextMenu.MenuItem (_("Weekly")) {
            autohide_popover = false
        };
		
        var monthly_item = new Widgets.ContextMenu.MenuItem (_("Monthly")) {
            autohide_popover = false
        };
		
        var yearly_item = new Widgets.ContextMenu.MenuItem (_("Yearly")) {
            autohide_popover = false
        };
		
        var custom_item = new Widgets.ContextMenu.MenuItem (_("Custom")) {
            autohide_popover = false
        };
        custom_item.arrow = true;

		var menu_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
		menu_box.margin_top = menu_box.margin_bottom = 3;
		menu_box.append (back_item);
		menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
		menu_box.append (daily_item);
		menu_box.append (weekly_item);
		menu_box.append (monthly_item);
		menu_box.append (yearly_item);
		menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
		menu_box.append (none_item);
		menu_box.append (custom_item);

        var toolbar_view = new Adw.ToolbarView ();
		toolbar_view.content = menu_box;

        back_item.clicked.connect (() => {
            navigation_view.pop ();
        });

        daily_item.clicked.connect (() => {
			var _duedate = new Objects.DueDate ();
			_duedate.is_recurring = true;
			_duedate.recurrency_type = RecurrencyType.EVERY_DAY;
			_duedate.recurrency_interval = 1;
            set_recurrency (_duedate);
            navigation_view.pop ();
		});

		weekly_item.clicked.connect (() => {
			var _duedate = new Objects.DueDate ();
			_duedate.is_recurring = true;
			_duedate.recurrency_type = RecurrencyType.EVERY_WEEK;
			_duedate.recurrency_interval = 1;
            set_recurrency (_duedate);
            navigation_view.pop ();
		});

		monthly_item.clicked.connect (() => {
			var _duedate = new Objects.DueDate ();
			_duedate.is_recurring = true;
			_duedate.recurrency_type = RecurrencyType.EVERY_MONTH;
			_duedate.recurrency_interval = 1;
            set_recurrency (_duedate);
            navigation_view.pop ();
		});

		yearly_item.clicked.connect (() => {
			var _duedate = new Objects.DueDate ();
			_duedate.is_recurring = true;
			_duedate.recurrency_type = RecurrencyType.EVERY_YEAR;
			_duedate.recurrency_interval = 1;
            set_recurrency (_duedate);
            navigation_view.pop ();
		});

		none_item.clicked.connect (() => {
			var _duedate = new Objects.DueDate ();
			_duedate.is_recurring = false;
			_duedate.recurrency_type = RecurrencyType.NONE;
			_duedate.recurrency_interval = 0;
            set_recurrency (_duedate);
            navigation_view.pop ();
		});

		custom_item.clicked.connect (() => {
            navigation_view.push (build_page ("repeat-config"));

            if (duedate != null) {
                ((Widgets.DateTimePicker.RepeatConfig) build_page ("repeat-config")).duedate = duedate;
            }

            ((Widgets.DateTimePicker.RepeatConfig) build_page ("repeat-config")).duedate_change.connect ((_duedate) => {
                set_recurrency (_duedate);
                navigation_view.pop_to_page (build_page ("main"));
            });

            ((Widgets.DateTimePicker.RepeatConfig) build_page ("repeat-config")).back.connect (() => {
                navigation_view.pop_to_page (build_page ("main"));
            });
		});

        return new Adw.NavigationPage (toolbar_view, _("Repeat"));
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

    private GLib.DateTime add_date_time (GLib.DateTime date, GLib.DateTime time) {
        return new GLib.DateTime.local (
            date.get_year (),
            date.get_month (),
            date.get_day_of_month (),
            time.get_hour (),
            time.get_minute (),
            time.get_second ()
        );
    }

    public void set_recurrency (Objects.DueDate _duedate) {
        if (duedate == null) {
            duedate = new Objects.DueDate ();
        }

        if (_duedate.recurrency_type == RecurrencyType.MINUTELY ||
            _duedate.recurrency_type == RecurrencyType.HOURLY) {
            if (duedate.datetime == null) {
                duedate.date = Utils.Datetime.get_todoist_datetime_format (
                    new DateTime.now_local ()
                );
            }
        } else if (_duedate.recurrency_type == RecurrencyType.EVERY_DAY ||
            _duedate.recurrency_type == RecurrencyType.EVERY_MONTH || 
            _duedate.recurrency_type == RecurrencyType.EVERY_YEAR) {
            if (duedate.datetime == null) {
                duedate.date = Utils.Datetime.get_todoist_datetime_format (
                    Utils.Datetime.get_today_format_date ()
                );
            }
        } else if (_duedate.recurrency_type == RecurrencyType.EVERY_WEEK) {
            if (_duedate.has_weeks) {
                GLib.DateTime due_selected = Utils.Datetime.get_today_format_date ();
                if (duedate.datetime != null) {
                    due_selected = duedate.datetime;
                }
                
                int day_of_week = due_selected.get_day_of_week ();
                int next_day = Utils.Datetime.get_next_day_of_week_from_recurrency_week (due_selected, _duedate);
                GLib.DateTime due_date = null;

                if (day_of_week == next_day) {
                    due_date = due_selected;
                } else {
                    due_date = Utils.Datetime.next_recurrency_week (due_selected, _duedate);
                }

                duedate.date = Utils.Datetime.get_todoist_datetime_format (due_date);
            } else {
                if (duedate.datetime == null) {
                    duedate.date = Utils.Datetime.get_todoist_datetime_format (
                        Utils.Datetime.get_today_format_date ()
                    );
                }
            }
        }

        duedate.is_recurring = _duedate.is_recurring;
        duedate.recurrency_type = _duedate.recurrency_type;
        duedate.recurrency_interval = _duedate.recurrency_interval;
        duedate.recurrency_weeks = _duedate.recurrency_weeks;
        duedate.recurrency_count = _duedate.recurrency_count;
        duedate.recurrency_end = _duedate.recurrency_end;

        visible_no_date = true;
        check_items (duedate);
    }

    public void reset () {
        time_picker.reset ();
        visible_no_date = false;
        calendar_view.reset ();
        check_items (null);
    }

    private void check_items (Objects.DueDate? duedate) {
        today_item.selected = false;
        tomorrow_item.selected = false;
        next_week_item.selected = false;
        date_item.selected = false;
        date_item.secondary_text = "";
        repeat_item.selected = false;
        repeat_item.secondary_text = "";

        if (duedate == null || duedate.datetime == null) {
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

        if (duedate.is_recurring) {
            repeat_item.secondary_text = Utils.Datetime.get_recurrency_weeks (
                duedate.recurrency_type,
                duedate.recurrency_interval,
                duedate.recurrency_weeks
            ).down ();
        }
    }
}
