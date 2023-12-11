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

public class Objects.ItemLabel : Objects.BaseObject {
    public string item_id { get; set; default = ""; }
    public string label_id { get; set; default = ""; }

    Objects.Label? _label = null;
    public Objects.Label label {
        get {
            if (_label == null) {
                _label = Services.Database.get_default ().get_label (label_id);
            }
            return _label;
        }
    }

    Objects.Item? _item = null;
    public Objects.Item item {
        get {
            if (_item == null) {
                _item = Services.Database.get_default ().get_item (item_id);
            }
            return _item;
        }
    }
}