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

public class Widgets.ShortcutLabel : Gtk.Grid {
    public string[] accels { get; construct; }

    public ShortcutLabel (string[] accels) {
        Object (accels: accels);
    }

    construct {
        valign = Gtk.Align.CENTER;
        halign = Gtk.Align.END;
        column_spacing = 6;

        update_accels (accels);
    }

    public void update_accels (string[] accels) {
        int index = 0;
        foreach (var child in this.get_children ()) {
            child.destroy ();
        }

        if (accels[0] != "") {
            foreach (unowned string accel in accels) {
                index += 1;
                if (accel == "") {
                    continue;
                }
                var label = new Gtk.Label (accel.replace ("Super", "⌘"));
                label.get_style_context ().add_class ("keycap");
                add (label);

                if (index < accels.length) {
                    label = new Gtk.Label ("+");
                    label.get_style_context ().add_class ("font-bold"); 
                    add (label);
                }
            }
        } else {
            var label = new Gtk.Label (_("Disabled"));
            label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
            add (label);
        }

        show_all ();
    }
}
