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
    public int64 id;
    public string name;
    public string note;
    public string color;
    public string icon;
    public string labels;
    public string duedate;
    public int item_order;
    public int is_todoist;
    public int is_deleted;
    public int is_archived;
    public int is_favorite;

    public Project (int64 id = 0,
                    string name = "",
                    string note = "",
                    string color = "",
                    string icon = "",
                    string labels = "",
                    string duedate = "",
                    int item_order = 0,
                    int is_todoist = 0,
                    int is_deleted = 0,
                    int is_archived = 0,
                    int is_favorite = 0) {

        this.id = id;
        this.name = name;
        this.note = note;
        this.color = color;
        this.icon = icon;
        this.labels = labels;
        this.duedate = duedate;
        this.item_order = item_order;
        this.is_todoist = is_todoist;
        this.is_deleted = is_deleted;
        this.is_archived = is_archived;
        this.is_favorite = is_favorite;
    }
}