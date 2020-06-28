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

public class Widgets.DueButton : Gtk.ToggleButton {
    public Objects.Item item { get; construct; }

    private Gtk.Label due_label;
    private Gtk.Image due_image;
    private Gtk.Revealer label_revealer;

    private Gtk.Popover popover = null;

    private Widgets.ModelButton today_button;
    private Widgets.ModelButton tomorrow_button;
    private Widgets.ModelButton undated_button;
    private Widgets.Calendar.Calendar calendar;
    private Gtk.Switch recurring_switch;
    private Gtk.Revealer combobox_revealer;
    private Gtk.ComboBox combobox;
    private Gtk.ListStore liststore;
    private Gtk.Image repeat_image;
    private Gtk.Revealer repeat_revealer;

    private Gtk.TreeIter e_day_iter;
    private Gtk.TreeIter e_week_iter;
    private Gtk.TreeIter e_month_iter;
    private Gtk.TreeIter e_year_iter;

    public DueButton (Objects.Item item) {
        Object (
            item: item
        );
    }

    construct {
        tooltip_text = _("Schedule");

        get_style_context ().add_class ("flat");
        get_style_context ().add_class ("item-action-button");

        due_image = new Gtk.Image ();
        due_image.valign = Gtk.Align.CENTER;
        due_image.pixel_size = 16;

        due_label = new Gtk.Label (_("Schedule"));
        due_label.use_markup = true;

        label_revealer = new Gtk.Revealer ();
        label_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
        label_revealer.add (due_label);
        label_revealer.reveal_child = true;

        repeat_image = new Gtk.Image ();
        repeat_image.valign = Gtk.Align.CENTER;
        repeat_image.pixel_size = 10;
        repeat_image.margin_top = 2;
        repeat_image.gicon = new ThemedIcon ("media-playlist-repeat-symbolic");

        repeat_revealer = new Gtk.Revealer ();
        repeat_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
        repeat_revealer.add (repeat_image);

        var main_grid = new Gtk.Grid ();
        main_grid.halign = Gtk.Align.CENTER;
        main_grid.valign = Gtk.Align.CENTER;
        main_grid.add (due_image);
        main_grid.add (label_revealer);
        main_grid.add (repeat_revealer);

        add (main_grid);

        this.toggled.connect (() => {
            if (this.active) {
                if (popover == null) {
                    create_popover ();
                }

                if (item.due_date == "") {
                    undated_button.visible = false;
                    undated_button.no_show_all = true;
                    combobox.set_active_iter (e_day_iter);
                } else {
                    undated_button.visible = true;
                    undated_button.no_show_all = false;
                }

                if (item.due_is_recurring == 1) {
                    int recurring_iter = Planner.utils.get_recurring_iter (item);

                    if (recurring_iter == 0) {
                        combobox.set_active_iter (e_day_iter);
                    } else if (recurring_iter == 1) {
                        combobox.set_active_iter (e_week_iter);
                    } else if (recurring_iter == 2) {
                        combobox.set_active_iter (e_month_iter);
                    } else if (recurring_iter == 3) {
                        combobox.set_active_iter (e_year_iter);
                    }

                    recurring_switch.active = true;
                }

                popover.popup ();
            }
        });

        update_date_text (item);
        Planner.settings.changed.connect ((key) => {
            if (key == "appearance") {
                update_date_text (item);
            }
        });
    }

    public void update_date_text (Objects.Item item) {
        due_label.label = _("Schedule");
        if (Planner.settings.get_enum ("appearance") == 0) {
            due_image.gicon = new ThemedIcon ("calendar-outline-light");
        } else {
            due_image.gicon = new ThemedIcon ("calendar-outline-dark");
        }

        due_image.get_style_context ().remove_class ("overdue-label");
        due_image.get_style_context ().remove_class ("today");
        due_image.get_style_context ().remove_class ("upcoming");

        repeat_revealer.reveal_child = false;

        if (item.due_date != "") {
            var date = new GLib.DateTime.from_iso8601 (item.due_date, new GLib.TimeZone.local ());
            due_label.label = "%s".printf (Planner.utils.get_relative_date_from_date (date));

            if (Planner.utils.is_today (date)) {
                due_image.gicon = new ThemedIcon ("help-about-symbolic");
                due_image.get_style_context ().add_class ("today");
            } else if (Planner.utils.is_overdue (date)) {
                due_image.gicon = new ThemedIcon ("calendar-overdue");
                due_image.get_style_context ().add_class ("overdue-label");
            } else {
                if (Planner.settings.get_enum ("appearance") == 0) {
                    due_image.gicon = new ThemedIcon ("calendar-outline-light");
                } else {
                    due_image.gicon = new ThemedIcon ("calendar-outline-dark");
                }

                due_image.get_style_context ().add_class ("upcoming");
            }

            if (item.due_is_recurring == 1) {
                repeat_revealer.reveal_child = true;
            } else {
                repeat_revealer.reveal_child = false;
            }
        }
    }

    private void create_popover () {
        popover = new Gtk.Popover (this);
        popover.position = Gtk.PositionType.RIGHT;
        popover.get_style_context ().add_class ("popover-background");

        var popover_grid = new Gtk.Grid ();
        popover_grid.margin_top = 6;
        popover_grid.margin_bottom = 12;
        popover_grid.width_request = 235;
        popover_grid.orientation = Gtk.Orientation.VERTICAL;
        popover_grid.add (get_calendar_widget ());
        popover_grid.show_all ();

        popover.add (popover_grid);

        popover.closed.connect (() => {
            this.active = false;
        });
    }

