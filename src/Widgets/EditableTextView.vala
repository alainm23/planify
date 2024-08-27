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

	public signal void focus_changed (bool active);
	public signal void changed ();

	private Gtk.Label label;
    private Widgets.TextView textview;
	private Gtk.Stack stack;

	public string text { get; set; }

	public bool is_editing {
		get {
			return stack.visible_child == textview;
		}
	}

	public void editing (bool value) {
		focus_changed (value);

		if (value) {
			textview.buffer.text = text;
			stack.set_visible_child (textview);
			textview.grab_focus ();
		} else {
			if (text != textview.buffer.text) {
				text = textview.buffer.text;
				changed ();
			}

			stack.set_visible_child (label);
		}
	}

	public bool editable {
		set {
			textview.editable = value;
		}
	}

	private Gee.HashMap<ulong, GLib.Object> signal_map = new Gee.HashMap<ulong, GLib.Object> ();

	public EditableTextView (string placeholder_text = "") {
		Object (
			placeholder_text: placeholder_text
		);
	}

	~EditableTextView () {
        print ("Destroying Widgets.EditableTextView\n");
    }

	construct {
		label = new Gtk.Label (null) {
            wrap = true,
            wrap_mode = Pango.WrapMode.WORD_CHAR,
            xalign = 0,
            yalign = 0
		};

        textview = new Widgets.TextView () {
            wrap_mode = Gtk.WrapMode.WORD_CHAR,
            css_classes = {}
        };

		stack = new Gtk.Stack () {
			transition_type = Gtk.StackTransitionType.CROSSFADE,
			hexpand = true,
            hhomogeneous = false,
            vhomogeneous = false
		};
        
		stack.add_child (label);
		stack.add_child (textview);

		child = stack;
		signal_map[notify["text"].connect (() => {
			label.label = text;
			label.opacity = 1;

			if (label.label.length <= 0) {
				label.label = placeholder_text;
				label.opacity = 0.7;
			}
		})] = this;

		var gesture_click = new Gtk.GestureClick ();
		add_controller (gesture_click);
		signal_map[gesture_click.pressed.connect (() => {
			editing (true);
		})] = gesture_click;

		var gesture_focus = new Gtk.EventControllerFocus ();
		textview.add_controller (gesture_focus);
		signal_map[gesture_focus.leave.connect (() => {
			if (stack.visible_child == textview) {
				editing (false);
			}
		})] = gesture_focus;

		destroy.connect (() => {
			print ("Widgets.EditableTextView Destroyed\n");

            // Clear Signals
            foreach (var entry in signal_map.entries) {
                entry.value.disconnect (entry.key);
            }
            
            signal_map.clear ();
        });
	}
}
