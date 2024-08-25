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
    private Gtk.DropDown recurrency_combobox;
    private Gtk.Label repeat_label;

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
    private Gtk.Calendar calendar;
    private Gtk.MenuButton datepicker_button;
    private Gtk.SpinButton count_interval;
    private Gtk.Stack ends_stack;

    public Objects.DueDate duedate {
        set {
            recurrency_interval.value = value.recurrency_interval;

            if (value.recurrency_type == RecurrencyType.NONE) {
                recurrency_combobox.selected = 0;
            } else {
                recurrency_combobox.selected = (int) value.recurrency_type;
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
                calendar.year = date.get_year ();
                calendar.month = date.get_month ();
                calendar.day = date.get_day_of_month ();
            }
            
            update_repeat_label ();
        }
    }

    public signal void duedate_change (Objects.DueDate duedate);
    public signal void back ();

    private Gee.HashMap<ulong, GLib.Object> signal_map = new Gee.HashMap<ulong, GLib.Object> ();

    public RepeatConfig () {
        Object (
            title: _("Repeat")
        );
    }

    ~RepeatConfig() {
        print ("Destroying Dialogs.RepeatConfig\n");
    }

    construct {
        var back_item = new Widgets.ContextMenu.MenuItem (_("Back"), "go-previous-symbolic");

        repeat_label = new Gtk.Label (null) {
            margin_top = 9,
            margin_bottom = 9,
            margin_start = 9,
            margin_end = 9
        };

        var repeat_preview_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            margin_top = 6
        };
        repeat_preview_box.append (repeat_label);
        repeat_preview_box.add_css_class ("card");
        repeat_preview_box.add_css_class ("border-radius-6");

        recurrency_interval = new Gtk.SpinButton.with_range (1, 100, 1) {
            hexpand = true,
            valign = CENTER,
            css_classes = { "popover-spinbutton" }
        };

        string[] items = {
            _("Minute(s)"), _("Hour(s)"), _("Day(s)"), _("Week(s)"), _("Month(s)"), _("Year(s)")
        };

        recurrency_combobox = new Gtk.DropDown.from_strings (items) {
            hexpand = true,
            selected = 0,
            valign = CENTER,
            selected = 2
        };

        var repeat_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            hexpand = true,
            margin_top = 6,
            homogeneous = true
        };
        repeat_box.append (recurrency_interval);
        repeat_box.append (recurrency_combobox);

        mo_button = new Gtk.ToggleButton.with_label (_("Mo")) {
            css_classes = { "no-padding", "caption", "toggle-circle-button" },
            width_request = 32,
            height_request = 32
        };        
        
        tu_button = new Gtk.ToggleButton.with_label (_("Tu")) {
            css_classes = { "no-padding", "caption", "toggle-circle-button" },
            width_request = 32,
            height_request = 32
        };  
        
        we_button = new Gtk.ToggleButton.with_label (_("We")) {
            css_classes = { "no-padding", "caption", "toggle-circle-button" },
            width_request = 32,
            height_request = 32
        };       
        
        th_button = new Gtk.ToggleButton.with_label (_("Th")) {
            css_classes = { "no-padding", "caption", "toggle-circle-button" },
            width_request = 32,
            height_request = 32
        };        
        
        fr_button = new Gtk.ToggleButton.with_label (_("Fr")) {
            css_classes = { "no-padding", "caption", "toggle-circle-button" },
            width_request = 32,
            height_request = 32
        };        
        
        sa_button = new Gtk.ToggleButton.with_label (_("Sa")) {
            css_classes = { "no-padding", "caption", "toggle-circle-button" },
            width_request = 32,
            height_request = 32
        };

        su_button = new Gtk.ToggleButton.with_label (_("Su")) {
            css_classes = { "no-padding", "caption", "toggle-circle-button" },
            width_request = 32,
            height_request = 32
        };

        var weeks_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            hexpand = true,
            margin_top = 12,
            margin_bottom = 12,
            homogeneous = true
        };
        weeks_box.append (mo_button);
        weeks_box.append (tu_button);
        weeks_box.append (we_button);
        weeks_box.append (th_button);
        weeks_box.append (fr_button);
        weeks_box.append (sa_button);
        weeks_box.append (su_button);

        var weeks_revealer = new Gtk.Revealer () {
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

        calendar = new Gtk.Calendar ();
        var calendar_popover = new Gtk.Popover () {
            child = calendar,
            has_arrow = false,
            halign = Gtk.Align.END,
            position = Gtk.PositionType.BOTTOM
        };

        datepicker_button = new Gtk.MenuButton () {
            label = Utils.Datetime.get_default_date_format_from_date (
                Utils.Datetime.get_date_only (new GLib.DateTime.now_local ().add_days (1))
            ),
            popover = calendar_popover
        };
        
        count_interval = new Gtk.SpinButton.with_range (1, 100, 1) {
            hexpand = true,
            halign = CENTER,
            valign = CENTER,
            css_classes = { "popover-spinbutton" }
        };

        ends_stack = new Gtk.Stack () {
			hexpand = true,
			transition_type = Gtk.StackTransitionType.CROSSFADE,
            margin_top = 6
		};

        ends_stack.add_named (new Gtk.Label (null), "never");
        ends_stack.add_named (datepicker_button, "on");
        ends_stack.add_named (count_interval, "after");

        var submit_button = new Widgets.LoadingButton (LoadingButtonType.LABEL, _("Done")) {
            margin_top = 6,
            vexpand = true,
            valign = Gtk.Align.END
        };
        submit_button.add_css_class ("suggested-action");

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            margin_start = 6,
            margin_end = 6
        };
        content_box.append (new Widgets.ContextMenu.MenuSeparator ());
        content_box.append (new Gtk.Label (_("Summary")) {
            css_classes = { "heading", "h4" },
            margin_top = 6,
            halign = Gtk.Align.START
        });
        content_box.append (repeat_preview_box);
        content_box.append (new Gtk.Label (_("Repeat every")) {
            css_classes = { "heading", "h4" },
            margin_top = 6,
            halign = Gtk.Align.START
        });
        content_box.append (repeat_box);
        content_box.append (weeks_revealer);
        content_box.append (new Gtk.Label (_("End")) {
            css_classes = { "heading", "h4" },
            margin_top = 6,
            halign = Gtk.Align.START
        });
        content_box.append (ends_grid);
        content_box.append (ends_stack);
        content_box.append (submit_button);

        var toolbar_view = new Adw.ToolbarView ();
        toolbar_view.add_top_bar (back_item);
		toolbar_view.content = content_box;

        child = toolbar_view;
        update_repeat_label ();
        Services.EventBus.get_default ().disconnect_typing_accel ();

        signal_map[recurrency_interval.value_changed.connect (() => {
            update_repeat_label ();
        })] = recurrency_interval;

        signal_map[recurrency_combobox.notify["selected-item"].connect (() => {
            if ((RecurrencyType) this.recurrency_combobox.selected == RecurrencyType.EVERY_WEEK) {
                weeks_revealer.reveal_child = true;
            } else {
                weeks_revealer.reveal_child = false;
            }

            update_repeat_label ();
        })] = recurrency_combobox;

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
            calendar_popover.popdown ();
            update_repeat_label ();
        })] = calendar;

        signal_map[count_interval.value_changed.connect (() => {
            update_repeat_label ();
        })] = count_interval;

        back_item.clicked.connect (() => {
            back ();
        });
    }

    private void set_repeat () {
        var duedate = new Objects.DueDate ();
        duedate.is_recurring = true;
        duedate.recurrency_type = (RecurrencyType) this.recurrency_combobox.selected;
        duedate.recurrency_interval = (int) recurrency_interval.value;

        if (on_button.active) {
            duedate.recurrency_count = 0;
            duedate.recurrency_end = calendar.get_date ().to_string ();
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

        if (returned.split (",").length > 0) {
            return returned.slice (0, -1);
        }

        return returned;
    }

    private void update_repeat_label () {
        var end_label = "";
        if (on_button.active) {
            var date_label = Utils.Datetime.get_default_date_format_from_date (
                Utils.Datetime.get_date_only (calendar.get_date ())
            );
            end_label = _("until") + " " + date_label;
            datepicker_button.label = date_label;
        } else if (after_button.active) {
            int count = (int) count_interval.value;
            end_label = _("for") + " " + "%d %s".printf (count, count > 1 ? _("times") : _("time"));
        }

        RecurrencyType selected_option = (RecurrencyType) this.recurrency_combobox.selected;
        string label = Utils.Datetime.get_recurrency_weeks (
            selected_option,
            (int) recurrency_interval.value,
            get_recurrency_weeks (),
            end_label
        );
        repeat_label.label = label;
    }
}
