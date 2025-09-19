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

public class Dialogs.ProjectPicker.ProjectPickerRow : Gtk.ListBoxRow {
    public string widget_type { get; construct; }
    public Objects.Project project { get; construct; }

    private Gtk.Label name_label;
    private Gtk.Revealer main_revealer;
    private Widgets.IconColorProject icon_project;

    private Gee.HashMap<ulong, weak GLib.Object> signal_map = new Gee.HashMap<ulong, weak GLib.Object> ();

    public ProjectPickerRow (Objects.Project project, string widget_type = "picker") {
        Object (
            project: project,
            widget_type: widget_type
        );
    }

    ~ProjectPickerRow () {
        debug ("Destroying - Dialogs.ProjectPicker.ProjectPickerRow\n");
    }

    construct {
        add_css_class ("no-selectable");
        add_css_class ("transition");

        icon_project = new Widgets.IconColorProject (10);
        icon_project.project = project;

        name_label = new Gtk.Label (null);
        name_label.valign = Gtk.Align.CENTER;
        name_label.ellipsize = Pango.EllipsizeMode.END;

        var selected_icon = new Gtk.Image () {
            gicon = new ThemedIcon ("checkmark-small-symbolic"),
            pixel_size = 16,
            hexpand = true,
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.END,
            margin_end = 3
        };

        selected_icon.add_css_class ("color-primary");

        var selected_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.CROSSFADE
        };

        selected_revealer.child = selected_icon;

        var menu_button = new Gtk.MenuButton () {
            hexpand = true,
            halign = END,
            popover = build_context_menu (),
            icon_name = "view-more-symbolic",
            css_classes = { "flat" }
        };

        var content_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            margin_top = 9,
            margin_start = 9,
            margin_end = 9,
            margin_bottom = 9
        };
        content_box.append (icon_project);
        content_box.append (name_label);

        if (widget_type == "picker") {
            content_box.append (selected_revealer);
        }

        if (widget_type == "menu") {
            content_box.margin_top = 3;
            content_box.margin_bottom = 3;
            content_box.margin_end = 3;
            content_box.append (menu_button);
        }

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
            Services.EventBus.get_default ().project_picker_changed (project.id);
        })] = select_gesture;

        signal_map[Services.EventBus.get_default ().project_picker_changed.connect ((id) => {
            selected_revealer.reveal_child = project.id == id;
        })] = Services.EventBus.get_default ();

        signal_map[project.deleted.connect (() => {
            hide_destroy ();
        })] = project;

        signal_map[project.unarchived.connect (() => {
            hide_destroy ();
        })] = project;

        destroy.connect (() => {            
            foreach (var entry in signal_map.entries) {
                entry.value.disconnect (entry.key);
            }

            signal_map.clear ();
        });
    }

    public void update_request () {
        name_label.label = project.inbox_project ? _("Inbox") : project.name;
        icon_project.update_request ();
    }

    public void hide_destroy () {
        main_revealer.reveal_child = false;
        clean_up ();
        Timeout.add (main_revealer.transition_duration, () => {
            ((Gtk.ListBox) parent).remove (this);
            return GLib.Source.REMOVE;
        });
    }

    private Gtk.Popover build_context_menu () {
        var unarchive_item = new Widgets.ContextMenu.MenuItem (_("Unarchive"), "shoe-box-symbolic");
        var delete_item = new Widgets.ContextMenu.MenuItem (_("Delete Project"), "user-trash-symbolic");
        delete_item.add_css_class ("menu-item-danger");

        var menu_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        menu_box.margin_top = menu_box.margin_bottom = 3;

        menu_box.append (unarchive_item);
        menu_box.append (delete_item);

        var menu_popover = new Gtk.Popover () {
            has_arrow = false,
            child = menu_box,
            position = Gtk.PositionType.BOTTOM,
            width_request = 250
        };

        signal_map[delete_item.clicked.connect (() => {
            menu_popover.popdown ();
            project.delete_project ((Gtk.Window) Planify.instance.main_window);
        })] = delete_item;

        signal_map[unarchive_item.clicked.connect (() => {
            menu_popover.popdown ();
            project.unarchive_project ();
        })] = unarchive_item;

        return menu_popover;
    }

    public void clean_up () {
        foreach (var entry in signal_map.entries) {
            entry.value.disconnect (entry.key);
        }

        signal_map.clear ();
    }
}
