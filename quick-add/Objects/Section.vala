/*
* Copyright © 2019 Alain M. (https://github.com/alainm23/planner)
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

public class Objects.Section : GLib.Object {
    public int64 id { get; set; default = Constants.INACTIVE; }
    public string name { get; set; default = ""; }
    public int64 project_id { get; set; default = 0; }
    public string archived_at { get; set; default = ""; }
    public string added_at { get; set; default = ""; }
    public int section_order { get; set; default = 0; }
    public bool collapsed { get; set; default = true; }
    public bool is_deleted { get; set; default = true; }
    public bool is_archived { get; set; default = true; }

    string _short_name;
    public string short_name {
        get {
            _short_name = QuickAddUtil.get_short_name (name);
            return _short_name;
        }
    }
}
