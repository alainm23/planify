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

public class Objects.Repository {
    public int64 id;
    public string name;
    public int sensitive;
    public string issues;
    public int64 user_id;

    public Repository (int64 id = 0,
                       string name = "",
                       int sensitive = 0,
                       string issues = "",
                       int64 user_id = 0) {
        this.id = id;
        this.name = name;
        this.sensitive = sensitive;
        this.issues = issues;
        this.user_id = user_id;
    }
}