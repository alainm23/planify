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

public class Dialogs.Preferences.ItemSwitch : Gtk.EventBox {
    public signal void activated (bool active);

    public ItemSwitch (string title, bool active=false, bool visible_separator=true) {
        var title_label = new Gtk.Label (title);
        title_label.get_style_context ().add_class ("font-weight-600");

        var button_switch = new Gtk.Switch ();
        button_switch.valign = Gtk.Align.CENTER;
        button_switch.get_style_context ().add_class ("active-switch");
        button_switch.active = active;

        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        box.margin_start = 12;
        box.margin_end = 12;
        box.margin_top = 6;
        box.margin_bottom = 6;
        box.hexpand = true;
        box.pack_start (title_label, false, true, 0);
        box.pack_end (button_switch, false, true, 0);

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.get_style_context ().add_class ("preferences-view");
        main_box.hexpand = true;
        main_box.pack_start (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), false, true, 0);
        main_box.pack_start (box, false, true, 0);

        if (visible_separator == true) {
            main_box.pack_start (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), false, true, 0);
        }

        button_switch.notify["active"].connect (() => {
            activated (button_switch.active);
        });

        add (main_box);
    }
}
