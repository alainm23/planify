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

public class Views.Welcome : Gtk.EventBox {
    Granite.Widgets.Welcome welcome;

    public signal void activated (int index);

    public Welcome () {
        Object (
            margin: 3
        );
    }

    construct {
        welcome = new Granite.Widgets.Welcome ("Planner", _("It helps you stay organized and focus on what matters most to you"));
        welcome.append ("com.github.alainm23.planner", _("New"), "The canonical source for Vala API references.");
        welcome.append ("document-import", _("Migrate"), _("Granite's source code is hosted on GitHub."));
        welcome.append ("planner-todoist", _("Todoist"), _("The canonical source for Vala API references."));

        add (welcome);

        welcome.activated.connect ((index) => {
            activated (index);
        });
    }
}