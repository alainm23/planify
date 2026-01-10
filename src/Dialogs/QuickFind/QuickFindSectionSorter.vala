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

public class Dialogs.QuickFind.QuickFindSectionSorter : Gtk.Sorter {
    public override Gtk.Ordering compare (Object? item1, Object? item2) {
        var a = item1 as Dialogs.QuickFind.QuickFindItem;
        if (a == null)
        return Gtk.Ordering.SMALLER;

        var b = item2 as Dialogs.QuickFind.QuickFindItem;
        if (b == null)
        return Gtk.Ordering.LARGER;

        var type_a = a.base_object.object_type;
        var type_b = b.base_object.object_type;

        if (type_a != type_b) {
            int order_a = get_type_order (type_a);
            int order_b = get_type_order (type_b);

            if (order_a < order_b)
            return Gtk.Ordering.SMALLER;
            else
            return Gtk.Ordering.LARGER;
        }

        return Gtk.Ordering.EQUAL;
    }

    private int get_type_order (ObjectType type) {
        switch (type) {
            case ObjectType.FILTER:
                return 0;
            case ObjectType.PROJECT:
                return 1;
            case ObjectType.SECTION:
                return 2;
            case ObjectType.ITEM:
                return 3;
            case ObjectType.LABEL:
                return 4;
            default:
                return 99;
        }
    }

    public override Gtk.SorterOrder get_order () {
        return Gtk.SorterOrder.PARTIAL;
    }
}
