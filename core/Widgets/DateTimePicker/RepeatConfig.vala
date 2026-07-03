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

public class Widgets.DateTimePicker.RepeatConfig : Adw.NavigationPage {
    private Gtk.SpinButton recurrency_interval;
    private Gtk.Button recurrency_type_button;
    private Gtk.Label recurrency_type_label;
    private Gtk.Revealer recurrency_type_revealer;
    private Gtk.Revealer weeks_revealer;
    private Widgets.ContextMenu.MenuItem[] type_menu_items;
    private Adw.Bin dimming_widget;
    private Gtk.Label repeat_label;
    private int _selected_type = 2; // Default: Day(s)

    private Gtk.ToggleButton mo_button;
    private Gtk.ToggleButton tu_button;
    private Gtk.ToggleButton we_button;
    private Gtk.ToggleButton th_button;
    private Gtk.ToggleButton fr_button;
    private Gtk.ToggleButton sa_button;
    private Gtk.ToggleButton su_button;


    private Gtk.ToggleButton never_button;
    private Gtk.ToggleButton on_button;
    private Gtk.ToggleButton after_button;
    private Widgets.Calendar.Calendar calendar;
    private Gtk.Button datepicker_button;
    private Gtk.Label datepicker_label;
    private Gtk.Revealer calendar_revealer;
    private Gtk.SpinButton count_interval;
    private Gtk.Stack ends_stack;

    public Objects.DueDate duedate {
        set {
            recurrency_interval.value = value.recurrency_interval;

            if (value.recurrency_type == RecurrencyType.NONE) {
                _selected_type = (int) RecurrencyType.EVERY_DAY;
            } else {
                _selected_type = (int) value.recurrency_type;
            }

            string[] recurrency_items = {
                _("Minute(s)"), _("Hour(s)"), _("Day(s)"), _("Week(s)"), _("Month(s)"), _("Year(s)")
            };
            if (recurrency_type_label != null && _selected_type < recurrency_items.length) {
                recurrency_type_label.label = get_type_label (_selected_type, (int) recurrency_interval.value);
            }

            if (value.recurrency_type == RecurrencyType.EVERY_WEEK) {
                mo_button.active = value.recurrency_weeks.contains ("1");
                tu_button.active = value.recurrency_weeks.contains ("2");
                we_button.active = value.recurrency_weeks.contains ("3");
                th_button.active = value.recurrency_weeks.contains ("4");
                fr_button.active = value.recurrency_weeks.contains ("5");
                sa_button.active = value.recurrency_weeks.contains ("6");
                su_button.active = value.recurrency_weeks.contains ("7");
            }

            if (value.recurrency_end != "") {
                on_button.active = true;
            } else if (value.recurrency_count > 0) {
                after_button.active = true;
            }

            count_interval.value = value.recurrency_count;

            if (value.recurrency_end != "") {
                var date = Utils.Datetime.get_date_from_string (value.recurrency_end);
                if (calendar != null) {
                    calendar.date = date;
                }
            }

            update_repeat_label ();
        }
    }

    public signal void duedate_change (Objects.DueDate duedate);

    private Gee.HashMap<ulong, GLib.Object> signal_map = new Gee.HashMap<ulong, GLib.Object> ();

    public RepeatConfig () {
        Object (
            title: _("Repeat")
        );
    }

    ~RepeatConfig () {
        debug ("Destroying - Widgets.DateTimePicker.RepeatConfig\n");
    }

    construct {
        repeat_label = new Gtk.Label (null) {
            margin_top = 9,
            margin_bottom = 9,
            margin_start = 9,
            margin_end = 9,
            ellipsize = Pango.EllipsizeMode.END
        };
        repeat_label.add_css_class ("accent");

        var repeat_preview_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            margin_top = 6
        };
        repeat_preview_box.append (repeat_label);
        repeat_preview_box.add_css_class ("card");
        repeat_preview_box.add_css_class ("border-radius-6");

        recurrency_interval = new Gtk.SpinButton.with_range (1, 100, 1) {
            hexpand = true,
            valign = CENTER
        };

        string[] recurrency_items = {
            _("Minute(s)"), _("Hour(s)"), _("Day(s)"), _("Week(s)"), _("Month(s)"), _("Year(s)")
        };

        recurrency_type_label = new Gtk.Label (get_type_label (_selected_type, 1)) {
            hexpand = true,
            halign = START
        };

