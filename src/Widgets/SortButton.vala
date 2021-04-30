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

public class Widgets.SortButton : Gtk.ToggleButton {
    public Objects.Project project { get; set; }

    private Gtk.Label sort_label;
    private Gtk.Popover popover = null;
    private Gtk.RadioButton duedate_radio;
    private Gtk.RadioButton priority_radio;
    private Gtk.RadioButton name_radio;
    private Gtk.RadioButton none_radio;

    construct {
        margin_bottom = 3;
        can_focus = false;
        valign = Gtk.Align.END;
        get_style_context ().add_class ("flat");
        
        sort_label = new Gtk.Label (_("Sort"));
        sort_label.get_style_context ().add_class ("font-bold");

        var down_icon = new Gtk.Image ();
        down_icon.gicon = new ThemedIcon ("pan-down-symbolic");
        down_icon.pixel_size = 16;

        var main_grid = new Gtk.Grid ();
        main_grid.halign = Gtk.Align.CENTER;
        main_grid.valign = Gtk.Align.CENTER;
        main_grid.add (sort_label);
        main_grid.add (down_icon);

        var main_revealer = new Gtk.Revealer ();
        main_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
        main_revealer.add (main_grid);
        main_revealer.reveal_child = true;

        add (main_revealer);

        notify["project"].connect (() => {
            
        });

        toggled.connect (() => {
            if (active) {
                if (popover == null) {
                    create_popover ();
                }

                if (project.sort_order == 1) {
                    duedate_radio.active = true;
                } else if (project.sort_order == 2) {
                    priority_radio.active = true;
                } else if (project.sort_order == 3) {
                    name_radio.active = true;
                } else if (project.sort_order == 0) {
                    none_radio.active = true;
                }

                popover.popup ();
            }
        });
    }

    private void create_popover () {
        popover = new Gtk.Popover (this);
        popover.position = Gtk.PositionType.BOTTOM;
        popover.get_style_context ().add_class ("popover-background");

        duedate_radio = new Gtk.RadioButton.with_label (null, _("Sort by due date"));
        duedate_radio.get_style_context ().add_class ("item-radio");
        duedate_radio.margin = 9;

        priority_radio = new Gtk.RadioButton.with_label_from_widget (duedate_radio, _("Sort by priority"));
        priority_radio.get_style_context ().add_class ("item-radio");
        priority_radio.margin = 9;
        priority_radio.margin_top = 0;

        name_radio = new Gtk.RadioButton.with_label_from_widget (duedate_radio, _("Sort alphabetically"));
        name_radio.get_style_context ().add_class ("item-radio");
        name_radio.margin = 9;
        name_radio.margin_top = 0;

        none_radio = new Gtk.RadioButton.with_label_from_widget (duedate_radio, _("None"));
        none_radio.get_style_context ().add_class ("item-radio");
        none_radio.margin = 9;
        none_radio.margin_top = 0;

        var popover_grid = new Gtk.Grid ();
        popover_grid.width_request = 150;
        popover_grid.orientation = Gtk.Orientation.VERTICAL;
        popover_grid.add (duedate_radio);
        popover_grid.add (priority_radio);
        popover_grid.add (name_radio);
        popover_grid.add (none_radio);
        popover_grid.show_all ();

        popover.add (popover_grid);

        popover.closed.connect (() => {
            this.active = false;
        });

        duedate_radio.toggled.connect (() => {
            project.sort_order = 1;
            Planner.database.update_sort_order_project (project.id, 1);
        });

        priority_radio.toggled.connect (() => {
            project.sort_order = 2;
            Planner.database.update_sort_order_project (project.id, 2);
        });

        name_radio.toggled.connect (() => {
            project.sort_order = 3;
            Planner.database.update_sort_order_project (project.id, 3);
        });

        none_radio.toggled.connect (() => {
            project.sort_order = 0;
            Planner.database.update_sort_order_project (project.id, 0);
        });
    }
}