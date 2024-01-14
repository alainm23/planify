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

public class Widgets.ScrolledWindow : Adw.Bin {
    public Gtk.Widget widget { get; construct; }
    public Gtk.Orientation orientation { get; construct; }
    public int margin { get; set; default = 24 ;}

    private Gtk.ScrolledWindow scrolled_window;
    private Gtk.DropControllerMotion drop_motion_ctrl;

    private bool scrolling = false;

    public Gtk.Adjustment vadjustment {
        get {
            return scrolled_window.vadjustment;
        }
    }

    public Gtk.Adjustment hadjustment {
        get {
            return scrolled_window.hadjustment;
        }
    }

    public ScrolledWindow (Gtk.Widget widget, Gtk.Orientation orientation = Gtk.Orientation.VERTICAL) {
        Object (
            widget: widget,
            orientation: orientation
        );
    }

    construct {
        scrolled_window = new Gtk.ScrolledWindow () {
            hexpand = true,
            vexpand = true,
            hscrollbar_policy = orientation == Gtk.Orientation.VERTICAL ? Gtk.PolicyType.NEVER : Gtk.PolicyType.AUTOMATIC,
            vscrollbar_policy = orientation == Gtk.Orientation.VERTICAL ? Gtk.PolicyType.AUTOMATIC : Gtk.PolicyType.NEVER,
            child = widget,
            propagate_natural_height = true,
            propagate_natural_width = true
        };

        drop_motion_ctrl = new Gtk.DropControllerMotion ();
        scrolled_window.add_controller (drop_motion_ctrl);

        drop_motion_ctrl.motion.connect ((x, y) => {
            if (orientation == Gtk.Orientation.VERTICAL) {
                int height = scrolled_window.get_height ();

                if (y < margin) {
                    scrolling = true;
                    GLib.Timeout.add (100, () => _auto_scroll (true));
                } else if (y > (height - margin)) {
                    scrolling = true;
                    GLib.Timeout.add (100, () => _auto_scroll (false));
                } else {
                    scrolling = false;
                }
            } else {
                int width = scrolled_window.get_width ();

                if (x < margin) {
                    scrolling = true;
                    GLib.Timeout.add (100, () => _auto_scroll (true));
                } else if (x > (width - margin)) {
                    scrolling = true;
                    GLib.Timeout.add (100, () => _auto_scroll (false));
                } else {
                    scrolling = false;
                }
            }
        });

        child = scrolled_window;
    }

    private bool _auto_scroll (bool scroll_up) {
        if (!scrolling || !drop_motion_ctrl.contains_pointer) {
            return false;
        }

        var adj = orientation == Gtk.Orientation.VERTICAL ? scrolled_window.get_vadjustment () : scrolled_window.get_hadjustment ();
        if (scroll_up) {
            adj.set_value (adj.get_value () - Constants.SCROLL_STEPS);
        } else {
            adj.set_value (adj.get_value () + Constants.SCROLL_STEPS);
        }

        return true;
    }
}
