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

public class Widgets.ItemLabelChild : Gtk.FlowBoxChild {
    public Objects.Label label { get; construct; }
    
    private Gtk.Label name_label;
    private Gtk.Revealer main_revealer;

    public ItemLabelChild (Objects.Label label) {
        Object (
            label: label,
            halign: Gtk.Align.START
        );
    }

    construct {     
        add_css_class ("item-label-child");
        
        name_label = new Gtk.Label (null);
        name_label.valign = Gtk.Align.CENTER;
        name_label.add_css_class ("small-label");

        var labelrow_grid = new Adw.Bin () {
            child = name_label
        };

        main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT,
            child = labelrow_grid
        };

        child = main_revealer;
        update_request ();

        Timeout.add (main_revealer.transition_duration, () => {
            main_revealer.reveal_child = true;
            return GLib.Source.REMOVE;
        });

        label.deleted.connect (() => {
            hide_destroy ();
        });
        
        label.updated.connect (update_request);
    }

    public void update_request () {
        name_label.label = label.name;
        Util.get_default ().set_widget_color (Util.get_default ().get_color (label.color), this);
    }

    public void hide_destroy () {
        main_revealer.reveal_child = false;
        Timeout.add (main_revealer.transition_duration, () => {
            ((Gtk.FlowBox) parent).remove (this);
            return GLib.Source.REMOVE;
        });
    }
}