        var type_button_box = new Gtk.Box (HORIZONTAL, 6) {
            margin_start = 9,
            margin_end = 9,
            margin_top = 6,
            margin_bottom = 6
        };
        type_button_box.append (recurrency_type_label);
        type_button_box.append (new Gtk.Image.from_icon_name ("pan-down-symbolic"));

        recurrency_type_button = new Gtk.Button () {
            child = type_button_box,
            hexpand = true,
            valign = CENTER
        };

        // Build action sheet revealer for type selection
        var type_items_box = new Gtk.Box (VERTICAL, 0) {
            margin_start = 9,
            margin_end = 9,
            margin_bottom = 9,
            margin_top = 9
        };

        type_menu_items = new Widgets.ContextMenu.MenuItem[recurrency_items.length];
        for (int i = 0; i < recurrency_items.length; i++) {
            var type_item = new Widgets.ContextMenu.MenuItem (recurrency_items[i]) {
                autohide_popover = false
            };
            type_menu_items[i] = type_item;
            int index = i;
            type_item.clicked.connect (() => {
                _selected_type = index;
                recurrency_type_label.label = get_type_label (index, (int) recurrency_interval.value);
                recurrency_type_revealer.reveal_child = false;
                dimming_widget.visible = false;

                if ((RecurrencyType) _selected_type == RecurrencyType.EVERY_WEEK) {
                    weeks_revealer.reveal_child = true;
                } else {
                    weeks_revealer.reveal_child = false;
                }

                update_repeat_label ();
            });
            type_items_box.append (type_item);
        }

        var type_container = new Adw.Bin () {
            child = type_items_box
        };
        type_container.add_css_class ("card");

        recurrency_type_revealer = new Gtk.Revealer () {
            child = type_container,
            valign = END,
            transition_type = SLIDE_UP,
            reveal_child = false
        };

        recurrency_type_button.clicked.connect (() => {
            recurrency_type_revealer.reveal_child = !recurrency_type_revealer.reveal_child;
            dimming_widget.visible = recurrency_type_revealer.reveal_child;
        });

