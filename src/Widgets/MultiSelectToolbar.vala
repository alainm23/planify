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

public class Widgets.MultiSelectToolbar : Gtk.Revealer {
    public Gee.HashMap<string, Widgets.ItemRow> items_selected;
    private Gtk.Popover reschedule_popover = null;
    private Widgets.ToggleButton reschedule_button;

    construct {
        items_selected = new Gee.HashMap <string, Widgets.ItemRow> ();

        halign = Gtk.Align.CENTER;
        valign = Gtk.Align.END;
        transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
        reveal_child = false;

        var done_button = new Gtk.Button ();
        done_button.label = _("Done");

        reschedule_button = new Widgets.ToggleButton (_("Schedule"), "office-calendar-symbolic");
        reschedule_button.margin_start = 6;
        reschedule_button.get_style_context ().add_class ("multi-select-toolbar-button");

        var move_button = new Widgets.ToggleButton (_("Move"), "move-project-symbolic");
        move_button.get_style_context ().add_class ("multi-select-toolbar-button");

        var delete_button = new Gtk.Button.from_icon_name ("user-trash-symbolic", Gtk.IconSize.MENU);
        delete_button.get_style_context ().add_class ("multi-select-toolbar-button");

        var view_button = new Gtk.Button.from_icon_name ("view-more-symbolic", Gtk.IconSize.MENU);
        view_button.get_style_context ().add_class ("multi-select-toolbar-button");

        var notification_box = new Gtk.Grid ();
        notification_box.valign = Gtk.Align.CENTER;

        notification_box.add (done_button);
        notification_box.add (reschedule_button);
        notification_box.add (move_button);
        notification_box.add (delete_button);
        notification_box.add (view_button);

        var notification_frame = new Gtk.Frame (null);
        notification_frame.margin = 9;
        notification_frame.width_request = 200;
        notification_frame.height_request = 24;
        notification_frame.get_style_context ().add_class ("app-notification");
        // notification_frame.get_style_context ().add_class ("select-box");
        notification_frame.add (notification_box);

        var notification_eventbox = new Gtk.EventBox ();
        notification_eventbox.margin_bottom = 12;
        notification_eventbox.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        notification_eventbox.above_child = false;
        notification_eventbox.add (notification_frame);

        done_button.clicked.connect (() => {
            unselect_all ();
        });

        add (notification_eventbox);

        Planner.event_bus.select_item.connect ((row) => {
            if (items_selected.has_key (row.item.id.to_string ())) {
                items_selected.unset (row.item.id.to_string ());
                row.item_selected = false;
            } else {
                items_selected.set (row.item.id.to_string (), row);
                row.item_selected = true;
            }

            check_select_bar ();
        });

        Planner.event_bus.unselect_all.connect ((row) => {
            if (items_selected.size > 0) {
                unselect_all ();
            }
        });

        reschedule_button.toggled.connect (() => {
            if (reschedule_button.active) {
                if (reschedule_popover == null) {
                    create_reschedule_popover ();
                }
            }

            reschedule_popover.popup ();
        });

        delete_button.clicked.connect (() => {
            if (items_selected.size > 0) {
                var message = "";
                if (items_selected.size > 1) {
                    message = _("Are you sure you want to delete %i tasks?".printf (items_selected.size));
                } else {
                    foreach (string key in items_selected.keys) {
                        message = _("Are you sure you want to delete <b>%s</b>?".printf (
                            items_selected.get (key).item.content
                        ));
                    }
                }
                var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (
                    _("Delete taks"),
                    message,
                    "user-trash-full",
                Gtk.ButtonsType.CANCEL);
    
                var remove_button = new Gtk.Button.with_label (_("Delete"));
                remove_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
                message_dialog.add_action_widget (remove_button, Gtk.ResponseType.ACCEPT);
    
                message_dialog.show_all ();
    
                if (message_dialog.run () == Gtk.ResponseType.ACCEPT) {
                    foreach (string key in items_selected.keys) {
                        var item = items_selected.get (key).item;

                        Planner.database.delete_item (item);
                        if (item.is_todoist == 1) {
                            Planner.todoist.add_delete_item (item);
                        }
                    }

                    unselect_all ();
                }
    
                message_dialog.destroy ();
            }
        });
    }

    private void create_reschedule_popover () {
        reschedule_popover = new Gtk.Popover (reschedule_button);
        reschedule_popover.position = Gtk.PositionType.BOTTOM;
        reschedule_popover.get_style_context ().add_class ("popover-background");

        var popover_grid = new Gtk.Grid ();
        popover_grid.margin_top = 6;
        popover_grid.width_request = 235;
        popover_grid.orientation = Gtk.Orientation.VERTICAL;
        popover_grid.add (get_calendar_widget ());
        popover_grid.show_all ();

        reschedule_popover.add (popover_grid);

        reschedule_popover.closed.connect (() => {
            reschedule_button.active = false;
        });
    }

    private Gtk.Widget get_calendar_widget () {
        var today_button = new Widgets.ModelButton (_("Today"), "help-about-symbolic", "");
        today_button.get_style_context ().add_class ("due-menuitem");
        today_button.item_image.pixel_size = 14;
        today_button.color = 0;
        today_button.due_label = true;

        var tomorrow_button = new Widgets.ModelButton (_("Tomorrow"), "x-office-calendar-symbolic", "");
        tomorrow_button.get_style_context ().add_class ("due-menuitem");
        tomorrow_button.item_image.pixel_size = 14;
        tomorrow_button.color = 1;
        tomorrow_button.due_label = true;

        var calendar = new Widgets.Calendar.Calendar ();
        calendar.hexpand = true;

        var grid = new Gtk.Grid ();
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.add (today_button);
        grid.add (tomorrow_button);
        grid.add (calendar);
        grid.show_all ();

        today_button.clicked.connect (() => {
            set_due (new GLib.DateTime.now_local ().to_string ());
        });

        tomorrow_button.clicked.connect (() => {
            set_due (new GLib.DateTime.now_local ().add_days (1).to_string ());
        });

        calendar.selection_changed.connect ((date) => {
            set_due (date.to_string ());
        });

        return grid;
    }

    private void set_due (string date) {
        //  foreach (var item in Planner.database.get_all_overdue_items ()) {
        //      item.due_date = date;
        //      Planner.database.set_due_item (item, false);
        //      if (item.is_todoist == 1) {
        //          Planner.todoist.update_item (item);
        //      }
        //  }
    }

    private void check_select_bar () {
        if (items_selected.size > 0) {
            // select_count_label.label = items_selected.size.to_string ();
            reveal_child = true;
            Planner.event_bus.magic_button_visible (false);
            Planner.event_bus.disconnect_typing_accel ();
        } else {
            reveal_child = false;
            Planner.event_bus.magic_button_visible (true);
            Planner.event_bus.connect_typing_accel ();
        }
    }

    private void unselect_all () {
        foreach (string key in items_selected.keys) {
            items_selected.get (key).item_selected = false;
        }

        items_selected.clear ();
        reveal_child = false;
        Planner.event_bus.magic_button_visible (true);
        Planner.event_bus.connect_typing_accel ();
    }
}
