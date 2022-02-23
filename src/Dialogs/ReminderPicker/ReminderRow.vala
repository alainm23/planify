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

public class Dialogs.ReminderPicker.ReminderRow : Gtk.ListBoxRow {
    public Objects.Reminder reminder { get; construct; }

    private Gtk.Revealer main_revealer;

    public bool is_creating {
        get {
            return reminder.id == Constants.INACTIVE;
        }
    }

    public signal void activated ();

    public ReminderRow (Objects.Reminder reminder) {
        Object (
            reminder: reminder
        );
    }

    public ReminderRow.new () {
        var reminder = new Objects.Reminder ();
        
        Object (
            reminder: reminder
        );
    }

    construct {
        get_style_context ().add_class ("row");

        var reminder_image = new Widgets.DynamicIcon ();
        reminder_image.size = 19;
        reminder_image.update_icon_name (is_creating ? "planner-plus-circle" : "planner-bell");

        var reminder_label = new Gtk.Label (is_creating ? _("Add reminder") : Util.get_default ().get_relative_date_from_date (reminder.due.datetime));

        var main_grid = new Gtk.Grid () {
            column_spacing = 6,
            margin = 3
        };

        main_grid.add (reminder_image);
        main_grid.add (reminder_label);

        var reminder_eventbox = new Gtk.EventBox ();
        reminder_eventbox.get_style_context ().add_class ("transition");
        reminder_eventbox.add (main_grid);

        main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };
        main_revealer.add (reminder_eventbox);

        add (main_revealer);

        Timeout.add (main_revealer.transition_duration, () => {
            main_revealer.reveal_child = true;
            return GLib.Source.REMOVE;
        });

        if (is_creating) {
            reminder_eventbox.button_press_event.connect ((sender, evt) => {
                if (evt.type == Gdk.EventType.BUTTON_PRESS && evt.button == 1) {
                    activated ();
                }
    
                return Gdk.EVENT_PROPAGATE;
            });
        }
    }

    public void hide_destroy () {
        main_revealer.reveal_child = false;
        Timeout.add (main_revealer.transition_duration, () => {
            destroy ();
            return GLib.Source.REMOVE;
        });
    }
}
