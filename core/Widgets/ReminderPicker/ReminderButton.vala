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

public class Widgets.ReminderPicker.ReminderButton : Adw.Bin {
    public bool is_board { get; construct; }

    private Gtk.Revealer indicator_revealer;
    private Gtk.Label value_label;
    private Widgets.ReminderPicker._ReminderPicker picker;

    public signal void reminder_added (Objects.Reminder reminder);
    

    public ReminderButton () {
        Object (
            is_board: false,
            valign: Gtk.Align.CENTER,
            halign: Gtk.Align.CENTER,
            tooltip_text: _("Add Reminders")
        );
    }

    public ReminderButton.for_board () {
        Object (
            is_board: true,
            tooltip_text: _("Add Reminders")
        );
    }

    construct {
        picker = new Widgets.ReminderPicker._ReminderPicker ();

        if (is_board) {
            var title_label = new Gtk.Label (_("Reminders")) {
                halign = START,
                css_classes = { "title-4", "small-label" }
            };

            value_label = new Gtk.Label (_("Add Reminders")) {
                xalign = 0,
                use_markup = true,
                halign = START,
                ellipsize = Pango.EllipsizeMode.END,
                css_classes = { "small-label" }
            };

            var card_grid = new Gtk.Grid () {
                column_spacing = 12,
                margin_start = 12,
                margin_end = 6,
                margin_top = 6,
                margin_bottom = 6,
                vexpand = true,
                hexpand = true
            };
            card_grid.attach (new Gtk.Image.from_icon_name ("alarm-symbolic"), 0, 0, 1, 2);
            card_grid.attach (title_label, 1, 0, 1, 1);
            card_grid.attach (value_label, 1, 1, 1, 1);

            picker.set_parent (card_grid);

            css_classes = { "card" };
            child = card_grid;
            hexpand = true;
            vexpand = true;
    
            var click_gesture = new Gtk.GestureClick ();
            card_grid.add_controller (click_gesture);
            click_gesture.pressed.connect ((n_press, x, y) => {
                picker.show ();
            });
        } else {
            var indicator_grid = new Gtk.Grid () {
                width_request = 9,
                height_request = 9,
                margin_top = 3,
                margin_end = 3,
                css_classes = { "indicator" }
            };

            indicator_revealer = new Gtk.Revealer () {
                transition_type = Gtk.RevealerTransitionType.CROSSFADE,
                child = indicator_grid,
                halign = END,
                valign = START,
                sensitive = false,
            };

            var button = new Gtk.MenuButton () {
                icon_name = "alarm-symbolic",
                popover = picker,
                css_classes = { "flat" }
            };

            var overlay = new Gtk.Overlay ();
            overlay.child = button;
            overlay.add_overlay (indicator_revealer);

            child = overlay;
        }

        picker.reminder_added.connect ((reminder) => {
            reminder_added (reminder);
        });
    }

    public void set_reminders (Gee.ArrayList<Objects.Reminder> reminders) {
        value_label.label = _("Add Reminders");
        value_label.tooltip_text = null;

        picker.set_reminders (reminders);

        if (reminders.size > 0) {
            build_value_label (reminders);
        }
    }

    public void add_reminder (Objects.Reminder reminder, Gee.ArrayList<Objects.Reminder> reminders) {
        picker.add_reminder (reminder);

        if (reminders.size > 0) {
            build_value_label (reminders);
        }
    }

    public void delete_reminder (Objects.Reminder reminder, Gee.ArrayList<Objects.Reminder> reminders) {
        picker.delete_reminder (reminder);

        value_label.label = _("Add Reminders");
        value_label.tooltip_text = null;

        if (reminders.size > 0) {
            build_value_label (reminders);
        }
    }

    private void build_value_label (Gee.ArrayList<Objects.Reminder> reminders) {
        value_label.label = "";        
        for (int index = 0; index < reminders.size; index++) {
            var date = Util.get_default ().get_relative_date_from_date (reminders[index].due.datetime);

            if (index < reminders.size - 1) {
                value_label.label += date + ", ";
            } else {
                value_label.label += date;
            }
        }

        value_label.tooltip_text = value_label.label;
    }
}
