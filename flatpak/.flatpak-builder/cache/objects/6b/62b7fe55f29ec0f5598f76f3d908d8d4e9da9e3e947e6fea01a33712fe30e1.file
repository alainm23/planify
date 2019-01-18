// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2011-2015 Maya Developers (http://launchpad.net/maya)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored by: Jaap Broekhuizen
 */

public class Maya.View.EventEdition.RepeatPanel : Gtk.Grid {
    private EventDialog parent_dialog;
    private Gtk.Switch repeat_switch;
    private Gtk.ComboBoxText repeat_combobox;
    private Gtk.ComboBoxText ends_combobox;
    private Gtk.SpinButton end_entry;
    private Granite.Widgets.DatePicker end_datepicker;
    private Gtk.Box week_box;
    private Gtk.Grid month_grid;
    private Gtk.SpinButton every_entry;
    private Gtk.Label every_unit_label;
    private Gtk.ListBox exceptions_list;

    private Gtk.ToggleButton mon_button;
    private Gtk.ToggleButton tue_button;
    private Gtk.ToggleButton wed_button;
    private Gtk.ToggleButton thu_button;
    private Gtk.ToggleButton fri_button;
    private Gtk.ToggleButton sat_button;
    private Gtk.ToggleButton sun_button;

    private Gtk.RadioButton every_radiobutton;
    private Gtk.RadioButton same_radiobutton;

