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

public class Widgets.PriorityButton : Gtk.ToggleButton {
    public Objects.Item item { get; construct; }
    private Gtk.Popover popover = null;
    private Gtk.Image priority_image;

    public PriorityButton (Objects.Item item) {
        Object (
            item: item
        );
    }

    construct {
        tooltip_text = _("Priority");

        get_style_context ().add_class ("flat");
        get_style_context ().add_class ("item-action-button");

        priority_image = new Gtk.Image ();
        priority_image.gicon = new ThemedIcon ("priority-symbolic");
        priority_image.pixel_size = 13;

        add (priority_image);

        this.toggled.connect (() => {
            if (this.active) {
                if (popover == null) {
                    create_popover ();
                }

                popover.popup ();
            }
        });

        update_icon (item);
    }

    public void update_icon (Objects.Item item) {
        priority_image.get_style_context ().remove_class ("priority-1-icon");
        priority_image.get_style_context ().remove_class ("priority-2-icon");
        priority_image.get_style_context ().remove_class ("priority-3-icon");
        priority_image.get_style_context ().remove_class ("priority-4-icon");

        if (item.priority == 1) {
            priority_image.get_style_context ().add_class ("priority-4-icon");
        } else if (item.priority == 2) {
            priority_image.get_style_context ().add_class ("priority-3-icon");
        } else if (item.priority == 3) {
            priority_image.get_style_context ().add_class ("priority-2-icon");
        } else if (item.priority == 4) {
            priority_image.get_style_context ().add_class ("priority-1-icon");
        }
    }

    public void set_priority (int priority) {
        item.priority = priority;

        Planner.database.update_item (item);
        if (item.is_todoist == 1) {
            Planner.todoist.update_item (item);
        }

        popover.popdown ();
    }

    private void create_popover () {
        popover = new Gtk.Popover (this);
        popover.position = Gtk.PositionType.BOTTOM;
        popover.get_style_context ().add_class ("popover-background");

        var priority_1_menu = new Widgets.ModelButton (_("Priority 1"), "priority-symbolic", "");
        priority_1_menu.item_image.get_style_context ().add_class ("priority-1-icon");

        var priority_2_menu = new Widgets.ModelButton (_("Priority 2"), "priority-symbolic", "");
        priority_2_menu.item_image.get_style_context ().add_class ("priority-2-icon");
        
        var priority_3_menu = new Widgets.ModelButton (_("Priority 3"), "priority-symbolic", "");
        priority_3_menu.item_image.get_style_context ().add_class ("priority-3-icon");

        var priority_4_menu = new Widgets.ModelButton (_("Priority 4"), "priority-symbolic", "");
        priority_4_menu.item_image.get_style_context ().add_class ("priority-4-icon");

        var popover_grid = new Gtk.Grid ();
        popover_grid.margin_top = 6;
        popover_grid.margin_bottom = 6;
        popover_grid.width_request = 150;
        popover_grid.orientation = Gtk.Orientation.VERTICAL;
        popover_grid.add (priority_1_menu);
        popover_grid.add (priority_2_menu);
        popover_grid.add (priority_3_menu);
        popover_grid.add (priority_4_menu);
        popover_grid.show_all ();

        popover.add (popover_grid);

        popover.closed.connect (() => {
            this.active = false;
        });

        priority_1_menu.clicked.connect (() => {
            set_priority (4);
        });

        priority_2_menu.clicked.connect (() => {
            set_priority (3);
        });

        priority_3_menu.clicked.connect (() => {
            set_priority (2);
        });

        priority_4_menu.clicked.connect (() => {
            set_priority (1);
        });
    }
}
