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
    public bool is_creating { get; construct; }

    private Gtk.Revealer indicator_revealer;
    private Gtk.Label value_label;
    private Widgets.ReminderPicker.ReminderPicker reminder_picker;
    private Gtk.MenuButton button;

    public signal void reminder_added (Objects.Reminder reminder);
    public signal void picker_opened (bool active);

    private Gee.HashMap<ulong, weak GLib.Object> signal_map = new Gee.HashMap<ulong, weak GLib.Object> ();

    public ReminderButton (bool is_creating = false) {
        Object (
            is_board: false,
            is_creating: is_creating,
            valign: Gtk.Align.CENTER,
            halign: Gtk.Align.CENTER,
            tooltip_text: _("Add Reminders")
        );
    }

    public ReminderButton.for_board () {
        Object (
            is_board: true,
            is_creating: false,
            tooltip_text: _("Add Reminders")
        );
    }

    ~ReminderButton () {
        debug ("Destroying - Widgets.ReminderPicker.ReminderButton\n");
    }

    construct {
        reminder_picker = new Widgets.ReminderPicker.ReminderPicker (is_creating);

        if (is_board) {
            var title_label = new Gtk.Label (_("Reminders")) {
                halign = START,
                css_classes = { "title-4", "caption" }
            };

            value_label = new Gtk.Label (_("Add Reminders")) {
                xalign = 0,
                use_markup = true,
                halign = START,
                ellipsize = Pango.EllipsizeMode.END,
                css_classes = { "caption" }
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

            button = new Gtk.MenuButton () {
                popover = reminder_picker,
                child = card_grid,
                css_classes = { "flat", "card", "activatable", "menu-button-no-padding" },
                hexpand = true
            };

            child = button;
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

            button = new Gtk.MenuButton () {
                icon_name = "alarm-symbolic",
                popover = reminder_picker,
                css_classes = { "flat" }
            };

            var overlay = new Gtk.Overlay ();
            overlay.child = button;
            overlay.add_overlay (indicator_revealer);

            child = overlay;
        }

        signal_map[reminder_picker.reminder_added.connect ((reminder) => {
            reminder_added (reminder);

            if (is_creating) {
                reminder.id = Util.get_default ().generate_id (reminder);
                add_reminder (reminder, new Gee.ArrayList<Objects.Reminder> ());
            }
        })] = reminder_picker;

        signal_map[reminder_picker.reminder_deleted.connect (() => {
            indicator_revealer.reveal_child = reminder_picker.has_reminders;
        })] = reminder_picker;

        signal_map[reminder_picker.show.connect (() => {
            picker_opened (true);
        })] = reminder_picker;

        signal_map[reminder_picker.closed.connect (() => {
            picker_opened (false);
        })] = reminder_picker;
    }

    public void set_reminders (Gee.ArrayList<Objects.Reminder> reminders) {
        if (is_board) {
            value_label.label = _("Add Reminders");
            value_label.tooltip_text = null;
        }

        reminder_picker.set_reminders (reminders);

        if (reminders.size > 0) {
            build_value_label (reminders);
        }

        indicator_revealer.reveal_child = reminder_picker.has_reminders;
    }

    public void add_reminder (Objects.Reminder reminder, Gee.ArrayList<Objects.Reminder> reminders) {
        reminder_picker.add_reminder (reminder);

        if (reminders.size > 0 && is_board) {
            build_value_label (reminders);
        }

        indicator_revealer.reveal_child = reminder_picker.has_reminders;
    }

    public void delete_reminder (Objects.Reminder reminder, Gee.ArrayList<Objects.Reminder> reminders) {
        reminder_picker.delete_reminder (reminder);

        if (is_board) {
            value_label.label = _("Add Reminders");
            value_label.tooltip_text = null;

            if (reminders.size > 0) {
                build_value_label (reminders);
            }
        }

        indicator_revealer.reveal_child = reminder_picker.has_reminders;
    }

    private void build_value_label (Gee.ArrayList<Objects.Reminder> reminders) {
        value_label.label = "";
        for (int index = 0; index < reminders.size; index++) {
            string date = reminders[index].relative_text;

            if (index < reminders.size - 1) {
                value_label.label += date + ", ";
            } else {
                value_label.label += date;
            }
        }

        value_label.tooltip_text = value_label.label;
    }

    public Gee.ArrayList<Objects.Reminder> reminders () {
        return reminder_picker.reminders ();
    }

    public void open_picker (bool suggestions_view = false) {
        reminder_picker.suggestions_view = suggestions_view;
        button.active = true;
    }

    public void clean_up () {
        foreach (var entry in signal_map.entries) {
            entry.value.disconnect (entry.key);
        }

        signal_map.clear ();

        if (reminder_picker != null) {
            reminder_picker.clean_up ();
        }
    }
}
