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

public class Widgets.LabelItem : Gtk.EventBox {
    public int64 id { get; construct; }
    public int64 item_id { get; construct; }
    public Objects.Label label { get; construct; }

    public LabelItem (int64 id, int64 item_id, Objects.Label label) {
        Object (
            id: id,
            item_id: item_id,
            label: label
        );
    }

    construct {
        add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);

        var delete_image = new Gtk.Image ();
        delete_image.gicon = new ThemedIcon ("window-close-symbolic");
        delete_image.pixel_size = 13;

        var delete_button = new Gtk.Button ();
        delete_button.tooltip_text = _("Remove");
        delete_button.can_focus = false;
        delete_button.valign = Gtk.Align.CENTER;
        delete_button.halign = Gtk.Align.CENTER;
        delete_button.margin_top = 1;
        delete_button.get_style_context ().add_class ("no-padding");
        delete_button.get_style_context ().add_class ("label-item-button");
        delete_button.image = delete_image;
        delete_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var delete_revealer = new Gtk.Revealer ();
        delete_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
        delete_revealer.add (delete_button);

        var name_label = new Gtk.Label (label.name);
        name_label.margin_end = 3;
        name_label.margin_top = 1;
        name_label.valign = Gtk.Align.CENTER;
        name_label.valign = Gtk.Align.CENTER;

        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3);
        box.valign = Gtk.Align.CENTER;
        box.get_style_context ().add_class ("label-preview-%s".printf (label.id.to_string ()));
        box.add (delete_revealer);
        box.add (name_label);

        var main_revealer = new Gtk.Revealer ();
        main_revealer.reveal_child = true;
        main_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT;
        main_revealer.add (box);

        add (main_revealer);

        Planner.database.label_updated.connect ((l) => {
            Idle.add (() => {
                if (label.id == l.id) {
                    name_label.label = l.name;
                }

                return false;
            });
        });

        enter_notify_event.connect ((event) => {
            delete_revealer.reveal_child = true;
            return true;
        });

        leave_notify_event.connect ((event) => {
            if (event.detail == Gdk.NotifyType.INFERIOR) {
                return false;
            }

            delete_revealer.reveal_child = false;

            return true;
        });

        delete_button.clicked.connect (() => {
            Planner.database.delete_item_label (id, item_id, label);
        });

        Planner.database.item_label_deleted.connect ((i, item_id, label) => {
            if (id == i) {
                main_revealer.reveal_child = false;

                Timeout.add (500, () => {
                    destroy ();
                    return false;
                });
            }
        });

        Planner.database.label_deleted.connect ((l) => {
            if (label.id == l.id) {
                main_revealer.reveal_child = false;

                Timeout.add (500, () => {
                    destroy ();
                    return false;
                });
            }
        });
    }
}
