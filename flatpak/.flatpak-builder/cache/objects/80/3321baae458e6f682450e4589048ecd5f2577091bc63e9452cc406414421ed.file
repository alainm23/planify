// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2011-2015 Maya Developers (http://launchpad.net/maya)
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
 * Authored by: Christian Dywan <christian@twotoasts.de>
 *              Corentin Noël <corentin@elementaryos.org>
 */

namespace Maya.View {
    public class VAutoHider : Gtk.EventBox {

        Gtk.Label more_label;
        Gtk.Box main_box;

        public VAutoHider () {
            more_label = new Gtk.Label ("");
            more_label.set_alignment (0.5f, 1);
            main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            main_box.pack_end (more_label);
            base.add (main_box);

            events |= Gdk.EventMask.SCROLL_MASK;
            events |= Gdk.EventMask.SMOOTH_SCROLL_MASK;
            scroll_event.connect ((event) => {return GesturesUtils.on_scroll_event (event);});
        }

        public override void add (Gtk.Widget widget) {
            List<weak Gtk.Widget> children = main_box.get_children ();
            children.append (widget);

            children.sort (compare_children);

            int index = children.index (widget);
            main_box.add (widget);
            main_box.reorder_child (widget, index);

            widget.destroy.connect (() => {
                queue_resize ();
            });

            queue_resize ();
        }

        public override void size_allocate (Gtk.Allocation allocation) {
            base.size_allocate (allocation);
            int global_height = allocation.height;
            int children_length = (int)main_box.get_children ().length () - 1;
            if (children_length == 0) {
                more_label.hide ();
                return;
            }

            int height = 0;
            int more_label_height;
            int shown_children = 0;
            more_label.show ();
            more_label.vexpand = false;
            more_label.get_preferred_height (out more_label_height, null);
            more_label.vexpand = true;
            more_label.hide ();
            foreach (var child in main_box.get_children ()) {
                if (child == more_label)
                    continue;

                bool last = (shown_children == children_length - 1);

                int child_height;
                child.show ();
                child.get_preferred_height (out child_height, null);
                child.hide ();

                bool should_hide;
                if (global_height - more_label_height < child_height + height) {
                    should_hide = true;
                    if (last && (global_height >= child_height + height)) {
                        should_hide = false;
                    }
                } else {
                    should_hide = false;
                    height += child_height;
                }

                if (should_hide) {
                    hide_revealer_now ((Gtk.Revealer)child);
                    child.hide ();
                } else {
                    show_revealer_now ((Gtk.Revealer)child);
                    child.show ();
                    shown_children++;
                }
            }

            int more = children_length  - shown_children;
            if (shown_children != children_length && more > 0) {
                more_label.show ();
                more_label.set_label (_("%u more…").printf ((uint)more));
            } else {
                more_label.hide ();
            }
        }

        private void hide_revealer_now (Gtk.Revealer revealer) {
            if (revealer.child_revealed == false)
                return;

            var reveal_duration = revealer.transition_duration;
            revealer.transition_duration = 0;
            revealer.set_reveal_child (false);
            revealer.transition_duration = reveal_duration;
            revealer.hide ();
        }

        private void show_revealer_now (Gtk.Revealer revealer) {
            if (revealer.child_revealed == true)
                return;

            var reveal_duration = revealer.transition_duration;
            revealer.transition_duration = 0;
            revealer.set_reveal_child (true);
            revealer.transition_duration = reveal_duration;
            revealer.show ();
        }

        public override void get_preferred_width (out int minimum_width, out int natural_width) {
            base.get_preferred_width (out minimum_width, out natural_width);
            more_label.get_preferred_width (out minimum_width, null);
            if (minimum_width > natural_width)
                natural_width = minimum_width;
        }

        public override void get_preferred_height (out int minimum_height, out int natural_height) {
            base.get_preferred_height (out minimum_height, out natural_height);
            more_label.get_preferred_height (out minimum_height, null);
            if (minimum_height > natural_height)
                natural_height = minimum_height;
        }

        public void update (Gtk.Widget widget) {
            List<weak Gtk.Widget> children = main_box.get_children ();

            children.sort (compare_children);
            int index = children.index (widget);
            main_box.reorder_child (widget, index);
        }

        public static GLib.CompareFunc<weak Gtk.Widget> compare_children = (a, b) => {
            EventButton a2 = a as EventButton;
            EventButton b2 = b as EventButton;

            if (a2 == null) {
                return 1;
            } else if (b2 == null) {
                return 0;
            } else {
                return Util.compare_events (a2.comp, b2.comp);
            }
        };

    }
}
