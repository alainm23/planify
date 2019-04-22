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

public class Objects.User {
    public int64 id;
    public string full_name;
    public string email;
    public string token;
    public string sync_token;
    public int is_todoist;
    public int is_premium;
    public string avatar;
    public string join_date;
    public int64 inbox_project;

    public User (int64 id = 0,
                 string full_name = "",
                 string email = "",
                 string token = "",
                 string sync_token = "",
                 int is_todoist = 0,
                 int is_premium = 0,
                 string avatar = "",
                 string join_date = "",
                 int64 inbox_project = 0) {

        this.id = id;
        this.full_name = full_name;
        this.email = email;
        this.token = token;
        this.sync_token = sync_token;
        this.is_todoist = is_todoist;
        this.is_premium = is_premium;
        this.avatar = avatar;
        this.join_date = join_date;
        this.inbox_project = inbox_project;
    }
}