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

public class Widgets.ProjectPicker.ProjectPickerRow : Gtk.ListBoxRow {
    public Objects.Project project { get; construct; }
    public bool is_selected { get; set; default = false; }

    private Gtk.Label name_label;
    private Gtk.Revealer main_revealer;
    private Gtk.Revealer selected_revealer;
    private Widgets.IconColorProject icon_project;

    public signal void selected ();

    private Gee.HashMap<ulong, weak GLib.Object> signal_map = new Gee.HashMap<ulong, weak GLib.Object> ();

    public ProjectPickerRow (Objects.Project project) {
        Object (
            project: project
        );
    }

    ~ProjectPickerRow () {
        debug ("Destroying - Widgets.ProjectPicker.ProjectPickerRow\n");
    }

    construct {
        css_classes = { "row", "no-padding" };

        icon_project = new Widgets.IconColorProject (20);
        icon_project.project = project;

        name_label = new Gtk.Label (null);
        name_label.valign = Gtk.Align.CENTER;
        name_label.ellipsize = Pango.EllipsizeMode.END;

        var selected_icon = new Gtk.Image.from_icon_name ("checkmark-small-symbolic") {
            pixel_size = 16,
            hexpand = true,
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.END,
            margin_end = 3
        };
        selected_icon.add_css_class ("color-primary");

        selected_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.CROSSFADE,
            child = selected_icon,
            reveal_child = false
        };

        var content_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            margin_start = 3,
            margin_end = 3,
            margin_top = 6,
            margin_bottom = 6
        };
        content_box.append (icon_project);
        content_box.append (name_label);
        content_box.append (selected_revealer);

        main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            child = content_box
        };

        child = main_revealer;
        update_request ();

        Timeout.add (main_revealer.transition_duration, () => {
            main_revealer.reveal_child = true;
            return GLib.Source.REMOVE;
        });

        var select_gesture = new Gtk.GestureClick ();
        add_controller (select_gesture);
        signal_map[select_gesture.pressed.connect (() => {
            selected ();
        })] =select_gesture ;

        signal_map[activate.connect (() => {
            selected ();
        })] = this;

        notify["is-selected"].connect (() => {
            selected_revealer.reveal_child = is_selected;
        });
    }

    public void update_request () {
        name_label.label = project.inbox_project ? _("Inbox") : project.name;
        icon_project.update_request ();
    }

    public void clean_up () {
        foreach (var entry in signal_map.entries) {
            entry.value.disconnect (entry.key);
        }

        signal_map.clear ();

        if (icon_project != null) {
            icon_project.clean_up ();
        }
    }
}
