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

public class Objects.Notification {
    public int id;
    public int task_id;
    public string summary;
    public string body;
    public string primary_icon;
    public string secondary_icon;

    public Notification (int id = 0,
                         int task_id = 0,
                         string summary = "",
                         string body = "",
                         string primary_icon = "",
                         string secondary_icon = "") {
        this.id = id;
        this.task_id = task_id;
        this.summary = summary;
        this.body = body;
        this.primary_icon = primary_icon;
        this.secondary_icon = secondary_icon;
    }
}
