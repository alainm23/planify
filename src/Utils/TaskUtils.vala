/*
 * Copyright © 2025 Alain M. (https://github.com/alainm23/planify)
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

public class Utils.TaskUtils {
    public static void update_single_item_order (Gtk.ListBox listbox, Layouts.ItemBase moved_row, int new_index) {
        var rows = new Gee.ArrayList<Layouts.ItemBase> ();
        for (int i = 0; i < Util.get_default ().get_children (listbox).length (); i++) {
            var row = (Layouts.ItemBase) listbox.get_row_at_index (i);
            if (row != null) {
                rows.add (row);
            }
        }

        Layouts.ItemBase? prev = null;
        Layouts.ItemBase? next = null;

        if (new_index > 0) {
            prev = rows.get (new_index - 1);
        }
        if (new_index < rows.size - 1) {
            next = rows.get (new_index + 1);
        }

        if (prev == null && next != null) {
            moved_row.item.child_order = (int) (next.item.child_order / 2);
        } else if (prev != null && next == null) {
            moved_row.item.child_order = prev.item.child_order + 1000;
        } else if (prev != null && next != null) {
            moved_row.item.child_order = (int) ((prev.item.child_order + next.item.child_order) / 2);
        } else {
            moved_row.item.child_order = 1000;
        }

        moved_row.item.update_async ();

        if (prev != null && next != null && moved_row.item.child_order == prev.item.child_order) {
            normalize_orders (rows);
        }
    }

    public static void normalize_orders (Gee.ArrayList<Layouts.ItemBase> rows) {
        int spacing = 1000;
        int order = spacing;

        foreach (var row in rows) {
            row.item.child_order = order;
            order += spacing;
            row.item.update_async ();
        }
    }
}