    private Gtk.Widget get_calendar_widget () {
        today_button = new Widgets.ModelButton (_("Today"), "help-about-symbolic", "");
        today_button.get_style_context ().add_class ("due-menuitem");
        today_button.item_image.pixel_size = 14;
        today_button.color = 0;
        today_button.due_label = true;

        tomorrow_button = new Widgets.ModelButton (_("Tomorrow"), "x-office-calendar-symbolic", "");
        tomorrow_button.get_style_context ().add_class ("due-menuitem");
        tomorrow_button.item_image.pixel_size = 14;
        tomorrow_button.color = 1;
        tomorrow_button.due_label = true;

        undated_button = new Widgets.ModelButton (_("Undated"), "window-close-symbolic", "");
        undated_button.get_style_context ().add_class ("due-menuitem");
        undated_button.item_image.pixel_size = 14;
        undated_button.color = 2;
        undated_button.due_label = true;

        calendar = new Widgets.Calendar.Calendar ();
        calendar.hexpand = true;

        var recurring_header = new Gtk.Label (_("Repeat"));
        recurring_header.get_style_context ().add_class ("font-bold");

        recurring_switch = new Gtk.Switch ();
        recurring_switch.get_style_context ().add_class ("active-switch");

        var recurring_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        recurring_box.hexpand = true;
        recurring_box.margin_start = 16;
        recurring_box.margin_end = 16;
        recurring_box.pack_start (recurring_header, false, false, 0);
        recurring_box.pack_end (recurring_switch, false, false, 0);

        liststore = new Gtk.ListStore (2, typeof (int), typeof (string));
        combobox = new Gtk.ComboBox.with_model (liststore);
        combobox.margin_top = 9;
        combobox.margin_start = 16;
        combobox.margin_end = 16;
        combobox.margin_bottom = 1;

        liststore.append (out e_day_iter);
        liststore.@set (e_day_iter,
            0, 0,
            1, " " + _("Every day")
        );

        liststore.append (out e_week_iter);
        liststore.@set (e_week_iter,
            0, 1,
            1, " " + _("Every week")
        );

        liststore.append (out e_month_iter);
        liststore.@set (e_month_iter,
            0, 2,
            1, " " + _("Every month")
        );

        liststore.append (out e_year_iter);
        liststore.@set (e_year_iter,
            0, 3,
            1, " " + _("Every year")
        );

        var text_cell = new Gtk.CellRendererText ();
        combobox.pack_start (text_cell, true);
        combobox.add_attribute (text_cell, "text", 1);

        combobox_revealer = new Gtk.Revealer ();
        combobox_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
        combobox_revealer.add (combobox);

        recurring_switch.notify["active"].connect (() => {
            update_duedate ();
        });

        combobox.changed.connect (() => {
            update_duedate ();
        });

        var grid = new Gtk.Grid ();
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.add (today_button);
        grid.add (tomorrow_button);
        grid.add (undated_button);
        grid.add (calendar);
        grid.add (recurring_box);
        grid.add (combobox_revealer);
        grid.show_all ();

        today_button.clicked.connect (() => {
            set_due (new GLib.DateTime.now_local ().to_string ());
        });

        tomorrow_button.clicked.connect (() => {
            set_due (new GLib.DateTime.now_local ().add_days (1).to_string ());
        });

        undated_button.clicked.connect (() => {
            set_due ("");
            popover.popdown ();
        });

        calendar.selection_changed.connect ((date) => {
            set_due (date.to_string ());
        });

        return grid;
    }

    private void update_duedate () {
        if (recurring_switch.active) {
            combobox_revealer.reveal_child = true;

            if (item.due_date == "") {
                item.due_is_recurring = 1;
                item.due_string = get_string_selected ();
                item.due_lang = "en";
                set_due (new GLib.DateTime.now_local ().to_string ());
            } else {
                item.due_is_recurring = 1;
                item.due_string = get_string_selected ();
                item.due_lang = "en";
                set_due (item.due_date);
            }
        } else {
            item.due_is_recurring = 0;
            item.due_string = "";
            item.due_lang = "";

            combobox_revealer.reveal_child = false;
            set_due (item.due_date);
        }
    }

    public string get_string_selected () {
        string returned = "";
        Gtk.TreeIter iter;
        if (!combobox.get_active_iter (out iter)) {
            return "";
        }

        Value item;
        liststore.get_value (iter, 0, out item);

        if (((int) item) == 0) {
            returned = "every day";
        } else if (((int) item) == 1) {
            returned = "every week";
        } else if (((int) item) == 2) {
            returned = "every month";
        } else if (((int) item) == 3) {
            returned = "every year";
        }

        return returned;
    }

    public void set_due (string date) {
        bool new_date = false;
        if (date != "") {
            undated_button.visible = true;
            undated_button.no_show_all = false;

            if (item.due_date == "") {
                new_date = true;
            }

            item.due_date = date;
        } else {
            undated_button.visible = false;
            undated_button.no_show_all = true;
            combobox.set_active_iter (e_day_iter);

            item.due_date = "";
            item.due_is_recurring = 0;
            item.due_string = "";
            item.due_lang = "";

            recurring_switch.active = false;
        }

        Planner.database.set_due_item (item, new_date);
        if (item.is_todoist == 1) {
            Planner.todoist.update_item (item);
        }
    }
}
