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
    public int margin { get; set; default = 64; }

    private Gtk.ScrolledWindow scrolled_window;
    private Gtk.DropControllerMotion drop_motion_ctrl;

    private uint scroll_timeout_id = 0;
    private double scroll_speed = 0;

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

    ~ScrolledWindow () {
        debug ("Destroying - Widgets.ScrolledWindow\n");
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
            double distance_from_edge = 0;
            bool should_scroll = false;
            bool scroll_up = false;

            if (orientation == Gtk.Orientation.VERTICAL) {
                int height = scrolled_window.get_height ();

                if (y < margin) {
                    distance_from_edge = margin - y;
                    should_scroll = true;
                    scroll_up = true;
                } else if (y > (height - margin)) {
                    distance_from_edge = y - (height - margin);
                    should_scroll = true;
                    scroll_up = false;
                }
            } else {
                int width = scrolled_window.get_width ();

                if (x < margin) {
                    distance_from_edge = margin - x;
                    should_scroll = true;
                    scroll_up = true;
                } else if (x > (width - margin)) {
                    distance_from_edge = x - (width - margin);
                    should_scroll = true;
                    scroll_up = false;
                }
            }

            if (should_scroll) {
                scroll_speed = (distance_from_edge / margin) * (scroll_up ? -1 : 1);
                start_auto_scroll ();
            } else {
                stop_auto_scroll ();
            }
        });

        drop_motion_ctrl.leave.connect (() => {
            stop_auto_scroll ();
        });

        child = scrolled_window;
    }

    private void start_auto_scroll () {
        if (scroll_timeout_id > 0) {
            return;
        }

        scroll_timeout_id = GLib.Timeout.add (16, () => {
            if (!drop_motion_ctrl.contains_pointer) {
                stop_auto_scroll ();
                return false;
            }

            var adj = orientation == Gtk.Orientation.VERTICAL ? scrolled_window.get_vadjustment () : scrolled_window.get_hadjustment ();
            double new_value = adj.get_value () + (scroll_speed * 10);
            new_value = double.max (adj.get_lower (), double.min (new_value, adj.get_upper () - adj.get_page_size ()));
            adj.set_value (new_value);

            return true;
        });
    }

    private void stop_auto_scroll () {
        if (scroll_timeout_id > 0) {
            GLib.Source.remove (scroll_timeout_id);
            scroll_timeout_id = 0;
        }
        scroll_speed = 0;
    }
}
