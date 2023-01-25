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

public class Dialogs.RepeatConfig : Adw.Window {
    private Gtk.SpinButton recurrency_interval;
    private Gtk.ComboBoxText recurrency_combobox;
    private Gtk.Label repeat_label;

    public Objects.DueDate duedate {
        set {
            recurrency_interval.value = value.recurrency_interval;

            if (value.recurrency_type == RecurrencyType.NONE) {
                recurrency_combobox.active = 0;
            } else {
                recurrency_combobox.active = (int) value.recurrency_type;
            }
            
            update_repeat_label ();
        }
    }

    public signal void changed (Objects.DueDate duedate);

    public RepeatConfig () {
        Object (
            deletable: true,
            resizable: true,
            modal: true,
            title: _("Repeat"),
            width_request: 320,
            height_request: 375,
            transient_for: (Gtk.Window) Planner.instance.main_window
        );
    }

    construct {
        var headerbar = new Adw.HeaderBar ();
        headerbar.add_css_class (Granite.STYLE_CLASS_FLAT);

        repeat_label = new Gtk.Label (null) {
            margin_top = 9,
            margin_bottom = 9,
            margin_start = 9,
            margin_end = 9
        };

        var repeat_preview_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            margin_top = 12,
            margin_start = 12,
            margin_end = 12
        };
        repeat_preview_box.append (repeat_label);
        repeat_preview_box.add_css_class ("card");
        repeat_preview_box.add_css_class ("border-radius-6");

        recurrency_interval = new Gtk.SpinButton.with_range (1, 100, 1) {
            hexpand = true,
            margin_start = 6,
            margin_top = 6,
            margin_bottom = 6
        };
        recurrency_interval.get_style_context ().add_class ("popover-spinbutton");

        recurrency_combobox = new Gtk.ComboBoxText () {
            hexpand = true,
            margin_top = 6,
            margin_end = 6,
            margin_bottom = 6
        };
        
        recurrency_combobox.append_text (_("Day(s)"));
        recurrency_combobox.append_text (_("Week(s)"));
        recurrency_combobox.append_text (_("Month(s)"));
        recurrency_combobox.append_text (_("Year(s)"));
        recurrency_combobox.active = 0;

        var repeat_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            hexpand = true,
            margin_top = 12,
            margin_start = 12,
            margin_end = 12,
            homogeneous = true
        };
        repeat_box.append (recurrency_interval);
        repeat_box.append (recurrency_combobox);
        repeat_box.add_css_class ("card");

        var submit_button = new Widgets.LoadingButton (LoadingButtonType.LABEL, _("Done")) {
            margin_top = 12,
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 12,
            vexpand = true,
            valign = Gtk.Align.END
        };
        submit_button.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            width_request = 225
        };
        
        content_box.append (headerbar);
        content_box.append (repeat_preview_box);
        content_box.append (repeat_box);
        content_box.append (submit_button);

        content = content_box;
        update_repeat_label ();
        
        recurrency_interval.value_changed.connect (() => {
            update_repeat_label ();
        });

        recurrency_combobox.changed.connect (() => {
            update_repeat_label ();
        });

        submit_button.clicked.connect (() => {
            set_repeat ();
        });
    }

    private void set_repeat () {
        var duedate = new Objects.DueDate ();
        duedate.is_recurring = true;
        duedate.recurrency_type = (RecurrencyType) this.recurrency_combobox.get_active();
        duedate.recurrency_interval = (int) recurrency_interval.value;
        changed (duedate);
        hide_destroy ();
    }

    private void update_repeat_label () {
        RecurrencyType selected_option = (RecurrencyType) this.recurrency_combobox.get_active();
        string label = selected_option.to_friendly_string ((int) recurrency_interval.value);
        repeat_label.label = label;
    }

    public void hide_destroy () {
        hide ();

        Timeout.add (500, () => {
            destroy ();
            return GLib.Source.REMOVE;
        });
    }
}