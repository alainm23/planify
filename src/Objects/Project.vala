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
    public int color;
    public string due;
    public bool is_todoist;
    public bool inbox_project;
    public bool team_inbox;
    public int child_order;
    public int is_deleted;
    public int is_archived;
    public int is_favorite;

    public Project (int64 id = 0,
                    string name = "",
                    string note = "",
                    int color = 30,
                    string due = "",
                    int child_order = 0,
                    bool is_todoist = false,
                    bool inbox_project = false,
                    bool team_inbox = false,
                    int is_deleted = 0,
                    int is_archived = 0,
                    int is_favorite = 0) {

        this.id = id;
        this.name = name;
        this.note = note;
        this.color = color;
        this.due = due;
        this.child_order = child_order;
        this.is_todoist = is_todoist;
        this.inbox_project = inbox_project;
        this.is_deleted = is_deleted;
        this.is_archived = is_archived;
        this.is_favorite = is_favorite;
    }
}