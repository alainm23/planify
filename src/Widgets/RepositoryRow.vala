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

        var checked_button = new Gtk.CheckButton.with_label (repository.name);
        checked_button.can_focus = false;
        checked_button.get_style_context ().add_class ("h3");

        if (repository.sensitive == 0) {
            checked_button.active = false;
        } else {
            checked_button.active = true;
        }

        var main_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        main_box.margin = 3;
        main_box.expand = true;

        main_box.pack_start (checked_button, false, false, 0);

        add (main_box);

        checked_button.toggled.connect (() => {
			if (checked_button.active) {
                repository.sensitive = 1;
			} else {
                repository.sensitive = 0;
            }
            
            Application.database.update_repository (repository);
		});
    }
}
