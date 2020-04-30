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

public class Project : GLib.Object {
    public int64 area_id { get; set; default = 0; }
    public int64 id { get; set; default = 0; }

    public string name { get; set; default = ""; }
    public string note { get; set; default = ""; }
    public string due_date { get; set; default = ""; }

    public int color { get; set; default = 0; }
    public int is_todoist { get; set; default = 0; }
    public int inbox_project { get; set; default = 0; }
    public int team_inbox { get; set; default = 0; }
    public int item_order { get; set; default = 0; }
    public int is_deleted { get; set; default = 0; }
    public int is_archived { get; set; default = 0; }
    public int is_favorite { get; set; default = 0; }
    public int64 is_sync { get; set; default = 0; }
    public int shared { get; set; default = 0; }
    public int is_kanban { get; set; default = 0; }
    public int show_completed { get; set; default = 0; }
}
