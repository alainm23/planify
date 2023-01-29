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
            return reminder.id == "";
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
        reminder_image.size = 21;
        reminder_image.update_icon_name (is_creating ? "planner-plus-circle" : "planner-bell");

        var reminder_label = new Gtk.Label (is_creating ? _("Add reminder") : Util.get_default ().get_relative_date_from_date (reminder.due.datetime));

        var remove_button = new Widgets.LoadingButton.with_icon ("planner-close-circle") {
            hexpand = true,
            halign = Gtk.Align.END
        };
        
        remove_button.get_style_context ().add_class (Granite.STYLE_CLASS_FLAT);
        remove_button.get_style_context ().add_class ("no-padding");
        
        var reminder_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            margin_top = 3,
            margin_bottom = 3,
            margin_start = 3,
            margin_end = 3
        };

        reminder_box.append (reminder_image);
        reminder_box.append (reminder_label);
        reminder_box.append (remove_button);

        main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };
        main_revealer.child = reminder_box;

        child = main_revealer;

        Timeout.add (main_revealer.transition_duration, () => {
            main_revealer.reveal_child = true;
            return GLib.Source.REMOVE;
        });

        remove_button.clicked.connect (() => {
            reminder.delete (remove_button);
        });
    }

    public void hide_destroy () {
        main_revealer.reveal_child = false;
        Timeout.add (main_revealer.transition_duration, () => {
            ((Gtk.ListBox) parent).remove (this);
            return GLib.Source.REMOVE;
        });
    }
}