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

public class Widgets.ReminderButton : Adw.Bin {
    public Objects.Item item { get; construct; }

    private Gtk.Revealer indicator_revealer;

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
        };

        var button = new Gtk.MenuButton () {
            child = new Widgets.DynamicIcon.from_icon_name ("planner-bell"),
            popover = reminder_picker,
            css_classes = { "flat" }
        };

        var overlay = new Gtk.Overlay ();
		overlay.child = button;
		overlay.add_overlay (indicator_revealer);

        child = overlay;
        update_request ();

        item.reminder_added.connect (() => {
            update_request ();
        });

        item.reminder_deleted.connect (() => {
            update_request ();
        });
    }

    public void update_request () {
        indicator_revealer.reveal_child = item.reminders.size > 0;
    }
}