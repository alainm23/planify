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

public class Widgets.Placeholder : Gtk.Revealer {
    public string icon_name { get; construct; }
    public string title { get; construct; }
    public string subtitle { get; construct; }

    public Placeholder (string title, string subtitle, string icon_name) {
        Object (
            title: title,
            subtitle: subtitle,
            icon_name: icon_name
        );
    }

    construct {
        transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        expand = true;

        var icon = new Gtk.Image ();
        icon.gicon = new ThemedIcon (icon_name);
        icon.pixel_size = 48;
        icon.halign = Gtk.Align.CENTER;
        icon.opacity = 0.9;
        icon.get_style_context ().add_class ("dim-label");

        var title_label = new Gtk.Label (title);
        title_label.margin_top = 9;
        title_label.get_style_context ().add_class ("dim-label");
        title_label.get_style_context ().add_class ("h3");

        var subtitle_label = new Gtk.Label (subtitle);
        subtitle_label.margin_top = 3;
        subtitle_label.get_style_context ().add_class ("dim-label");

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        box.valign = Gtk.Align.CENTER;
        box.margin_bottom = 64;
        box.pack_start (icon, false, false, 0);
        box.pack_start (title_label, false, false, 0);
        box.pack_start (subtitle_label, false, false, 0);

        add (box);
    }
}