        var repeat_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            hexpand = true,
            margin_top = 6,
            homogeneous = true
        };
        repeat_box.append (recurrency_interval);
        repeat_box.append (recurrency_type_button);

        mo_button = new Gtk.ToggleButton.with_label (_("Mo")) {
            css_classes = { "no-padding", "caption" },
            width_request = 32,
            height_request = 32
        };

        tu_button = new Gtk.ToggleButton.with_label (_("Tu")) {
            css_classes = { "no-padding", "caption" },
            width_request = 32,
            height_request = 32
        };

        we_button = new Gtk.ToggleButton.with_label (_("We")) {
            css_classes = { "no-padding", "caption" },
            width_request = 32,
            height_request = 32
        };

        th_button = new Gtk.ToggleButton.with_label (_("Th")) {
            css_classes = { "no-padding", "caption" },
            width_request = 32,
            height_request = 32
        };

        fr_button = new Gtk.ToggleButton.with_label (_("Fr")) {
            css_classes = { "no-padding", "caption" },
            width_request = 32,
            height_request = 32
        };

        sa_button = new Gtk.ToggleButton.with_label (_("Sa")) {
            css_classes = { "no-padding", "caption" },
            width_request = 32,
            height_request = 32
        };

        su_button = new Gtk.ToggleButton.with_label (_("Su")) {
            css_classes = { "no-padding", "caption" },
            width_request = 32,
            height_request = 32
        };

        var weeks_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            hexpand = true,
            margin_top = 12,
            margin_bottom = 6,
            homogeneous = true
        };
        weeks_box.append (mo_button);
        weeks_box.append (tu_button);
        weeks_box.append (we_button);
        weeks_box.append (th_button);
        weeks_box.append (fr_button);
        weeks_box.append (sa_button);
        weeks_box.append (su_button);

        weeks_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            reveal_child = false,
            child = weeks_box
        };

        never_button = new Gtk.ToggleButton.with_label (_("Never")) {
            active = true
        };

        on_button = new Gtk.ToggleButton.with_label (_("On Date")) {
            group = never_button
        };

        after_button = new Gtk.ToggleButton.with_label (_("After")) {
            group = never_button
        };

        var ends_grid = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            css_classes = { "linked" },
            hexpand = true,
            homogeneous = true,
            margin_top = 6
        };

        ends_grid.append (never_button);
        ends_grid.append (on_button);
        ends_grid.append (after_button);

        calendar = new Widgets.Calendar.Calendar () {
            margin_start = 9,
            margin_end = 9,
            margin_bottom = 9,
            margin_top = 9
        };

        var calendar_container = new Adw.Bin () {
            child = calendar,
            margin_start = 0,
            margin_end = 0,
            margin_bottom = 0,
            margin_top = 0
        };
        calendar_container.add_css_class ("card");

        calendar_revealer = new Gtk.Revealer () {
            child = calendar_container,
            valign = END,
            transition_type = SLIDE_UP,
            reveal_child = false
        };

        datepicker_label = new Gtk.Label (Utils.Datetime.get_default_date_format_from_date (
            Utils.Datetime.get_date_only (new GLib.DateTime.now_local ().add_days (1))
        )) {
            hexpand = true,
            halign = CENTER
        };

        var datepicker_box = new Gtk.Box (HORIZONTAL, 6) {
            margin_start = 9, margin_end = 9, margin_top = 6, margin_bottom = 6
        };
        datepicker_box.append (datepicker_label);
        datepicker_box.append (new Gtk.Image.from_icon_name ("pan-down-symbolic"));

        datepicker_button = new Gtk.Button () {
            child = datepicker_box,
            hexpand = true
        };

        count_interval = new Gtk.SpinButton.with_range (1, 100, 1) {
            hexpand = true,
            halign = CENTER,
            valign = CENTER
        };

        ends_stack = new Gtk.Stack () {
            hexpand = true,
            transition_type = Gtk.StackTransitionType.CROSSFADE,
            margin_top = 12,
            margin_bottom = 6
        };

        ends_stack.add_named (new Gtk.Label (null), "never");
        ends_stack.add_named (datepicker_button, "on");
        ends_stack.add_named (count_interval, "after");

        var submit_button = new Widgets.LoadingButton (LoadingButtonType.LABEL, _("Apply")) {
            margin_top = 12,
            vexpand = true,
            valign = Gtk.Align.END
        };
        submit_button.add_css_class ("suggested-action");

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            margin_start = 9,
            margin_end = 9,
            margin_bottom = 9
        };
        content_box.append (repeat_preview_box);
        content_box.append (new Gtk.Label (_("Repeat every")) {
            css_classes = { "heading", "h4" },
            margin_top = 12,
            halign = Gtk.Align.START
        });
        content_box.append (repeat_box);
        content_box.append (weeks_revealer);
        content_box.append (new Gtk.Label (_("End")) {
            css_classes = { "heading", "h4" },
            margin_top = 12,
            halign = Gtk.Align.START
        });
        content_box.append (ends_grid);
        content_box.append (ends_stack);
        content_box.append (submit_button);

        dimming_widget = new Adw.Bin () {
            visible = false
        };
        dimming_widget.add_css_class ("dimming-bg");

        var content_overlay = new Gtk.Overlay () {
            child = content_box
        };
        content_overlay.add_overlay (dimming_widget);
        content_overlay.add_overlay (recurrency_type_revealer);
        content_overlay.add_overlay (calendar_revealer);

        var gesture = new Gtk.GestureClick ();
        dimming_widget.add_controller (gesture);
        gesture.pressed.connect (() => {
            recurrency_type_revealer.reveal_child = false;
            calendar_revealer.reveal_child = false;
            dimming_widget.visible = false;
        });

        child = content_overlay;
        update_repeat_label ();

        signal_map[recurrency_interval.value_changed.connect (() => {
            update_repeat_label ();
        })] = recurrency_interval;

        signal_map[mo_button.toggled.connect (() => {
            update_repeat_label ();
        })] = mo_button;

        signal_map[tu_button.toggled.connect (() => {
            update_repeat_label ();
        })] = tu_button;

        signal_map[we_button.toggled.connect (() => {
            update_repeat_label ();
        })] = we_button;

        signal_map[th_button.toggled.connect (() => {
            update_repeat_label ();
        })] = th_button;

        signal_map[fr_button.toggled.connect (() => {
            update_repeat_label ();
        })] = fr_button;

        signal_map[sa_button.toggled.connect (() => {
            update_repeat_label ();
        })] = sa_button;

        signal_map[su_button.toggled.connect (() => {
            update_repeat_label ();
        })] = su_button;

        submit_button.clicked.connect (() => {
            set_repeat ();
        });

        signal_map[never_button.toggled.connect (() => {
            ends_stack.visible_child_name = "never";
            update_repeat_label ();
        })] = never_button;

        signal_map[on_button.toggled.connect (() => {
            ends_stack.visible_child_name = "on";
            update_repeat_label ();
        })] = on_button;

        signal_map[after_button.toggled.connect (() => {
            ends_stack.visible_child_name = "after";
            update_repeat_label ();
        })] = after_button;

        signal_map[calendar.day_selected.connect (() => {
            calendar_revealer.reveal_child = false;
            dimming_widget.visible = false;
            update_repeat_label ();
        })] = calendar;

        datepicker_button.clicked.connect (() => {
            calendar_revealer.reveal_child = !calendar_revealer.reveal_child;
            dimming_widget.visible = calendar_revealer.reveal_child;
        });

        signal_map[count_interval.value_changed.connect (() => {
            update_repeat_label ();
        })] = count_interval;
    }

    private void set_repeat () {
        var duedate = new Objects.DueDate ();
        duedate.is_recurring = true;
        duedate.recurrency_type = (RecurrencyType) _selected_type;
        duedate.recurrency_interval = (int) recurrency_interval.value;

        if (on_button.active) {
            duedate.recurrency_count = 0;
            duedate.recurrency_end = calendar.date != null ? calendar.date.to_string () : "";
        } else if (after_button.active) {
            duedate.recurrency_count = (int) count_interval.value;
            duedate.recurrency_end = "";
        }

        if (duedate.recurrency_type == RecurrencyType.EVERY_WEEK) {
            duedate.recurrency_weeks = get_recurrency_weeks ();
        } else {
            duedate.recurrency_weeks = "";
        }

        duedate_change (duedate);
    }

    private string get_type_label (int type, int interval) {
        switch (type) {
            case 0: return ngettext ("Minute", "Minutes", interval);
            case 1: return ngettext ("Hour", "Hours", interval);
            case 2: return ngettext ("Day", "Days", interval);
            case 3: return ngettext ("Week", "Weeks", interval);
            case 4: return ngettext ("Month", "Months", interval);
            case 5: return ngettext ("Year", "Years", interval);
            default: return ngettext ("Day", "Days", interval);
        }
    }

    private string get_recurrency_weeks () {
        string returned = "";

        if (mo_button.active) {
            returned += "1,";
        }

        if (tu_button.active) {
            returned += "2,";
        }


        if (we_button.active) {
            returned += "3,";
        }


        if (th_button.active) {
            returned += "4,";
        }


        if (fr_button.active) {
            returned += "5,";
        }


        if (sa_button.active) {
            returned += "6,";
        }


        if (su_button.active) {
            returned += "7,";
        }

        if (returned != null && returned.split (",").length > 0) {
            return returned.slice (0, -1);
        }

        return returned;
    }

    private void update_repeat_label () {
        int interval = (int) recurrency_interval.value;
        recurrency_type_label.label = get_type_label (_selected_type, interval);

        if (type_menu_items != null) {
            for (int i = 0; i < type_menu_items.length; i++) {
                type_menu_items[i].title = get_type_label (i, interval);
            }
        }

        var end_label = "";
        if (on_button.active) {
            var cal_date = calendar.date ?? new GLib.DateTime.now_local ().add_days (1);
            var date_label = Utils.Datetime.get_default_date_format_from_date (
                Utils.Datetime.get_date_only (cal_date)
            );
            end_label = _("until") + " " + date_label;
            datepicker_label.label = date_label;
        } else if (after_button.active) {
            int count = (int) count_interval.value;
            end_label = _("for") + " " + "%d %s".printf (count, count > 1 ? _("times") : _("time"));
        }

        RecurrencyType selected_option = (RecurrencyType) _selected_type;
        string label = Utils.Datetime.get_recurrency_weeks (
            selected_option,
            (int) recurrency_interval.value,
            get_recurrency_weeks (),
            end_label
        );
        repeat_label.label = label;
    }

    public void clean_up () {
        foreach (var entry in signal_map.entries) {
            entry.value.disconnect (entry.key);
        }

        signal_map.clear ();
    }
}