    public RepeatPanel (EventDialog parent_dialog) {
        this.parent_dialog = parent_dialog;
        margin_start = 12;
        margin_end = 12;
        row_spacing = 6;
        column_spacing = 12;
        sensitive = parent_dialog.can_edit;

        var reminder_label = Maya.View.EventDialog.make_label (_("Repeat:"));

        repeat_switch = new Gtk.Switch ();

        repeat_combobox = new Gtk.ComboBoxText ();
        repeat_combobox.append_text (_("Daily"));
        repeat_combobox.append_text (_("Weekly"));
        repeat_combobox.append_text (_("Monthly"));
        repeat_combobox.append_text (_("Yearly"));
        repeat_combobox.active = 1;
        repeat_combobox.hexpand = true;
        repeat_combobox.sensitive = false;
        repeat_combobox.changed.connect (() => {
            switch (repeat_combobox.active) {
                case 1:
                    week_box.no_show_all = false;
                    week_box.show_all ();
                    month_grid.no_show_all = true;
                    month_grid.hide ();
                    break;
                case 2:
                    int day_of_week = parent_dialog.date_time.get_day_of_week ()+1;
                    if (day_of_week > 7)
                        day_of_week = 1;
                    set_every_day ((short)(day_of_week + Math.ceil ((double)parent_dialog.date_time.get_day_of_month ()/(double)7) * 8));
                    week_box.no_show_all = true;
                    week_box.hide ();
                    month_grid.no_show_all = false;
                    month_grid.show_all ();
                    break;
                default:
                    month_grid.no_show_all = true;
                    month_grid.hide ();
                    week_box.no_show_all = true;
                    week_box.hide ();
                    break;
            }
            every_entry.value_changed ();
        });

        var repeat_switch_grid = new Gtk.Grid ();
        repeat_switch_grid.valign = Gtk.Align.CENTER;
        repeat_switch_grid.add (repeat_switch);

        var repeat_grid = new Gtk.Grid ();
        repeat_grid.row_spacing = 6;
        repeat_grid.column_spacing = 12;
        repeat_grid.orientation = Gtk.Orientation.HORIZONTAL;
        repeat_grid.add (repeat_switch_grid);
        repeat_grid.add (repeat_combobox);

        var every_label = Maya.View.EventDialog.make_label (_("Every:"));

        every_entry = new Gtk.SpinButton.with_range (1, 99, 1);
        every_entry.hexpand = true;
        every_entry.value_changed.connect (() => {
            switch (repeat_combobox.active) {
                case 0:
                    every_unit_label.label = ngettext ("Day", "Days", (ulong)every_entry.value);
                    break;
                case 1:
                    every_unit_label.label = ngettext ("Week", "Weeks", (ulong)every_entry.value);
                    break;
                case 2:
                    every_unit_label.label = ngettext ("Month", "Months", (ulong)every_entry.value);
                    break;
                case 3:
                    every_unit_label.label = ngettext ("Year", "Years", (ulong)every_entry.value);
                    break;
            }
        });

        every_unit_label = new Gtk.Label (ngettext ("Week", "Weeks", 1));

        var every_grid = new Gtk.Grid ();
        every_grid.row_spacing = 6;
        every_grid.column_spacing = 12;
        every_grid.orientation = Gtk.Orientation.HORIZONTAL;
        every_grid.sensitive = false;
        every_grid.add (every_entry);
        every_grid.add (every_unit_label);

        var ends_label = Maya.View.EventDialog.make_label (_("Ends:"));

        var end_label = new Gtk.Label (ngettext ("Repeat", "Repeats", 1));
        end_label.no_show_all = true;

        ends_combobox = new Gtk.ComboBoxText ();
        ends_combobox.append_text (_("Never"));
        ends_combobox.append_text (_("Until"));
        ends_combobox.append_text (_("After"));
        ends_combobox.hexpand = true;
        ends_combobox.active = 0;
        ends_combobox.changed.connect (() => {
            switch (ends_combobox.active) {
                case 0:
                    end_label.hide ();
                    end_entry.hide ();
                    end_datepicker.hide ();
                    break;
                case 1:
                    end_label.hide ();
                    end_entry.hide ();
                    end_datepicker.show ();
                    break;
                case 2:
                    end_label.show ();
                    end_entry.show ();
                    end_datepicker.hide ();
                    break;
            }
        });

        end_entry = new Gtk.SpinButton.with_range (1, 99, 1);
        end_entry.no_show_all = true;
        end_entry.hexpand = true;
        end_entry.value_changed.connect (() => {
            end_label.label = ngettext ("Repeat", "Repeats", (ulong)end_entry.value);
        });

        end_datepicker = new Granite.Widgets.DatePicker.with_format (Maya.Settings.DateFormat ());
        end_datepicker.no_show_all = true;

        var ends_grid = new Gtk.Grid ();
        ends_grid.row_spacing = 6;
        ends_grid.column_spacing = 12;
        ends_grid.orientation = Gtk.Orientation.HORIZONTAL;
        ends_grid.sensitive = false;
        ends_grid.add (ends_combobox);
        ends_grid.add (end_entry);
        ends_grid.add (end_label);
        ends_grid.add (end_datepicker);

        create_week_box ();
        week_box.sensitive = false;

        same_radiobutton = new Gtk.RadioButton.with_label (null, _("The same day every month"));
        every_radiobutton = new Gtk.RadioButton.from_widget (same_radiobutton);

        month_grid = new Gtk.Grid ();
        month_grid.row_spacing = 6;
        month_grid.orientation = Gtk.Orientation.VERTICAL;
        month_grid.no_show_all = true;
        month_grid.sensitive = false;
        month_grid.add (same_radiobutton);
        month_grid.add (every_radiobutton);

        var exceptions_label = Maya.View.EventDialog.make_label (_("Exceptions:"));

        var no_exceptions_label = new Gtk.Label ("");
        no_exceptions_label.set_markup (_("No Exceptions"));
        no_exceptions_label.sensitive = false;
        no_exceptions_label.show ();

        exceptions_list = new Gtk.ListBox ();
        exceptions_list.expand = true;
        exceptions_list.set_selection_mode (Gtk.SelectionMode.NONE);
        exceptions_list.set_placeholder (no_exceptions_label);

        var exceptions_scrolled = new Gtk.ScrolledWindow (null, null);
        exceptions_scrolled.add (exceptions_list);
        exceptions_scrolled.expand = true;

        var exceptions_frame = new Gtk.Frame (null);
        exceptions_frame.add (exceptions_scrolled);

        var inline_toolbar = new Gtk.Toolbar ();
        inline_toolbar.get_style_context ().add_class (Gtk.STYLE_CLASS_INLINE_TOOLBAR);
        inline_toolbar.icon_size = Gtk.IconSize.SMALL_TOOLBAR;

        var add_button = new Gtk.ToolButton (new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.BUTTON), null);
        add_button.tooltip_text = _("Add Exception");
        add_button.clicked.connect (() => {
            var exception_grid = new ExceptionGrid (new GLib.DateTime.now_local ());
            exception_grid.show_all ();
            exceptions_list.add (exception_grid);
        });

        inline_toolbar.add (add_button);
        var exceptions_grid = new Gtk.Grid ();
        exceptions_grid.sensitive = false;
        exceptions_grid.orientation = Gtk.Orientation.VERTICAL;
        exceptions_grid.add (exceptions_frame);
        exceptions_grid.add (inline_toolbar);

