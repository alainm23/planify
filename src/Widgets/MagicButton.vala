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

public class Widgets.MagicButton : Gtk.Grid {
    public Gtk.Button magic_button;

    public signal void clicked ();

    //  private const Gtk.TargetEntry[] MAGICBUTTON_TARGET_ENTRIES = {
    //      {"MAGICBUTTON", Gtk.TargetFlags.SAME_APP, 0}
    //  };

    public MagicButton () {
        Object (
            // tooltip_markup: Granite.markup_accel_tooltip ({"a"}, _("Add Task")),
            margin_top: 32,
            margin_start: 32,
            margin_end: 32,
            margin_bottom: 32,
            valign: Gtk.Align.END,
            halign: Gtk.Align.END
        );
    }

    construct {
        var add_icon = new Gtk.Image () {
            gicon = new ThemedIcon ("list-add-symbolic"),
            pixel_size = 16
        };
        
        magic_button = new Gtk.Button () {
            height_request = 48,
            width_request = 48
        };

        magic_button.child = add_icon;

        magic_button.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);
        magic_button.add_css_class ("magic-button");

        var revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.CROSSFADE,
            reveal_child = true,
        };

        revealer.child = magic_button;

        attach (revealer, 0, 0);
        // build_drag_and_drop ();

        magic_button.clicked.connect (() => {
            clicked ();
        });

        Services.EventBus.get_default ().magic_button_visible.connect ((visible) => {
            revealer.reveal_child = visible;
        });
    }

    //  private void build_drag_and_drop () {
    //      Gtk.drag_source_set (magic_button, Gdk.ModifierType.BUTTON1_MASK, MAGICBUTTON_TARGET_ENTRIES, Gdk.DragAction.MOVE);
    //      magic_button.drag_data_get.connect (on_drag_data_get);
    //      magic_button.drag_begin.connect (on_drag_begin);
    //      magic_button.drag_end.connect (on_drag_end);
    //  }

    //  private void on_drag_begin (Gtk.Widget widget, Gdk.DragContext context) {
    //      var magic_button = (Gtk.Button) widget;

    //      Gtk.Allocation alloc;
    //      magic_button.get_allocation (out alloc);

    //      var surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, alloc.width, alloc.height);
    //      var cr = new Cairo.Context (surface);
    //      cr.set_source_rgba (255, 255, 255, 0);
    //      cr.set_line_width (1);

    //      cr.move_to (0, 0);
    //      cr.line_to (alloc.width, 0);
    //      cr.line_to (alloc.width, alloc.height);
    //      cr.line_to (0, alloc.height);
    //      cr.line_to (0, 0);
    //      cr.stroke ();

    //      cr.set_source_rgba (255, 255, 255, 0);
    //      cr.rectangle (0, 0, alloc.width, alloc.height);
    //      cr.fill ();

    //      magic_button.draw (cr);

    //      Gtk.drag_set_icon_surface (context, surface);
    //      reveal_child = false;

    //      Services.EventBus.get_default ().magic_button_activated (true);
    //  }

    //  private void on_drag_data_get (Gtk.Widget widget, Gdk.DragContext context,
    //      Gtk.SelectionData selection_data, uint target_type, uint time) {
    //      uchar[] data = new uchar[(sizeof (Gtk.Button))];
    //      ((Gtk.Widget[])data)[0] = widget;

    //      selection_data.set (
    //          Gdk.Atom.intern_static_string ("MAGICBUTTON"), 32, data
    //      );
    //  }

    //  public void on_drag_end (Gdk.DragContext context) {
    //      reveal_child = true;
    //      Services.EventBus.get_default ().magic_button_activated (false);
    //  }
}