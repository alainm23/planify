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

public class Widgets.MagicButton : Gtk.Revealer {
    public Gtk.Button magic_button;

    public signal void clicked ();

    private const Gtk.TargetEntry[] TARGET_ENTRIES = {
        {"MAGICBUTTON", Gtk.TargetFlags.SAME_APP, 0}
    };

    construct {
        tooltip_markup = Granite.markup_accel_tooltip ({"a"}, _("Add Task"));
        transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        reveal_child = true;
        margin = 24;
        valign = Gtk.Align.END;
        halign = Gtk.Align.END;

        magic_button = new Gtk.Button.from_icon_name ("list-add-symbolic", Gtk.IconSize.MENU);
        magic_button.height_request = 32;
        magic_button.width_request = 32;
        magic_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        magic_button.get_style_context ().add_class ("magic-button");
        magic_button.get_style_context ().add_class ("magic-button-animation");

        add (magic_button);

        build_drag_and_drop ();

        magic_button.clicked.connect (() => {
            clicked ();
        });

        Planner.event_bus.magic_button_visible.connect ((visible) => {
            reveal_child = visible;
        });
    }

    private void build_drag_and_drop () {
        Gtk.drag_source_set (magic_button, Gdk.ModifierType.BUTTON1_MASK, TARGET_ENTRIES, Gdk.DragAction.MOVE);
        magic_button.drag_data_get.connect (on_drag_data_get);
        magic_button.drag_begin.connect (on_drag_begin);
        magic_button.drag_end.connect (on_drag_end);
    }

    private void on_drag_begin (Gtk.Widget widget, Gdk.DragContext context) {
        var magic_button = (Gtk.Button) widget;

        Gtk.Allocation alloc;
        magic_button.get_allocation (out alloc);

        var surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, alloc.width, alloc.height);
        var cr = new Cairo.Context (surface);
        cr.set_source_rgba (255, 255, 255, 0);
        cr.set_line_width (1);

        cr.move_to (0, 0);
        cr.line_to (alloc.width, 0);
        cr.line_to (alloc.width, alloc.height);
        cr.line_to (0, alloc.height);
        cr.line_to (0, 0);
        cr.stroke ();

        cr.set_source_rgba (255, 255, 255, 0);
        cr.rectangle (0, 0, alloc.width, alloc.height);
        cr.fill ();

        magic_button.draw (cr);

        Gtk.drag_set_icon_surface (context, surface);
        reveal_child = false;

        Planner.event_bus.drag_magic_button_activated (true);
    }

    private void on_drag_data_get (Gtk.Widget widget, Gdk.DragContext context,
        Gtk.SelectionData selection_data, uint target_type, uint time) {
        uchar[] data = new uchar[(sizeof (Gtk.Button))];
        ((Gtk.Widget[])data)[0] = widget;

        selection_data.set (
            Gdk.Atom.intern_static_string ("MAGICBUTTON"), 32, data
        );
    }

    public void on_drag_end (Gdk.DragContext context) {
        reveal_child = true;
        Planner.event_bus.drag_magic_button_activated (false);
    }
}
