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

public class Widgets.LabelRow : Gtk.ListBoxRow {
    public Objects.Label label { get; construct; }

    private Gtk.Label name_label;
    private Gtk.Revealer main_revealer;
    private Gtk.Grid widget_color;

    public LabelRow (Objects.Label label) {
        Object (
            label: label
        );
    }

    construct {
        get_style_context ().add_class ("selectable-item");
        
        widget_color = new Gtk.Grid () {
            valign = Gtk.Align.CENTER
        };

        unowned Gtk.StyleContext widget_color_context = widget_color.get_style_context ();
        widget_color_context.add_class ("label-color");

        name_label = new Gtk.Label (label.name);
        name_label.valign = Gtk.Align.CENTER;
        name_label.ellipsize = Pango.EllipsizeMode.END;

        var main_grid = new Gtk.Grid () {
            column_spacing = 6,
            margin = 3
        };
        main_grid.add (widget_color);
        main_grid.add (name_label);

        main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };
        main_revealer.add (main_grid);

        add (main_revealer);

        update_request ();
        
        Timeout.add (main_revealer.transition_duration, () => {
            main_revealer.reveal_child = true;
            return GLib.Source.REMOVE;
        });

        label.updated.connect (() => {
            update_request ();
        });
    }

    public void update_request () {
        name_label.label = label.name;
        Util.get_default ().set_widget_color (Util.get_default ().get_color (label.color), widget_color);
    }

    public void hide_destroy () {
        main_revealer.reveal_child = false;

        Timeout.add (main_revealer.transition_duration, () => {
            destroy ();
            return GLib.Source.REMOVE;
        });
    }
}
