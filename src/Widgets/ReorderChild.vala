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

public class Widgets.ReorderChild : Adw.Bin {
    public Gtk.Widget widget { get; construct; }
    public Gtk.ListBoxRow row { get; construct; }

    private Gtk.DropControllerMotion drop_motion_ctrl;
    private Gtk.Grid motion_top_grid;
    private Gtk.Revealer motion_top_revealer;
    private Gtk.Grid motion_bottom_grid;
    private Gtk.Revealer main_revealer;

    public bool reveal_child {
        set {
            main_revealer.reveal_child = value;
        }

        get {
            return main_revealer.reveal_child;
        }
    }

    public bool on_drag { get; set; default = false; }
    public signal void on_drop_end (Gtk.ListBox listbox);
    public signal void on_drag_event (bool active);

    private Gee.HashMap<ulong, GLib.Object> signal_map = new Gee.HashMap<ulong, GLib.Object> ();
    
    public ReorderChild (Gtk.Widget widget, Gtk.ListBoxRow row) {
        Object (
            widget: widget,
            row: row
        );
    }

    ~ReorderChild() {
        print ("Destroying Widgets.ReorderChild\n");
    }

    construct {
        motion_top_grid = new Gtk.Grid () {
            height_request = 32,
            margin_top = 6,
            margin_start = 6,
            margin_end = 6,
            margin_bottom = 6,
            css_classes = { "drop-area", "drop-target" }
        };

        motion_top_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            child = motion_top_grid
        };

        motion_bottom_grid = new Gtk.Grid () {
            height_request = 32,
            margin_top = 6,
            margin_start = 6,
            margin_end = 6,
            margin_bottom = 6,
            css_classes = { "drop-area", "drop-target" }
        };

        var motion_bottom_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            child = motion_bottom_grid
        };

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.append (motion_top_revealer);
        main_box.append (widget);
        main_box.append (motion_bottom_revealer);

        main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            child = main_box,
            reveal_child = true
        };

        child = main_revealer;

        drop_motion_ctrl = new Gtk.DropControllerMotion ();
        row.add_controller (drop_motion_ctrl);

        signal_map[drop_motion_ctrl.enter .connect ((x, y) => {
            motion_top_revealer.reveal_child = true;
        })] = drop_motion_ctrl;

        signal_map[drop_motion_ctrl.leave.connect (() => {
            motion_top_revealer.reveal_child = false;
        })] = drop_motion_ctrl;

        destroy.connect (() => {
            foreach (var entry in signal_map.entries) {
                entry.value.disconnect (entry.key);
            }

            signal_map.clear ();
        });
    }

    public void build_drag_and_drop () {
        var drag_source = new Gtk.DragSource ();
        drag_source.set_actions (Gdk.DragAction.MOVE);
        widget.add_controller (drag_source);

        signal_map[drag_source.prepare.connect ((source, x, y) => {
            return new Gdk.ContentProvider.for_value (this);
        })] = drag_source;

        signal_map[drag_source.drag_begin.connect ((source, drag) => {
            var paintable = new Gtk.WidgetPaintable (widget);
            source.set_icon (paintable, 0, 0);
            drag_begin ();
        })] = drag_source;
        
        signal_map[drag_source.drag_end.connect ((source, drag, delete_data) => {
            drag_end ();
        })] = drag_source;

        signal_map[drag_source.drag_cancel.connect ((source, drag, reason) => {
            drag_end ();
            return false;
        })] = drag_source;

        var drop_order_target = new Gtk.DropTarget (typeof (Widgets.ReorderChild), Gdk.DragAction.MOVE);
        motion_bottom_grid.add_controller (drop_order_target);
        signal_map[drop_order_target.drop.connect ((value, x, y) => on_drop (value, x, y, false))] = drop_order_target;

        var drop_order_first_target = new Gtk.DropTarget (typeof (Widgets.ReorderChild), Gdk.DragAction.MOVE);
        motion_top_grid.add_controller (drop_order_first_target);
        signal_map[drop_order_first_target.drop.connect ((value, x, y) => on_drop (value, x, y, true))] = drop_order_first_target;
    }

    private bool on_drop (GLib.Value value, double x, double y, bool first = false) {
        var picked_widget = (Widgets.ReorderChild) value;
        var target_widget = this;

        picked_widget.drag_end ();
        target_widget.drag_end ();
        target_widget.motion_top_revealer.reveal_child = false;

        if (picked_widget == target_widget || target_widget == null) {
            return false;
        }

        var source_list = (Gtk.ListBox) picked_widget.row.parent;
        var target_list = (Gtk.ListBox) target_widget.row.parent;
        
        source_list.remove (picked_widget.row);
        target_list.insert (picked_widget.row, target_widget.row.get_index ());

        on_drop_end (target_list);
        return true;
    }
    
    public void drag_begin () {
        widget.add_css_class ("drop-begin");
        on_drag = true;
        on_drag_event (true);
        main_revealer.reveal_child = false;
    }

    public void drag_end () {
        widget.remove_css_class ("drop-begin");
        on_drag = false;
        on_drag_event (false);
        main_revealer.reveal_child = true;
    }
}
