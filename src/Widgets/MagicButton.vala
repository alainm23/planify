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

public class Widgets.MagicButton : Adw.Bin {
    public Gtk.Button magic_button;
    private Gtk.Revealer main_revealer;

    public signal void clicked ();
    public signal void drag_begin ();
    public signal void drag_end ();

    public MagicButton () {
        Object (
            margin_top: 32,
            margin_start: 32,
            margin_end: 32,
            margin_bottom: 32,
            valign: Gtk.Align.END,
            halign: Gtk.Align.END
        );
    }

    construct {
        magic_button = new Gtk.Button.from_icon_name ("plus-large-symbolic") {
            height_request = 48,
            width_request = 48,
            css_classes = { "suggested-action", "magic-button" },
            tooltip_markup = Util.get_default ().markup_accel_tooltip (_("Add Task"), "A"),
            focusable = false
        };

        main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.CROSSFADE,
            reveal_child = true,
            child = magic_button
        };

        child = main_revealer;
        build_drag_and_drop ();

        magic_button.clicked.connect (() => {
            clicked ();
        });

        Services.EventBus.get_default ().magic_button_visible.connect ((visible) => {
            main_revealer.reveal_child = visible;
        });
    }

    private void build_drag_and_drop () {
        var drag_source = new Gtk.DragSource ();
        drag_source.set_actions (Gdk.DragAction.MOVE);
        add_controller (drag_source);

        drag_source.prepare.connect ((source, x, y) => {
            return new Gdk.ContentProvider.for_value (this);
        });

        drag_source.drag_begin.connect ((source, drag) => {
            var paintable = new Gtk.WidgetPaintable (magic_button);
            source.set_icon (paintable, 0, 0);
            main_revealer.reveal_child = false;
            drag_begin ();
        });

        drag_source.drag_end.connect ((source, drag, delete_data) => {
            main_revealer.reveal_child = true;
            drag_end ();
        });

        drag_source.drag_cancel.connect ((source, drag, reason) => {
            main_revealer.reveal_child = true;
            drag_end ();
            return false;
        });
    }
}
