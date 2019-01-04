/*
* Copyright © 2019 Alain M. (https://github.com/alainm23/planner)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
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
* Authored by: Alain M. <alain23@protonmail.com>
*/

public class Widgets.MoveButton : Gtk.ToggleButton {
    private Widgets.Popovers.MovePopover move_popover;

    public signal void on_selected_project (bool is_inbox, Objects.Project project);
    public MoveButton () {
        Object (
            valign: Gtk.Align.CENTER
        );
    }

    construct {
        get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var move_label = new Gtk.Label (_("Move"));
        var move_icon = new Gtk.Image.from_icon_name ("pan-end-symbolic", Gtk.IconSize.MENU);
        move_icon.yalign = 0.9f;

        move_popover = new Widgets.Popovers.MovePopover (this);

        var main_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        main_box.pack_start (move_label, false, false, 0);
        main_box.pack_start (move_icon, false, false, 0);

        add (main_box);

        this.toggled.connect (() => {
          if (this.active) {
            move_popover.show_all ();
            move_popover.update_project_list ();
          }
        });

        move_popover.closed.connect (() => {
            this.active = false;
        });

        move_popover.on_selected_project.connect ((is_inbox, project) => {
            on_selected_project (is_inbox, project);
        });
    }
}
