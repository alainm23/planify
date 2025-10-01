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
 
public class Widgets.IconColorProject : Adw.Bin {
    public Objects.Project project { get; set; }
    public int pixel_size { get; construct; }

    private Widgets.CircularProgressBar circular_progress_bar;
    public Gtk.Image inbox_icon;
    private Gtk.Label emoji_label;
    private Gtk.Stack color_emoji_stack;
    private Gtk.Stack stack;

    private Gee.HashMap<ulong, weak GLib.Object> signal_map = new Gee.HashMap<ulong, weak GLib.Object> ();

    public IconColorProject (int pixel_size) {
        Object (
            pixel_size: pixel_size
        );
    }

    ~IconColorProject () {
        debug ("Destroying - Widgets.IconColorProject\n");
    }

    construct {
        circular_progress_bar = new Widgets.CircularProgressBar (pixel_size);

        emoji_label = new Gtk.Label (null) {
            halign = CENTER
        };

        color_emoji_stack = new Gtk.Stack () {
            transition_type = CROSSFADE
        };

        color_emoji_stack.add_named (circular_progress_bar, "color");
        color_emoji_stack.add_named (emoji_label, "emoji");

        inbox_icon = new Gtk.Image.from_icon_name ("mailbox-symbolic") {
            pixel_size = 16,
            valign = CENTER,
            halign = CENTER,
        };

        stack = new Gtk.Stack () {
            transition_type = CROSSFADE,
            vhomogeneous = true,
            hhomogeneous = true
        };

        stack.add_named (color_emoji_stack, "color-emoji");
        stack.add_named (inbox_icon, "inbox");

        child = stack;

        signal_map[notify["project"].connect (() => {
            update_request ();
        })] = this;
    }

    public void update_request () {
        stack.visible_child_name = project.is_inbox_project ? "inbox" : "color-emoji";
        color_emoji_stack.visible_child_name = project.icon_style == ProjectIconStyle.PROGRESS ? "color" : "emoji";
        circular_progress_bar.color = project.color;
        circular_progress_bar.percentage = project.percentage;
        emoji_label.label = project.emoji;
    }

    public void clean_up () {
        foreach (var entry in signal_map.entries) {
            entry.value.disconnect (entry.key);
        }

        signal_map.clear ();
    }
}
