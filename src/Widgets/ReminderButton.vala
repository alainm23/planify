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

public class Widgets.ReminderButton : Gtk.Grid {
    public Objects.Item item { get; construct; }

    private Gtk.Label badge_label;
    private Gtk.Revealer badge_revealer;

    public ReminderButton (Objects.Item item) {
        Object (
            item: item,
            valign: Gtk.Align.CENTER,
            halign: Gtk.Align.CENTER,
            tooltip_text: _("Add reminder(s)")
        );
    }

    construct {
        var reminder_picker = new Widgets.ReminderPicker.ReminderPicker (item);

        var bell_image = new Widgets.DynamicIcon ();
        bell_image.size = 16;
        bell_image.update_icon_name ("planner-bell");

        badge_label = new Gtk.Label (null);
        badge_label.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);

        badge_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT
        };

        badge_revealer.child = badge_label;

        var button_grid = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            valign = Gtk.Align.CENTER
        };

        button_grid.append (bell_image);
        button_grid.append (badge_revealer);

        var button = new Gtk.MenuButton () {
            child = button_grid,
            popover = reminder_picker
        };

        button.add_css_class (Granite.STYLE_CLASS_FLAT);

        attach (button, 0, 0);
        update_request ();

        item.reminder_added.connect (() => {
            update_request ();
        });

        item.reminder_deleted.connect (() => {
            update_request ();
        });
    }

    public void update_request () {
        badge_label.label = "%d".printf (item.reminders.size);
        badge_revealer.reveal_child = item.reminders.size > 0;
    }
}