        repeat_switch.notify["active"].connect (() => {
            bool active = repeat_switch.active;
            repeat_combobox.sensitive = active;
            every_grid.sensitive = active;
            week_box.sensitive = active;
            month_grid.sensitive = active;
            ends_grid.sensitive = active;
            exceptions_grid.sensitive = active;
        });
        repeat_switch.active = false;

        attach (reminder_label, 1, 0, 1, 1);
        attach (repeat_grid, 1, 1, 1, 1);
        attach (every_label, 1, 2, 1, 1);
        attach (every_grid, 1, 3, 1, 1);
        attach (week_box, 1, 4, 1, 1);
        attach (month_grid, 1, 4, 1, 1);
        attach (ends_label, 1, 5, 1, 1);
        attach (ends_grid, 1, 6, 1, 1);
        attach (exceptions_label, 1, 7, 1, 1);
        attach (exceptions_grid, 1, 8, 1, 1);
        load ();
    }

    private void load () {
        if (parent_dialog.ecal == null)
            return;

        unowned iCal.Component comp = parent_dialog.ecal.get_icalcomponent ();
        // Load the guests
        unowned iCal.Property property = comp.get_first_property (iCal.PropertyKind.RRULE);
        if (property != null) {
            repeat_switch.active = true;
            var rrule = property.get_rrule ();
            switch (rrule.freq) {
                case (iCal.RecurrenceTypeFrequency.WEEKLY):
                    repeat_combobox.active = 1;
                    for (int i = 0; i <= iCal.Size.BY_DAY; i++) {
                        if (rrule.by_day[i] > 7)
                            break;
                        switch (rrule.by_day[i]) {
                            case 1:
                                sun_button.active = true;
                                break;
                            case 2:
                                mon_button.active = true;
                                break;
                            case 3:
                                tue_button.active = true;
                                break;
                            case 4:
                                wed_button.active = true;
                                break;
                            case 5:
                                thu_button.active = true;
                                break;
                            case 6:
                                fri_button.active = true;
                                break;
                            default:
                                sat_button.active = true;
                                break;
                        }
                    }
                    break;
                case (iCal.RecurrenceTypeFrequency.MONTHLY):
                    repeat_combobox.active = 2;
                    for (int i = 0; i <= iCal.Size.BY_DAY; i++) {
                        if (rrule.by_day[i] < iCal.Size.BY_DAY) {
                            set_every_day (rrule.by_day[i]);
                            every_radiobutton.active = true;
                        }
                    }
                    if (rrule.by_month_day[0] < iCal.Size.BY_MONTHDAY) {
                        same_radiobutton.active = true;
                    }
                    break;
                case (iCal.RecurrenceTypeFrequency.YEARLY):
                    repeat_combobox.active = 3;
                    break;
                default:
                    warning ("%d", (int)rrule.freq);
                    repeat_combobox.active = 0;
                    break;
            }

            every_entry.value = rrule.interval;
            if (rrule.until.is_null_time () == 1) {
                ends_combobox.active = 0;
            } else {
                ends_combobox.active = 1;
                end_datepicker.date = Util.ical_to_date_time (rrule.until);
            }
            if (rrule.count > 0) {
                end_entry.value = rrule.count;
                ends_combobox.active = 2;
            }
        }

        property = comp.get_first_property (iCal.PropertyKind.EXDATE);
        while (property != null) {
            var exdate = property.get_exdate ();
            var exception_grid = new ExceptionGrid (Util.ical_to_date_time (exdate));
            exception_grid.show_all ();
            exceptions_list.add (exception_grid);
            property = comp.get_next_property (iCal.PropertyKind.EXDATE);
        }
    }

    /**
     * This can't be simplified because of some problems with the translation.
     * see https://bugs.launchpad.net/maya/+bug/1405605 for reference.
     */
    private void set_every_day (short day) {
        var day_position = iCal.RecurrenceType.day_position (day);
        var weekday = iCal.RecurrenceType.day_day_of_week (day);
        switch (day_position) {
            case -1:
                switch (weekday) {
                    case iCal.RecurrenceTypeWeekday.SUNDAY:
                        every_radiobutton.label = _("Every last Sunday");
                        break;
                    case iCal.RecurrenceTypeWeekday.MONDAY:
                        every_radiobutton.label = _("Every last Monday");
                        break;
                    case iCal.RecurrenceTypeWeekday.TUESDAY:
                        every_radiobutton.label = _("Every last Tuesday");
                        break;
                    case iCal.RecurrenceTypeWeekday.WEDNESDAY:
                        every_radiobutton.label = _("Every last Wednesday");
                        break;
                    case iCal.RecurrenceTypeWeekday.THURSDAY:
                        every_radiobutton.label = _("Every last Thursday");
                        break;
                    case iCal.RecurrenceTypeWeekday.FRIDAY:
                        every_radiobutton.label = _("Every last Friday");
                        break;
                    default:
                        every_radiobutton.label = _("Every last Saturday");
                        break;
                }
                break;
            case 1:
                switch (weekday) {
                    case iCal.RecurrenceTypeWeekday.SUNDAY:
                        every_radiobutton.label = _("Every first Sunday");
                        break;
                    case iCal.RecurrenceTypeWeekday.MONDAY:
                        every_radiobutton.label = _("Every first Monday");
                        break;
                    case iCal.RecurrenceTypeWeekday.TUESDAY:
                        every_radiobutton.label = _("Every first Tuesday");
                        break;
                    case iCal.RecurrenceTypeWeekday.WEDNESDAY:
                        every_radiobutton.label = _("Every first Wednesday");
                        break;
                    case iCal.RecurrenceTypeWeekday.THURSDAY:
                        every_radiobutton.label = _("Every first Thursday");
                        break;
                    case iCal.RecurrenceTypeWeekday.FRIDAY:
                        every_radiobutton.label = _("Every first Friday");
                        break;
                    default:
                        every_radiobutton.label = _("Every first Saturday");
                        break;
                }
                break;
            case 2:
                switch (weekday) {
                    case iCal.RecurrenceTypeWeekday.SUNDAY:
                        every_radiobutton.label = _("Every second Sunday");
                        break;
                    case iCal.RecurrenceTypeWeekday.MONDAY:
                        every_radiobutton.label = _("Every second Monday");
                        break;
                    case iCal.RecurrenceTypeWeekday.TUESDAY:
                        every_radiobutton.label = _("Every second Tuesday");
                        break;
                    case iCal.RecurrenceTypeWeekday.WEDNESDAY:
                        every_radiobutton.label = _("Every second Wednesday");
                        break;
                    case iCal.RecurrenceTypeWeekday.THURSDAY:
                        every_radiobutton.label = _("Every second Thursday");
                        break;
                    case iCal.RecurrenceTypeWeekday.FRIDAY:
                        every_radiobutton.label = _("Every second Friday");
                        break;
                    default:
                        every_radiobutton.label = _("Every second Saturday");
                        break;
                }
                break;
            case 3:
                switch (weekday) {
                    case iCal.RecurrenceTypeWeekday.SUNDAY:
                        every_radiobutton.label = _("Every third Sunday");
                        break;
                    case iCal.RecurrenceTypeWeekday.MONDAY:
                        every_radiobutton.label = _("Every third Monday");
                        break;
                    case iCal.RecurrenceTypeWeekday.TUESDAY:
                        every_radiobutton.label = _("Every third Tuesday");
                        break;
                    case iCal.RecurrenceTypeWeekday.WEDNESDAY:
                        every_radiobutton.label = _("Every third Wednesday");
                        break;
                    case iCal.RecurrenceTypeWeekday.THURSDAY:
                        every_radiobutton.label = _("Every third Thursday");
                        break;
                    case iCal.RecurrenceTypeWeekday.FRIDAY:
                        every_radiobutton.label = _("Every third Friday");
                        break;
                    default:
                        every_radiobutton.label = _("Every third Saturday");
                        break;
                }
                break;
            case 4:
                switch (weekday) {
                    case iCal.RecurrenceTypeWeekday.SUNDAY:
                        every_radiobutton.label = _("Every fourth Sunday");
                        break;
                    case iCal.RecurrenceTypeWeekday.MONDAY:
                        every_radiobutton.label = _("Every fourth Monday");
                        break;
                    case iCal.RecurrenceTypeWeekday.TUESDAY:
                        every_radiobutton.label = _("Every fourth Tuesday");
                        break;
                    case iCal.RecurrenceTypeWeekday.WEDNESDAY:
                        every_radiobutton.label = _("Every fourth Wednesday");
                        break;
                    case iCal.RecurrenceTypeWeekday.THURSDAY:
                        every_radiobutton.label = _("Every fourth Thursday");
                        break;
                    case iCal.RecurrenceTypeWeekday.FRIDAY:
                        every_radiobutton.label = _("Every fourth Friday");
                        break;
                    default:
                        every_radiobutton.label = _("Every fourth Saturday");
                        break;
                }
                break;
            default:
                switch (weekday) {
                    case iCal.RecurrenceTypeWeekday.SUNDAY:
                        every_radiobutton.label = _("Every fifth Sunday");
                        break;
                    case iCal.RecurrenceTypeWeekday.MONDAY:
                        every_radiobutton.label = _("Every fifth Monday");
                        break;
                    case iCal.RecurrenceTypeWeekday.TUESDAY:
                        every_radiobutton.label = _("Every fifth Tuesday");
                        break;
                    case iCal.RecurrenceTypeWeekday.WEDNESDAY:
                        every_radiobutton.label = _("Every fifth Wednesday");
                        break;
                    case iCal.RecurrenceTypeWeekday.THURSDAY:
                        every_radiobutton.label = _("Every fifth Thursday");
                        break;
                    case iCal.RecurrenceTypeWeekday.FRIDAY:
                        every_radiobutton.label = _("Every fifth Friday");
                        break;
                    default:
                        every_radiobutton.label = _("Every fifth Saturday");
                        break;
                }
                break;
        }
    }

    private void create_week_box () {
        week_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        week_box.homogeneous = true;
        mon_button = new Gtk.ToggleButton.with_label (_("Mon"));
        tue_button = new Gtk.ToggleButton.with_label (_("Tue"));
        wed_button = new Gtk.ToggleButton.with_label (_("Wed"));
        thu_button = new Gtk.ToggleButton.with_label (_("Thu"));
        fri_button = new Gtk.ToggleButton.with_label (_("Fri"));
        sat_button = new Gtk.ToggleButton.with_label (_("Sat"));
        sun_button = new Gtk.ToggleButton.with_label (_("Sun"));
        week_box.get_style_context ().add_class (Gtk.STYLE_CLASS_LINKED);
        week_box.get_style_context ().add_class ("raised");
        switch (Maya.Model.CalendarModel.get_default ().week_starts_on) {
            case Settings.Weekday.TUESDAY:
                week_box.add (thu_button);
                week_box.add (fri_button);
                week_box.add (sat_button);
                week_box.add (sun_button);
                week_box.add (mon_button);
                week_box.add (tue_button);
                week_box.add (wed_button);
                break;
            case Settings.Weekday.WEDNESDAY:
                week_box.add (wed_button);
                week_box.add (thu_button);
                week_box.add (fri_button);
                week_box.add (sat_button);
                week_box.add (sun_button);
                week_box.add (mon_button);
                week_box.add (tue_button);
                break;
            case Settings.Weekday.THURSDAY:
                week_box.add (thu_button);
                week_box.add (fri_button);
                week_box.add (sat_button);
                week_box.add (sun_button);
                week_box.add (mon_button);
                week_box.add (tue_button);
                week_box.add (wed_button);
                break;
            case Settings.Weekday.FRIDAY:
                week_box.add (fri_button);
                week_box.add (sat_button);
                week_box.add (sun_button);
                week_box.add (mon_button);
                week_box.add (tue_button);
                week_box.add (wed_button);
                week_box.add (thu_button);
                break;
            case Settings.Weekday.SATURDAY:
                week_box.add (sat_button);
                week_box.add (sun_button);
                week_box.add (mon_button);
                week_box.add (tue_button);
                week_box.add (wed_button);
                week_box.add (thu_button);
                week_box.add (fri_button);
                break;
            case Settings.Weekday.SUNDAY:
                week_box.add (sun_button);
                week_box.add (mon_button);
                week_box.add (tue_button);
                week_box.add (wed_button);
                week_box.add (thu_button);
                week_box.add (fri_button);
                week_box.add (sat_button);
                break;
            default:
                week_box.add (mon_button);
                week_box.add (tue_button);
                week_box.add (wed_button);
                week_box.add (thu_button);
                week_box.add (fri_button);
                week_box.add (sat_button);
                week_box.add (sun_button);
                break;
        }
    }

    /**
     * Save the values in the dialog into the component.
     */
    public void save () {
        // First clear all rrules
        unowned iCal.Component comp = parent_dialog.ecal.get_icalcomponent ();
        int count = comp.count_properties (iCal.PropertyKind.RRULE);

        for (int i = 0; i < count; i++) {
            unowned iCal.Property remove_prop = comp.get_first_property (iCal.PropertyKind.RRULE);
            comp.remove_property (remove_prop);
        }

        if (repeat_switch.active == false)
            return;

        // Add the rrule
        var property = new iCal.Property (iCal.PropertyKind.RRULE);

        iCal.RecurrenceType rrule = iCal.RecurrenceType.from_string ("");
        switch (repeat_combobox.active) {
            case 1:
                rrule.freq = iCal.RecurrenceTypeFrequency.WEEKLY;
                int index = 0;
                if (sun_button.active == true) {
                    rrule.by_day[index] = 1;
                    index++;
                }

                if (mon_button.active == true) {
                    rrule.by_day[index] = 2;
                    index++;
                }

                if (tue_button.active == true) {
                    rrule.by_day[index] = 3;
                    index++;
                }

                if (wed_button.active == true) {
                    rrule.by_day[index] = 4;
                    index++;
                }

                if (thu_button.active == true) {
                    rrule.by_day[index] = 5;
                    index++;
                }

                if (fri_button.active == true) {
                    rrule.by_day[index] = 6;
                    index++;
                }

                if (sat_button.active == true) {
                    rrule.by_day[index] = 7;
                    index++;
                }
                break;
            case 2:
                rrule.freq = iCal.RecurrenceTypeFrequency.MONTHLY;
                if (every_radiobutton.active == true) {
                    int day_of_week = parent_dialog.date_time.get_day_of_week ()+1;
                    if (day_of_week > 7)
                        day_of_week = 1;
                    rrule.by_day[0] = (short)(day_of_week + Math.ceil ((double)parent_dialog.date_time.get_day_of_month ()/(double)7) * 8);
                } else {
                    rrule.by_month_day[0] = (short)parent_dialog.date_time.get_day_of_month ();
                }
                break;
            case 3:
                rrule.freq = iCal.RecurrenceTypeFrequency.YEARLY;
                break;
            default:
                rrule.freq = iCal.RecurrenceTypeFrequency.DAILY;
                break;
        }
        if (ends_combobox.active == 2) {
            rrule.count = (int)end_entry.value;
        } else if (ends_combobox.active == 1) {
            rrule.until = iCal.TimeType.from_day_of_year (end_datepicker.date.get_day_of_year (), end_datepicker.date.get_year ());
        }

        rrule.interval = (short)every_entry.value;
        property.set_rrule (rrule);
        comp.add_property (property);

        // Save exceptions
        count = comp.count_properties (iCal.PropertyKind.EXDATE);
        for (int i = 0; i < count; i++) {
            unowned iCal.Property remove_prop = comp.get_first_property (iCal.PropertyKind.EXDATE);
            comp.remove_property (remove_prop);
        }

        foreach (var child in exceptions_list.get_children ()) {
            if (child is ExceptionGrid == false)
                continue;
            var exgrid = (ExceptionGrid)child;
            var date = exgrid.get_date ();
            var exdate = new iCal.Property (iCal.PropertyKind.EXDATE);
            exdate.set_exdate (Util.date_time_to_ical (date, null));
            comp.add_property (exdate);
        }
    }
}

public class Maya.View.EventEdition.ExceptionGrid : Gtk.ListBoxRow {
    private Granite.Widgets.DatePicker date;
    public ExceptionGrid (GLib.DateTime dt) {
        set_margin_top (6);
        set_margin_start (6);
        set_margin_end (6);

        date = new Granite.Widgets.DatePicker ();
        date.date = dt;
        date.hexpand = true;

        var remove_button = new Gtk.Button.from_icon_name ("edit-delete-symbolic", Gtk.IconSize.BUTTON);
        remove_button.relief = Gtk.ReliefStyle.NONE;
        remove_button.clicked.connect (() => {hide (); destroy ();});

        var grid = new Gtk.Grid ();
        grid.row_spacing = 6;
        grid.column_spacing = 12;
        grid.attach (date, 0, 0, 1, 1);
        grid.attach (remove_button, 2, 0, 1, 1);

        add (grid);
    }

    public GLib.DateTime get_date () {
        return date.date;
    }
}
