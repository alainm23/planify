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

public class Widgets.PinButton : Gtk.Button {
    public Objects.Item item { get; construct; }
    private Gtk.Image pinned_image;

    public signal void changed ();

    public PinButton (Objects.Item item) {
        Object (
            item: item,
            can_focus: false,
            valign: Gtk.Align.CENTER,
            halign: Gtk.Align.CENTER,
            tooltip_text: _("Pinned")
        );
    }

    construct {       
        add_css_class ("flat");
        
        pinned_image = new Gtk.Image.from_icon_name ("pin-symbolic");

        child = pinned_image;

        update_request ();

        var gesture = new Gtk.GestureClick ();
        add_controller (gesture);

        gesture.pressed.connect ((n_press, x, y) => {
            gesture.set_state (Gtk.EventSequenceState.CLAIMED);
            changed ();
        });
    }

    public void update_request () {
        pinned_image.icon_name = item.pinned ? "pinboard" : "pin-symbolic";
    }

    public void reset () {
        pinned_image.icon_name = "pin-symbolic";
    }
}
