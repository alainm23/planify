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

public class Widgets.StatusButton : Adw.Bin {
    public bool is_board { get; construct; }

    private Gtk.Image status_image;
    private Gtk.Label value_label;
    private Gtk.Popover popover_picker = null;

    public signal void changed (bool status);

    public StatusButton () {
        Object (
            tooltip_text: _("Set The Status")
        );
    }

    construct {
        status_image = new Gtk.Image.from_icon_name ("check-round-outline-symbolic");

        var title_label = new Gtk.Label (_("Status")) {
            halign = START,
            css_classes = { "title-4", "caption" }
        };

        value_label = new Gtk.Label (_("To Do")) {
            xalign = 0,
            use_markup = true,
            halign = START,
            css_classes = { "caption" }
        };

        var card_grid = new Gtk.Grid () {
            column_spacing = 12,
            margin_start = 12,
            margin_end = 6,
            margin_top = 6,
            margin_bottom = 6,
            vexpand = true,
            hexpand = true
        };
        card_grid.attach (status_image, 0, 0, 1, 2);
        card_grid.attach (title_label, 1, 0, 1, 1);
        card_grid.attach (value_label, 1, 1, 1, 1);

        var menu_button = new Gtk.MenuButton () {
            popover = build_popover (),
            child = card_grid,
            css_classes = { "flat", "card", "activatable", "menu-button-no-padding" },
            hexpand = true
        };

        child = menu_button;
    }


    public Gtk.Popover build_popover () {
        var todo_item = new Widgets.ContextMenu.MenuItem (_("To Do"), "check-round-outline-symbolic");
        var complete_item = new Widgets.ContextMenu.MenuItem (_("Complete"), "check-round-outline-symbolic");
        complete_item.add_css_class ("completed-color");

        var menu_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        menu_box.margin_top = menu_box.margin_bottom = 3;
        menu_box.append (todo_item);
        menu_box.append (complete_item);

        var popover = new Gtk.Popover () {
            has_arrow = false,
            child = menu_box,
            position = Gtk.PositionType.BOTTOM
        };

        todo_item.clicked.connect (() => {
            popover.popdown ();
            changed (false);
        });

        complete_item.clicked.connect (() => {
            popover.popdown ();
            changed (true);
        });

        return popover;
    }

    public void update_from_item (Objects.Item item) {
        set_status (item.completed);
    }

    public void set_status (bool active) {
        if (active) {
            status_image.add_css_class ("completed-image-color");
            value_label.label = _("Complete");
        } else {
            status_image.remove_css_class ("completed-image-color");
            value_label.label = _("To Do");
        }
    }
}
