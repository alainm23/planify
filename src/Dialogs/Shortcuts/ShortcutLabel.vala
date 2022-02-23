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

public class Dialogs.Shortcuts.ShortcutLabel : Gtk.Grid {
    public string title { get; construct; }
    public string[] accels { get; construct; }

    public ShortcutLabel (string title, string[] accels) {
        Object (
            accels: accels,
            title: title
        );
    }

    construct {
        valign = Gtk.Align.CENTER;
        update_accels (accels);
    }

    public void update_accels (string[] accels) {
        var accels_grid = new Gtk.Grid () {
            column_spacing = 3
        };

        int index = 0;
        foreach (var child in accels_grid.get_children ()) {
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
                accels_grid.add (label);

                if (index < accels.length) {
                    label = new Gtk.Label ("+");
                    label.get_style_context ().add_class ("font-bold"); 
                    accels_grid.add (label);
                }
            }
        } else {
            var label = new Gtk.Label (_("Disabled"));
            label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
            accels_grid.add (label);
        }

        var title_label = new NameLabel (title);

        var main_grid = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12) {
            hexpand = true,
            margin_start = 6,
            margin_end = 3
        };
        main_grid.pack_start (title_label, false, true, 0);
        main_grid.pack_end (accels_grid, false, false, 0);

        add (main_grid);

        show_all ();
    }
}

private class NameLabel : Gtk.Label {
    public NameLabel (string label) {
        Object (
            label: label
        );
    }

    construct {
        halign = Gtk.Align.START;
        xalign = 0;
        wrap = true;
    }
}