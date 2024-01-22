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

public class Dialogs.ItemView : Adw.Window {
    public Objects.Item item { get; construct; }

    private Adw.NavigationView navigation_view;
    
    public ItemView (Objects.Item item) {
        Object (
            item: item,
            deletable: true,
            resizable: false,
            modal: false,
            width_request: 700,
            transient_for: (Gtk.Window) Planify.instance.main_window
        );
    }

    construct {
        var parent_page = new Adw.NavigationPage (new Layouts.ItemViewContent (item), item.id);

        navigation_view = new Adw.NavigationView ();
		navigation_view.add (parent_page);

        content = navigation_view;

        Services.EventBus.get_default ().push_item.connect ((item) => {
            navigation_view.push (new Adw.NavigationPage (new Layouts.ItemViewContent (item), item.id));
        });
    }
}
