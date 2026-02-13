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
    private Widgets.DateTimePicker.TimePicker time_picker;
    private Widgets.Calendar.CalendarMonth calendar_view;
    private Widgets.Calendar.CalendarScroll calendar_scroll_view;
    private Widgets.ContextMenu.MenuItem repeat_item;
    private NoDateButton no_date_button;
    private OptionButton time_option_button;
    private OptionButton repeat_option_button;
    private Gtk.Revealer time_option_revealer;
    private Adw.Bin dimming_widget;
    private Gtk.Overlay main_overlay;
    private Gee.ArrayList<Gtk.Revealer> active_revealers;
    private Gtk.Revealer repeat_option_revealer;
    private Gtk.Stack main_stack;
    private Widgets.DateTimePicker.RepeatConfig repeat_config_widget;
    
    bool _has_time = false;
    public bool has_time {
        get {
            return _has_time;
        }

        set {
            _has_time = value;
            time_option_button.has_value = _has_time;
        }
    }

    bool _has_recurrency = false;
    public bool has_recurrency {
        get {
            return _has_recurrency;
        }

        set {
            _has_recurrency = value;
            repeat_option_button.has_value = _has_recurrency;
        }
    }

    Objects.DueDate _duedate = new Objects.DueDate ();
    public Objects.DueDate duedate {
        set {
            _duedate = value;

            if (_duedate != null && _duedate.datetime != null) {
                calendar_view.date = _duedate.datetime;
                calendar_scroll_view.date = _duedate.datetime;
            }

            if (_duedate != null && time_picker != null && _duedate.datetime != null && Utils.Datetime.has_time (_duedate.datetime)) {
                time_picker.time = _duedate.datetime;
                if (time_picker.time != null) {
                    time_option_button.label_text = time_picker.time.format (Utils.Datetime.get_default_time_format ());
                }
                has_time = true;
            } else {
                has_time = false;
                time_option_button.label_text = _("Time");
            }

            if (_duedate != null && _duedate.is_recurring) {
                var end_label = "";
                if (_duedate.end_type == RecurrencyEndType.ON_DATE) {
                    var date_label = Utils.Datetime.get_default_date_format_from_date (
                        Utils.Datetime.get_date_only (
                            Utils.Datetime.get_date_from_string (_duedate.recurrency_end)
                        )
                    );
                    end_label = _("until") + " " + date_label;
                } else if (_duedate.end_type == RecurrencyEndType.AFTER) {
                    int count = _duedate.recurrency_count;
                    end_label = _("for") + " " + "%d %s".printf (count, count > 1 ? _("times") : _("time"));
                }

                repeat_option_button.label_text = Utils.Datetime.get_recurrency_weeks (
                    _duedate.recurrency_type,
                    _duedate.recurrency_interval,
                    _duedate.recurrency_weeks,
                    end_label
                ).down ();
                has_recurrency = true;
            } else {
                repeat_option_button.label_text = _("Repeat");
                has_recurrency = false;
            }
        }

        get {
            if (time_picker != null && has_time) {
                if (_duedate.datetime == null) {
                    _duedate.datetime = time_picker.time;
                } else {
                    _duedate.datetime = add_date_time (_duedate.datetime, time_picker.time);
                }
            } else {
                if (_duedate != null && _duedate.datetime != null) {
                    _duedate.datetime = Utils.Datetime.get_date_only (_duedate.datetime);
                }
            }

            return _duedate;
        }
    }

    public bool visible_no_date {
        set {
            if (no_date_button != null) {
                no_date_button.visible = value;
            }
        }
    }

    public signal void duedate_changed ();

    private Gee.HashMap<ulong, weak GLib.Object> signal_map = new Gee.HashMap<ulong, weak GLib.Object> ();

    private Chrono.Chrono chrono;
    private uint search_timeout_id = 0;

    public DateTimePicker () {
        Object (
            has_arrow: false,
            position: Gtk.PositionType.RIGHT,
            width_request: 275
        );
    }

    ~DateTimePicker () {
        debug ("Destroying - Widgets.DateTimePicker.DateTimePicker\n");
    }

    construct {
        chrono = new Chrono.Chrono ();
        active_revealers = new Gee.ArrayList<Gtk.Revealer> ();

        Objects.DueDate ? last_parsed_duedate = null;

        var search_entry = new Gtk.SearchEntry () {
            placeholder_text = _("Type a date…")
        };

        var search_key_controller = new Gtk.EventControllerKey ();
        search_entry.add_controller (search_key_controller);
        search_key_controller.key_pressed.connect ((keyval, keycode, state) => {
            if (keyval == Gdk.Key.Escape) {
                popdown ();
                return true;
            }

            return false;
        });

        var suggested_date_box = new Adw.WrapBox () {
            child_spacing = 6,
            line_spacing = 6,
            margin_top = 9,
            margin_bottom = 6
        };

        calendar_view = new Widgets.Calendar.CalendarMonth ();

        time_option_button = new OptionButton ("clock-symbolic", _("Time"));

        repeat_option_button = new OptionButton ("playlist-repeat-symbolic", _("Repeat"));

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            margin_start = 9,
            margin_end = 9,
            margin_top = 9,
            margin_bottom = 9
        };
        content_box.append (search_entry);
        content_box.append (suggested_date_box);
        content_box.append (new Widgets.ContextMenu.MenuSeparator ());
        content_box.append (calendar_view);
        content_box.append (new Widgets.ContextMenu.MenuSeparator ());
        content_box.append (time_option_button);
        content_box.append (repeat_option_button);

        var popover_scrolled = new Gtk.ScrolledWindow () {
            child = content_box,
            vscrollbar_policy = NEVER,
            hscrollbar_policy = NEVER
        };

        var toolbar_view = new Adw.ToolbarView () {
            content = popover_scrolled
        };

        dimming_widget = new Adw.Bin () {
            visible = false
        };
        dimming_widget.add_css_class ("dimming-bg");

        main_overlay = new Gtk.Overlay () {
            child = toolbar_view
        };
        main_overlay.add_overlay (dimming_widget);

        build_time_picker_revealer ();
        build_repeat_picker_revealer ();

        main_stack = new Gtk.Stack () {
            transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT
        };
        main_stack.add_named (main_overlay, "main");
        main_stack.add_named (build_calendar_page (), "calendar");

        repeat_config_widget = new Widgets.DateTimePicker.RepeatConfig ();
        main_stack.add_named (build_repeat_config_page (repeat_config_widget), "repeat-config");

        child = main_stack;
        add_css_class ("popover-contents");
        add_default_suggestions (suggested_date_box);

        time_option_button.clicked.connect (() => {
            show_revealer (time_option_revealer);
            time_picker.grab_entry_focus ();
        });

        time_option_button.clear_clicked.connect (() => {
            has_time = false;
            time_picker.reset ();
            duedate_changed ();
        });

        repeat_option_button.clicked.connect (() => {
            show_revealer (repeat_option_revealer);
        });

        repeat_option_button.clear_clicked.connect (() => {
            apply_recurrency (RecurrencyType.NONE, 0, null, false);
        });

        repeat_item.clicked.connect (() => {
            show_revealer (repeat_option_revealer);
        });

        closed.connect (() => {
            main_stack.visible_child_name = "main";
        });

        search_entry.activate.connect (() => {
            if (last_parsed_duedate != null) {
                duedate = last_parsed_duedate;
                visible_no_date = true;
                duedate_changed ();
                popdown ();
            }
        });

        search_entry.search_changed.connect (() => {
            if (search_timeout_id != 0) {
                GLib.Source.remove (search_timeout_id);
            }

            search_timeout_id = Timeout.add (300, () => {
                search_timeout_id = 0;

                while (suggested_date_box.get_first_child () != null) {
                    suggested_date_box.remove (suggested_date_box.get_first_child ());
                }

                var text = search_entry.text.strip ();
                if (text.length == 0) {
                    last_parsed_duedate = null;
                    add_default_suggestions (suggested_date_box);
                    return GLib.Source.REMOVE;
                }

                var result = chrono.parse (text);
                if (result != null && result.date != null) {
                    var parsed_duedate = new Objects.DueDate ();
                    parsed_duedate.datetime = result.date;

                    if (result.recurrence != null) {
                        parsed_duedate.is_recurring = true;
                        parsed_duedate.recurrency_interval = result.recurrence.interval;

                        switch (result.recurrence.recurrence_type) {
                                case Chrono.RecurrenceType.DAILY :
                                    parsed_duedate.recurrency_type = RecurrencyType.EVERY_DAY;
                                    break;
                                case Chrono.RecurrenceType.WEEKLY:
                                    parsed_duedate.recurrency_type = RecurrencyType.EVERY_WEEK;
                                    break;
                                case Chrono.RecurrenceType.MONTHLY:
                                    parsed_duedate.recurrency_type = RecurrencyType.EVERY_MONTH;
                                    break;
                                case Chrono.RecurrenceType.YEARLY:
                                    parsed_duedate.recurrency_type = RecurrencyType.EVERY_YEAR;
                                    break;
                        }

                        if (result.recurrence.days_of_week != null && result.recurrence.days_of_week.size > 0) {
                            string weeks = "";
                            foreach (var day in result.recurrence.days_of_week) {
                                weeks += day.to_string () + ",";
                            }
                            parsed_duedate.recurrency_weeks = weeks.substring (0, weeks.length - 1);
                        }
                    }

                    last_parsed_duedate = parsed_duedate;
                    var suggested_date = new SuggestedDate (parsed_duedate);
                    suggested_date_box.append (suggested_date);
                    connect_suggested_date (suggested_date);
                } else {
                    last_parsed_duedate = null;
                }

                return GLib.Source.REMOVE;
            });
        });

        signal_map[calendar_view.day_selected.connect (() => {
            set_date (calendar_view.date, true);
            visible_no_date = true;
        })] = calendar_view;

        calendar_view.choose_date_clicked.connect (() => {
            main_stack.visible_child_name = "calendar";
            calendar_scroll_view.scroll_to_selected_date ();
        });

        hide.connect (() => {
            if (time_option_revealer.reveal_child) {
                time_option_revealer.reveal_child = false;
            }

            if (repeat_option_revealer.reveal_child) {
                repeat_option_revealer.reveal_child = false;
            }

            main_stack.visible_child_name = "main";
        });

        var gesture = new Gtk.GestureClick ();
        dimming_widget.add_controller (gesture);
        gesture.pressed.connect ((n_press, x, y) => {
            hide_all_revealers ();
        });
    }

    private void add_default_suggestions (Adw.WrapBox box) {
        var today_item = new SuggestedDate (build_duedate (new DateTime.now_local ())) {
            title = _("Today")
        };
        box.append (today_item);
        connect_suggested_date (today_item);

        var tomorrow_item = new SuggestedDate (build_duedate (new DateTime.now_local ().add_days (1))) {
            title = _("Tomorrow")
        };
        box.append (tomorrow_item);
        connect_suggested_date (tomorrow_item);

        var next_week_item = new SuggestedDate (build_duedate (new DateTime.now_local ().add_days (7))) {
            title = _("Next week")
        };
        box.append (next_week_item);
        connect_suggested_date (next_week_item);

        no_date_button = new NoDateButton () {
            visible = false
        };
        box.append (no_date_button);
        no_date_button.clicked.connect (() => {
            duedate = new Objects.DueDate ();
            
            reset ();

            duedate_changed ();
            popdown ();
        });
    }

    private void connect_suggested_date (SuggestedDate suggested_date) {
        suggested_date.clicked.connect (() => {
            _duedate.datetime = suggested_date.due_date.datetime;
            visible_no_date = true;
            duedate_changed ();
            popdown ();
        });
    }

    private void save_time () {
        visible_no_date = true;
        has_time = true;

        if (duedate.datetime == null) {
            _duedate.datetime = time_picker.time;
        }

        time_option_button.label_text = time_picker.time.format (Utils.Datetime.get_default_time_format ());
        time_option_revealer.reveal_child = false;
        duedate_changed ();
    }

    private Objects.DueDate build_duedate (DateTime date) {
        var duedate = new Objects.DueDate ();
        duedate.datetime = Utils.Datetime.get_date_only (date);
        return duedate;
    }

    private void set_date (DateTime date, bool hide_popover = true, bool no_signal = false) {
        _duedate.datetime = Utils.Datetime.get_date_only (date);

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

    public void set_recurrency (Objects.DueDate value) {
        if (value.recurrency_type == RecurrencyType.MINUTELY ||
            value.recurrency_type == RecurrencyType.HOURLY) {
            if (_duedate.datetime == null) {
                _duedate.date = Utils.Datetime.get_todoist_datetime_format (
                    new DateTime.now_local ()
                );
            }
        } else if (value.recurrency_type == RecurrencyType.EVERY_DAY ||
                   value.recurrency_type == RecurrencyType.EVERY_MONTH ||
                   value.recurrency_type == RecurrencyType.EVERY_YEAR) {
            if (_duedate.datetime == null) {
                _duedate.date = Utils.Datetime.get_todoist_datetime_format (
                    Utils.Datetime.get_today_format_date ()
                );
            }
        } else if (value.recurrency_type == RecurrencyType.EVERY_WEEK) {
            if (value.has_weeks) {
                GLib.DateTime due_selected = Utils.Datetime.get_today_format_date ();
                if (_duedate.datetime != null) {
                    due_selected = duedate.datetime;
                }

                int day_of_week = due_selected.get_day_of_week ();
                int next_day = Utils.Datetime.get_next_day_of_week_from_recurrency_week (due_selected, value);
                GLib.DateTime due_date = null;

                if (day_of_week == next_day) {
                    due_date = due_selected;
                } else {
                    due_date = Utils.Datetime.next_recurrency_week (due_selected, value);
                }

                _duedate.date = Utils.Datetime.get_todoist_datetime_format (due_date);
            } else {
                if (_duedate.datetime == null) {
                    _duedate.date = Utils.Datetime.get_todoist_datetime_format (
                        Utils.Datetime.get_today_format_date ()
                    );
                }
            }
        }

        _duedate.is_recurring = value.is_recurring;
        _duedate.recurrency_type = value.recurrency_type;
        _duedate.recurrency_interval = value.recurrency_interval;
        _duedate.recurrency_weeks = value.recurrency_weeks;
        _duedate.recurrency_count = value.recurrency_count;
        _duedate.recurrency_end = value.recurrency_end;

        visible_no_date = true;
    }

    public void reset () {
        time_option_button.label_text = _("Time");
        has_time = false;
        if (time_picker != null) {
            time_picker.reset ();
        }

        visible_no_date = false;
        has_recurrency = false;
        if (calendar_view != null) {
            calendar_view.reset ();
        }
    }

    private void build_time_picker_revealer () {
        time_picker = new Widgets.DateTimePicker.TimePicker () {
            hexpand = true
        };

        var save_time_button = new Gtk.Button.with_label (_("Save"));

        var time_option_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
            margin_start = 9,
            margin_end = 9,
            margin_bottom = 9,
            margin_top = 9,
        };
        time_option_box.append (time_picker);
        time_option_box.append (save_time_button);

        var time_option_container = new Adw.Bin () {
            child = time_option_box
        };
        time_option_container.add_css_class ("card");

        time_option_revealer = new Gtk.Revealer () {
            child = time_option_container,
            valign = END,
            transition_type = SLIDE_UP,
            reveal_child = false
        };

        main_overlay.add_overlay (time_option_revealer);
        register_revealer (time_option_revealer);

        save_time_button.clicked.connect (() => {
            save_time ();
        });

        time_picker.activated.connect (() => {
            save_time ();
        });
    }

    private void build_repeat_picker_revealer () {
        var daily_item = new Widgets.ContextMenu.MenuItem (_("Daily")) {
            autohide_popover = false
        };

        var weekdays_item = new Widgets.ContextMenu.MenuItem (_("Weekdays")) {
            autohide_popover = false
        };

        var weekends_item = new Widgets.ContextMenu.MenuItem (_("Weekends")) {
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

        var repeat_option_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
            margin_start = 9,
            margin_end = 9,
            margin_bottom = 9,
            margin_top = 9,
        };

        repeat_option_box.append (daily_item);
        repeat_option_box.append (weekdays_item);
        repeat_option_box.append (weekends_item);
        repeat_option_box.append (weekly_item);
        repeat_option_box.append (monthly_item);
        repeat_option_box.append (yearly_item);
        repeat_option_box.append (new Widgets.ContextMenu.MenuSeparator ());
        repeat_option_box.append (custom_item);

        var repeat_option_container = new Adw.Bin () {
            child = repeat_option_box
        };
        repeat_option_container.add_css_class ("card");

        repeat_option_revealer = new Gtk.Revealer () {
            child = repeat_option_container,
            valign = END,
            transition_type = SLIDE_UP,
            reveal_child = false
        };

        main_overlay.add_overlay (repeat_option_revealer);
        register_revealer (repeat_option_revealer);

        signal_map[daily_item.clicked.connect (() => {
            apply_recurrency (RecurrencyType.EVERY_DAY, 1);
        })] = daily_item;

        signal_map[weekdays_item.clicked.connect (() => {
            apply_recurrency (RecurrencyType.EVERY_WEEK, 1, "1,2,3,4,5");
        })] = weekdays_item;

        signal_map[weekends_item.clicked.connect (() => {
            apply_recurrency (RecurrencyType.EVERY_WEEK, 1, "6,7");
        })] = weekends_item;

        signal_map[weekly_item.clicked.connect (() => {
            apply_recurrency (RecurrencyType.EVERY_WEEK, 1);
        })] = weekly_item;

        signal_map[monthly_item.clicked.connect (() => {
            apply_recurrency (RecurrencyType.EVERY_MONTH, 1);
        })] = monthly_item;

        signal_map[yearly_item.clicked.connect (() => {
            apply_recurrency (RecurrencyType.EVERY_YEAR, 1);
        })] = yearly_item;

        signal_map[custom_item.clicked.connect (() => {
            repeat_option_revealer.reveal_child = false;
            main_stack.visible_child_name = "repeat-config";

            if (duedate != null) {
                repeat_config_widget.duedate = duedate;
            }
        })] = custom_item;
    }

    private void apply_recurrency (RecurrencyType type, int interval, string? weeks = null, bool is_recurring = true) {
        var value = new Objects.DueDate ();
        value.is_recurring = is_recurring;
        value.recurrency_type = type;
        value.recurrency_interval = interval;
        
        if (weeks != null) {
            value.recurrency_weeks = weeks;
        }

        set_recurrency (value);
        repeat_option_revealer.reveal_child = false;
        duedate_changed ();
    }

    private void register_revealer (Gtk.Revealer revealer) {
        active_revealers.add (revealer);
        revealer.notify["reveal-child"].connect (() => {
            update_dimming_visibility ();
        });
    }

    private void update_dimming_visibility () {
        bool any_visible = false;
        foreach (var revealer in active_revealers) {
            if (revealer.reveal_child) {
                any_visible = true;
                break;
            }
        }
        dimming_widget.visible = any_visible;
    }

    private void show_revealer (Gtk.Revealer revealer, owned VoidFunc ? callback = null) {
        revealer.reveal_child = true;
        if (callback != null) {
            callback ();
        }
    }

    private void hide_all_revealers () {
        foreach (var revealer in active_revealers) {
            revealer.reveal_child = false;
        }
    }

    private Gtk.Widget build_calendar_page () {
        var back_button = new Gtk.Button.from_icon_name ("go-previous-symbolic") {
            css_classes = { "flat" },
            margin_start = 6,
            margin_top = 6,
            margin_bottom = 6,
            halign = START
        };

        calendar_scroll_view = new Widgets.Calendar.CalendarScroll () {
            margin_top = 6
        };

        var toolbar_view = new Adw.ToolbarView () {
            content = calendar_scroll_view
        };

        toolbar_view.add_top_bar (back_button);

        signal_map[calendar_scroll_view.day_selected.connect (() => {
            if (calendar_scroll_view.date != null) {
                set_date (calendar_scroll_view.date, true);
                visible_no_date = true;
                main_stack.visible_child_name = "main"; 
            }
        })] = calendar_scroll_view;

        back_button.clicked.connect (() => {
            main_stack.visible_child_name = "main";
        });

        return toolbar_view;
    }

    private Gtk.Widget build_repeat_config_page (Widgets.DateTimePicker.RepeatConfig repeat_config_widget) {
        var back_button = new Gtk.Button.from_icon_name ("go-previous-symbolic") {
            css_classes = { "flat" },
            margin_start = 6,
            margin_top = 6,
            margin_bottom = 6,
            halign = START
        };

        var toolbar_view = new Adw.ToolbarView () {
            content = repeat_config_widget
        };

        toolbar_view.add_top_bar (back_button);

        repeat_config_widget.duedate_change.connect ((value) => {
            set_recurrency (value);
            main_stack.visible_child_name = "main";
            duedate_changed ();
        });

        back_button.clicked.connect (() => {
            main_stack.visible_child_name = "main";
        });

        return toolbar_view;
    }

    public void clean_up () {
        foreach (var entry in signal_map.entries) {
            entry.value.disconnect (entry.key);
        }

        signal_map.clear ();
    }

    public class SuggestedDate : Adw.Bin {
        public Objects.DueDate due_date { get; construct; }

        private Gtk.Image date_icon;
        private Gtk.Label date_label;
        private Gtk.Button button;

        public signal void clicked ();

        public string title {
            set {
                date_label.label = value;
            }
        }

        public SuggestedDate (Objects.DueDate due_date) {
            Object (
                due_date: due_date
            );
        }

        construct {
            date_icon = new Gtk.Image ();

            date_label = new Gtk.Label (Utils.Datetime.get_relative_date_from_date (due_date.datetime)) {
                use_markup = true,
                ellipsize = END
            };

            var date_box = new Gtk.Box (HORIZONTAL, 6);
            date_box.append (date_icon);
            date_box.append (date_label);

            button = new Gtk.Button () {
                child = date_box
            };

            button.clicked.connect (() => clicked ());

            child = button;

            if (Utils.Datetime.is_today (due_date.datetime)) {
                date_icon.icon_name = "star-outline-thick-symbolic";
            } else if (Utils.Datetime.is_tomorrow (due_date.datetime)) {
                date_icon.icon_name = "today-calendar-symbolic";
            } else if (Utils.Datetime.is_overdue (due_date.datetime)) {
                date_icon.icon_name = "month-symbolic";
            } else {
                date_icon.icon_name = "month-symbolic";
            }

            if (due_date.is_recurring) {
                var end_label = "";
                if (due_date.end_type == RecurrencyEndType.ON_DATE) {
                    var date_label = Utils.Datetime.get_default_date_format_from_date (
                        Utils.Datetime.get_date_only (
                            Utils.Datetime.get_date_from_string (due_date.recurrency_end)
                        )
                    );
                    end_label = _("until") + " " + date_label;
                } else if (due_date.end_type == RecurrencyEndType.AFTER) {
                    int count = due_date.recurrency_count;
                    end_label = _("for") + " " + "%d %s".printf (count, count > 1 ? _("times") : _("time"));
                }

                date_icon.icon_name = "playlist-repeat-symbolic";

                string repeat_text = Utils.Datetime.get_recurrency_weeks (
                    due_date.recurrency_type,
                    due_date.recurrency_interval,
                    due_date.recurrency_weeks,
                    end_label
                ).down ();

                date_label.label += ", <small>%s</small>".printf (repeat_text);
                date_label.tooltip_text = repeat_text;
            }
        }
    }

    public class NoDateButton : Adw.Bin {
        public signal void clicked ();

        construct {
            var date_icon = new Gtk.Image.from_icon_name ("cross-large-circle-filled-symbolic");

            var date_label = new Gtk.Label (_("No date")) {
                ellipsize = END
            };

            var date_box = new Gtk.Box (HORIZONTAL, 6);
            date_box.append (date_icon);
            date_box.append (date_label);

            var button = new Gtk.Button () {
                child = date_box
            };

            button.clicked.connect (() => clicked ());

            child = button;
        }
    }

    public class OptionButton : Gtk.Box {
        public Gtk.Button main_button { get; private set; }
        public Gtk.Revealer clear_revealer { get; private set; }
        
        private Gtk.Label label;
        private Gtk.Image add_icon;

        public string icon_name { get; construct; }
        public string text { get; construct; }

        private bool _has_value = false;
        public bool has_value {
            get {
                return _has_value;
            }
            set {
                _has_value = value;
                add_icon.visible = !_has_value;
                clear_revealer.reveal_child = _has_value;
            }
        }

        public string label_text {
            get {
                return label.label;
            }
            set {
                label.label = value;
                label.tooltip_text = value;
            }
        }

        public signal void clicked ();
        public signal void clear_clicked ();

        public OptionButton (string icon_name, string text) {
            Object (
                icon_name: icon_name,
                text: text,
                orientation: Gtk.Orientation.HORIZONTAL,
                spacing: 0
            );
        }

        construct {
            var icon = new Gtk.Image.from_icon_name (icon_name);

            label = new Gtk.Label (text) {
                css_classes = { "font-weight-500" },
                ellipsize = END
            };

            add_icon = new Gtk.Image.from_icon_name ("plus-large-symbolic") {
                valign = Gtk.Align.CENTER,
                halign = Gtk.Align.END,
                hexpand = true
            };
            add_icon.add_css_class ("dimmed");

            var button_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
                hexpand = true,
                margin_start = 9,
                margin_top = 6,
                margin_bottom = 6,
                margin_end = 9
            };
            button_box.append (icon);
            button_box.append (label);
            button_box.append (add_icon);

            main_button = new Gtk.Button () {
                child = button_box,
                css_classes = { "flat", "no-padding" }
            };

            var clear_button = new Gtk.Button.from_icon_name ("cross-large-circle-filled-symbolic") {
                valign = Gtk.Align.CENTER,
                halign = Gtk.Align.CENTER,
                css_classes = { "flat" }
            };

            clear_revealer = new Gtk.Revealer () {
                child = clear_button,
                transition_type = SLIDE_RIGHT,
                reveal_child = false
            };

            append (main_button);
            append (clear_revealer);

            main_button.clicked.connect (() => {
                clicked ();
            });

            clear_button.clicked.connect (() => {
                clear_clicked ();
            });
        }
    }
}
