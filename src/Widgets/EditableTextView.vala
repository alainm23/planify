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

public class Widgets.EditableTextView : Adw.Bin {
    public string placeholder_text { get; construct; }
    public int max_chars { get; construct; default = 150; }

    private Gtk.Box main_box;
    private Widgets.TextView textview;
    private Gtk.Button show_more_button;
    private bool is_expanded = false;
    private bool updating = false;

    public signal void focus_changed (bool active);
    public signal void changed ();

    public string text { get; set; }

    public bool is_editing {
        get {
            return textview.has_focus;
        }
    }
    
    public void editing (bool value) {
        focus_changed (value);
        if (value) {
            textview.grab_focus ();
        }
    }

    public bool editable {
        set {
            textview.editable = value;
        }
    }

    private Gee.HashMap<ulong, GLib.Object> signal_map = new Gee.HashMap<ulong, GLib.Object> ();

    public EditableTextView (string placeholder_text = "", int max_chars = 150) {
        Object (
            placeholder_text: placeholder_text,
            max_chars: max_chars
        );
    }

    ~EditableTextView () {
        debug ("Destroying Widgets.EditableTextView\n");
    }

    construct {
        textview = new Widgets.TextView () {
            wrap_mode = Gtk.WrapMode.WORD_CHAR,
            css_classes = { "flat" },
            placeholder_text = placeholder_text
        };

        show_more_button = new Gtk.Button.with_label (_("Show more")) {
            css_classes = { "flat", "caption" },
            halign = Gtk.Align.CENTER,
            visible = false
        };

        main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
        main_box.append (textview);
        main_box.append (show_more_button);

        child = main_box;

        signal_map[notify["text"].connect (update_display)] = this;
        signal_map[Services.EventBus.get_default ().mobile_mode_change.connect (update_display)] = Services.EventBus.get_default ();

        signal_map[show_more_button.clicked.connect (() => {
            is_expanded = !is_expanded;
            update_display ();
        })] = show_more_button;

        var gesture_focus = new Gtk.EventControllerFocus ();
        textview.add_controller (gesture_focus);
        signal_map[gesture_focus.enter.connect (() => {
            focus_changed (true);
            update_display ();
            Services.EventBus.get_default ().disconnect_typing_accel ();
        })] = gesture_focus;

        signal_map[gesture_focus.leave.connect (() => {
            focus_changed (false);
            update_display ();
            Services.EventBus.get_default ().connect_typing_accel ();
        })] = gesture_focus;

        signal_map[textview.buffer.changed.connect (() => {
            if (!updating) {
                text = textview.get_text ();
                changed ();
            }
        })] = textview.buffer;

        destroy.connect (() => {
            foreach (var entry in signal_map.entries) {
                entry.value.disconnect (entry.key);
            }
            signal_map.clear ();
        });
    }

    private void update_display () {
        updating = true;
        
        if (is_editing || !Services.EventBus.get_default ().mobile_mode || text.length <= max_chars) {
            textview.set_text (text);
            show_more_button.visible = false;
        } else if (!is_expanded) {
            var truncated = text.substring (0, max_chars).strip () + "…";
            textview.set_text (truncated);
            show_more_button.label = _("Show more");
            show_more_button.visible = true;
        } else {
            textview.set_text (text);
            show_more_button.label = _("Show less");
            show_more_button.visible = true;
        }
        
        updating = false;
    }
}
