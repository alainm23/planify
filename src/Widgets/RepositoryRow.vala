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

public class Widgets.RepositoryRow : Gtk.ListBoxRow {
    public Objects.Repository repository { get; construct; }

    public RepositoryRow (Objects.Repository _objec) {
        Object (
            repository: _objec
        );
    }

    construct {
        get_style_context ().add_class ("task");
        selectable = false;

        var repo_icon = new Gtk.Image ();
        repo_icon.gicon = new ThemedIcon ("planner-repository-symbolic");
        repo_icon.pixel_size = 16;

        var name_label = new Gtk.Label (repository.name);
        name_label.margin_bottom = 1;
        name_label.get_style_context ().add_class ("h3");

        var sensitive_switch = new Gtk.Switch ();
        sensitive_switch.margin_end = 6;
        sensitive_switch.get_style_context ().add_class ("active-switch");
        sensitive_switch.valign = Gtk.Align.CENTER;

        if (repository.sensitive == 0) {
            sensitive_switch.active = false;
        } else {
            sensitive_switch.active = true;
        }

        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        box.margin = 6;
        box.expand = true;

        box.pack_start (repo_icon, false, false, 0);
        box.pack_start (name_label, false, false, 6);
        box.pack_end (sensitive_switch, false, false, 0);

        var main_grid = new Gtk.Grid ();
        main_grid.orientation = Gtk.Orientation.VERTICAL;

        main_grid.add (box);
        main_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));

        var eventbox = new Gtk.EventBox ();
        eventbox.add (main_grid);

        add (eventbox);

        sensitive_switch.notify["active"].connect(() => {
            if (sensitive_switch.active) {
                repository.sensitive = 1;
            } else {
                repository.sensitive = 0;
            }

            Application.database.update_repository (repository);
        });

        eventbox.event.connect ((event) => {
            if (event.type == Gdk.EventType.BUTTON_PRESS) {
                if (sensitive_switch.active) {
                    sensitive_switch.active = false;
                } else {
                    sensitive_switch.active = true;
                }
            }
            return false;
        });
    }
}
