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

public class Widgets.EditableLabel : Gtk.Grid {
    public string placeholder_text { get; construct; }
    public bool auto_focus { get; construct; }

    public signal void focus_changed (bool active);
    public signal void changed ();

    private Gtk.Label title;
    private Widgets.Entry entry;
    private Gtk.Stack stack;
    private Gtk.Box grid;
    private Gtk.Revealer edit_revealer;

    public string text { get; set; }
    public bool entry_menu_opened { get; set; default = false; }

    public bool is_editing {
        get {
            return stack.visible_child == entry;
        }
    }

    public bool show_edit {
        set {
            edit_revealer.reveal_child = value;
        }
    }

    public void editing (bool value, bool grab_focus = false) {
        focus_changed (value);

        if (value) {
            entry.text = text;
            stack.set_visible_child (entry);

            if (grab_focus) {
                entry.grab_focus ();
            } else {
                entry.grab_focus_without_selecting ();
                if (entry.cursor_position < entry.text_length) {
                    entry.set_position ((int32) entry.text_length);
                }
            }
        } else {
            if (entry.text.strip () != "" && text != entry.text) {
                text = entry.text;
                changed ();
            }

            stack.set_visible_child (grid);
        }
    }

    public bool editable {
        set {
            entry.editable = value;
        }
    }

    public EditableLabel (string placeholder_text = "", bool auto_focus = true) {
        Object (
            placeholder_text: placeholder_text,
            auto_focus: auto_focus
        );
    }

    construct {
        title = new Gtk.Label (null) {
            ellipsize = Pango.EllipsizeMode.END,
            xalign = 0
        };

        var edit_icon = new Gtk.Image.from_icon_name ("edit-symbolic") {
            css_classes = { "dim-label" },
            pixel_size = 16
        };

        edit_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.CROSSFADE,
            child = edit_icon
        };

        grid = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12) {
            valign = Gtk.Align.CENTER
        };

        grid.append (title);
        grid.append (edit_revealer);

        entry = new Widgets.Entry () {
            placeholder_text = placeholder_text,
            css_classes = { "editable-label" }
        };

        stack = new Gtk.Stack () {
            transition_type = Gtk.StackTransitionType.CROSSFADE,
            transition_duration = 115,
            hexpand = true
        };

        stack.add_child (grid);
        stack.add_child (entry);

        attach (stack, 0, 0);

        bind_property ("text", title, "label");

        if (auto_focus) {
            var gesture_click = new Gtk.GestureClick ();
            add_controller (gesture_click);
            gesture_click.pressed.connect (() => {
                editing (true);
            });
        }

        entry.activate.connect (() => {
            if (stack.visible_child == entry) {
                editing (false);
            }
        });

        var gesture = new Gtk.EventControllerFocus ();
        entry.add_controller (gesture);

        gesture.enter.connect (handle_focus_in);
        gesture.leave.connect (update_on_leave);

        gesture.leave.connect (() => {
            if (stack.visible_child == entry && !entry_menu_opened) {
                editing (false);
            }
        });
    }

    public void add_style (string style) {
        stack.add_css_class (style);
    }

    private void handle_focus_in () {
        Services.EventBus.get_default ().disconnect_typing_accel ();
    }

    public void update_on_leave () {
        Services.EventBus.get_default ().connect_typing_accel ();
    }
}
