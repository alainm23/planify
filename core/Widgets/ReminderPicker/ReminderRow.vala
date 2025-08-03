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

public class Widgets.ReminderPicker.ReminderRow : Gtk.ListBoxRow {
    public Objects.Reminder reminder { get; construct; }

    private Gtk.Revealer main_revealer;

    public signal void activated ();
    public signal void deleted ();

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
        add_css_class ("row");

        var reminder_label = new Gtk.Label (reminder.relative_text);

        var remove_button = new Widgets.LoadingButton.with_icon ("cross-large-circle-filled-symbolic") {
            hexpand = true,
            margin_end = 6,
            halign = Gtk.Align.END
        };

        remove_button.add_css_class ("flat");
        remove_button.add_css_class ("no-padding");

        var reminder_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            margin_top = 3,
            margin_bottom = 3,
            margin_start = 3
        };

        reminder_box.append (new Gtk.Image.from_icon_name ("alarm-symbolic"));
        reminder_box.append (reminder_label);
        reminder_box.append (remove_button);

        main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            child = reminder_box
        };

        child = main_revealer;

        Timeout.add (main_revealer.transition_duration, () => {
            main_revealer.reveal_child = true;
            return GLib.Source.REMOVE;
        });

        remove_button.clicked.connect (() => {
            deleted ();
        });

        reminder.loading_change.connect (() => {
            remove_button.is_loading = reminder.loading;
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
