// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2013-2015 Maya Developers (http://launchpad.net/maya)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Library General Public License as published by
 * the Free Software Foundation, either version 2.1 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Library General Public License for more details.
 * 
 * You should have received a copy of the GNU Library General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored by: Corentin Noël <corentin@elementaryos.org>
 */

/* 
 * This widget auto-updates his image when the contact changes his avatar.
 * It draws circle icons following the current trend.
 */
public class Maya.ContactImage : Gtk.Stack {
    private Gtk.IconSize icon_size;
    private Gtk.Image current_image = null;
    private bool default_avatar = true;
    public ContactImage (Gtk.IconSize icon_size, Folks.Individual? individual = null) {
        this.icon_size = icon_size;
        transition_type = Gtk.StackTransitionType.CROSSFADE;

        var force_size_image = new Gtk.Image.from_icon_name ("avatar-default", icon_size);
        add (force_size_image);
        show_default_avatar ();

        if (individual != null) {
            add_contact (individual);
        }

        show_all ();
    }

    public void add_contact (Folks.Individual individual) {
        if (individual.avatar != null && default_avatar == true) {
            show_avatar_from_loadable_icon (individual.avatar);
        }

        individual.notify["avatar"].connect (() => {
            if (individual.avatar != null && default_avatar == true) {
                show_avatar_from_loadable_icon (individual.avatar);
            } else {
                show_default_avatar ();
            }
        });
    }

    private void show_avatar_from_loadable_icon (LoadableIcon icon) {
        var image = new Gtk.Image ();
        image.draw.connect ((cr) => {
            try {
                var width = get_allocated_width ();
                var height = get_allocated_height ();
                int size = (int) double.min (width, height);
                var stream = icon.load (size, null);
                var img_pixbuf = new Gdk.Pixbuf.from_stream_at_scale (stream, size, size, true);
                cr.set_operator (Cairo.Operator.OVER);
                var x = (width-size)/2;
                var y = (height-size)/2;
                Granite.Drawing.Utilities.cairo_rounded_rectangle (cr, x, y, size, size, size/2);
                Gdk.cairo_set_source_pixbuf (cr, img_pixbuf, x, y);
                cr.fill_preserve ();
                cr.set_line_width (0);
                cr.set_source_rgba (0, 0, 0, 0.3);
                cr.stroke ();
            } catch (Error e) {
                critical (e.message);
                return false;
            }

            return true;
        });
        show_avatar_image (image);
    }

    private void show_default_avatar () {
        var image = new Gtk.Image ();
        image.draw.connect ((cr) => {
            try {
                var width = get_allocated_width ();
                var height = get_allocated_height ();
                int size = (int) double.min (width, height);
                var img_pixbuf = Gtk.IconTheme.get_default ().load_icon ("avatar-default", size, Gtk.IconLookupFlags.GENERIC_FALLBACK);
                cr.set_operator (Cairo.Operator.OVER);
                var x = (width-size)/2;
                var y = (height-size)/2;
                Granite.Drawing.Utilities.cairo_rounded_rectangle (cr, x, y, size, size, size/2);
                Gdk.cairo_set_source_pixbuf (cr, img_pixbuf, x, y);
                cr.fill_preserve ();
                cr.set_line_width (0);
                cr.set_source_rgba (0, 0, 0, 0.3);
                cr.stroke ();
            } catch (Error e) {
                critical (e.message);
                return false;
            }

            return true;
        });

        show_avatar_image (image);
        default_avatar = true;
    }

    private void show_avatar_image (Gtk.Image image) {
        add (image);
        image.show ();
        set_visible_child (image);
        if (current_image != null)
            current_image.destroy ();
        current_image = image;
    }
}
