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

public class Models.ItemList : GLib.Object, GLib.ListModel {
    public Gee.ArrayList<Objects.Item> entries { get; construct; }

    public ItemList (Gee.ArrayList<Objects.Item> entries) {
        Object (entries: entries);
    }

    public uint get_n_items () {
        return entries.size;
    }

    public GLib.Type get_item_type () {
        return typeof (Objects.Item);
    }

    public GLib.Object ? get_item (uint position) {
        if (position > entries.size) {
            return null;
        }
        
        return entries[(int) position];
    }
}