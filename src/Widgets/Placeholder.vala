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
    public Placeholder () {
        transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        expand = true;
    }

    construct {
        var icon = new Gtk.Image ();
        icon.gicon = new ThemedIcon ("mail-mailbox-symbolic");
        icon.pixel_size = 64;
        icon.get_style_context ().add_class ("dim-label");

        var title_label = new Gtk.Label (_("All clear"));
        title_label.margin_top = 6;
        title_label.get_style_context ().add_class ("h2");

        var subtitle_label = new Gtk.Label (_("Looks like everything's organized in the right place."));
        subtitle_label.margin_top = 6;
        subtitle_label.get_style_context ().add_class ("dim-label");
        //subtitle_label.get_style_context ().add_class ("welcome");

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        box.margin_bottom = 128;
        box.pack_start (icon, false, false, 0);
        box.pack_start (title_label, false, false, 0);
        box.pack_start (subtitle_label, false, false, 0);

        add (box);
    }
}
