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

public class Widgets.LabelPreview : Gtk.EventBox {
    public int64 id { get; construct; }
    public int64 item_id { get; construct; }
    public Objects.Label label { get; construct; }

    public LabelPreview (int64 id, int64 item_id, Objects.Label label) {
        Object (
            id: id,
            item_id: item_id,
            label: label
        );
    }

    construct {
        valign = Gtk.Align.CENTER;

        var color_image = new Gtk.Image ();
        color_image.valign = Gtk.Align.CENTER;
        color_image.gicon = new ThemedIcon ("mail-unread-symbolic");
        color_image.pixel_size = 13;

        var name_label = new Gtk.Label (label.name);
        name_label.valign = Gtk.Align.CENTER;
        name_label.valign = Gtk.Align.CENTER;

        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3);
        box.get_style_context ().add_class ("label-preview-%s".printf (label.id.to_string ()));
        box.add (name_label);

        add (box);

        Planner.database.label_updated.connect ((l) => {
            Idle.add (() => {
                if (label.id == l.id) {
                    name_label.label = l.name;
                }

                return false;
            });
        });

        Planner.database.item_label_deleted.connect ((i) => {
            if (id == i) {
                destroy ();
            }
        });

        Planner.database.label_deleted.connect ((l) => {
            if (label.id == l.id) {
                destroy ();
            }
        });
    }
}
