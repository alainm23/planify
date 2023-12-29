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

public class Widgets.LoadingButton : Gtk.Button {
    public string text_icon { get; construct; }
    public LoadingButtonType loading_type { get; construct; }
    public int icon_size { get; construct; }
    bool _is_loading;

    private Gtk.Stack submit_stack;
    private Widgets.DynamicIcon icon;

    [Description (nick = "Show loading", blurb = "Show loading")]
    public bool is_loading {
        get {
            return _is_loading;
        }

        set {
            if (value) {
                submit_stack.visible_child_name = "spinner";
            } else {
                submit_stack.visible_child_name = "button";
            }

            _is_loading = value;
        }
    }

    public LoadingButton (LoadingButtonType loading_type, string text_icon) {
        Object (
            loading_type: loading_type,
            text_icon: text_icon
        );
    }

    public LoadingButton.with_label (string label) {
        Object (
            loading_type: LoadingButtonType.LABEL,
            text_icon: label,
            icon_size: 16
        );
    }

    public LoadingButton.with_icon (string icon_name, int icon_size = 16) {
        Object (
            loading_type: LoadingButtonType.ICON,
            text_icon: icon_name,
            icon_size: icon_size
        );
    }

    construct {
        var submit_spinner = new Gtk.Spinner () {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER
        };
        submit_spinner.start ();

        submit_stack = new Gtk.Stack () {
            transition_type = Gtk.StackTransitionType.CROSSFADE,
            valign = Gtk.Align.CENTER
        };

        if (loading_type == LoadingButtonType.LABEL) {
            submit_stack.add_named (new Gtk.Label (text_icon), "button");
        } else {
            icon = new Widgets.DynamicIcon ();
            icon.size = icon_size;
            icon.update_icon_name (text_icon);
            submit_stack.add_named (icon, "button");
        }
        
        submit_stack.add_named (submit_spinner, "spinner");
        child = submit_stack;
    }

    public void update_icon (string icon_name) {
        if (icon != null) {
            icon.update_icon_name (icon_name);
        }
    }
}
