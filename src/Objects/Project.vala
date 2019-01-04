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

public class Objects.Project {
    public int id;
    public string name;
    public string note;
    public string deadline;
    public int item_order;
    public int is_deleted;
    public string color;

    public Project (int id = 0,
                    int item_order = 0,
                    int is_deleted = 0,
                    string name = "",
                    string note = "",
                    string deadline = "",
                    string color = "") {

        this.id = id;
        this.name = name;
        this.note = note;
        this.deadline = deadline;
        this.item_order = item_order;
        this.is_deleted = is_deleted;
        this.color = color;
    }
}
