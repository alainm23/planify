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

public class Widgets.PriorityButton : Adw.Bin {
    public bool is_board { get; construct; }

    private Gtk.Image priority_image;
    private Gtk.Label priority_label;
    private Gtk.MenuButton button; 
    private Gtk.Popover priority_picker = null;

    public signal void changed (int priority);

    public PriorityButton () {
        Object (
            is_board: false,
            valign: Gtk.Align.CENTER,
            halign: Gtk.Align.CENTER,
            tooltip_text: _("Set The Priority")
        );
    }

    public PriorityButton.for_board () {
        Object (
            is_board: true,
            tooltip_text: _("Set The Priority")
        );
    }

    construct {
        if (is_board) {
            build_card_ui ();
        } else {
            build_ui ();
        }
    }

    private void build_ui () {
        priority_image = new Gtk.Image.from_icon_name ("flag-outline-thick-symbolic");

        button = new Gtk.MenuButton () {
            css_classes = { "flat" },
            valign = Gtk.Align.CENTER,
			halign = Gtk.Align.CENTER,
            child = priority_image,
            popover = build_popover (),
        };

        child = button;
    }

    private void build_card_ui () {
        priority_image = new Gtk.Image.from_icon_name ("flag-outline-thick-symbolic");

        var title_label = new Gtk.Label (_("Priority")) {
            halign = START,
            css_classes = { "title-4", "small-label" }
        };

        priority_label = new Gtk.Label (_("Priority 4: None")) {
            xalign = 0,
            use_markup = true,
            halign = START,
            css_classes = { "small-label" }
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
        card_grid.attach (priority_image, 0, 0, 1, 2);
        card_grid.attach (title_label, 1, 0, 1, 1);
        card_grid.attach (priority_label, 1, 1, 1, 1);

        var priority_popover = build_popover ();
        priority_popover.position = Gtk.PositionType.BOTTOM;
        priority_popover.has_arrow = true;
        priority_popover.set_parent (card_grid);

        css_classes = { "card" };
        child = card_grid;
        hexpand = true;
        vexpand = true;

        var click_gesture = new Gtk.GestureClick ();
        card_grid.add_controller (click_gesture);
        click_gesture.pressed.connect ((n_press, x, y) => {
            priority_popover.show ();
        });
    }

    public Gtk.Popover build_popover () {
        var priority_1_item = new Widgets.ContextMenu.MenuItem (_("Priority 1: High"), "flag-outline-thick-symbolic");
        priority_1_item.add_css_class ("priority-1-button");

        var priority_2_item = new Widgets.ContextMenu.MenuItem (_("Priority 2: Medium"), "flag-outline-thick-symbolic");
        priority_2_item.add_css_class ("priority-2-button");

        var priority_3_item = new Widgets.ContextMenu.MenuItem (_("Priority 3: Low"), "flag-outline-thick-symbolic");
        priority_3_item.add_css_class ("priority-3-button");

        var priority_4_item = new Widgets.ContextMenu.MenuItem (_("Priority 4: None"), "flag-outline-thick-symbolic");

        var menu_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        menu_box.margin_top = menu_box.margin_bottom = 3;
        menu_box.append (priority_1_item);
        menu_box.append (priority_2_item);
        menu_box.append (priority_3_item);
        menu_box.append (priority_4_item);

        priority_picker = new Gtk.Popover () {
            has_arrow = false,
            child = menu_box,
            position = Gtk.PositionType.BOTTOM
        };

        priority_1_item.clicked.connect (() => {
            priority_picker.popdown ();
            changed (Constants.PRIORITY_1);
        });

        priority_2_item.clicked.connect (() => {
            priority_picker.popdown ();
            changed (Constants.PRIORITY_2);
        });

        priority_3_item.clicked.connect (() => {
            priority_picker.popdown ();
            changed (Constants.PRIORITY_3);
        });

        priority_4_item.clicked.connect (() => {
            priority_picker.popdown ();
            changed (Constants.PRIORITY_4);
        });

        return priority_picker;
    }
    
    public void update_from_item (Objects.Item item) {
        set_priority (item.priority);
    }

    public void set_priority (int priority) {
        if (priority == Constants.PRIORITY_1) {
            priority_image.css_classes = { "priority-1-icon" };

            if (is_board) {
                priority_label.label = _("Priority 1: High");
            }
        } else if (priority == Constants.PRIORITY_2) {
            priority_image.css_classes = { "priority-2-icon" };

            if (is_board) {
                priority_label.label = _("Priority 1: Medium");
            }
        } else if (priority == Constants.PRIORITY_3) {
            priority_image.css_classes = { "priority-3-icon" };

            if (is_board) {
                priority_label.label = _("Priority 1: Low");
            }
        } else {
            priority_image.css_classes = { };

            if (is_board) {
                priority_label.label = _("Priority 4: None");
            }
        }
    }
    
    public void reset () {
        priority_image.icon_name = "flag-outline-thick-symbolic";
    }
}
