/*
* Copyright © 2019 Alain M. (https://github.com/alainm23/planner)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
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
* Authored by: Alain M. <alain23@protonmail.com>
*/

public class Widgets.WhenButton : Gtk.ToggleButton {
    private Widgets.Popovers.WhenPopover when_popover;
    const string when_text = _("When");

    public bool has_when = false;
    public bool has_reminder = false;

    public GLib.DateTime reminder_datetime;
    public GLib.DateTime when_datetime;

    private Gtk.Revealer reminder_revealer;
    private Gtk.Label when_label;
    private Gtk.Label reminder_label;

    public signal void on_signal_selected ();
    public WhenButton () {
        Object (
            valign: Gtk.Align.CENTER
        );
    }

    construct {
        get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var when_icon = new Gtk.Image.from_icon_name ("office-calendar-symbolic", Gtk.IconSize.MENU);

        when_label = new Gtk.Label (when_text);
        when_label.margin_bottom = 1;

        var reminder_icon = new Gtk.Image.from_icon_name ("notification-new-symbolic", Gtk.IconSize.MENU);
        reminder_label = new Gtk.Label ("");

        var reminder_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        reminder_box.pack_start (reminder_icon, false, false, 0);
        reminder_box.pack_start (reminder_label, false, false, 0);

        reminder_revealer = new Gtk.Revealer ();
        reminder_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
        reminder_revealer.margin_start = 3;
        reminder_revealer.reveal_child = false;
        reminder_revealer.add (reminder_box);

        when_popover = new Widgets.Popovers.WhenPopover (this);

        var main_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        main_box.pack_start (when_icon, false, false, 0);
        main_box.pack_start (when_label, false, false, 0);
        main_box.pack_start (reminder_revealer, false, false, 0);

        add (main_box);

        this.toggled.connect (() => {
          if (this.active) {
            when_popover.show_all ();
            if (has_when) {
                when_popover.remove_button.visible = true;
            }
          }
        });

        when_popover.closed.connect (() => {
            this.active = false;
        });

        when_popover.on_selected_remove.connect (() => {
            clear ();
        });

        when_popover.on_selected_date.connect ((date, _has_reminder, _reminder_datetime) => {
            set_date (date, _has_reminder, _reminder_datetime);
            on_signal_selected ();
        });
    }

    public void clear () {
        when_label.label = when_text;
        reminder_revealer.reveal_child = false;

        has_when = false;
        has_reminder = false;
    }

    public void set_date (GLib.DateTime date, bool _has_reminder, GLib.DateTime _reminder_datetime) {
        reminder_revealer.reveal_child = _has_reminder;

        when_popover.reminder_switch.active = _has_reminder;
        when_popover.reminder_timepicker.time = _reminder_datetime;

        string time_format = Granite.DateTime.get_default_time_format (true, false);
        reminder_label.label = _reminder_datetime.format (time_format);

        when_datetime = date;
        reminder_datetime = _reminder_datetime;
        has_reminder = _has_reminder;
        has_when = true;

        if (Application.utils.is_today (date)) {
            when_label.label = _("Today");
            has_when = true;
        } else if (Application.utils.is_tomorrow (date)) {
            when_label.label = _("Tomorrow");
            has_when = true;
        } else {
            when_label.label = Application.utils.get_default_date_format_from_date (date);
            has_when = true;
        }

        show_all ();
    }
}
