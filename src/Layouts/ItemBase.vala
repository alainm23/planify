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

public abstract class Layouts.ItemBase : Gtk.ListBoxRow {
    public Objects.Item item { get; construct; }

    public string update_id { get; set; default = Util.get_default ().generate_id (); }

    public abstract void update_request ();
    public abstract void hide_destroy ();
    public abstract void delete_request (bool undo = true);
    public abstract void select_row (bool active);
    public abstract void checked_toggled (bool active, uint ? time = null);
}
