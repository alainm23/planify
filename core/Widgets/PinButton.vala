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
    private Gtk.Image pinned_image;

    public bool no_padding {
        set {
            if (value) {
                add_css_class ("no-padding");
            } else {
                remove_css_class ("no-padding");
            }
        }
    }

    public signal void changed ();

    public PinButton () {
        Object (
            valign: Gtk.Align.CENTER,
            halign: Gtk.Align.CENTER,
            tooltip_text: _("Pin")
        );
    }

    ~PinButton () {
        debug ("Destroying - Widgets.PinButton\n");
    }

    construct {
        add_css_class ("flat");

        pinned_image = new Gtk.Image.from_icon_name ("pin-symbolic");
        child = pinned_image;

        clicked.connect (() => {
            changed ();
        });
    }

    public void update_from_item (Objects.Item item) {
        update_request (item.pinned);
    }

    public void update_request (bool pinned) {
        if (pinned) {
            pinned_image.add_css_class ("pinboard-color");
        } else {
            pinned_image.remove_css_class ("pinboard-color");
        }
    } 

    public void reset () {
        pinned_image.css_classes = {};
    }
}
